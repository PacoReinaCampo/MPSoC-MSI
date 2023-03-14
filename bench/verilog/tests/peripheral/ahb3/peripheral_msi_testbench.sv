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
 *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
 */

module peripheral_msi_testbench;

  //////////////////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam XLEN = 64;
  localparam PLEN = 64;

  localparam MASTERS = 3;
  localparam SLAVES  = 5;

  //////////////////////////////////////////////////////////////////////////////
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

  //////////////////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //DUT AHB3
  peripheral_msi_interface_ahb3 #(
  .PLEN    ( PLEN    ),
  .XLEN    ( XLEN    ),
  .MASTERS ( MASTERS ),
  .SLAVES  ( SLAVES  )
  )
  peripheral_interface_ahb3 (
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
endmodule