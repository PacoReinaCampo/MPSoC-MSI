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
//              AMBA3 AHB-Lite Bus Interface                                  //
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
 *   Francisco Javier Reina Campo <frareicam@gmail.com>
 */

module mpsoc_msi_testbench;

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam XLEN = 64;
  localparam PLEN = 64;

  parameter APB_ADDR_WIDTH = 64;
  parameter APB_DATA_WIDTH = 64;

  localparam MASTERS = 5;
  localparam SLAVES  = 5;

  localparam SYNC_DEPTH = 3;
  localparam TECHNOLOGY = "GENERIC";

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Common signals
  wire                                     HRESETn;
  wire                                     HCLK;

  //AHB3 signals
  wire  [MASTERS-1:0]                      mst_HSEL;
  wire  [MASTERS-1:0][PLEN           -1:0] mst_HADDR;
  wire  [MASTERS-1:0][XLEN           -1:0] mst_HWDATA;
  wire  [MASTERS-1:0][XLEN           -1:0] mst_HRDATA;
  wire  [MASTERS-1:0]                      mst_HWRITE;
  wire  [MASTERS-1:0][                2:0] mst_HSIZE;
  wire  [MASTERS-1:0][                2:0] mst_HBURST;
  wire  [MASTERS-1:0][                3:0] mst_HPROT;
  wire  [MASTERS-1:0][                1:0] mst_HTRANS;
  wire  [MASTERS-1:0]                      mst_HMASTLOCK;
  wire  [MASTERS-1:0]                      mst_HREADY;
  wire  [MASTERS-1:0]                      mst_HREADYOUT;
  wire  [MASTERS-1:0]                      mst_HRESP;

  wire  [SLAVES-1:0]                       slv_HSEL;
  wire  [SLAVES-1:0][PLEN            -1:0] slv_HADDR;
  wire  [SLAVES-1:0][XLEN            -1:0] slv_HWDATA;
  wire  [SLAVES-1:0][XLEN            -1:0] slv_HRDATA;
  wire  [SLAVES-1:0]                       slv_HWRITE;
  wire  [SLAVES-1:0][                 2:0] slv_HSIZE;
  wire  [SLAVES-1:0][                 2:0] slv_HBURST;
  wire  [SLAVES-1:0][                 3:0] slv_HPROT;
  wire  [SLAVES-1:0][                 1:0] slv_HTRANS;
  wire  [SLAVES-1:0]                       slv_HMASTLOCK;
  wire  [SLAVES-1:0]                       slv_HREADY;
  wire  [SLAVES-1:0]                       slv_HRESP;

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

  //DUT AHB3
  mpsoc_msi_ahb3_interface #(
    .PLEN    ( PLEN    ),
    .XLEN    ( XLEN    ),
    .MASTERS ( MASTERS ),
    .SLAVES  ( SLAVES  )
  )
  peripheral_ahb3_interface (
    //Common signals
    .HRESETn       ( HRESETn ),
    .HCLK          ( HCLK    ),

    //Master Ports; AHB masters connect to these
    //thus these are actually AHB Slave Interfaces
    .mst_priority  (               ),

    .mst_HSEL      ( mst_HSEL      ),
    .mst_HADDR     ( mst_HADDR     ),
    .mst_HWDATA    ( mst_HWDATA    ),
    .mst_HRDATA    ( mst_HRDATA    ),
    .mst_HWRITE    ( mst_HWRITE    ),
    .mst_HSIZE     ( mst_HSIZE     ),
    .mst_HBURST    ( mst_HBURST    ),
    .mst_HPROT     ( mst_HPROT     ),
    .mst_HTRANS    ( mst_HTRANS    ),
    .mst_HMASTLOCK ( mst_HMASTLOCK ),
    .mst_HREADYOUT ( mst_HREADYOUT ),
    .mst_HREADY    ( mst_HREADY    ),
    .mst_HRESP     ( mst_HRESP     ),

    //Slave Ports; AHB Slaves connect to these
    //thus these are actually AHB Master Interfaces
    .slv_addr_mask (               ),
    .slv_addr_base (               ),

    .slv_HSEL      ( slv_HSEL      ),
    .slv_HADDR     ( slv_HADDR     ),
    .slv_HWDATA    ( slv_HWDATA    ),
    .slv_HRDATA    ( slv_HRDATA    ),
    .slv_HWRITE    ( slv_HWRITE    ),
    .slv_HSIZE     ( slv_HSIZE     ),
    .slv_HBURST    ( slv_HBURST    ),
    .slv_HPROT     ( slv_HPROT     ),
    .slv_HTRANS    ( slv_HTRANS    ),
    .slv_HMASTLOCK ( slv_HMASTLOCK ),
    .slv_HREADYOUT (               ),
    .slv_HREADY    ( slv_HREADY    ),
    .slv_HRESP     ( slv_HRESP     )
  );

  //DUT WB
  mpsoc_msi_wb_interface wb_interface0 (
    .wb_clk_i        (HRESETn),
    .wb_rst_i        (HCLK),

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
