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
//              Universal Asynchronous Receiver-Transmitter                   //
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
 *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
 */

module peripheral_msi_synthesis #(
  parameter HADDR_SIZE =  8,
  parameter HDATA_SIZE = 32,
  parameter APB_ADDR_WIDTH =  8,
  parameter APB_DATA_WIDTH = 32,
  parameter SYNC_DEPTH =  3
)
  (
  //Common signals
  input                         HRESETn,
  input                         HCLK,

  //UART AHB3
  input                         msi_HSEL,
  input      [HADDR_SIZE  -1:0] msi_HADDR,
  input      [HDATA_SIZE  -1:0] msi_HWDATA,
  output reg [HDATA_SIZE  -1:0] msi_HRDATA,
  input                         msi_HWRITE,
  input      [             2:0] msi_HSIZE,
  input      [             2:0] msi_HBURST,
  input      [             3:0] msi_HPROT,
  input      [             1:0] msi_HTRANS,
  input                         msi_HMASTLOCK,
  output reg                    msi_HREADYOUT,
  input                         msi_HREADY,
  output reg                    msi_HRESP
);

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Common signals
  logic [APB_ADDR_WIDTH -1:0] msi_PADDR;
  logic [APB_DATA_WIDTH -1:0] msi_PWDATA;
  logic                       msi_PWRITE;
  logic                       msi_PSEL;
  logic                       msi_PENABLE;
  logic [APB_DATA_WIDTH -1:0] msi_PRDATA;
  logic                       msi_PREADY;
  logic                       msi_PSLVERR;

  logic                       msi_rx_i; // Receiver input
  logic                       msi_tx_o; // Transmitter output

  logic                       msi_event_o;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //DUT AHB3
  peripheral_bridge_apb2ahb #(
  .HADDR_SIZE ( HADDR_SIZE     ),
  .HDATA_SIZE ( HDATA_SIZE     ),
  .PADDR_SIZE ( APB_ADDR_WIDTH ),
  .PDATA_SIZE ( APB_DATA_WIDTH ),
  .SYNC_DEPTH ( SYNC_DEPTH     )
  )
  bridge_apb2ahb (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( msi_HSEL      ),
    .HADDR     ( msi_HADDR     ),
    .HWDATA    ( msi_HWDATA    ),
    .HRDATA    ( msi_HRDATA    ),
    .HWRITE    ( msi_HWRITE    ),
    .HSIZE     ( msi_HSIZE     ),
    .HBURST    ( msi_HBURST    ),
    .HPROT     ( msi_HPROT     ),
    .HTRANS    ( msi_HTRANS    ),
    .HMASTLOCK ( msi_HMASTLOCK ),
    .HREADYOUT ( msi_HREADYOUT ),
    .HREADY    ( msi_HREADY    ),
    .HRESP     ( msi_HRESP     ),

    //APB Master Interface
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( msi_PSEL    ),
    .PENABLE ( msi_PENABLE ),
    .PPROT   (              ),
    .PWRITE  ( msi_PWRITE  ),
    .PSTRB   (              ),
    .PADDR   ( msi_PADDR   ),
    .PWDATA  ( msi_PWDATA  ),
    .PRDATA  ( msi_PRDATA  ),
    .PREADY  ( msi_PREADY  ),
    .PSLVERR ( msi_PSLVERR )
  );

  peripheral_apb4_msi #(
  .APB_ADDR_WIDTH ( APB_ADDR_WIDTH ),
  .APB_DATA_WIDTH ( APB_DATA_WIDTH )
  )
  apb4_msi (
    .RSTN ( HRESETn ),
    .CLK  ( HCLK    ),

    .PADDR   ( msi_PADDR   ),
    .PWDATA  ( msi_PWDATA  ),
    .PWRITE  ( msi_PWRITE  ),
    .PSEL    ( msi_PSEL    ),
    .PENABLE ( msi_PENABLE ),
    .PRDATA  ( msi_PRDATA  ),
    .PREADY  ( msi_PREADY  ),
    .PSLVERR ( msi_PSLVERR ),

    .rx_i ( msi_rx_i ),
    .tx_o ( msi_tx_o ),

    .event_o ( msi_event_o )
  );
endmodule
