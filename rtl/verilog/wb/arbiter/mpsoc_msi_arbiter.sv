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
//              Master Slave Interface                                        //
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
 *   Olof Kindgren <olof.kindgren@gmail.com>
 *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
 */

module mpsoc_msi_arbiter #(
  parameter NUM_PORTS = 6
)
  (
    input                               clk,
    input                               rst,
    input      [NUM_PORTS        -1:0]  request,
    output reg [NUM_PORTS        -1:0]  grant,
    output reg [$clog2(NUM_PORTS)-1:0]  selection,
    output reg                          active
  );

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam WRAP_LENGTH = 2*NUM_PORTS;

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //

  // Find First 1
  // Start from MSB and count downwards, returns 0 when no bit set
  function [$clog2(NUM_PORTS)-1:0] ff1;
    input [NUM_PORTS-1:0] in;
    integer i;
    begin
      ff1 = 0;
      for (i = NUM_PORTS-1; i >= 0; i=i-1) begin
        if (in[i])
          ff1 = i;
      end
    end
  endfunction

  `ifdef VERBOSE
  initial $display("Bus arbiter with %d units", NUM_PORTS);
  `endif

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  genvar                  xx;
  integer                 yy;

  wire                    next;
  wire [NUM_PORTS  -1:0]  order;

  reg  [NUM_PORTS  -1:0]  token;
  wire [NUM_PORTS  -1:0]  token_lookahead [NUM_PORTS-1:0];
  wire [WRAP_LENGTH-1:0]  token_wrap;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  assign token_wrap = {token, token};
  assign next       = ~|(token & request);

  always @(posedge clk) begin
    grant     <= token & request;
    selection <= ff1(token & request);
    active    <= |(token & request);
  end

  always @(posedge clk) begin
    if (rst) token <= 'b1;
    else if (next) begin
      for (yy = 0; yy < NUM_PORTS; yy = yy + 1) begin : TOKEN
        if (order[yy]) begin
          token <= token_lookahead[yy];
        end
      end
    end
  end

  generate
    for (xx = 0; xx < NUM_PORTS; xx = xx + 1) begin : ORDER
      assign token_lookahead[xx] = token_wrap[xx +: NUM_PORTS];
      assign order[xx]           = |(token_lookahead[xx] & request);
    end
  endgenerate
endmodule
