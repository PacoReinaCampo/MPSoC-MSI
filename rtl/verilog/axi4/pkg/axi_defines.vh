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

//
// Burst length specifies the number of data transfers that occur within each burst.
//
`define AXI_BURST_LENGTH_1  4'h0
`define AXI_BURST_LENGTH_2  4'h1
`define AXI_BURST_LENGTH_3  4'h2
`define AXI_BURST_LENGTH_4  4'h3
`define AXI_BURST_LENGTH_5  4'h4
`define AXI_BURST_LENGTH_6  4'h5
`define AXI_BURST_LENGTH_7  4'h6
`define AXI_BURST_LENGTH_8  4'h7
`define AXI_BURST_LENGTH_9  4'h8
`define AXI_BURST_LENGTH_10 4'h9
`define AXI_BURST_LENGTH_11 4'hA
`define AXI_BURST_LENGTH_12 4'hB
`define AXI_BURST_LENGTH_13 4'hC
`define AXI_BURST_LENGTH_14 4'hD
`define AXI_BURST_LENGTH_15 4'he
`define AXI_BURST_LENGTH_16 4'hF

//
//Burst Size specifies the maximum number of data bytes to transfer in each 
// beat, or data transfer, within a burst
//
`define AXI_BURST_SIZE_BYTE      3'b000
`define AXI_BURST_SIZE_HALF      3'b001
`define AXI_BURST_SIZE_WORD      3'b010
`define AXI_BURST_SIZE_LONG_WORD 3'b011
`define AXI_BURST_SIZE_16BYTES   3'b100
`define AXI_BURST_SIZE_32BYTES   3'b101
`define AXI_BURST_SIZE_64BYTES   3'b110
`define AXI_BURST_SIZE_128BYTES  3'b111

//
// Burst Type 
//
`define AXI_BURST_TYPE_FIXED 2'b00
`define AXI_BURST_TYPE_INCR  2'b01
`define AXI_BURST_TYPE_WRAP  2'b10
`define AXI_BURST_TYPE_RSRV  2'b11

//
// Lock Type
//
`define AXI_LOCK_NORMAL    2'b00
`define AXI_LOCK_EXCLUSIVE 2'b01
`define AXI_LOCK_LOCKED    2'b10
`define AXI_LOCK__RESERVED 2'b11

//
// Protection Type
//
`define AXI_PROTECTION_NORMAL      3'b000
`define AXI_PROTECTION_PRIVILEGED  3'b001
`define AXI_PROTECTION_SECURE      3'b000
`define AXI_PROTECTION_NONSECURE   3'b010
`define AXI_PROTECTION_INSTRUCTION 3'b100
`define AXI_PROTECTION_DATA        3'b00

//
// Response Type
//
`define AXI_RESPONSE_OKAY         2'b00
`define AXI_RESPONSE_EXOKAY       2'b01
`define AXI_RESPONSE_SLAVE_ERROR  2'b10
`define AXI_RESPONSE_DECODE_ERROR 2'b10
