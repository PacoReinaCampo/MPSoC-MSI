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

module testbench_axi_master_bfm (/*AUTOARG*/) ;

   //
   // Free running clock
   //
   reg aclk;
   initial begin
      aclk <= 0;
      forever #5 aclk<=~aclk;      
   end

   //
   // Reset
   //
   reg aresetn;
   initial begin
      aresetn <= 1;
      #11;
      aresetn <= 0;
      repeat (10) @(posedge aclk);
      aresetn <= 1;            
   end

   /*AUTOREG*/
   reg test_passed;
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [31:0]          araddr;                 // From master of axi_master_bfm.v
   wire [3:0]           arcache;                // From master of axi_master_bfm.v
   wire [3:0]           arid;                   // From master of axi_master_bfm.v
   wire [3:0]           arlen;                  // From master of axi_master_bfm.v
   wire [1:0]           arlock;                 // From master of axi_master_bfm.v
   wire [2:0]           arprot;                 // From master of axi_master_bfm.v
   wire                 arready;                // From slave of axi_slave_generic.v
   wire [2:0]           arsize;                 // From master of axi_master_bfm.v
   wire                 arvalid;                // From master of axi_master_bfm.v
   wire [31:0]          awadr;                  // From master of axi_master_bfm.v
   wire [1:0]           awburst;                // From master of axi_master_bfm.v
   wire [3:0]           awcache;                // From master of axi_master_bfm.v
   wire [3:0]           awid;                   // From master of axi_master_bfm.v
   wire [3:0]           awlen;                  // From master of axi_master_bfm.v
   wire [1:0]           awlock;                 // From master of axi_master_bfm.v
   wire [2:0]           awprot;                 // From master of axi_master_bfm.v
   wire                 awready;                // From slave of axi_slave_generic.v
   wire [2:0]           awsize;                 // From master of axi_master_bfm.v
   wire                 awvalid;                // From master of axi_master_bfm.v
   wire [3:0]           bid;                    // From master of axi_master_bfm.v, ...
   wire [1:0]           bresp;                  // From master of axi_master_bfm.v, ...
   wire                 bvalid;                 // From master of axi_master_bfm.v, ...
   wire [31:0]          rdata;                  // From slave of axi_slave_generic.v
   wire [3:0]           rid;                    // From slave of axi_slave_generic.v
   wire                 rlast;                  // From slave of axi_slave_generic.v
   wire                 rready;                 // From master of axi_master_bfm.v
   wire [1:0]           rresp;                  // From slave of axi_slave_generic.v
   wire                 rvalid;                 // From slave of axi_slave_generic.v
   wire                 test_fail;              // From master of axi_master_bfm.v
   wire [3:0]           wid;                    // From master of axi_master_bfm.v
   wire                 wlast;                  // From master of axi_master_bfm.v
   wire [31:0]          wrdata;                 // From master of axi_master_bfm.v
   wire                 wready;                 // From slave of axi_slave_generic.v
   wire [3:0]           wstrb;                  // From master of axi_master_bfm.v
   wire                 wvalid;                 // From master of axi_master_bfm.v
   // End of automatics

   axi_master_bfm master(/*AUTOINST*/
                         // Outputs
                         .awid                  (awid[3:0]),
                         .awadr                 (awadr[31:0]),
                         .awlen                 (awlen[3:0]),
                         .awsize                (awsize[2:0]),
                         .awburst               (awburst[1:0]),
                         .awlock                (awlock[1:0]),
                         .awcache               (awcache[3:0]),
                         .awprot                (awprot[2:0]),
                         .awvalid               (awvalid),
                         .wid                   (wid[3:0]),
                         .wrdata                (wrdata[31:0]),
                         .wstrb                 (wstrb[3:0]),
                         .wlast                 (wlast),
                         .wvalid                (wvalid),
                         .bid                   (bid[3:0]),
                         .bresp                 (bresp[1:0]),
                         .bvalid                (bvalid),
                         .arid                  (arid[3:0]),
                         .araddr                (araddr[31:0]),
                         .arlen                 (arlen[3:0]),
                         .arsize                (arsize[2:0]),
                         .arlock                (arlock[1:0]),
                         .arcache               (arcache[3:0]),
                         .arprot                (arprot[2:0]),
                         .arvalid               (arvalid),
                         .rready                (rready),
                         .test_fail             (test_fail),
                         // Inputs
                         .aclk                  (aclk),
                         .aresetn               (aresetn),
                         .awready               (awready),
                         .wready                (wready),
                         .bready                (bready),
                         .arready               (arready),
                         .rid                   (rid[3:0]),
                         .rdata                 (rdata[31:0]),
                         .rresp                 (rresp[1:0]),
                         .rlast                 (rlast),
                         .rvalid                (rvalid));
   
   axi_slave_generic slave (/*AUTOINST*/
                            // Outputs
                            .awready            (awready),
                            .wready             (wready),
                            .bid                (bid[3:0]),
                            .bresp              (bresp[1:0]),
                            .bvalid             (bvalid),
                            .arready            (arready),
                            .rid                (rid[3:0]),
                            .rdata              (rdata[31:0]),
                            .rresp              (rresp[1:0]),
                            .rlast              (rlast),
                            .rvalid             (rvalid),
                            // Inputs
                            .aclk               (aclk),
                            .aresetn            (aresetn),
                            .awid               (awid[3:0]),
                            .awadr              (awadr[31:0]),
                            .awlen              (awlen[3:0]),
                            .awsize             (awsize[2:0]),
                            .awburst            (awburst[1:0]),
                            .awlock             (awlock[1:0]),
                            .awcache            (awcache[3:0]),
                            .awprot             (awprot[2:0]),
                            .awvalid            (awvalid),
                            .wid                (wid[3:0]),
                            .wrdata             (wrdata[31:0]),
                            .wstrb              (wstrb[3:0]),
                            .wlast              (wlast),
                            .wvalid             (wvalid),
                            .bready             (bready),
                            .arid               (arid[3:0]),
                            .araddr             (araddr[31:0]),
                            .arlen              (arlen[3:0]),
                            .arsize             (arsize[2:0]),
                            .arlock             (arlock[1:0]),
                            .arcache            (arcache[3:0]),
                            .arprot             (arprot[2:0]),
                            .arvalid            (arvalid),
                            .rready             (rready));
   

   test_case test();
   initial begin
      @(posedge test_fail);      
      $display("TEST FAIL @ %d", $time);
      repeat (10) @(posedge aclk);
      $finish;            
   end

   initial begin
      test_passed <= 0;      
      @(posedge test_passed);
      $display("TEST PASSED: @ %d", $time);      
      repeat (10) @(posedge aclk);
      $finish;      
   end
   
endmodule // testbench_axi_master_bfm
