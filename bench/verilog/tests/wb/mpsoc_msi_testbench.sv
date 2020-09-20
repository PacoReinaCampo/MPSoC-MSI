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
//              Master Slave Interface Tesbench                               //
//              WishBone Bus Interface                                        //
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
 *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
 */

module mpsoc_msi_testbench;

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Common signals
  wire clk;
  wire rst;

  //WB signals
  wire [31:0] wb_or1k_d_adr_i;
  wire [31:0] wb_or1k_d_dat_i;
  wire  [3:0] wb_or1k_d_sel_i;
  wire        wb_or1k_d_we_i;
  wire        wb_or1k_d_cyc_i;
  wire        wb_or1k_d_stb_i;
  wire  [2:0] wb_or1k_d_cti_i;
  wire  [1:0] wb_or1k_d_bte_i;
  wire [31:0] wb_or1k_d_dat_o;
  wire        wb_or1k_d_ack_o;
  wire        wb_or1k_d_err_o;
  wire        wb_or1k_d_rty_o;
  wire [31:0] wb_or1k_i_adr_i;
  wire [31:0] wb_or1k_i_dat_i;
  wire  [3:0] wb_or1k_i_sel_i;
  wire        wb_or1k_i_we_i;
  wire        wb_or1k_i_cyc_i;
  wire        wb_or1k_i_stb_i;
  wire  [2:0] wb_or1k_i_cti_i;
  wire  [1:0] wb_or1k_i_bte_i;
  wire [31:0] wb_or1k_i_dat_o;
  wire        wb_or1k_i_ack_o;
  wire        wb_or1k_i_err_o;
  wire        wb_or1k_i_rty_o;
  wire [31:0] wb_dbg_adr_i;
  wire [31:0] wb_dbg_dat_i;
  wire  [3:0] wb_dbg_sel_i;
  wire        wb_dbg_we_i;
  wire        wb_dbg_cyc_i;
  wire        wb_dbg_stb_i;
  wire  [2:0] wb_dbg_cti_i;
  wire  [1:0] wb_dbg_bte_i;
  wire [31:0] wb_dbg_dat_o;
  wire        wb_dbg_ack_o;
  wire        wb_dbg_err_o;
  wire        wb_dbg_rty_o;
  wire [31:0] wb_mem_adr_o;
  wire [31:0] wb_mem_dat_o;
  wire  [3:0] wb_mem_sel_o;
  wire        wb_mem_we_o;
  wire        wb_mem_cyc_o;
  wire        wb_mem_stb_o;
  wire  [2:0] wb_mem_cti_o;
  wire  [1:0] wb_mem_bte_o;
  wire [31:0] wb_mem_dat_i;
  wire        wb_mem_ack_i;
  wire        wb_mem_err_i;
  wire        wb_mem_rty_i;
  wire [31:0] wb_uart_adr_o;
  wire  [7:0] wb_uart_dat_o;
  wire  [3:0] wb_uart_sel_o;
  wire        wb_uart_we_o;
  wire        wb_uart_cyc_o;
  wire        wb_uart_stb_o;
  wire  [2:0] wb_uart_cti_o;
  wire  [1:0] wb_uart_bte_o;
  wire  [7:0] wb_uart_dat_i;
  wire        wb_uart_ack_i;
  wire        wb_uart_err_i;
  wire        wb_uart_rty_i;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //DUT WB
  mpsoc_msi_wb_interface wb_interface0 (
    .wb_clk_i        (clk),
    .wb_rst_i        (rst),

    .wb_or1k_d_adr_i (wb_or1k_d_adr_i),
    .wb_or1k_d_dat_i (wb_or1k_d_dat_i),
    .wb_or1k_d_sel_i (wb_or1k_d_sel_i),
    .wb_or1k_d_we_i  (wb_or1k_d_we_i),
    .wb_or1k_d_cyc_i (wb_or1k_d_cyc_i),
    .wb_or1k_d_stb_i (wb_or1k_d_stb_i),
    .wb_or1k_d_cti_i (wb_or1k_d_cti_i),
    .wb_or1k_d_bte_i (wb_or1k_d_bte_i),
    .wb_or1k_d_dat_o (wb_or1k_d_dat_o),
    .wb_or1k_d_ack_o (wb_or1k_d_ack_o),
    .wb_or1k_d_err_o (wb_or1k_d_err_o),
    .wb_or1k_d_rty_o (wb_or1k_d_rty_o),
    .wb_or1k_i_adr_i (wb_or1k_i_adr_i),
    .wb_or1k_i_dat_i (wb_or1k_i_dat_i),
    .wb_or1k_i_sel_i (wb_or1k_i_sel_i),
    .wb_or1k_i_we_i  (wb_or1k_i_we_i),
    .wb_or1k_i_cyc_i (wb_or1k_i_cyc_i),
    .wb_or1k_i_stb_i (wb_or1k_i_stb_i),
    .wb_or1k_i_cti_i (wb_or1k_i_cti_i),
    .wb_or1k_i_bte_i (wb_or1k_i_bte_i),
    .wb_or1k_i_dat_o (wb_or1k_i_dat_o),
    .wb_or1k_i_ack_o (wb_or1k_i_ack_o),
    .wb_or1k_i_err_o (wb_or1k_i_err_o),
    .wb_or1k_i_rty_o (wb_or1k_i_rty_o),
    .wb_dbg_adr_i    (wb_dbg_adr_i),
    .wb_dbg_dat_i    (wb_dbg_dat_i),
    .wb_dbg_sel_i    (wb_dbg_sel_i),
    .wb_dbg_we_i     (wb_dbg_we_i),
    .wb_dbg_cyc_i    (wb_dbg_cyc_i),
    .wb_dbg_stb_i    (wb_dbg_stb_i),
    .wb_dbg_cti_i    (wb_dbg_cti_i),
    .wb_dbg_bte_i    (wb_dbg_bte_i),
    .wb_dbg_dat_o    (wb_dbg_dat_o),
    .wb_dbg_ack_o    (wb_dbg_ack_o),
    .wb_dbg_err_o    (wb_dbg_err_o),
    .wb_dbg_rty_o    (wb_dbg_rty_o),
    .wb_mem_adr_o    (wb_mem_adr_o),
    .wb_mem_dat_o    (wb_mem_dat_o),
    .wb_mem_sel_o    (wb_mem_sel_o),
    .wb_mem_we_o     (wb_mem_we_o),
    .wb_mem_cyc_o    (wb_mem_cyc_o),
    .wb_mem_stb_o    (wb_mem_stb_o),
    .wb_mem_cti_o    (wb_mem_cti_o),
    .wb_mem_bte_o    (wb_mem_bte_o),
    .wb_mem_dat_i    (wb_mem_dat_i),
    .wb_mem_ack_i    (wb_mem_ack_i),
    .wb_mem_err_i    (wb_mem_err_i),
    .wb_mem_rty_i    (wb_mem_rty_i),
    .wb_uart_adr_o   (wb_uart_adr_o),
    .wb_uart_dat_o   (wb_uart_dat_o),
    .wb_uart_sel_o   (wb_uart_sel_o),
    .wb_uart_we_o    (wb_uart_we_o),
    .wb_uart_cyc_o   (wb_uart_cyc_o),
    .wb_uart_stb_o   (wb_uart_stb_o),
    .wb_uart_cti_o   (wb_uart_cti_o),
    .wb_uart_bte_o   (wb_uart_bte_o),
    .wb_uart_dat_i   (wb_uart_dat_i),
    .wb_uart_ack_i   (wb_uart_ack_i),
    .wb_uart_err_i   (wb_uart_err_i),
    .wb_uart_rty_i   (wb_uart_rty_i)
  );
endmodule
