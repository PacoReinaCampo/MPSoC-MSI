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

module wb_upsizer_tb (
  input wb_clk_i,
  input wb_rst_i,
  output done
);

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam AW = 32;
  localparam MEMORY_SIZE_WORDS = 2**10;

  localparam DW_IN  = 32;
  localparam SCALE  = 2;
  localparam DW_OUT = DW_IN*SCALE;

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  wire [AW     -1:0] wbm_m2s_adr;
  wire [DW_IN  -1:0] wbm_m2s_dat;
  wire [DW_IN/8-1:0] wbm_m2s_sel;
  wire               wbm_m2s_we ;
  wire               wbm_m2s_cyc;
  wire               wbm_m2s_stb;
  wire [        2:0] wbm_m2s_cti;
  wire [        1:0] wbm_m2s_bte;
  wire [DW_IN  -1:0] wbm_s2m_dat;
  wire               wbm_s2m_ack;
  wire               wbm_s2m_err;
  wire               wbm_s2m_rty;

  wire [AW-1:0]       wbs_m2s_adr;
  wire [DW_OUT  -1:0] wbs_m2s_dat;
  wire [DW_OUT/8-1:0] wbs_m2s_sel;
  wire                wbs_m2s_we ;
  wire                wbs_m2s_cyc;
  wire                wbs_m2s_stb;
  wire [         2:0] wbs_m2s_cti;
  wire [         1:0] wbs_m2s_bte;
  wire [DW_OUT  -1:0] wbs_s2m_dat;
  wire                wbs_s2m_ack;
  wire                wbs_s2m_err;
  wire                wbs_s2m_rty;

  wire [        31:0] slave_writes;
  wire [        31:0] slave_reads;

  integer idx;

  time start_time;
  time ack_delay;
  integer num_transactions;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  mpsoc_msi_wb_bfm_transactor #(
    .MEM_HIGH(MEMORY_SIZE_WORDS-1),
    .MEM_LOW (0),
    .VERBOSE (0)
  )
  wb_bfm_transactor (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
    .wb_adr_o (wbm_m2s_adr),
    .wb_dat_o (wbm_m2s_dat),
    .wb_sel_o (wbm_m2s_sel),
    .wb_we_o  (wbm_m2s_we ),
    .wb_cyc_o (wbm_m2s_cyc),
    .wb_stb_o (wbm_m2s_stb),
    .wb_cti_o (wbm_m2s_cti),
    .wb_bte_o (wbm_m2s_bte),
    .wb_dat_i (wbm_s2m_dat),
    .wb_ack_i (wbm_s2m_ack),
    .wb_err_i (wbm_s2m_err),
    .wb_rty_i (wbm_s2m_rty),
    //Test Control
    .done(done)
  );

  always @(done) begin
    if(done === 1) begin
      $display("Average wait times");
      $display("Master : %f", ack_delay/num_transactions);
      $display("%0d : All tests passed!", $time);
    end
  end

  mpsoc_msi_wb_upsizer #(
    .DW_IN (DW_IN),
    .SCALE (SCALE)
  )
  dut (
    .wb_clk_i  (wb_clk_i),
    .wb_rst_i  (wb_rst_i),
    // Master Interface
    .wbs_adr_i (wbm_m2s_adr),
    .wbs_dat_i (wbm_m2s_dat),
    .wbs_sel_i (wbm_m2s_sel),
    .wbs_we_i  (wbm_m2s_we ),
    .wbs_cyc_i (wbm_m2s_cyc),
    .wbs_stb_i (wbm_m2s_stb),
    .wbs_cti_i (wbm_m2s_cti),
    .wbs_bte_i (wbm_m2s_bte),
    .wbs_dat_o (wbm_s2m_dat),
    .wbs_ack_o (wbm_s2m_ack),
    .wbs_err_o (wbm_s2m_err),
    .wbs_rty_o (wbm_s2m_rty),
    // Wishbone Slave interface
    .wbm_adr_o (wbs_m2s_adr),
    .wbm_dat_o (wbs_m2s_dat),
    .wbm_sel_o (wbs_m2s_sel),
    .wbm_we_o  (wbs_m2s_we),
    .wbm_cyc_o (wbs_m2s_cyc),
    .wbm_stb_o (wbs_m2s_stb),
    .wbm_cti_o (wbs_m2s_cti),
    .wbm_bte_o (wbs_m2s_bte),
    .wbm_dat_i (wbs_s2m_dat),
    .wbm_ack_i (wbs_s2m_ack),
    .wbm_err_i (wbs_s2m_err),
    .wbm_rty_i (wbs_s2m_rty)
  );

  assign slave_writes = mem.writes;
  assign slave_reads  = mem.reads;

  initial begin
    ack_delay = 0;
    num_transactions = 0;
    while(1) begin
      @(posedge wbm_m2s_cyc);
      start_time = $time;
      @(posedge wbm_s2m_ack);
      ack_delay = ack_delay + $time-start_time;
      num_transactions = num_transactions+1;
    end
  end

  mpsoc_msi_wb_bfm_memory #(
    .DEBUG (0),
    .DW (DW_OUT),
    .MEM_SIZE_BYTES (MEMORY_SIZE_WORDS*(DW_IN/8))
  )
  mem (
    .wb_clk_i (wb_clk_i),
    .wb_rst_i (wb_rst_i),
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
