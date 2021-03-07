-- Converted from core/mpsoc_msi_wb_interface.v
-- by verilog2vhdl - QueenField

--//////////////////////////////////////////////////////////////////////////////
--                                            __ _      _     _               //
--                                           / _(_)    | |   | |              //
--                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
--               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
--              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
--               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
--                  | |                                                       //
--                  |_|                                                       //
--                                                                            //
--                                                                            //
--              MPSoC-RISCV CPU                                               //
--              Master Slave Interface                                        //
--              Wishbone Bus Interface                                        //
--                                                                            //
--//////////////////////////////////////////////////////////////////////////////

-- Copyright (c) 2018-2019 by the author(s)
-- *
-- * Permission is hereby granted, free of charge, to any person obtaining a copy
-- * of this software and associated documentation files (the "Software"), to deal
-- * in the Software without restriction, including without limitation the rights
-- * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- * copies of the Software, and to permit persons to whom the Software is
-- * furnished to do so, subject to the following conditions:
-- *
-- * The above copyright notice and this permission notice shall be included in
-- * all copies or substantial portions of the Software.
-- *
-- * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- * THE SOFTWARE.
-- *
-- * =============================================================================
-- * Author(s):
-- *   Olof Kindgren <olof.kindgren@gmail.com>
-- *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mpsoc_msi_wb_pkg.all;

entity mpsoc_msi_wb_interface is
  port (
    wb_clk_i        : in  std_logic;
    wb_rst_i        : in  std_logic;
    wb_or1k_d_adr_i : in  std_logic_vector(31 downto 0);
    wb_or1k_d_dat_i : in  std_logic_vector(31 downto 0);
    wb_or1k_d_sel_i : in  std_logic_vector(3 downto 0);
    wb_or1k_d_we_i  : in  std_logic;
    wb_or1k_d_cyc_i : in  std_logic;
    wb_or1k_d_stb_i : in  std_logic;
    wb_or1k_d_cti_i : in  std_logic_vector(2 downto 0);
    wb_or1k_d_bte_i : in  std_logic_vector(1 downto 0);
    wb_or1k_d_dat_o : out std_logic_vector(31 downto 0);
    wb_or1k_d_ack_o : out std_logic;
    wb_or1k_d_err_o : out std_logic;
    wb_or1k_d_rty_o : out std_logic;
    wb_or1k_i_adr_i : in  std_logic_vector(31 downto 0);
    wb_or1k_i_dat_i : in  std_logic_vector(31 downto 0);
    wb_or1k_i_sel_i : in  std_logic_vector(3 downto 0);
    wb_or1k_i_we_i  : in  std_logic;
    wb_or1k_i_cyc_i : in  std_logic;
    wb_or1k_i_stb_i : in  std_logic;
    wb_or1k_i_cti_i : in  std_logic_vector(2 downto 0);
    wb_or1k_i_bte_i : in  std_logic_vector(1 downto 0);
    wb_or1k_i_dat_o : out std_logic_vector(31 downto 0);
    wb_or1k_i_ack_o : out std_logic;
    wb_or1k_i_err_o : out std_logic;
    wb_or1k_i_rty_o : out std_logic;
    wb_dbg_adr_i    : in  std_logic_vector(31 downto 0);
    wb_dbg_dat_i    : in  std_logic_vector(31 downto 0);
    wb_dbg_sel_i    : in  std_logic_vector(3 downto 0);
    wb_dbg_we_i     : in  std_logic;
    wb_dbg_cyc_i    : in  std_logic;
    wb_dbg_stb_i    : in  std_logic;
    wb_dbg_cti_i    : in  std_logic_vector(2 downto 0);
    wb_dbg_bte_i    : in  std_logic_vector(1 downto 0);
    wb_dbg_dat_o    : out std_logic_vector(31 downto 0);
    wb_dbg_ack_o    : out std_logic;
    wb_dbg_err_o    : out std_logic;
    wb_dbg_rty_o    : out std_logic;
    wb_mem_adr_o    : out std_logic_vector(31 downto 0);
    wb_mem_dat_o    : out std_logic_vector(31 downto 0);
    wb_mem_sel_o    : out std_logic_vector(3 downto 0);
    wb_mem_we_o     : out std_logic;
    wb_mem_cyc_o    : out std_logic;
    wb_mem_stb_o    : out std_logic;
    wb_mem_cti_o    : out std_logic_vector(2 downto 0);
    wb_mem_bte_o    : out std_logic_vector(1 downto 0);
    wb_mem_dat_i    : in  std_logic_vector(31 downto 0);
    wb_mem_ack_i    : in  std_logic;
    wb_mem_err_i    : in  std_logic;
    wb_mem_rty_i    : in  std_logic;
    wb_uart_adr_o   : out std_logic_vector(31 downto 0);
    wb_uart_dat_o   : out std_logic_vector(7 downto 0);
    wb_uart_sel_o   : out std_logic_vector(3 downto 0);
    wb_uart_we_o    : out std_logic;
    wb_uart_cyc_o   : out std_logic;
    wb_uart_stb_o   : out std_logic;
    wb_uart_cti_o   : out std_logic_vector(2 downto 0);
    wb_uart_bte_o   : out std_logic_vector(1 downto 0);
    wb_uart_dat_i   : in  std_logic_vector(7 downto 0);
    wb_uart_ack_i   : in  std_logic;
    wb_uart_err_i   : in  std_logic;
    wb_uart_rty_i   : in  std_logic
    );
end mpsoc_msi_wb_interface;

architecture RTL of mpsoc_msi_wb_interface is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant AW : integer := 32;
  constant DW : integer := 32;

  --////////////////////////////////////////////////////////////////
  --
  -- Components
  --
  component mpsoc_msi_wb_mux
    generic (
      DW : integer := 32;  -- Data width
      AW : integer := 32;  -- Address width

      NUM_SLAVES : integer := 2;  -- Number of slaves

      MATCH_ADDR : std_logic_vector(NUM_SLAVES*AW-1 downto 0) := (others => '0');
      MATCH_MASK : std_logic_vector(NUM_SLAVES*AW-1 downto 0) := (others => '0')
      );
    port (
      wb_clk_i : in std_logic;
      wb_rst_i : in std_logic;

      -- Master Interface
      wbm_adr_i : in  std_logic_vector(AW-1 downto 0);
      wbm_dat_i : in  std_logic_vector(DW-1 downto 0);
      wbm_sel_i : in  std_logic_vector(3 downto 0);
      wbm_we_i  : in  std_logic;
      wbm_cyc_i : in  std_logic;
      wbm_stb_i : in  std_logic;
      wbm_cti_i : in  std_logic_vector(2 downto 0);
      wbm_bte_i : in  std_logic_vector(1 downto 0);
      wbm_dat_o : out std_logic_vector(DW-1 downto 0);
      wbm_ack_o : out std_logic;
      wbm_err_o : out std_logic;
      wbm_rty_o : out std_logic;

      -- Wishbone Slave interface
      wbs_adr_o : out std_logic_matrix(NUM_SLAVES-1 downto 0)(AW-1 downto 0);
      wbs_dat_o : out std_logic_matrix(NUM_SLAVES-1 downto 0)(DW-1 downto 0);
      wbs_sel_o : out std_logic_matrix(NUM_SLAVES-1 downto 0)(3 downto 0);
      wbs_we_o  : out std_logic_vector(NUM_SLAVES-1 downto 0);
      wbs_cyc_o : out std_logic_vector(NUM_SLAVES-1 downto 0);
      wbs_stb_o : out std_logic_vector(NUM_SLAVES-1 downto 0);
      wbs_cti_o : out std_logic_matrix(NUM_SLAVES-1 downto 0)(2 downto 0);
      wbs_bte_o : out std_logic_matrix(NUM_SLAVES-1 downto 0)(1 downto 0);
      wbs_dat_i : in  std_logic_matrix(NUM_SLAVES-1 downto 0)(DW-1 downto 0);
      wbs_ack_i : in  std_logic_vector(NUM_SLAVES-1 downto 0);
      wbs_err_i : in  std_logic_vector(NUM_SLAVES-1 downto 0);
      wbs_rty_i : in  std_logic_vector(NUM_SLAVES-1 downto 0)
      );
  end component;

  component mpsoc_msi_wb_arbiter
    generic (
      DW : integer := 32;
      AW : integer := 32;

      NUM_MASTERS : integer := 0
      );
    port (
      wb_clk_i : in std_logic;
      wb_rst_i : in std_logic;

      -- Wishbone Master Interface
      wbm_adr_i : in  std_logic_matrix(NUM_MASTERS-1 downto 0)(AW-1 downto 0);
      wbm_dat_i : in  std_logic_matrix(NUM_MASTERS-1 downto 0)(DW-1 downto 0);
      wbm_sel_i : in  std_logic_matrix(NUM_MASTERS-1 downto 0)(3 downto 0);
      wbm_we_i  : in  std_logic_vector(NUM_MASTERS-1 downto 0);
      wbm_cyc_i : in  std_logic_vector(NUM_MASTERS-1 downto 0);
      wbm_stb_i : in  std_logic_vector(NUM_MASTERS-1 downto 0);
      wbm_cti_i : in  std_logic_matrix(NUM_MASTERS-1 downto 0)(2 downto 0);
      wbm_bte_i : in  std_logic_matrix(NUM_MASTERS-1 downto 0)(1 downto 0);
      wbm_dat_o : out std_logic_matrix(NUM_MASTERS-1 downto 0)(DW-1 downto 0);
      wbm_ack_o : out std_logic_vector(NUM_MASTERS-1 downto 0);
      wbm_err_o : out std_logic_vector(NUM_MASTERS-1 downto 0);
      wbm_rty_o : out std_logic_vector(NUM_MASTERS-1 downto 0);

      -- Wishbone Slave interface
      wbs_adr_o : out std_logic_vector(AW-1 downto 0);
      wbs_dat_o : out std_logic_vector(DW-1 downto 0);
      wbs_sel_o : out std_logic_vector(3 downto 0);
      wbs_we_o  : out std_logic;
      wbs_cyc_o : out std_logic;
      wbs_stb_o : out std_logic;
      wbs_cti_o : out std_logic_vector(2 downto 0);
      wbs_bte_o : out std_logic_vector(1 downto 0);
      wbs_dat_i : in  std_logic_vector(DW-1 downto 0);
      wbs_ack_i : in  std_logic;
      wbs_err_i : in  std_logic;
      wbs_rty_i : in  std_logic
      );
  end component;

  component mpsoc_msi_wb_data_resize
    generic (
      AW  : integer := 32;  --Address width
      MDW : integer := 32;  --Master Data Width
      SDW : integer := 8   --Slave Data Width
      );
    port (
      --Wishbone Master interface
      wbm_adr_i : in  std_logic_vector(AW-1 downto 0);
      wbm_dat_i : in  std_logic_vector(MDW-1 downto 0);
      wbm_sel_i : in  std_logic_vector(3 downto 0);
      wbm_we_i  : in  std_logic;
      wbm_cyc_i : in  std_logic;
      wbm_stb_i : in  std_logic;
      wbm_cti_i : in  std_logic_vector(2 downto 0);
      wbm_bte_i : in  std_logic_vector(1 downto 0);
      wbm_dat_o : out std_logic_vector(MDW-1 downto 0);
      wbm_ack_o : out std_logic;
      wbm_err_o : out std_logic;
      wbm_rty_o : out std_logic;

      -- Wishbone Slave interface
      wbs_adr_o : out std_logic_vector(AW-1 downto 0);
      wbs_dat_o : out std_logic_vector(SDW-1 downto 0);
      wbs_we_o  : out std_logic;
      wbs_cyc_o : out std_logic;
      wbs_stb_o : out std_logic;
      wbs_cti_o : out std_logic_vector(2 downto 0);
      wbs_bte_o : out std_logic_vector(1 downto 0);
      wbs_dat_i : in  std_logic_vector(SDW-1 downto 0);
      wbs_ack_i : in  std_logic;
      wbs_err_i : in  std_logic;
      wbs_rty_i : in  std_logic
      );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal wb_m2s_or1k_d_mem_adr  : std_logic_vector(31 downto 0);
  signal wb_m2s_or1k_d_mem_dat  : std_logic_vector(31 downto 0);
  signal wb_m2s_or1k_d_mem_sel  : std_logic_vector(3 downto 0);
  signal wb_m2s_or1k_d_mem_we   : std_logic;
  signal wb_m2s_or1k_d_mem_cyc  : std_logic;
  signal wb_m2s_or1k_d_mem_stb  : std_logic;
  signal wb_m2s_or1k_d_mem_cti  : std_logic_vector(2 downto 0);
  signal wb_m2s_or1k_d_mem_bte  : std_logic_vector(1 downto 0);
  signal wb_s2m_or1k_d_mem_dat  : std_logic_vector(31 downto 0);
  signal wb_s2m_or1k_d_mem_ack  : std_logic;
  signal wb_s2m_or1k_d_mem_err  : std_logic;
  signal wb_s2m_or1k_d_mem_rty  : std_logic;

  signal wb_m2s_or1k_i_mem_adr  : std_logic_matrix(0 downto 0)(31 downto 0);
  signal wb_m2s_or1k_i_mem_dat  : std_logic_matrix(0 downto 0)(31 downto 0);
  signal wb_m2s_or1k_i_mem_sel  : std_logic_matrix(0 downto 0)(3 downto 0);
  signal wb_m2s_or1k_i_mem_we   : std_logic_vector(0 downto 0);
  signal wb_m2s_or1k_i_mem_cyc  : std_logic_vector(0 downto 0);
  signal wb_m2s_or1k_i_mem_stb  : std_logic_vector(0 downto 0);
  signal wb_m2s_or1k_i_mem_cti  : std_logic_matrix(0 downto 0)(2 downto 0);
  signal wb_m2s_or1k_i_mem_bte  : std_logic_matrix(0 downto 0)(1 downto 0);
  signal wb_s2m_or1k_i_mem_dat  : std_logic_matrix(0 downto 0)(31 downto 0);
  signal wb_s2m_or1k_i_mem_ack  : std_logic_vector(0 downto 0);
  signal wb_s2m_or1k_i_mem_err  : std_logic_vector(0 downto 0);
  signal wb_s2m_or1k_i_mem_rty  : std_logic_vector(0 downto 0);

  signal wb_m2s_dbg_mem_adr     : std_logic_matrix(0 downto 0)(31 downto 0);
  signal wb_m2s_dbg_mem_dat     : std_logic_matrix(0 downto 0)(31 downto 0);
  signal wb_m2s_dbg_mem_sel     : std_logic_matrix(0 downto 0)(3 downto 0);
  signal wb_m2s_dbg_mem_we      : std_logic_vector(0 downto 0);
  signal wb_m2s_dbg_mem_cyc     : std_logic_vector(0 downto 0);
  signal wb_m2s_dbg_mem_stb     : std_logic_vector(0 downto 0);
  signal wb_m2s_dbg_mem_cti     : std_logic_matrix(0 downto 0)(2 downto 0);
  signal wb_m2s_dbg_mem_bte     : std_logic_matrix(0 downto 0)(1 downto 0);
  signal wb_s2m_dbg_mem_dat     : std_logic_matrix(0 downto 0)(31 downto 0);
  signal wb_s2m_dbg_mem_ack     : std_logic_vector(0 downto 0);
  signal wb_s2m_dbg_mem_err     : std_logic_vector(0 downto 0);
  signal wb_s2m_dbg_mem_rty     : std_logic_vector(0 downto 0);

  signal wb_m2s_resize_uart_adr : std_logic_vector(31 downto 0);
  signal wb_m2s_resize_uart_dat : std_logic_vector(31 downto 0);
  signal wb_m2s_resize_uart_sel : std_logic_vector(3 downto 0);
  signal wb_m2s_resize_uart_we  : std_logic;
  signal wb_m2s_resize_uart_cyc : std_logic;
  signal wb_m2s_resize_uart_stb : std_logic;
  signal wb_m2s_resize_uart_cti : std_logic_vector(2 downto 0);
  signal wb_m2s_resize_uart_bte : std_logic_vector(1 downto 0);
  signal wb_s2m_resize_uart_dat : std_logic_vector(31 downto 0);
  signal wb_s2m_resize_uart_ack : std_logic;
  signal wb_s2m_resize_uart_err : std_logic;
  signal wb_s2m_resize_uart_rty : std_logic;

  signal wb_m2s_or1k_d_adr_o : std_logic_matrix(1 downto 0)(AW-1 downto 0);
  signal wb_m2s_or1k_d_dat_o : std_logic_matrix(1 downto 0)(DW-1 downto 0);
  signal wb_m2s_or1k_d_sel_o : std_logic_matrix(1 downto 0)(3 downto 0);
  signal wb_m2s_or1k_d_we_o  : std_logic_vector(1 downto 0);
  signal wb_m2s_or1k_d_cyc_o : std_logic_vector(1 downto 0);
  signal wb_m2s_or1k_d_stb_o : std_logic_vector(1 downto 0);
  signal wb_m2s_or1k_d_cti_o : std_logic_matrix(1 downto 0)(2 downto 0);
  signal wb_m2s_or1k_d_bte_o : std_logic_matrix(1 downto 0)(1 downto 0);
  signal wb_s2m_or1k_d_dat_i : std_logic_matrix(1 downto 0)(DW-1 downto 0);
  signal wb_s2m_or1k_d_ack_i : std_logic_vector(1 downto 0);
  signal wb_s2m_or1k_d_err_i : std_logic_vector(1 downto 0);
  signal wb_s2m_or1k_d_rty_i : std_logic_vector(1 downto 0);

  signal wb_m2s_or1k_i_adr_i : std_logic_matrix(2 downto 0)(AW-1 downto 0);
  signal wb_m2s_or1k_i_dat_i : std_logic_matrix(2 downto 0)(DW-1 downto 0);
  signal wb_m2s_or1k_i_sel_i : std_logic_matrix(2 downto 0)(3 downto 0);
  signal wb_m2s_or1k_i_we_i  : std_logic_vector(2 downto 0);
  signal wb_m2s_or1k_i_cyc_i : std_logic_vector(2 downto 0);
  signal wb_m2s_or1k_i_stb_i : std_logic_vector(2 downto 0);
  signal wb_m2s_or1k_i_cti_i : std_logic_matrix(2 downto 0)(2 downto 0);
  signal wb_m2s_or1k_i_bte_i : std_logic_matrix(2 downto 0)(1 downto 0);
  signal wb_s2m_or1k_i_dat_o : std_logic_matrix(2 downto 0)(DW-1 downto 0);
  signal wb_s2m_or1k_i_ack_o : std_logic_vector(2 downto 0);
  signal wb_s2m_or1k_i_err_o : std_logic_vector(2 downto 0);
  signal wb_s2m_or1k_i_rty_o : std_logic_vector(2 downto 0);

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  wb_mux_or1k_d : mpsoc_msi_wb_mux
    generic map (
      DW => DW,
      AW => AW,

      NUM_SLAVES => 2,

      MATCH_ADDR => (X"00000000", X"00000000"),
      MATCH_MASK => (X"fe000000", X"fffffff8")
      )
    port map (
      wb_clk_i  => wb_clk_i,
      wb_rst_i  => wb_rst_i,
      wbm_adr_i => wb_or1k_d_adr_i,
      wbm_dat_i => wb_or1k_d_dat_i,
      wbm_sel_i => wb_or1k_d_sel_i,
      wbm_we_i  => wb_or1k_d_we_i,
      wbm_cyc_i => wb_or1k_d_cyc_i,
      wbm_stb_i => wb_or1k_d_stb_i,
      wbm_cti_i => wb_or1k_d_cti_i,
      wbm_bte_i => wb_or1k_d_bte_i,
      wbm_dat_o => wb_or1k_d_dat_o,
      wbm_ack_o => wb_or1k_d_ack_o,
      wbm_err_o => wb_or1k_d_err_o,
      wbm_rty_o => wb_or1k_d_rty_o,
      wbs_adr_o => wb_m2s_or1k_d_adr_o,
      wbs_dat_o => wb_m2s_or1k_d_dat_o,
      wbs_sel_o => wb_m2s_or1k_d_sel_o,
      wbs_we_o  => wb_m2s_or1k_d_we_o,
      wbs_cyc_o => wb_m2s_or1k_d_cyc_o,
      wbs_stb_o => wb_m2s_or1k_d_stb_o,
      wbs_cti_o => wb_m2s_or1k_d_cti_o,
      wbs_bte_o => wb_m2s_or1k_d_bte_o,
      wbs_dat_i => wb_s2m_or1k_d_dat_i,
      wbs_ack_i => wb_s2m_or1k_d_ack_i,
      wbs_err_i => wb_s2m_or1k_d_err_i,
      wbs_rty_i => wb_s2m_or1k_d_rty_i
      );

  wb_m2s_or1k_d_adr_o <= (wb_m2s_or1k_d_mem_adr, wb_m2s_resize_uart_adr);
  wb_m2s_or1k_d_dat_o <= (wb_m2s_or1k_d_mem_dat, wb_m2s_resize_uart_dat);
  wb_m2s_or1k_d_sel_o <= (wb_m2s_or1k_d_mem_sel, wb_m2s_resize_uart_sel);
  wb_m2s_or1k_d_we_o  <= (wb_m2s_or1k_d_mem_we,  wb_m2s_resize_uart_we);
  wb_m2s_or1k_d_cyc_o <= (wb_m2s_or1k_d_mem_cyc, wb_m2s_resize_uart_cyc);
  wb_m2s_or1k_d_stb_o <= (wb_m2s_or1k_d_mem_stb, wb_m2s_resize_uart_stb);
  wb_m2s_or1k_d_cti_o <= (wb_m2s_or1k_d_mem_cti, wb_m2s_resize_uart_cti);
  wb_m2s_or1k_d_bte_o <= (wb_m2s_or1k_d_mem_bte, wb_m2s_resize_uart_bte);
  wb_s2m_or1k_d_dat_i <= (wb_s2m_or1k_d_mem_dat, wb_s2m_resize_uart_dat);
  wb_s2m_or1k_d_ack_i <= (wb_s2m_or1k_d_mem_ack, wb_s2m_resize_uart_ack);
  wb_s2m_or1k_d_err_i <= (wb_s2m_or1k_d_mem_err, wb_s2m_resize_uart_err);
  wb_s2m_or1k_d_rty_i <= (wb_s2m_or1k_d_mem_rty, wb_s2m_resize_uart_rty);

  wb_mux_or1k_i : mpsoc_msi_wb_mux
    generic map (
      DW => DW,
      AW => AW,

      NUM_SLAVES => 1,

      MATCH_ADDR => X"00000000",
      MATCH_MASK => X"fe000000"
      )
    port map (
      wb_clk_i  => wb_clk_i,
      wb_rst_i  => wb_rst_i,
      wbm_adr_i => wb_or1k_i_adr_i,
      wbm_dat_i => wb_or1k_i_dat_i,
      wbm_sel_i => wb_or1k_i_sel_i,
      wbm_we_i  => wb_or1k_i_we_i,
      wbm_cyc_i => wb_or1k_i_cyc_i,
      wbm_stb_i => wb_or1k_i_stb_i,
      wbm_cti_i => wb_or1k_i_cti_i,
      wbm_bte_i => wb_or1k_i_bte_i,
      wbm_dat_o => wb_or1k_i_dat_o,
      wbm_ack_o => wb_or1k_i_ack_o,
      wbm_err_o => wb_or1k_i_err_o,
      wbm_rty_o => wb_or1k_i_rty_o,
      wbs_adr_o => wb_m2s_or1k_i_mem_adr,
      wbs_dat_o => wb_m2s_or1k_i_mem_dat,
      wbs_sel_o => wb_m2s_or1k_i_mem_sel,
      wbs_we_o  => wb_m2s_or1k_i_mem_we,
      wbs_cyc_o => wb_m2s_or1k_i_mem_cyc,
      wbs_stb_o => wb_m2s_or1k_i_mem_stb,
      wbs_cti_o => wb_m2s_or1k_i_mem_cti,
      wbs_bte_o => wb_m2s_or1k_i_mem_bte,
      wbs_dat_i => wb_s2m_or1k_i_mem_dat,
      wbs_ack_i => wb_s2m_or1k_i_mem_ack,
      wbs_err_i => wb_s2m_or1k_i_mem_err,
      wbs_rty_i => wb_s2m_or1k_i_mem_rty
      );

  wb_mux_dbg : mpsoc_msi_wb_mux
    generic map (
      DW => DW,
      AW => AW,

      NUM_SLAVES => 1,

      MATCH_ADDR => X"00000000",
      MATCH_MASK => X"fe000000"
      )
    port map (
      wb_clk_i  => wb_clk_i,
      wb_rst_i  => wb_rst_i,
      wbm_adr_i => wb_dbg_adr_i,
      wbm_dat_i => wb_dbg_dat_i,
      wbm_sel_i => wb_dbg_sel_i,
      wbm_we_i  => wb_dbg_we_i,
      wbm_cyc_i => wb_dbg_cyc_i,
      wbm_stb_i => wb_dbg_stb_i,
      wbm_cti_i => wb_dbg_cti_i,
      wbm_bte_i => wb_dbg_bte_i,
      wbm_dat_o => wb_dbg_dat_o,
      wbm_ack_o => wb_dbg_ack_o,
      wbm_err_o => wb_dbg_err_o,
      wbm_rty_o => wb_dbg_rty_o,
      wbs_adr_o => wb_m2s_dbg_mem_adr,
      wbs_dat_o => wb_m2s_dbg_mem_dat,
      wbs_sel_o => wb_m2s_dbg_mem_sel,
      wbs_we_o  => wb_m2s_dbg_mem_we,
      wbs_cyc_o => wb_m2s_dbg_mem_cyc,
      wbs_stb_o => wb_m2s_dbg_mem_stb,
      wbs_cti_o => wb_m2s_dbg_mem_cti,
      wbs_bte_o => wb_m2s_dbg_mem_bte,
      wbs_dat_i => wb_s2m_dbg_mem_dat,
      wbs_ack_i => wb_s2m_dbg_mem_ack,
      wbs_err_i => wb_s2m_dbg_mem_err,
      wbs_rty_i => wb_s2m_dbg_mem_rty
      );

  wb_arbiter_mem : mpsoc_msi_wb_arbiter
    generic map (
      DW => DW,
      AW => AW,

      NUM_MASTERS => 3
      )
    port map (
      wb_clk_i  => wb_clk_i,
      wb_rst_i  => wb_rst_i,
      wbm_adr_i => wb_m2s_or1k_i_adr_i,
      wbm_dat_i => wb_m2s_or1k_i_dat_i,
      wbm_sel_i => wb_m2s_or1k_i_sel_i,
      wbm_we_i  => wb_m2s_or1k_i_we_i,
      wbm_cyc_i => wb_m2s_or1k_i_cyc_i,
      wbm_stb_i => wb_m2s_or1k_i_stb_i,
      wbm_cti_i => wb_m2s_or1k_i_cti_i,
      wbm_bte_i => wb_m2s_or1k_i_bte_i,
      wbm_dat_o => wb_s2m_or1k_i_dat_o,
      wbm_ack_o => wb_s2m_or1k_i_ack_o,
      wbm_err_o => wb_s2m_or1k_i_err_o,
      wbm_rty_o => wb_s2m_or1k_i_rty_o,
      wbs_adr_o => wb_mem_adr_o,
      wbs_dat_o => wb_mem_dat_o,
      wbs_sel_o => wb_mem_sel_o,
      wbs_we_o  => wb_mem_we_o,
      wbs_cyc_o => wb_mem_cyc_o,
      wbs_stb_o => wb_mem_stb_o,
      wbs_cti_o => wb_mem_cti_o,
      wbs_bte_o => wb_mem_bte_o,
      wbs_dat_i => wb_mem_dat_i,
      wbs_ack_i => wb_mem_ack_i,
      wbs_err_i => wb_mem_err_i,
      wbs_rty_i => wb_mem_rty_i
      );

  wb_m2s_or1k_i_adr_i <= (wb_m2s_or1k_i_mem_adr, wb_m2s_or1k_d_mem_adr, wb_m2s_dbg_mem_adr);
  wb_m2s_or1k_i_dat_i <= (wb_m2s_or1k_i_mem_dat, wb_m2s_or1k_d_mem_dat, wb_m2s_dbg_mem_dat);
  wb_m2s_or1k_i_sel_i <= (wb_m2s_or1k_i_mem_sel, wb_m2s_or1k_d_mem_sel, wb_m2s_dbg_mem_sel);
  wb_m2s_or1k_i_we_i  <= (wb_m2s_or1k_i_mem_we,  wb_m2s_or1k_d_mem_we,  wb_m2s_dbg_mem_we);
  wb_m2s_or1k_i_cyc_i <= (wb_m2s_or1k_i_mem_cyc, wb_m2s_or1k_d_mem_cyc, wb_m2s_dbg_mem_cyc);
  wb_m2s_or1k_i_stb_i <= (wb_m2s_or1k_i_mem_stb, wb_m2s_or1k_d_mem_stb, wb_m2s_dbg_mem_stb);
  wb_m2s_or1k_i_cti_i <= (wb_m2s_or1k_i_mem_cti, wb_m2s_or1k_d_mem_cti, wb_m2s_dbg_mem_cti);
  wb_m2s_or1k_i_bte_i <= (wb_m2s_or1k_i_mem_bte, wb_m2s_or1k_d_mem_bte, wb_m2s_dbg_mem_bte);
  wb_s2m_or1k_i_dat_o <= (wb_s2m_or1k_i_mem_dat, wb_s2m_or1k_d_mem_dat, wb_s2m_dbg_mem_dat);
  wb_s2m_or1k_i_ack_o <= (wb_s2m_or1k_i_mem_ack, wb_s2m_or1k_d_mem_ack, wb_s2m_dbg_mem_ack);
  wb_s2m_or1k_i_err_o <= (wb_s2m_or1k_i_mem_err, wb_s2m_or1k_d_mem_err, wb_s2m_dbg_mem_err);
  wb_s2m_or1k_i_rty_o <= (wb_s2m_or1k_i_mem_rty, wb_s2m_or1k_d_mem_rty, wb_s2m_dbg_mem_rty);

  wb_data_resize_uart : mpsoc_msi_wb_data_resize
    generic map (
      AW  => 32,
      MDW => 32,
      SDW => 8
      )
    port map (
      wbm_adr_i => wb_m2s_resize_uart_adr,
      wbm_dat_i => wb_m2s_resize_uart_dat,
      wbm_sel_i => wb_m2s_resize_uart_sel,
      wbm_we_i  => wb_m2s_resize_uart_we,
      wbm_cyc_i => wb_m2s_resize_uart_cyc,
      wbm_stb_i => wb_m2s_resize_uart_stb,
      wbm_cti_i => wb_m2s_resize_uart_cti,
      wbm_bte_i => wb_m2s_resize_uart_bte,
      wbm_dat_o => wb_s2m_resize_uart_dat,
      wbm_ack_o => wb_s2m_resize_uart_ack,
      wbm_err_o => wb_s2m_resize_uart_err,
      wbm_rty_o => wb_s2m_resize_uart_rty,
      wbs_adr_o => wb_uart_adr_o,
      wbs_dat_o => wb_uart_dat_o,
      wbs_we_o  => wb_uart_we_o,
      wbs_cyc_o => wb_uart_cyc_o,
      wbs_stb_o => wb_uart_stb_o,
      wbs_cti_o => wb_uart_cti_o,
      wbs_bte_o => wb_uart_bte_o,
      wbs_dat_i => wb_uart_dat_i,
      wbs_ack_i => wb_uart_ack_i,
      wbs_err_i => wb_uart_err_i,
      wbs_rty_i => wb_uart_rty_i
      );

  wb_uart_sel_o <= (others => '0');
end RTL;
