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

module peripheral_cdc_wb #(
  parameter AUTORUN = 1
);

  //////////////////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam AW = 32;
  localparam DW = 32;

  localparam MEM_SIZE = 256;

  //////////////////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  reg wbm_clk = 1'b1;
  reg wbm_rst = 1'b1;
  reg wbs_clk = 1'b1;
  reg wbs_rst = 1'b1;

  wire [AW-1:0] wbm_m2s_adr;
  wire [DW-1:0] wbm_m2s_dat;
  wire [   3:0] wbm_m2s_sel;
  wire          wbm_m2s_we;
  wire          wbm_m2s_cyc;
  wire          wbm_m2s_stb;
  wire [DW-1:0] wbm_s2m_dat;
  wire          wbm_s2m_ack;

  wire [AW-1:0] wbs_m2s_adr;
  wire [DW-1:0] wbs_m2s_dat;
  wire [   3:0] wbs_m2s_sel;
  wire          wbs_m2s_we;
  wire          wbs_m2s_cyc;
  wire          wbs_m2s_stb;
  wire [DW-1:0] wbs_s2m_dat;
  wire          wbs_s2m_ack;

  wire done;

  integer TRANSACTIONS;

  //////////////////////////////////////////////////////////////////////////////
  //
  // Tasks
  //
  task run;
    begin
      transactor.bfm_master_wb.reset;
      @(posedge wbs_clk) wbs_rst = 1'b0;
      @(posedge wbm_clk) wbm_rst = 1'b0;

      if($value$plusargs("transactions=%d", TRANSACTIONS))
        transactor.set_transactions(TRANSACTIONS);
      transactor.display_settings;
      transactor.run();
      transactor.display_stats;
    end
  endtask

  //////////////////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  generate
    if (AUTORUN) begin
      vlog_tb_utils vtu();
      vlog_tap_generator #("wb_cdc.tap", 1) vtg();

      initial begin
        run;
        vtg.ok("wb_cdc: All tests passed!");
        $finish;
      end
    end
  endgenerate

  always #5 wbm_clk <= ~wbm_clk;
  always #3 wbs_clk <= ~wbs_clk;

  peripheral_bfm_transactor_wb #(
    .MEM_HIGH (MEM_SIZE-1),
    .AUTORUN  (0),
    .VERBOSE  (0)
  )
  transactor (
    .wb_clk_i (wbm_clk),
    .wb_rst_i (1'b0),
    .wb_adr_o (wbm_m2s_adr),
    .wb_dat_o (wbm_m2s_dat),
    .wb_sel_o (wbm_m2s_sel),
    .wb_we_o  (wbm_m2s_we),
    .wb_cyc_o (wbm_m2s_cyc),
    .wb_stb_o (wbm_m2s_stb),
    .wb_cti_o (),
    .wb_bte_o (),
    .wb_dat_i (wbm_s2m_dat),
    .wb_ack_i (wbm_s2m_ack),
    .wb_err_i (1'b0),
    .wb_rty_i (1'b0),
    //Test Control
    .done()
  );

  peripheral_msi_cdc_wb #(
    .AW (AW)
  )
  dut (
    .wbm_clk    (wbm_clk),
    .wbm_rst    (wbm_rst),

    // Master Interface
    .wbm_adr_i (wbm_m2s_adr),
    .wbm_dat_i (wbm_m2s_dat),
    .wbm_sel_i (wbm_m2s_sel),
    .wbm_we_i  (wbm_m2s_we ),
    .wbm_cyc_i (wbm_m2s_cyc),
    .wbm_stb_i (wbm_m2s_stb),
    .wbm_dat_o (wbm_s2m_dat),
    .wbm_ack_o (wbm_s2m_ack),
    // Wishbone Slave interface
    .wbs_clk   (wbs_clk),
    .wbs_rst   (wbs_rst),
    .wbs_adr_o (wbs_m2s_adr),
    .wbs_dat_o (wbs_m2s_dat),
    .wbs_sel_o (wbs_m2s_sel),
    .wbs_we_o  (wbs_m2s_we),
    .wbs_cyc_o (wbs_m2s_cyc),
    .wbs_stb_o (wbs_m2s_stb),
    .wbs_dat_i (wbs_s2m_dat),
    .wbs_ack_i (wbs_s2m_ack & !wbs_rst)
  );

  peripheral_bfm_memory_wb #(
    .DEBUG (0),
    .MEM_SIZE_BYTES (MEM_SIZE)
  )
  mem (
    .wb_clk_i (wbs_clk),
    .wb_rst_i (wbs_rst),
    .wb_adr_i (wbs_m2s_adr),
    .wb_dat_i (wbs_m2s_dat),
    .wb_sel_i (wbs_m2s_sel),
    .wb_we_i  (wbs_m2s_we),
    .wb_cyc_i (wbs_m2s_cyc),
    .wb_stb_i (wbs_m2s_stb),
    .wb_cti_i (3'b000),
    .wb_bte_i (2'b00),
    .wb_dat_o (wbs_s2m_dat),
    .wb_ack_o (wbs_s2m_ack),
    .wb_err_o (),
    .wb_rty_o ()
  );
endmodule
