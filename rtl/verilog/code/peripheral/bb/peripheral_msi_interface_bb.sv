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
//              Master Slave Interface Top                                    //
//              AMBA4 AHB-Lite Bus Interface                                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2019 by the author(s)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////
// Author(s):
//   Paco Reina Campo <pacoreinacampo@queenfield.tech>

module peripheral_msi_interface_bb #(
  parameter PLEN    = 64,
  parameter XLEN    = 64,
  parameter MASTERS = 5,   // number of AHB Masters
  parameter SLAVES  = 5    // number of AHB slaves
) (
  // Common signals
  input HRESETn,
  input HCLK,

  // Master Ports; AHB masters connect to these
  // thus these are actually AHB Slave Interfaces
  input [MASTERS-1:0][2:0] mst_priority,

  input  [MASTERS-1:0]           mst_HSEL,
  input  [MASTERS-1:0][PLEN-1:0] mst_HADDR,
  input  [MASTERS-1:0][XLEN-1:0] mst_HWDATA,
  output [MASTERS-1:0][XLEN-1:0] mst_HRDATA,
  input  [MASTERS-1:0]           mst_HWRITE,
  input  [MASTERS-1:0][     2:0] mst_HSIZE,
  input  [MASTERS-1:0][     2:0] mst_HBURST,
  input  [MASTERS-1:0][     3:0] mst_HPROT,
  input  [MASTERS-1:0][     1:0] mst_HTRANS,
  input  [MASTERS-1:0]           mst_HMASTLOCK,
  output [MASTERS-1:0]           mst_HREADYOUT,
  input  [MASTERS-1:0]           mst_HREADY,
  output [MASTERS-1:0]           mst_HRESP,

  // Slave Ports; AHB Slaves connect to these
  //  thus these are actually AHB Master Interfaces
  input [SLAVES-1:0][PLEN-1:0] slv_addr_mask,
  input [SLAVES-1:0][PLEN-1:0] slv_addr_base,

  output [SLAVES-1:0]           slv_HSEL,
  output [SLAVES-1:0][PLEN-1:0] slv_HADDR,
  output [SLAVES-1:0][XLEN-1:0] slv_HWDATA,
  input  [SLAVES-1:0][XLEN-1:0] slv_HRDATA,
  output [SLAVES-1:0]           slv_HWRITE,
  output [SLAVES-1:0][     2:0] slv_HSIZE,
  output [SLAVES-1:0][     2:0] slv_HBURST,
  output [SLAVES-1:0][     3:0] slv_HPROT,
  output [SLAVES-1:0][     1:0] slv_HTRANS,
  output [SLAVES-1:0]           slv_HMASTLOCK,
  output [SLAVES-1:0]           slv_HREADYOUT,  // HREADYOUT to slave-decoder; generates HREADY to all connected slaves
  input  [SLAVES-1:0]           slv_HREADY,     // combinatorial HREADY from all connected slaves
  input  [SLAVES-1:0]           slv_HRESP
);

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Variables
  //////////////////////////////////////////////////////////////////////////////

  logic [MASTERS-1:0][        2:0]           frommstpriority;
  logic [MASTERS-1:0][SLAVES -1:0]           frommstHSEL;
  logic [MASTERS-1:0][   PLEN-1:0]           frommstHADDR;
  logic [MASTERS-1:0][   XLEN-1:0]           frommstHWDATA;
  logic [MASTERS-1:0][SLAVES -1:0][XLEN-1:0] tomstHRDATA;
  logic [MASTERS-1:0]                        frommstHWRITE;
  logic [MASTERS-1:0][        2:0]           frommstHSIZE;
  logic [MASTERS-1:0][        2:0]           frommstHBURST;
  logic [MASTERS-1:0][        3:0]           frommstHPROT;
  logic [MASTERS-1:0][        1:0]           frommstHTRANS;
  logic [MASTERS-1:0]                        frommstHMASTLOCK;
  logic [MASTERS-1:0]                        frommstHREADYOUT;
  logic [MASTERS-1:0]                        frommst_canswitch;
  logic [MASTERS-1:0][SLAVES -1:0]           tomstHREADY;
  logic [MASTERS-1:0][SLAVES -1:0]           tomstHRESP;
  logic [MASTERS-1:0][SLAVES -1:0]           tomstgrant;

  logic [SLAVES -1:0][MASTERS-1:0][     2:0] toslvpriority;
  logic [SLAVES -1:0][MASTERS-1:0]           toslvHSEL;
  logic [SLAVES -1:0][MASTERS-1:0][PLEN-1:0] toslvHADDR;
  logic [SLAVES -1:0][MASTERS-1:0][XLEN-1:0] toslvHWDATA;
  logic [SLAVES -1:0][   XLEN-1:0]           fromslvHRDATA;
  logic [SLAVES -1:0][MASTERS-1:0]           toslvHWRITE;
  logic [SLAVES -1:0][MASTERS-1:0][     2:0] toslvHSIZE;
  logic [SLAVES -1:0][MASTERS-1:0][     2:0] toslvHBURST;
  logic [SLAVES -1:0][MASTERS-1:0][     3:0] toslvHPROT;
  logic [SLAVES -1:0][MASTERS-1:0][     1:0] toslvHTRANS;
  logic [SLAVES -1:0][MASTERS-1:0]           toslvHMASTLOCK;
  logic [SLAVES -1:0][MASTERS-1:0]           toslvHREADY;
  logic [SLAVES -1:0][MASTERS-1:0]           toslv_canswitch;
  logic [SLAVES -1:0]                        fromslvHREADYOUT;
  logic [SLAVES -1:0]                        fromslvHRESP;
  logic [SLAVES -1:0][MASTERS-1:0]           fromslvgrant;

  genvar m, s;

  //////////////////////////////////////////////////////////////////////////////
  // Body
  //////////////////////////////////////////////////////////////////////////////

  // Hookup Master Interfaces
  generate
    for (m = 0; m < MASTERS; m = m + 1) begin : gen_master_ports
      peripheral_msi_master_port_bb #(
        .PLEN   (PLEN),
        .XLEN   (XLEN),
        .MASTERS(MASTERS),
        .SLAVES (SLAVES)
      ) master_port (
        .HRESETn(HRESETn),
        .HCLK   (HCLK),

        // AHB Slave Interfaces (receive data from AHB Masters)
        // AHB Masters conect to these ports
        .mst_priority (mst_priority[m]),
        .mst_HSEL     (mst_HSEL[m]),
        .mst_HADDR    (mst_HADDR[m]),
        .mst_HWDATA   (mst_HWDATA[m]),
        .mst_HRDATA   (mst_HRDATA[m]),
        .mst_HWRITE   (mst_HWRITE[m]),
        .mst_HSIZE    (mst_HSIZE[m]),
        .mst_HBURST   (mst_HBURST[m]),
        .mst_HPROT    (mst_HPROT[m]),
        .mst_HTRANS   (mst_HTRANS[m]),
        .mst_HMASTLOCK(mst_HMASTLOCK[m]),
        .mst_HREADYOUT(mst_HREADYOUT[m]),
        .mst_HREADY   (mst_HREADY[m]),
        .mst_HRESP    (mst_HRESP[m]),

        // AHB Master Interfaces (send data to AHB slaves)
        // AHB Slaves connect to these ports
        .slvHADDRmask(slv_addr_mask),
        .slvHADDRbase(slv_addr_base),
        .slvpriority (frommstpriority[m]),
        .slvHSEL     (frommstHSEL[m]),
        .slvHADDR    (frommstHADDR[m]),
        .slvHWDATA   (frommstHWDATA[m]),
        .slvHRDATA   (tomstHRDATA[m]),
        .slvHWRITE   (frommstHWRITE[m]),
        .slvHSIZE    (frommstHSIZE[m]),
        .slvHBURST   (frommstHBURST[m]),
        .slvHPROT    (frommstHPROT[m]),
        .slvHTRANS   (frommstHTRANS[m]),
        .slvHMASTLOCK(frommstHMASTLOCK[m]),
        .slvHREADY   (tomstHREADY[m]),
        .slvHREADYOUT(frommstHREADYOUT[m]),
        .slvHRESP    (tomstHRESP[m]),

        .can_switch    (frommst_canswitch[m]),
        .master_granted(tomstgrant[m])
      );
    end
  endgenerate

  // wire mangling

  // Master-->Slave
  generate
    for (s = 0; s < SLAVES; s = s + 1) begin : slave
      for (m = 0; m < MASTERS; m = m + 1) begin : master
        assign toslvpriority[s][m]   = frommstpriority[m];
        assign toslvHSEL[s][m]       = frommstHSEL[m][s];
        assign toslvHADDR[s][m]      = frommstHADDR[m];
        assign toslvHWDATA[s][m]     = frommstHWDATA[m];
        assign toslvHWRITE[s][m]     = frommstHWRITE[m];
        assign toslvHSIZE[s][m]      = frommstHSIZE[m];
        assign toslvHBURST[s][m]     = frommstHBURST[m];
        assign toslvHPROT[s][m]      = frommstHPROT[m];
        assign toslvHTRANS[s][m]     = frommstHTRANS[m];
        assign toslvHMASTLOCK[s][m]  = frommstHMASTLOCK[m];
        assign toslvHREADY[s][m]     = frommstHREADYOUT[m];  // feed Masters's HREADY signal to slave port
        assign toslv_canswitch[s][m] = frommst_canswitch[m];
      end  // next m
    end  // next s
  endgenerate

  // wire mangling

  // Slave-->Master
  generate
    for (m = 0; m < MASTERS; m = m + 1) begin : master
      for (s = 0; s < SLAVES; s = s + 1) begin : slave
        assign tomstgrant[m][s]  = fromslvgrant[s][m];
        assign tomstHRDATA[m][s] = fromslvHRDATA[s];
        assign tomstHREADY[m][s] = fromslvHREADYOUT[s];
        assign tomstHRESP[m][s]  = fromslvHRESP[s];
      end  // next s
    end  // next m
  endgenerate

  // Hookup Slave Interfaces
  generate
    for (s = 0; s < SLAVES; s = s + 1) begin : gen_slave_ports
      peripheral_msi_slave_port_bb #(
        .PLEN   (PLEN),
        .XLEN   (XLEN),
        .MASTERS(MASTERS),
        .SLAVES (SLAVES)
      ) slave_port (
        .HRESETn(HRESETn),
        .HCLK   (HCLK),

        // AHB Slave Interfaces (receive data from AHB Masters)
        // AHB Masters connect to these ports
        .mstpriority (toslvpriority[s]),
        .mstHSEL     (toslvHSEL[s]),
        .mstHADDR    (toslvHADDR[s]),
        .mstHWDATA   (toslvHWDATA[s]),
        .mstHRDATA   (fromslvHRDATA[s]),
        .mstHWRITE   (toslvHWRITE[s]),
        .mstHSIZE    (toslvHSIZE[s]),
        .mstHBURST   (toslvHBURST[s]),
        .mstHPROT    (toslvHPROT[s]),
        .mstHTRANS   (toslvHTRANS[s]),
        .mstHMASTLOCK(toslvHMASTLOCK[s]),
        .mstHREADY   (toslvHREADY[s]),
        .mstHREADYOUT(fromslvHREADYOUT[s]),
        .mstHRESP    (fromslvHRESP[s]),

        // AHB Master Interfaces (send data to AHB slaves)
        // AHB Slaves connect to these ports
        .slv_HSEL     (slv_HSEL[s]),
        .slv_HADDR    (slv_HADDR[s]),
        .slv_HWDATA   (slv_HWDATA[s]),
        .slv_HRDATA   (slv_HRDATA[s]),
        .slv_HWRITE   (slv_HWRITE[s]),
        .slv_HSIZE    (slv_HSIZE[s]),
        .slv_HBURST   (slv_HBURST[s]),
        .slv_HPROT    (slv_HPROT[s]),
        .slv_HTRANS   (slv_HTRANS[s]),
        .slv_HMASTLOCK(slv_HMASTLOCK[s]),
        .slv_HREADYOUT(slv_HREADYOUT[s]),
        .slv_HREADY   (slv_HREADY[s]),
        .slv_HRESP    (slv_HRESP[s]),

        // Internal signals
        .can_switch    (toslv_canswitch[s]),
        .granted_master(fromslvgrant[s])
      );
    end
  endgenerate
endmodule
