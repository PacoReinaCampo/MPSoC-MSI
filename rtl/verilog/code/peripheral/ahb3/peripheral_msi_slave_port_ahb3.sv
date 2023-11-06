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
//              Master Slave Interface Slave Port                             //
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

module peripheral_msi_slave_port_ahb3 #(
  parameter PLEN    = 64,
  parameter XLEN    = 64,
  parameter MASTERS = 5,   // number of slave-ports
  parameter SLAVES  = 5    // number of master-ports
) (
  input HRESETn,
  input HCLK,

  // AHB Slave Interfaces (receive data from AHB Masters)
  // AHB Masters conect to these ports
  input  [MASTERS-1:0][      2:0] mstpriority,
  input  [MASTERS-1:0]            mstHSEL,
  input  [MASTERS-1:0][PLEN -1:0] mstHADDR,
  input  [MASTERS-1:0][XLEN -1:0] mstHWDATA,
  output [  XLEN -1:0]            mstHRDATA,
  input  [MASTERS-1:0]            mstHWRITE,
  input  [MASTERS-1:0][      2:0] mstHSIZE,
  input  [MASTERS-1:0][      2:0] mstHBURST,
  input  [MASTERS-1:0][      3:0] mstHPROT,
  input  [MASTERS-1:0][      1:0] mstHTRANS,
  input  [MASTERS-1:0]            mstHMASTLOCK,
  input  [MASTERS-1:0]            mstHREADY,     // HREADY input from master-bus
  output                          mstHREADYOUT,  // HREADYOUT output to master-bus
  output                          mstHRESP,

  // AHB Master Interfaces (send data to AHB slaves)
  // AHB Slaves connect to these ports
  output            slv_HSEL,
  output [PLEN-1:0] slv_HADDR,
  output [XLEN-1:0] slv_HWDATA,
  input  [XLEN-1:0] slv_HRDATA,
  output            slv_HWRITE,
  output [     2:0] slv_HSIZE,
  output [     2:0] slv_HBURST,
  output [     3:0] slv_HPROT,
  output [     1:0] slv_HTRANS,
  output            slv_HMASTLOCK,
  output            slv_HREADYOUT,
  input             slv_HREADY,
  input             slv_HRESP,

  input      [MASTERS-1:0] can_switch,
  output reg [MASTERS-1:0] granted_master
);

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  localparam MASTER_BITS = $clog2(MASTERS);

  //////////////////////////////////////////////////////////////////////////////
  // Variables
  //////////////////////////////////////////////////////////////////////////////

  logic [            2:0]              requested_priority_lvl;  // requested priority level
  logic [MASTERS    -1:0]              priority_masters;  // all masters at this priority level

  logic [MASTERS    -1:0]              pending_master;  // next master waiting to be served
  logic [MASTERS    -1:0]              last_granted_master;  // for requested priority level
  logic [            2:0][MASTERS-1:0] last_granted_masters;  // per priority level, for round-robin

  logic [MASTER_BITS-1:0]              granted_master_idx;  // granted master as index
  logic [MASTER_BITS-1:0]              granted_master_idx_dly;  // deleayed granted master index (for HWDATA)

  logic                                can_switch_master;  // Slave may switch to a new master

  genvar m;

  //////////////////////////////////////////////////////////////////////////////
  //
  // Tasks
  //

  //////////////////////////////////////////////////////////////////////////////
  //
  // Functions
  //

  function integer onehot2int;
    input [SLAVES-1:0] onehot;

    for (onehot2int = -1; |onehot; onehot2int++) onehot = onehot >> 1;
  endfunction  // onehot2int

  function [2:0] highest_requested_priority(input [MASTERS-1:0] hsel, input [MASTERS-1:0][2:0] priorities);

    highest_requested_priority = 0;
    for (int n = 0; n < MASTERS; n++) begin
      if (hsel[n] && priorities[n] > highest_requested_priority) begin
        highest_requested_priority = priorities[n];
      end
    end
  endfunction  // highest_requested_priority

  function [MASTERS-1:0] requesters;
    input [MASTERS-1:0] hsel;
    input [MASTERS-1:0][2:0] priorities;
    input [2:0] priority_select;

    for (int n = 0; n < MASTERS; n++) begin
      requesters[n] = (priorities[n] == priority_select) & hsel[n];
    end
  endfunction  // requesters

  function [MASTERS-1:0] nxt_master;
    input [MASTERS-1:0] pending_masters;  // pending masters for the requesed priority level
    input [MASTERS-1:0] last_master;  // last granted master for the priority level
    input [MASTERS-1:0] current_master;  // current granted master (indpendent of priority level)

    integer                 offset;
    logic   [MASTERS*2-1:0] sr;

    // default value, don't switch if not needed
    nxt_master = current_master;

    // implement round-robin
    offset     = onehot2int(last_master) + 1;

    sr         = {pending_masters, pending_masters};
    for (int n = 0; n < MASTERS; n++) begin
      if (sr[n + offset]) begin
        return (1 << ((n + offset) % MASTERS));
      end
    end
  endfunction

  //////////////////////////////////////////////////////////////////////////////
  // Module Body
  //////////////////////////////////////////////////////////////////////////////

  /*
   * Select which master to service
   * 1. Priority
   * 2. Round-Robin
   */

  // get highest priority from selected masters
  assign requested_priority_lvl = highest_requested_priority(mstHSEL, mstpriority);

  // get pending masters for the highest priority requested
  assign priority_masters       = requesters(mstHSEL, mstpriority, requested_priority_lvl);

  // get last granted master for the priority requested
  assign last_granted_master    = last_granted_masters[requested_priority_lvl];

  // get next master to serve
  assign pending_master         = nxt_master(priority_masters, last_granted_master, granted_master);

  // Master port signals when it can be switched
  assign can_switch_master      = can_switch[granted_master_idx];

  // select new master
  always @(posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      granted_master <= 'h1;
      // end else if (!slv_HSEL) begin
      //   granted_master <= pending_master;
    end else if (slv_HREADY) begin
      if (can_switch_master) begin
        granted_master <= pending_master;
      end
    end
  end

  // store current master (for this priority level)
  always @(posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      last_granted_masters <= 'h1;
      // end else if (!slv_HSEL) begin
      //   last_granted_masters[requested_priority_lvl] <= pending_master;
    end else if (slv_HREADY) begin
      if (can_switch_master) begin
        last_granted_masters[requested_priority_lvl] <= pending_master;
      end
    end
  end

  // Get signals from current requester
  always @(posedge HCLK, negedge HRESETn) begin
    if (!HRESETn) begin
      granted_master_idx <= 'h0;
      // end else if (!slv_HSEL  ) begin
      //   granted_master_idx <= onehot2int( pending_master);
    end else if (slv_HREADY) begin
      granted_master_idx <= onehot2int(can_switch_master ? pending_master : granted_master);
    end
  end

  always @(posedge HCLK) begin
    if (slv_HREADY) begin
      granted_master_idx_dly <= granted_master_idx;
    end
  end

  /*
   * If first granted access from slave-port and HTRANS = SEQ, then change to NONSEQ
   * as this is most likely a burst going over a slave boundary
   * If it's not, then this was a bad access to start with and we're in a mess anyways
   *
   * Do NOT switch when HMASTLOCK is asserted
   * It is allowed to switch in the middle of a burst ... but that will get ugly pretty quick
   */

  assign slv_HSEL      = mstHSEL[granted_master_idx];
  assign slv_HADDR     = mstHADDR[granted_master_idx];
  assign slv_HWDATA    = mstHWDATA[granted_master_idx_dly];
  assign slv_HWRITE    = mstHWRITE[granted_master_idx];
  assign slv_HSIZE     = mstHSIZE[granted_master_idx];
  assign slv_HBURST    = mstHBURST[granted_master_idx];
  assign slv_HPROT     = mstHPROT[granted_master_idx];
  assign slv_HTRANS    = mstHTRANS[granted_master_idx];
  assign slv_HREADYOUT = mstHREADY[granted_master_idx];  // Slave Ports HREADYOUT connects to Master Port's HREADY
  assign slv_HMASTLOCK = mstHMASTLOCK[granted_master_idx];

  assign mstHRDATA     = slv_HRDATA;
  assign mstHREADYOUT  = slv_HREADY;  // Master Port's HREADYOUT is driven by Slave Port's (local) HREADY signal
  assign mstHRESP      = slv_HRESP;
endmodule
