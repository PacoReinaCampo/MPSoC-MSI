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

module mpsoc_msi_wb_arbiter #(
  parameter DW = 32,
  parameter AW = 32,
  parameter NUM_MASTERS = 0
)
  (
    input wb_clk_i,
    input wb_rst_i,

    // Wishbone Master Interface
    input  [NUM_MASTERS-1:0][AW-1:0] wbm_adr_i,
    input  [NUM_MASTERS-1:0][DW-1:0] wbm_dat_i,
    input  [NUM_MASTERS-1:0][   3:0] wbm_sel_i,
    input  [NUM_MASTERS-1:0]         wbm_we_i,
    input  [NUM_MASTERS-1:0]         wbm_cyc_i,
    input  [NUM_MASTERS-1:0]         wbm_stb_i,
    input  [NUM_MASTERS-1:0][   2:0] wbm_cti_i,
    input  [NUM_MASTERS-1:0][   1:0] wbm_bte_i,
    output [NUM_MASTERS-1:0][DW-1:0] wbm_dat_o,
    output [NUM_MASTERS-1:0]         wbm_ack_o,
    output [NUM_MASTERS-1:0]         wbm_err_o,
    output [NUM_MASTERS-1:0]         wbm_rty_o, 

    // Wishbone Slave interface
    output [AW-1:0] wbs_adr_o,
    output [DW-1:0] wbs_dat_o,
    output [   3:0] wbs_sel_o, 
    output          wbs_we_o,
    output          wbs_cyc_o,
    output          wbs_stb_o,
    output [   2:0] wbs_cti_o,
    output [   1:0] wbs_bte_o,
    input  [DW-1:0] wbs_dat_i,
    input           wbs_ack_i,
    input           wbs_err_i,
    input           wbs_rty_i
 );

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  parameter MASTER_SEL_BITS = NUM_MASTERS > 1 ? $clog2(NUM_MASTERS) : 1;

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  wire [NUM_MASTERS    -1:0] grant;
  wire [MASTER_SEL_BITS-1:0] master_sel;
  wire                       active;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  mpsoc_msi_arbiter #(
    .NUM_PORTS (NUM_MASTERS)
  )
  arbiter0 (
    .clk       (wb_clk_i),
    .rst       (wb_rst_i),
    .request   (wbm_cyc_i),
    .grant     (grant),
    .selection (master_sel),
    .active    (active)
  );

  //Mux active master
  assign wbs_adr_o = wbm_adr_i[master_sel];
  assign wbs_dat_o = wbm_dat_i[master_sel];
  assign wbs_sel_o = wbm_sel_i[master_sel];
  assign wbs_we_o  = wbm_we_i [master_sel];
  assign wbs_cyc_o = wbm_cyc_i[master_sel] & active;
  assign wbs_stb_o = wbm_stb_i[master_sel];
  assign wbs_cti_o = wbm_cti_i[master_sel];
  assign wbs_bte_o = wbm_bte_i[master_sel];

  assign wbm_dat_o = {NUM_MASTERS{wbs_dat_i}};
  assign wbm_ack_o = ((wbs_ack_i & active) << master_sel);
  assign wbm_err_o = ((wbs_err_i & active) << master_sel);
  assign wbm_rty_o = ((wbs_rty_i & active) << master_sel);   
endmodule // wb_arbiter
