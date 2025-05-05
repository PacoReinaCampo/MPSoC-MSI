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
//              Master Slave Interface Master Port                            //
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

import peripheral_bb_pkg::*;

module peripheral_msi_master_port_bb #(
  parameter PLEN    = 64,
  parameter XLEN    = 64,
  parameter MASTERS = 5,   // number of AHB masters
  parameter SLAVES  = 5    // number of AHB slaves
) (
  // Common signals
  input HRESETn,
  input HCLK,

  // AHB Slave Interfaces (receive data from AHB Masters)
  // AHB Masters connect to these ports
  input [2:0] mst_priority,

  input             mst_HSEL,
  input  [PLEN-1:0] mst_HADDR,
  input  [XLEN-1:0] mst_HWDATA,
  output [XLEN-1:0] mst_HRDATA,
  input             mst_HWRITE,
  input  [     2:0] mst_HSIZE,
  input  [     2:0] mst_HBURST,
  input  [     3:0] mst_HPROT,
  input  [     1:0] mst_HTRANS,
  input             mst_HMASTLOCK,
  output            mst_HREADYOUT,
  input             mst_HREADY,
  output            mst_HRESP,

  // AHB Master Interfaces; send data to AHB slaves
  input  [SLAVES-1:0][PLEN -1:0] slvHADDRmask,
  input  [SLAVES-1:0][PLEN -1:0] slvHADDRbase,
  output [SLAVES-1:0]            slvHSEL,
  output [ PLEN -1:0]            slvHADDR,
  output [ XLEN -1:0]            slvHWDATA,
  input  [SLAVES-1:0][XLEN -1:0] slvHRDATA,
  output                         slvHWRITE,
  output [       2:0]            slvHSIZE,
  output [       2:0]            slvHBURST,
  output [       3:0]            slvHPROT,
  output [       1:0]            slvHTRANS,
  output                         slvHMASTLOCK,
  input  [SLAVES-1:0]            slvHREADY,
  output                         slvHREADYOUT,
  input  [SLAVES-1:0]            slvHRESP,

  // Internal signals
  output reg              can_switch,
  output     [       2:0] slvpriority,
  input      [SLAVES-1:0] master_granted
);

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  localparam SLAVES_BITS = $clog2(SLAVES);

  //////////////////////////////////////////////////////////////////////////////
  // Variables
  //////////////////////////////////////////////////////////////////////////////

  enum logic [1:0] {
    NO_ACCESS,
    ACCESS_PENDING,
    ACCESS_GRANTED
  } access_state;

  logic no_access, access_pending, access_granted;

  logic [SLAVES     -1:0] current_HSEL, pending_HSEL;

  logic local_HREADYOUT;

  logic mux_sel;
  logic [SLAVES_BITS-1:0] slave_sel, slaves2int;

  logic [            3:0] burst_cnt;

  logic [            2:0] regpriority;
  logic [PLEN       -1:0] regHADDR;
  logic [XLEN       -1:0] regHWDATA;
  logic [            1:0] regHTRANS;
  logic                   regHWRITE;
  logic [            2:0] regHSIZE;
  logic [            3:0] regHBURST;
  logic [            3:0] regHPROT;
  logic                   regHMASTLOCK;

  genvar s;

  //////////////////////////////////////////////////////////////////////////////
  // Tasks
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Functions
  //////////////////////////////////////////////////////////////////////////////

  function integer onehot2int;
    input [SLAVES-1:0] onehot;

    for (onehot2int = -1; |onehot; onehot2int++) begin
      onehot = onehot >> 1;
    end
  endfunction  // onehot2int

  //////////////////////////////////////////////////////////////////////////////
  // Body
  //////////////////////////////////////////////////////////////////////////////

  // Register Address Phase Signals
  always @(posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      regHTRANS <= HTRANS_IDLE;
    end else if (mst_HREADY) begin
      regHTRANS <= mst_HSEL ? mst_HTRANS : HTRANS_IDLE;
    end
  end

  always @(posedge HCLK) begin
    if (mst_HREADY) begin
      regpriority  <= mst_priority;
      regHADDR     <= mst_HADDR;
      regHWDATA    <= mst_HWDATA;
      regHWRITE    <= mst_HWRITE;
      regHSIZE     <= mst_HSIZE;
      regHBURST    <= mst_HBURST;
      regHPROT     <= mst_HPROT;
      regHMASTLOCK <= mst_HMASTLOCK;
    end
  end

  // Generate local HREADY response
  always @(posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      local_HREADYOUT <= 1'b1;
    end else if (mst_HREADY) begin
      local_HREADYOUT <= (mst_HTRANS == HTRANS_IDLE) | ~mst_HSEL;
    end
  end

  // Access granted state machine
  //
  // NO_ACCESS     : reset state
  //                 If there's no access requested, stay in this state
  //                 If there's an access requested and we get an access-grant, go to ACCESS state
  //                 else the access is pending
  //
  // ACCESS_PENDING: Intermediate state to hold bus-command (HTRANS, ...)
  // ACCESS_GRANTED: while access requested and granted stay in this state
  //                 else go to NO_ACCESS

  always @(posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      access_state <= NO_ACCESS;
    end else begin
      case (access_state)
        NO_ACCESS: begin
          if (~|current_HSEL && ~|pending_HSEL) begin
            access_state <= NO_ACCESS;
          end else if (|(current_HSEL & master_granted)) begin
            access_state <= ACCESS_GRANTED;
          end else begin
            access_state <= ACCESS_PENDING;
          end
        end
        ACCESS_PENDING: begin
          if (|(pending_HSEL & master_granted) && slvHREADY[slave_sel]) begin
            access_state <= ACCESS_GRANTED;
          end
        end
        ACCESS_GRANTED: begin
          if (mst_HREADY && ~|current_HSEL) begin
            access_state <= NO_ACCESS;
          end else if (mst_HREADY && ~|(current_HSEL & master_granted & slvHREADY)) begin
            access_state <= ACCESS_PENDING;
          end
        end
      endcase
    end
  end

  assign no_access      = access_state == NO_ACCESS;
  assign access_pending = access_state == ACCESS_PENDING;
  assign access_granted = access_state == ACCESS_GRANTED;

  // Generate burst counter
  always @(posedge HCLK) begin
    if (mst_HREADY) begin
      if (mst_HTRANS == HTRANS_NONSEQ) begin
        case (mst_HBURST)
          HBURST_WRAP4:  burst_cnt <= 'd2;
          HBURST_INCR4:  burst_cnt <= 'd2;
          HBURST_WRAP8:  burst_cnt <= 'd6;
          HBURST_INCR8:  burst_cnt <= 'd6;
          HBURST_WRAP16: burst_cnt <= 'd14;
          HBURST_INCR16: burst_cnt <= 'd14;
          default:       burst_cnt <= 'd0;
        endcase
      end
    end else begin
      burst_cnt <= burst_cnt - 'h1;
    end
  end

  // Indicate that the slave may switch masters on the NEXT cycle
  always @(*) begin
    case (access_state)
      NO_ACCESS:      can_switch = ~|(current_HSEL & master_granted);
      ACCESS_PENDING: can_switch = ~|(pending_HSEL & master_granted);
      ACCESS_GRANTED: can_switch = ~mst_HSEL | (mst_HSEL & ~mst_HMASTLOCK & mst_HREADY & ((mst_HTRANS == HTRANS_IDLE) | (mst_HTRANS == HTRANS_NONSEQ & mst_HBURST == HBURST_SINGLE) | (mst_HTRANS == HTRANS_SEQ & mst_HBURST != HBURST_INCR & ~|burst_cnt)));
    endcase
  end

  // Decode slave-request; which AHB slave (master-port) to address?
  //
  // Send out connection request to slave-port
  // Slave-port replies by asserting master_gnt
  // TO-DO: check for illegal combinations (more than 1 slvHSEL asserted)

  generate
    for (s = 0; s < SLAVES; s = s + 1) begin : gen_HSEL
      assign current_HSEL[s] = (mst_HTRANS != HTRANS_IDLE) & ((mst_HADDR & slvHADDRmask[s]) == (slvHADDRbase[s] & slvHADDRmask[s]));
      assign pending_HSEL[s] = (regHTRANS != HTRANS_IDLE) & ((regHADDR & slvHADDRmask[s]) == (slvHADDRbase[s] & slvHADDRmask[s]));
      assign slvHSEL[s]      = access_pending ? (pending_HSEL[s]) : (mst_HSEL & current_HSEL[s]);
    end
  endgenerate

  // Check if granted access
  always @(posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      slave_sel <= 'h0;
    end else if (mst_HREADY) begin
      slave_sel <= onehot2int(slvHSEL);
    end
  end

  // Outgoing data (to slaves)
  assign mux_sel       = ~access_pending;

  assign slvHADDR      = mux_sel ? mst_HADDR : regHADDR;
  assign slvHWDATA     = mux_sel ? mst_HWDATA : regHWDATA;
  assign slvHWRITE     = mux_sel ? mst_HWRITE : regHWRITE;
  assign slvHSIZE      = mux_sel ? mst_HSIZE : regHSIZE;
  assign slvHBURST     = mux_sel ? mst_HBURST : regHBURST;
  assign slvHPROT      = mux_sel ? mst_HPROT : regHPROT;
  assign slvHTRANS     = mux_sel ? mst_HTRANS : regHTRANS == HTRANS_SEQ && regHBURST == HBURST_INCR ? HTRANS_NONSEQ : regHTRANS;
  assign slvHMASTLOCK  = mux_sel ? mst_HMASTLOCK : regHMASTLOCK;
  assign slvHREADYOUT  = mux_sel ? mst_HREADY & |(current_HSEL & slvHREADY) : slvHREADY[slave_sel];  // slave's HREADYOUT is driven by master's HREADY (mst_HREADY -> slv_HREADYOUT)
  assign slvpriority   = mux_sel ? mst_priority : regpriority;

  // Incoming data (to masters)
  assign mst_HRDATA    = slvHRDATA[slave_sel];
  assign mst_HREADYOUT = access_granted ? slvHREADY[slave_sel] : local_HREADYOUT;  // master's HREADYOUT is driven by slave's HREADY (slv_HREADY -> mst_HREADYOUT)
  assign mst_HRESP     = access_granted ? slvHRESP[slave_sel] : HRESP_OKAY;
endmodule
