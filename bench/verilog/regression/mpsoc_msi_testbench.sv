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

  wire                                     mst_sram_HSEL;
  wire               [PLEN           -1:0] mst_sram_HADDR;
  wire               [XLEN           -1:0] mst_sram_HWDATA;
  wire               [XLEN           -1:0] mst_sram_HRDATA;
  wire                                     mst_sram_HWRITE;
  wire               [                2:0] mst_sram_HSIZE;
  wire               [                2:0] mst_sram_HBURST;
  wire               [                3:0] mst_sram_HPROT;
  wire               [                1:0] mst_sram_HTRANS;
  wire                                     mst_sram_HMASTLOCK;
  wire                                     mst_sram_HREADY;
  wire                                     mst_sram_HREADYOUT;
  wire                                     mst_sram_HRESP;

  wire  [MASTERS-1:0]                      mst_mram_HSEL;
  wire  [MASTERS-1:0][PLEN           -1:0] mst_mram_HADDR;
  wire  [MASTERS-1:0][XLEN           -1:0] mst_mram_HWDATA;
  wire  [MASTERS-1:0][XLEN           -1:0] mst_mram_HRDATA;
  wire  [MASTERS-1:0]                      mst_mram_HWRITE;
  wire  [MASTERS-1:0][                2:0] mst_mram_HSIZE;
  wire  [MASTERS-1:0][                2:0] mst_mram_HBURST;
  wire  [MASTERS-1:0][                3:0] mst_mram_HPROT;
  wire  [MASTERS-1:0][                1:0] mst_mram_HTRANS;
  wire  [MASTERS-1:0]                      mst_mram_HMASTLOCK;
  wire  [MASTERS-1:0]                      mst_mram_HREADY;
  wire  [MASTERS-1:0]                      mst_mram_HREADYOUT;
  wire  [MASTERS-1:0]                      mst_mram_HRESP;

  //GPIO Interface
  wire                        mst_gpio_HSEL;
  wire  [PLEN           -1:0] mst_gpio_HADDR;
  wire  [XLEN           -1:0] mst_gpio_HWDATA;
  wire  [XLEN           -1:0] mst_gpio_HRDATA;
  wire                        mst_gpio_HWRITE;
  wire  [                2:0] mst_gpio_HSIZE;
  wire  [                2:0] mst_gpio_HBURST;
  wire  [                3:0] mst_gpio_HPROT;
  wire  [                1:0] mst_gpio_HTRANS;
  wire                        mst_gpio_HMASTLOCK;
  wire                        mst_gpio_HREADY;
  wire                        mst_gpio_HREADYOUT;
  wire                        mst_gpio_HRESP;

  wire                        gpio_PSEL;
  wire                        gpio_PENABLE;
  wire                        gpio_PWRITE;
  wire                        gpio_PSTRB;
  wire  [PLEN           -1:0] gpio_PADDR;
  wire  [XLEN           -1:0] gpio_PWDATA;
  wire  [XLEN           -1:0] gpio_PRDATA;
  wire                        gpio_PREADY;
  wire                        gpio_PSLVERR;

  wire  [XLEN           -1:0] gpio_i;
  reg   [XLEN           -1:0] gpio_o;
  reg   [XLEN           -1:0] gpio_oe;

  //UART Interface
  wire                        mst_uart_HSEL;
  wire  [PLEN           -1:0] mst_uart_HADDR;
  wire  [XLEN           -1:0] mst_uart_HWDATA;
  wire  [XLEN           -1:0] mst_uart_HRDATA;
  wire                        mst_uart_HWRITE;
  wire  [                2:0] mst_uart_HSIZE;
  wire  [                2:0] mst_uart_HBURST;
  wire  [                3:0] mst_uart_HPROT;
  wire  [                1:0] mst_uart_HTRANS;
  wire                        mst_uart_HMASTLOCK;
  wire                        mst_uart_HREADY;
  wire                        mst_uart_HREADYOUT;
  wire                        mst_uart_HRESP;

  logic [APB_ADDR_WIDTH -1:0] uart_PADDR;
  logic [APB_DATA_WIDTH -1:0] uart_PWDATA;
  logic                       uart_PWRITE;
  logic                       uart_PSEL;
  logic                       uart_PENABLE;
  logic [APB_DATA_WIDTH -1:0] uart_PRDATA;
  logic                       uart_PREADY;
  logic                       uart_PSLVERR;

  logic                       uart_rx_i;  // Receiver input
  logic                       uart_tx_o;  // Transmitter output

  logic                       uart_event_o;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //DUT
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

  mpsoc_msi_wb_interface #(
    .PLEN    ( PLEN    ),
    .XLEN    ( XLEN    ),
    .MASTERS ( MASTERS ),
    .SLAVES  ( SLAVES  )
  )
  peripheral_wb_interface (
    //Common signals
    .HRESETn       ( HRESETn ),
    .HCLK          ( HCLK    ),

    //Master Ports; AHB masters connect to these
    //thus these are actually AHB Slave Interfaces
    .mst_priority  (               ),

    .mst_HSEL      (       ),
    .mst_HADDR     (      ),
    .mst_HWDATA    (     ),
    .mst_HRDATA    (     ),
    .mst_HWRITE    (     ),
    .mst_HSIZE     (      ),
    .mst_HBURST    (     ),
    .mst_HPROT     (      ),
    .mst_HTRANS    (     ),
    .mst_HMASTLOCK (  ),
    .mst_HREADYOUT (  ),
    .mst_HREADY    (     ),
    .mst_HRESP     (      ),

    //Slave Ports; AHB Slaves connect to these
    //thus these are actually AHB Master Interfaces
    .slv_addr_mask (               ),
    .slv_addr_base (               ),

    .slv_HSEL      (       ),
    .slv_HADDR     (      ),
    .slv_HWDATA    (     ),
    .slv_HRDATA    (     ),
    .slv_HWRITE    (     ),
    .slv_HSIZE     (      ),
    .slv_HBURST    (     ),
    .slv_HPROT     (      ),
    .slv_HTRANS    (     ),
    .slv_HMASTLOCK (  ),
    .slv_HREADYOUT (               ),
    .slv_HREADY    (     ),
    .slv_HRESP     (      )
  );

  //Instantiate RISC-V GPIO
  mpsoc_ahb3_peripheral_bridge #(
    .HADDR_SIZE ( PLEN ),
    .HDATA_SIZE ( XLEN ),
    .PADDR_SIZE ( PLEN ),
    .PDATA_SIZE ( XLEN ),
    .SYNC_DEPTH ( SYNC_DEPTH )
  )
  gpio_ahb3_bridge (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_gpio_HSEL      ),
    .HADDR     ( mst_gpio_HADDR     ),
    .HWDATA    ( mst_gpio_HWDATA    ),
    .HRDATA    ( mst_gpio_HRDATA    ),
    .HWRITE    ( mst_gpio_HWRITE    ),
    .HSIZE     ( mst_gpio_HSIZE     ),
    .HBURST    ( mst_gpio_HBURST    ),
    .HPROT     ( mst_gpio_HPROT     ),
    .HTRANS    ( mst_gpio_HTRANS    ),
    .HMASTLOCK ( mst_gpio_HMASTLOCK ),
    .HREADYOUT ( mst_gpio_HREADYOUT ),
    .HREADY    ( mst_gpio_HREADY    ),
    .HRESP     ( mst_gpio_HRESP     ),

    //APB Master Interface
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( gpio_PSEL    ),
    .PENABLE ( gpio_PENABLE ),
    .PPROT   (              ),
    .PWRITE  ( gpio_PWRITE  ),
    .PSTRB   ( gpio_PSTRB   ),
    .PADDR   ( gpio_PADDR   ),
    .PWDATA  ( gpio_PWDATA  ),
    .PRDATA  ( gpio_PRDATA  ),
    .PREADY  ( gpio_PREADY  ),
    .PSLVERR ( gpio_PSLVERR )
  );

  mpsoc_wb_peripheral_bridge #(
    .HADDR_SIZE ( PLEN ),
    .HDATA_SIZE ( XLEN ),
    .PADDR_SIZE ( PLEN ),
    .PDATA_SIZE ( XLEN ),
    .SYNC_DEPTH ( SYNC_DEPTH )
  )
  gpio_wb_bridge (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      (       ),
    .HADDR     (      ),
    .HWDATA    (     ),
    .HRDATA    (     ),
    .HWRITE    (     ),
    .HSIZE     (      ),
    .HBURST    (     ),
    .HPROT     (      ),
    .HTRANS    (     ),
    .HMASTLOCK (  ),
    .HREADYOUT (  ),
    .HREADY    (     ),
    .HRESP     (      ),

    //APB Master Interface
    .PRESETn (  ),
    .PCLK    (     ),

    .PSEL    (     ),
    .PENABLE (  ),
    .PPROT   (              ),
    .PWRITE  (   ),
    .PSTRB   (    ),
    .PADDR   (    ),
    .PWDATA  (   ),
    .PRDATA  (   ),
    .PREADY  (   ),
    .PSLVERR (  )
  );

  mpsoc_apb_gpio #(
    .PADDR_SIZE ( PLEN ),
    .PDATA_SIZE ( XLEN )
  )
  gpio (
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( gpio_PSEL    ),
    .PENABLE ( gpio_PENABLE ),
    .PWRITE  ( gpio_PWRITE  ),
    .PSTRB   ( gpio_PSTRB   ),
    .PADDR   ( gpio_PADDR   ),
    .PWDATA  ( gpio_PWDATA  ),
    .PRDATA  ( gpio_PRDATA  ),
    .PREADY  ( gpio_PREADY  ),
    .PSLVERR ( gpio_PSLVERR ),

    .gpio_i  ( gpio_i       ),
    .gpio_o  ( gpio_o       ),
    .gpio_oe ( gpio_oe      )
  );

  //Instantiate RISC-V UART
  mpsoc_ahb3_peripheral_bridge #(
    .HADDR_SIZE ( PLEN ),
    .HDATA_SIZE ( XLEN ),
    .PADDR_SIZE ( PLEN ),
    .PDATA_SIZE ( XLEN ),
    .SYNC_DEPTH ( SYNC_DEPTH )
  )
  uart_ahb3_bridge (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_uart_HSEL      ),
    .HADDR     ( mst_uart_HADDR     ),
    .HWDATA    ( mst_uart_HWDATA    ),
    .HRDATA    ( mst_uart_HRDATA    ),
    .HWRITE    ( mst_uart_HWRITE    ),
    .HSIZE     ( mst_uart_HSIZE     ),
    .HBURST    ( mst_uart_HBURST    ),
    .HPROT     ( mst_uart_HPROT     ),
    .HTRANS    ( mst_uart_HTRANS    ),
    .HMASTLOCK ( mst_uart_HMASTLOCK ),
    .HREADYOUT ( mst_uart_HREADYOUT ),
    .HREADY    ( mst_uart_HREADY    ),
    .HRESP     ( mst_uart_HRESP     ),

    //APB Master Interface
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( uart_PSEL    ),
    .PENABLE ( uart_PENABLE ),
    .PPROT   (              ),
    .PWRITE  ( uart_PWRITE  ),
    .PSTRB   (              ),
    .PADDR   ( uart_PADDR   ),
    .PWDATA  ( uart_PWDATA  ),
    .PRDATA  ( uart_PRDATA  ),
    .PREADY  ( uart_PREADY  ),
    .PSLVERR ( uart_PSLVERR )
  );

  mpsoc_wb_peripheral_bridge #(
    .HADDR_SIZE ( PLEN ),
    .HDATA_SIZE ( XLEN ),
    .PADDR_SIZE ( PLEN ),
    .PDATA_SIZE ( XLEN ),
    .SYNC_DEPTH ( SYNC_DEPTH )
  )
  uart_wb_bridge (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      (       ),
    .HADDR     (      ),
    .HWDATA    (     ),
    .HRDATA    (     ),
    .HWRITE    (     ),
    .HSIZE     (      ),
    .HBURST    (     ),
    .HPROT     (      ),
    .HTRANS    (     ),
    .HMASTLOCK (  ),
    .HREADYOUT (  ),
    .HREADY    (     ),
    .HRESP     (      ),

    //APB Master Interface
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    (     ),
    .PENABLE (  ),
    .PPROT   (              ),
    .PWRITE  (   ),
    .PSTRB   (              ),
    .PADDR   (    ),
    .PWDATA  (   ),
    .PRDATA  (   ),
    .PREADY  (   ),
    .PSLVERR (  )
  );

  mpsoc_ahb3_uart #(
    .APB_ADDR_WIDTH ( APB_ADDR_WIDTH ),
    .APB_DATA_WIDTH ( APB_DATA_WIDTH )
  )
  ahb3_uart (
    .RSTN ( HRESETn ),
    .CLK  ( HCLK    ),

    .PADDR   ( uart_PADDR   ),
    .PWDATA  ( uart_PWDATA  ),
    .PWRITE  ( uart_PWRITE  ),
    .PSEL    ( uart_PSEL    ),
    .PENABLE ( uart_PENABLE ),
    .PRDATA  ( uart_PRDATA  ),
    .PREADY  ( uart_PREADY  ),
    .PSLVERR ( uart_PSLVERR ),

    .rx_i ( uart_rx_i ),
    .tx_o ( uart_tx_o ),

    .event_o ( uart_event_o )
  );

  mpsoc_wb_uart #(
    .APB_ADDR_WIDTH ( APB_ADDR_WIDTH ),
    .APB_DATA_WIDTH ( APB_DATA_WIDTH )
  )
  wb_uart (
    .RSTN ( HRESETn ),
    .CLK  ( HCLK    ),

    .PADDR   (    ),
    .PWDATA  (   ),
    .PWRITE  (   ),
    .PSEL    (     ),
    .PENABLE (  ),
    .PRDATA  (   ),
    .PREADY  (   ),
    .PSLVERR (  ),

    .rx_i (  ),
    .tx_o (  ),

    .event_o (  )
  );

  //Instantiate RISC-V RAM
  mpsoc_ahb3_mpram #(
    .MEM_SIZE          ( 0 ),
    .MEM_DEPTH         ( 256 ),
    .HADDR_SIZE        ( PLEN ),
    .HDATA_SIZE        ( XLEN ),
    .CORES_PER_TILE    ( MASTERS ),
    .TECHNOLOGY        ( TECHNOLOGY ),
    .REGISTERED_OUTPUT ( "NO" )
  )
  ahb3_mpram (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_mram_HSEL      ),
    .HADDR     ( mst_mram_HADDR     ),
    .HWDATA    ( mst_mram_HWDATA    ),
    .HRDATA    ( mst_mram_HRDATA    ),
    .HWRITE    ( mst_mram_HWRITE    ),
    .HSIZE     ( mst_mram_HSIZE     ),
    .HBURST    ( mst_mram_HBURST    ),
    .HPROT     ( mst_mram_HPROT     ),
    .HTRANS    ( mst_mram_HTRANS    ),
    .HMASTLOCK ( mst_mram_HMASTLOCK ),
    .HREADYOUT ( mst_mram_HREADYOUT ),
    .HREADY    ( mst_mram_HREADY    ),
    .HRESP     ( mst_mram_HRESP     )
  );

  mpsoc_wb_mpram #(
    .MEM_SIZE          ( 0 ),
    .MEM_DEPTH         ( 256 ),
    .HADDR_SIZE        ( PLEN ),
    .HDATA_SIZE        ( XLEN ),
    .CORES_PER_TILE    ( MASTERS ),
    .TECHNOLOGY        ( TECHNOLOGY ),
    .REGISTERED_OUTPUT ( "NO" )
  )
  wb_mpram (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      (       ),
    .HADDR     (      ),
    .HWDATA    (     ),
    .HRDATA    (     ),
    .HWRITE    (     ),
    .HSIZE     (      ),
    .HBURST    (     ),
    .HPROT     (      ),
    .HTRANS    (     ),
    .HMASTLOCK (  ),
    .HREADYOUT (  ),
    .HREADY    (     ),
    .HRESP     (      )
  );

  mpsoc_ahb3_spram #(
    .MEM_SIZE          ( 0 ),
    .MEM_DEPTH         ( 256 ),
    .HADDR_SIZE        ( PLEN ),
    .HDATA_SIZE        ( XLEN ),
    .TECHNOLOGY        ( TECHNOLOGY ),
    .REGISTERED_OUTPUT ( "NO" )
  )
  ahb3_spram (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_sram_HSEL      ),
    .HADDR     ( mst_sram_HADDR     ),
    .HWDATA    ( mst_sram_HWDATA    ),
    .HRDATA    ( mst_sram_HRDATA    ),
    .HWRITE    ( mst_sram_HWRITE    ),
    .HSIZE     ( mst_sram_HSIZE     ),
    .HBURST    ( mst_sram_HBURST    ),
    .HPROT     ( mst_sram_HPROT     ),
    .HTRANS    ( mst_sram_HTRANS    ),
    .HMASTLOCK ( mst_sram_HMASTLOCK ),
    .HREADYOUT ( mst_sram_HREADYOUT ),
    .HREADY    ( mst_sram_HREADY    ),
    .HRESP     ( mst_sram_HRESP     )
  );

  mpsoc_wb_spram #(
    .MEM_SIZE          ( 0 ),
    .MEM_DEPTH         ( 256 ),
    .HADDR_SIZE        ( PLEN ),
    .HDATA_SIZE        ( XLEN ),
    .TECHNOLOGY        ( TECHNOLOGY ),
    .REGISTERED_OUTPUT ( "NO" )
  )
  wb_spram (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      (       ),
    .HADDR     (      ),
    .HWDATA    (     ),
    .HRDATA    (     ),
    .HWRITE    (     ),
    .HSIZE     (      ),
    .HBURST    (     ),
    .HPROT     (      ),
    .HTRANS    (     ),
    .HMASTLOCK (  ),
    .HREADYOUT (  ),
    .HREADY    (     ),
    .HRESP     (      )
  );
endmodule
