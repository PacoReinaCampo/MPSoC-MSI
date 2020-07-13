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

module mpsoc_msi_wb_mux #(
  parameter DW = 32,         // Data width
  parameter AW = 32,         // Address width
  parameter NUM_SLAVES = 2,  // Number of slaves

  parameter [NUM_SLAVES*AW-1:0] MATCH_ADDR = 0,
  parameter [NUM_SLAVES*AW-1:0] MATCH_MASK = 0
)
  (
    input                      wb_clk_i,
    input                      wb_rst_i,

    // Master Interface
    input  [AW-1:0]            wbm_adr_i,
    input  [DW-1:0]            wbm_dat_i,
    input  [   3:0]            wbm_sel_i,
    input                      wbm_we_i,
    input                      wbm_cyc_i,
    input                      wbm_stb_i,
    input  [   2:0]            wbm_cti_i,
    input  [   1:0]            wbm_bte_i,
    output [DW-1:0]            wbm_dat_o,
    output                     wbm_ack_o,
    output                     wbm_err_o,
    output                     wbm_rty_o,

    // Wishbone Slave interface
    output [NUM_SLAVES-1:0][AW-1:0] wbs_adr_o,
    output [NUM_SLAVES-1:0][DW-1:0] wbs_dat_o,
    output [NUM_SLAVES-1:0][   3:0] wbs_sel_o,
    output [NUM_SLAVES-1:0]         wbs_we_o,
    output [NUM_SLAVES-1:0]         wbs_cyc_o,
    output [NUM_SLAVES-1:0]         wbs_stb_o,
    output [NUM_SLAVES-1:0][   2:0] wbs_cti_o,
    output [NUM_SLAVES-1:0][   1:0] wbs_bte_o,
    input  [NUM_SLAVES-1:0][DW-1:0] wbs_dat_i,
    input  [NUM_SLAVES-1:0]         wbs_ack_i,
    input  [NUM_SLAVES-1:0]         wbs_err_i,
    input  [NUM_SLAVES-1:0]         wbs_rty_i
  );

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  parameter SLAVE_SEL_BITS = NUM_SLAVES > 1 ? $clog2(NUM_SLAVES) : 1;

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  reg                       wbm_err;
  wire [SLAVE_SEL_BITS-1:0] slave_sel;
  wire [NUM_SLAVES    -1:0] match;

  genvar idx;

  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //

  // Find First 1
  // Start from MSB and count downwards, returns 0 when no bit set
  function [SLAVE_SEL_BITS-1:0] ff1;
    input [NUM_SLAVES-1:0] in;
    integer i;

    begin
      ff1 = 0;
      for (i = NUM_SLAVES-1; i >= 0; i=i-1) begin
        if (in[i])
          ff1 = i;
      end
    end
  endfunction

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  generate
    for(idx=0; idx<NUM_SLAVES ; idx=idx+1) begin
      assign match[idx] = (wbm_adr_i & MATCH_MASK[idx*AW+:AW]) == MATCH_ADDR[idx*AW+:AW];
    end
  endgenerate

  assign slave_sel = ff1(match);

  always @(posedge wb_clk_i)
    wbm_err <= wbm_cyc_i & !(|match);

  assign wbs_adr_o = {NUM_SLAVES{wbm_adr_i}};
  assign wbs_dat_o = {NUM_SLAVES{wbm_dat_i}};
  assign wbs_sel_o = {NUM_SLAVES{wbm_sel_i}};
  assign wbs_we_o  = {NUM_SLAVES{wbm_we_i}};
  assign wbs_stb_o = {NUM_SLAVES{wbm_stb_i}};
  assign wbs_cti_o = {NUM_SLAVES{wbm_cti_i}};
  assign wbs_bte_o = {NUM_SLAVES{wbm_bte_i}};

  assign wbs_cyc_o = match & (wbm_cyc_i << slave_sel);

  assign wbm_dat_o = wbs_dat_i[slave_sel];
  assign wbm_ack_o = wbs_ack_i[slave_sel];
  assign wbm_err_o = wbs_err_i[slave_sel] | wbm_err;
  assign wbm_rty_o = wbs_rty_i[slave_sel];
endmodule
