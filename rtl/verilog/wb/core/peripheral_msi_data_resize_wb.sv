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

module mpsoc_msi_wb_data_resize #(
  parameter AW  = 32,  //Address width
  parameter MDW = 32,  //Master Data Width
  parameter SDW = 8    //Slave Data Width
)
  (
    //Wishbone Master interface
    input  [AW- 1:0] wbm_adr_i,
    input  [MDW-1:0] wbm_dat_i,
    input  [    3:0] wbm_sel_i,
    input            wbm_we_i,
    input            wbm_cyc_i,
    input            wbm_stb_i,
    input  [    2:0] wbm_cti_i,
    input  [    1:0] wbm_bte_i,
    output [MDW-1:0] wbm_dat_o,
    output           wbm_ack_o,
    output           wbm_err_o,
    output           wbm_rty_o,

    // Wishbone Slave interface
    output [ AW-1:0] wbs_adr_o,
    output [SDW-1:0] wbs_dat_o,
    output           wbs_we_o,
    output           wbs_cyc_o,
    output           wbs_stb_o,
    output [    2:0] wbs_cti_o,
    output [    1:0] wbs_bte_o,
    input  [SDW-1:0] wbs_dat_i,
    input            wbs_ack_i,
    input            wbs_err_i,
    input            wbs_rty_i
  );

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  assign wbs_adr_o[AW-1:2] = wbm_adr_i[AW-1:2];
  assign wbs_adr_o[1:0] = wbm_sel_i[3] ? 2'd0 :
                          wbm_sel_i[2] ? 2'd1 :
                          wbm_sel_i[1] ? 2'd2 : 2'd3;

  assign wbs_dat_o = wbm_sel_i[3] ? wbm_dat_i[31:24] :
                     wbm_sel_i[2] ? wbm_dat_i[23:16] :
                     wbm_sel_i[1] ? wbm_dat_i[15:8]  :
                     wbm_sel_i[0] ? wbm_dat_i[7:0]   : 8'b0;

  assign wbs_we_o  = wbm_we_i;

  assign wbs_cyc_o = wbm_cyc_i;
  assign wbs_stb_o = wbm_stb_i;

  assign wbs_cti_o = wbm_cti_i;
  assign wbs_bte_o = wbm_bte_i;

  assign wbm_dat_o = (wbm_sel_i[3]) ? {wbs_dat_i, 24'd0} :
                     (wbm_sel_i[2]) ? {8'd0 , wbs_dat_i, 16'd0} :
                     (wbm_sel_i[1]) ? {16'd0, wbs_dat_i, 8'd0} : {24'd0, wbs_dat_i};

  assign wbm_ack_o = wbs_ack_i;
  assign wbm_err_o = wbs_err_i;
  assign wbm_rty_o = wbs_rty_i;
endmodule
