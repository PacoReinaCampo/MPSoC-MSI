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
//   Olof Kindgren <olof.kindgren@gmail.com>
//   Paco Reina Campo <pacoreinacampo@queenfield.tech>

module peripheral_msi_upsizer_wb #(
  parameter DW_IN = 0,
  parameter SCALE = 0,
  parameter AW    = 32
) (
  input wb_clk_i,
  input wb_rst_i,

  input [AW-1:0] wbs_adr_i,

  // Slave Port
  input  [DW_IN  -1:0] wbs_dat_i,
  input  [DW_IN/8-1:0] wbs_sel_i,
  input                wbs_we_i,
  input                wbs_cyc_i,
  input                wbs_stb_i,
  input  [        2:0] wbs_cti_i,
  input  [        1:0] wbs_bte_i,
  output [ DW_IN -1:0] wbs_dat_o,
  output               wbs_ack_o,
  output               wbs_err_o,
  output               wbs_rty_o,

  // Master Port
  output     [AW   -1:0]              wbm_adr_o,
  output reg [DW_IN-1:0][  SCALE-1:0] wbm_dat_o,
  output     [DW_IN-1:0][SCALE/8-1:0] wbm_sel_o,
  output                              wbm_we_o,
  output                              wbm_cyc_o,
  output                              wbm_stb_o,
  output     [      2:0]              wbm_cti_o,
  output     [      1:0]              wbm_bte_o,
  input      [DW_IN-1:0][  SCALE-1:0] wbm_dat_i,
  input                               wbm_ack_i,
  input                               wbm_err_i,
  input                               wbm_rty_i
);

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  import peripheral_wb_pkg::*;

  localparam SELW = DW_IN / 8;  // sel width

  localparam DW_OUT = DW_IN * SCALE;
  localparam SW_OUT = SELW * SCALE;

  localparam BUFW = $clog2(DW_IN / 8) - 1;  // Buffer width

  localparam ADR_LSB = BUFW + 1;  // Bit position of the LSB of the buffer address. Lower bits are used for index part

  localparam [1:0] S_IDLE = 2'b00;
  localparam [1:0] S_READ = 2'b01;
  localparam [1:0] S_WRITE = 2'b10;

  //////////////////////////////////////////////////////////////////////////////
  // Variables
  //////////////////////////////////////////////////////////////////////////////

  reg  [         1:0]              state;

  wire [AW-1:ADR_LSB]              adr_i;
  wire [BUFW    -1:0]              idx_i;

  reg  [AW-1:ADR_LSB]              radr;
  reg  [DW_OUT  -1:0]              rdat;
  reg                              rdat_vld;

  wire [      AW-1:0]              next_adr;

  wire                             req;
  wire                             wr_req;

  wire                             last;
  wire                             last_in_batch;
  wire                             bufhit;
  wire                             next_bufhit;

  reg  [   AW   -1:0]              wr_adr;
  reg  [   DW_IN-1:0][SCALE/8-1:0] wr_sel;
  reg                              wr_we;
  reg                              wr_cyc;
  reg                              wr_stb;
  reg  [         2:0]              wr_cti;
  reg  [         1:0]              wr_bte;

  reg  [DW_OUT  -1:0]              wdat;
  reg  [DW_OUT/8-1:0]              sel;
  reg                              write_ack;
  reg                              first_ack;

  reg  [      AW-1:0]              next_radr;

  reg                              wbm_stb_o_r;

  wire                             rd_cyc;

  wire                             wr;

  wire [      AW-1:0]              rd_adr;

  //////////////////////////////////////////////////////////////////////////////
  // Body
  //////////////////////////////////////////////////////////////////////////////

  assign next_adr       = wb_next_adr(wbs_adr_i, wbs_cti_i, wbs_bte_i, DW_IN) >> ($clog2(SELW) + BUFW);

  assign req            = wbs_cyc_i & wbs_stb_i;
  assign wr_req         = req & wbs_we_i;

  assign last           = wbs_cyc_i & (wbs_cti_i == 3'b000 | wbs_cti_i == 3'b111);
  assign last_in_batch  = (adr_i != next_adr) | last;
  assign bufhit         = (adr_i == radr) & rdat_vld;
  assign next_bufhit    = (next_adr == radr);

  assign rd_cyc         = wbs_cyc_i & !(last & bufhit);

  assign wr             = (wr_req | wr_cyc);

  assign rd_adr         = (first_ack ? next_adr : adr_i) << ($clog2(SELW) + BUFW);

  assign {adr_i, idx_i} = wbs_adr_i >> $clog2(SELW);

  assign wbs_dat_o      = rdat_vld ? rdat[idx_i] : wbm_dat_i[idx_i];

  assign wbs_ack_o      = wr ? write_ack : (wbm_ack_i | bufhit);
  assign wbm_adr_o      = wr ? wr_adr : rd_adr;
  assign wbm_sel_o      = wr ? wr_sel : {SW_OUT{1'b1}};
  assign wbm_we_o       = wr ? wr_cyc : 1'b0;
  assign wbm_cyc_o      = wr ? wr_cyc : rd_cyc;
  assign wbm_stb_o      = wr ? wr_stb : rd_cyc;
  assign wbm_cti_o      = wr ? wr_cti : 3'b111;
  assign wbm_bte_o      = wr ? wr_bte : 2'b00;

  always @(posedge wb_clk_i) begin
    if (wbs_ack_o & !wr) begin
      first_ack <= 1'b1;
      if (last) begin
        first_ack <= 1'b0;
      end
    end
    write_ack   <= 1'b0;
    wbm_stb_o_r <= wbm_stb_o & !wbm_we_o;
    if (wbm_cyc_o & wbm_ack_i & last) begin
      rdat_vld <= 1'b0;
    end

    case (state)
      S_IDLE: begin
        wr_cyc <= 1'b0;
        wr_stb <= 1'b0;
        wr_cti <= 3'b000;
        wr_bte <= 2'b00;

        if (req) begin
          radr   <= wbm_adr_o >> ($clog2(SELW) + BUFW);
          wr_adr <= adr_i << ($clog2(SELW) + BUFW);
          wr_cti <= wbs_cti_i;
          wr_bte <= wbs_bte_i;

          if (wbs_we_i) begin
            wr_cyc           <= 1'b1;
            wr_stb           <= last_in_batch;
            wbm_dat_o[idx_i] <= wbs_dat_i;
            wr_sel[idx_i]    <= wbs_sel_i;

            // FIXME
            wbm_dat_o[idx_i] <= {DW_IN{1'b0}};
            wr_sel[!idx_i]   <= {SELW{1'b0}};

            write_ack        <= 1'b1 | (!last_in_batch) & !(last & wbs_ack_o);

            state            <= S_WRITE;
          end else begin  // Read request
            if (wbs_cti_i == 3'b111) begin
              rdat_vld <= 1'b0;
            end
            if (!next_bufhit | !first_ack) begin  // !wbm_stb_o_r
              rdat_vld <= 1'b0;
              state    <= S_READ;
            end
          end
        end
      end

      S_READ: begin
        if (wbm_ack_i) begin
          next_radr   <= wb_next_adr(wbs_adr_i, wbs_cti_i, wbs_bte_i, DW_OUT) >> ($clog2(SELW) + BUFW);
          // next_radr <= next_adr;
          radr        <= adr_i;
          rdat        <= wbm_dat_i;
          rdat_vld    <= !last;
          state       <= S_IDLE;
          wbm_stb_o_r <= 1'b1;
        end
      end

      S_WRITE: begin
        // write_ack <= (!last_in_batch | wbm_ack_i) & !(last & wbs_ack_o);
        if (!wr_stb | wbm_ack_i) begin
          write_ack   <= !last & (!last_in_batch | wbm_ack_i);
          wr_adr      <= adr_i << ($clog2(SELW) + BUFW);
          wdat[idx_i] <= wbs_dat_i;
          sel[idx_i]  <= wbs_sel_i;
          if (last_in_batch) begin
            wbm_dat_o[idx_i] <= wbs_dat_i;
            wbm_dat_o[idx_i] <= wdat[idx_i];
            wr_sel[idx_i]    <= wbs_sel_i;
            wr_sel[!idx_i]   <= sel[!idx_i];
            sel              <= 0;
          end
          wr_sel[idx_i] <= wbs_sel_i;
          wr_stb        <= last_in_batch;
          wr_cti        <= wbs_cti_i;
          wr_bte        <= wbs_bte_i;
        end
        if ((wbm_cti_o == 3'b111) & wbm_ack_i) begin
          write_ack <= 1'b0;

          wr_adr    <= 0;
          wbm_dat_o <= 0;
          wr_sel    <= 0;

          wr_stb    <= 1'b0;
          wr_cyc    <= 1'b0;
          state     <= S_IDLE;
        end
      end
      default: begin
        state <= S_IDLE;
      end
    endcase
    if (wb_rst_i) begin
      state     <= S_IDLE;
      rdat_vld  <= 1'b0;
      first_ack <= 1'b0;
    end
  end
endmodule
