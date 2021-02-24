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
//              Peripheral-GPIO for MPSoC                                     //
//              General Purpose Input Output for MPSoC                        //
//              AMBA4 AXI-Lite Bus Interface                                  //
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

`include "axi_defines.vh"

module test_case (/*AUTOARG*/ ) ;
`define TB testbench_axi_master_bfm
`define MASTER `TB.master
`define SLAVE `TB.slave
`define MEMORY `SLAVE.memory
   
   initial begin
`ifdef NCVERILOG
      $shm_open("basic.shm");	  
      $shm_probe(`TB,"MAC");      
`else
      $dumpfile("basic.vcd");
	  $dumpvars(0, `TB);
`endif
   end

   integer i;
   reg [31:0] read_data;

   initial begin
      repeat(100) @(posedge `TB.aclk);
      $display("BASIC: Timeout Failure! @ %d", $time);
      $finish;      
   end
   
   initial begin
      $display("AXI Master BFM Test: Basic");
      
      @(negedge `TB.aresetn);
      @(posedge `TB.aresetn);
      repeat (10) @(posedge `TB.aclk);
      `MASTER.write_single(32'h0000_0004, 32'hdead_beef, `AXI_BURST_SIZE_WORD, 4'hF);
      `MASTER.write_single(32'h0000_0008, 32'h1234_5678, `AXI_BURST_SIZE_WORD, 4'hF);
      `MASTER.write_single(32'h0000_000C, 32'hABCD_EF00, `AXI_BURST_SIZE_WORD, 4'hF);
      `MASTER.write_single(32'h0000_0010, 32'hAA55_66BB, `AXI_BURST_SIZE_WORD, 4'hF);
      repeat (10) @(posedge `TB.aclk);
    
      `MASTER.read_single_and_check(32'h0000_0004, 32'hdead_beef, `AXI_BURST_SIZE_WORD, 4'hF);
      `MASTER.read_single_and_check(32'h0000_0008, 32'h1234_5678, `AXI_BURST_SIZE_WORD, 4'hF);
      `MASTER.read_single_and_check(32'h0000_000C, 32'hABCD_EF00, `AXI_BURST_SIZE_WORD, 4'hF);
      `MASTER.read_single_and_check(32'h0000_0010, 32'hAA55_66BB, `AXI_BURST_SIZE_WORD, 4'hF);

      for (i=0; i<32; i=i+1) begin
         $display("MEMORY[%d] = 0x%04x", i, `MEMORY[i]);         
      end
      
      `TB.test_passed <= 1;      
      
   end
   
endmodule // test_case