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

module mpsoc_msi_wb_cdc #(
  parameter AW = 32
)
  (
    input           wbm_clk,
    input           wbm_rst,
    input  [AW-1:0] wbm_adr_i,
    input  [  31:0] wbm_dat_i,
    input  [   3:0] wbm_sel_i,
    input           wbm_we_i,
    input           wbm_cyc_i,
    input           wbm_stb_i,
    output [  31:0] wbm_dat_o,
    output          wbm_ack_o,
    input           wbs_clk,
    input           wbs_rst,
    output [AW-1:0] wbs_adr_o,
    output [  31:0] wbs_dat_o,
    output [   3:0] wbs_sel_o,
    output          wbs_we_o,
    output          wbs_cyc_o,
    output          wbs_stb_o,
    input [   31:0] wbs_dat_i,
    input           wbs_ack_i
  );

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  wire      wbm_m2s_en;
  reg       wbm_busy = 1'b0;
  wire      wbm_cs;
  wire      wbm_done;

  wire      wbs_m2s_en;
  reg       wbs_cs = 1'b0;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  mpsoc_msi_wb_cc561 #(
    .DW (AW+32+4+1)
  )
  cdc_m2s (
    .aclk  (wbm_clk),
    .arst  (wbm_rst),
    .adata ({wbm_adr_i, wbm_dat_i, wbm_sel_i, wbm_we_i}),
    .aen   (wbm_m2s_en),
    .bclk  (wbs_clk),
    .bdata ({wbs_adr_o, wbs_dat_o, wbs_sel_o, wbs_we_o}),
    .ben   (wbs_m2s_en)
  );

  assign wbm_cs = wbm_cyc_i & wbm_stb_i;
  assign wbm_m2s_en = wbm_cs & ~wbm_busy;

  always @(posedge wbm_clk) begin
    if (wbm_ack_o | wbm_rst)
      wbm_busy <= 1'b0;
    else if (wbm_cs)
      wbm_busy <= 1'b1;
  end

  always @(posedge wbs_clk) begin
    if (wbs_ack_i)
      wbs_cs <= 1'b0;
    else if (wbs_m2s_en)
      wbs_cs <= 1'b1;
  end

  assign wbs_cyc_o = wbs_m2s_en | wbs_cs;
  assign wbs_stb_o = wbs_m2s_en | wbs_cs;

  mpsoc_msi_wb_cc561 #(
    .DW (32)
  )
  cdc_s2m (
   .aclk  (wbs_clk),
   .arst  (wbs_rst),
   .adata (wbs_dat_i),
   .aen   (wbs_ack_i),
   .bclk  (wbm_clk),
   .bdata (wbm_dat_o),
   .ben   (wbm_ack_o)
  );
endmodule
