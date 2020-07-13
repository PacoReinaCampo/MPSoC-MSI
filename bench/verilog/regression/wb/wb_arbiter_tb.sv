////////////////////////////////////////////////////////////////////////////////
//                                            __ _      _     _               //
//                                           / _(_)    | |   | |              //
//                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
//               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
//              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
//               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
//                  | |                                                       //
//                  |_|                                                       //
//                                                                            //
//                                                                            //
//              MPSoC-RISCV CPU                                               //
//              Master Slave Interface                                        //
//              Wishbone Bus Interface                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* Copyright (c) 2018-2019 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 * Author(s):
 *   Olof Kindgren <olof.kindgren@gmail.com>
 *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
 */

`default_nettype none
module wb_arbiter_tb #(
  parameter NUM_MASTERS = 5,
  parameter AUTORUN     = 1
);

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam AW = 32;
  localparam DW = 32;

  localparam MEMORY_SIZE_BITS  = 8;
  localparam MEMORY_SIZE_WORDS = 2**MEMORY_SIZE_BITS;

  parameter TRANSACTIONS_PARAM = 1000;

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  reg wb_clk = 1'b1;
  reg wb_rst = 1'b1;

  wire [AW-1:0] wbs_m2s_adr;
  wire [DW-1:0] wbs_m2s_dat;
  wire [   3:0] wbs_m2s_sel;
  wire          wbs_m2s_we;
  wire          wbs_m2s_cyc;
  wire          wbs_m2s_stb;
  wire [   2:0] wbs_m2s_cti;
  wire [   1:0] wbs_m2s_bte;
  wire [DW-1:0] wbs_s2m_dat;
  wire          wbs_s2m_ack;
  wire          wbs_s2m_err;
  wire          wbs_s2m_rty;

  wire [NUM_MASTERS-1:0][AW-1:0] wbm_m2s_adr;
  wire [NUM_MASTERS-1:0][DW-1:0] wbm_m2s_dat;
  wire [NUM_MASTERS-1:0][   3:0] wbm_m2s_sel;
  wire [NUM_MASTERS-1:0]         wbm_m2s_we;
  wire [NUM_MASTERS-1:0]         wbm_m2s_cyc;
  wire [NUM_MASTERS-1:0]         wbm_m2s_stb;
  wire [NUM_MASTERS-1:0][   2:0] wbm_m2s_cti;
  wire [NUM_MASTERS-1:0][   1:0] wbm_m2s_bte;
  wire [NUM_MASTERS-1:0][DW-1:0] wbm_s2m_dat;
  wire [NUM_MASTERS-1:0]         wbm_s2m_ack;
  wire [NUM_MASTERS-1:0]         wbm_s2m_err;
  wire [NUM_MASTERS-1:0]         wbm_s2m_rty;

  wire [           31:0] slave_writes;
  wire [           31:0] slave_reads;
  wire [NUM_MASTERS-1:0] done_int;
  wire                   done;

  integer TRANSACTIONS;

  time start_time[NUM_MASTERS-1:0];
  time ack_delay[NUM_MASTERS-1:0];
  integer num_transactions[NUM_MASTERS-1:0];

  genvar i;

  //////////////////////////////////////////////////////////////////
  //
  // Tasks
  //
  task run;
    integer idx;
    begin
      wb_rst = 1'b0;
      @(posedge done);
      $display("Average wait times");
      for(idx=0;idx<NUM_MASTERS;idx=idx+1)
        $display("Master %0d : %f",idx, ack_delay[idx]/num_transactions[idx]);
    end
  endtask

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  generate
    if (AUTORUN) begin
      vlog_tb_utils vtu();
      vlog_tap_generator #("wb_arbiter.tap", 1) vtg();
      initial begin
        #100 run;
        vtg.ok("wb_arbiter: All tests passed!");
        $finish;
      end
    end
  endgenerate

  always #5 wb_clk <= ~wb_clk;

  generate
    for(i=0;i<NUM_MASTERS;i=i+1) begin : masters
      initial begin
        @(negedge wb_rst);
        if($value$plusargs("transactions=%d", TRANSACTIONS))
          transactor.set_transactions(TRANSACTIONS);
        transactor.display_settings;
        transactor.run();
        transactor.display_stats;
      end

      mpsoc_msi_wb_bfm_transactor #(
        .MEM_HIGH ((i+1)*MEMORY_SIZE_WORDS-1),
        .AUTORUN  (0),
        .MEM_LOW  (i*MEMORY_SIZE_WORDS)
      )
      transactor (
        .wb_clk_i (wb_clk),
        .wb_rst_i (wb_rst),
        .wb_adr_o (wbm_m2s_adr[i]),
        .wb_dat_o (wbm_m2s_dat[i]),
        .wb_sel_o (wbm_m2s_sel[i]),
        .wb_we_o  (wbm_m2s_we[i] ),
        .wb_cyc_o (wbm_m2s_cyc[i]),
        .wb_stb_o (wbm_m2s_stb[i]),
        .wb_cti_o (wbm_m2s_cti[i]),
        .wb_bte_o (wbm_m2s_bte[i]),
        .wb_dat_i (wbm_s2m_dat[i]),
        .wb_ack_i (wbm_s2m_ack[i]),
        .wb_err_i (wbm_s2m_err[i]),
        .wb_rty_i (wbm_s2m_rty[i]),
        //Test Control
        .done(done_int[i])
      );
    end // block: slaves
  endgenerate

  assign done = &done_int;

  mpsoc_msi_wb_arbiter #(
    .NUM_MASTERS (NUM_MASTERS)
  )
  wb_arbiter (
    .wb_clk_i (wb_clk),
    .wb_rst_i (wb_rst),

    // Master Interface
    .wbm_adr_i (wbm_m2s_adr),
    .wbm_dat_i (wbm_m2s_dat),
    .wbm_sel_i (wbm_m2s_sel),
    .wbm_we_i  (wbm_m2s_we ),
    .wbm_cyc_i (wbm_m2s_cyc),
    .wbm_stb_i (wbm_m2s_stb),
    .wbm_cti_i (wbm_m2s_cti),
    .wbm_bte_i (wbm_m2s_bte),
    .wbm_dat_o (wbm_s2m_dat),
    .wbm_ack_o (wbm_s2m_ack),
    .wbm_err_o (wbm_s2m_err),
    .wbm_rty_o (wbm_s2m_rty),
    // Wishbone Slave interface
    .wbs_adr_o (wbs_m2s_adr),
    .wbs_dat_o (wbs_m2s_dat),
    .wbs_sel_o (wbs_m2s_sel),
    .wbs_we_o  (wbs_m2s_we),
    .wbs_cyc_o (wbs_m2s_cyc),
    .wbs_stb_o (wbs_m2s_stb),
    .wbs_cti_o (wbs_m2s_cti),
    .wbs_bte_o (wbs_m2s_bte),
    .wbs_dat_i (wbs_s2m_dat),
    .wbs_ack_i (wbs_s2m_ack),
    .wbs_err_i (wbs_s2m_err),
    .wbs_rty_i (wbs_s2m_rty)
  );

  assign slave_writes = wb_mem_model.writes;
  assign slave_reads  = wb_mem_model.reads;

  generate
    for(i=0;i<NUM_MASTERS;i=i+1) begin : wait_time
      initial begin
        ack_delay[i] = 0;
        num_transactions[i] = 0;
        while(!done) begin
          @(posedge wbm_m2s_cyc[i]);
          start_time[i] = $time;
          @(posedge wbm_s2m_ack[i]);
          ack_delay[i] = ack_delay[i] + $time-start_time[i];
          num_transactions[i] = num_transactions[i]+1;
        end
      end
    end
  endgenerate

  mpsoc_msi_wb_bfm_memory #(
    .DEBUG (0),
    .MEM_SIZE_BYTES (MEMORY_SIZE_WORDS*(DW/8)*NUM_MASTERS)
  )
  wb_mem_model (
    .wb_clk_i (wb_clk),
    .wb_rst_i (wb_rst),
    .wb_adr_i (wbs_m2s_adr),
    .wb_dat_i (wbs_m2s_dat),
    .wb_sel_i (wbs_m2s_sel),
    .wb_we_i  (wbs_m2s_we),
    .wb_cyc_i (wbs_m2s_cyc),
    .wb_stb_i (wbs_m2s_stb),
    .wb_cti_i (wbs_m2s_cti),
    .wb_bte_i (wbs_m2s_bte),
    .wb_dat_o (wbs_s2m_dat),
    .wb_ack_o (wbs_s2m_ack),
    .wb_err_o (wbs_s2m_err),
    .wb_rty_o (wbs_s2m_rty)
  );
endmodule
