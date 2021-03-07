-- Converted from core/mpsoc_msi_wb_arbiter.v
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
use ieee.math_real.all;

use work.mpsoc_msi_wb_pkg.all;

entity mpsoc_msi_wb_arbiter is
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
end mpsoc_msi_wb_arbiter;

architecture RTL of mpsoc_msi_wb_arbiter is
  component mpsoc_msi_arbiter
    generic (
      NUM_PORTS : integer := 6
      );
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      request   : in  std_logic_vector(NUM_PORTS-1 downto 0);
      grant     : out std_logic_vector(NUM_PORTS-1 downto 0);
      selection : out std_logic_vector(integer(log2(real(NUM_PORTS)))-1 downto 0);
      active    : out std_logic
      );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant MASTER_SEL_BITS : integer := integer(log2(real(NUM_MASTERS)));

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal grant  : std_logic_vector(NUM_MASTERS-1 downto 0);
  signal active : std_logic;

  signal selection : std_logic_vector(MASTER_SEL_BITS-1 downto 0);

  signal master_selection : integer;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  arbiter0 : mpsoc_msi_arbiter
    generic map (
      NUM_PORTS => NUM_MASTERS
      )
    port map (
      clk       => wb_clk_i,
      rst       => wb_rst_i,
      request   => wbm_cyc_i,
      grant     => grant,
      selection => selection,
      active    => active
      );

  master_selection <= to_integer(unsigned(selection));

  --Mux active master
  wbs_adr_o <= wbm_adr_i(0);
  wbs_dat_o <= wbm_dat_i(0);
  wbs_sel_o <= wbm_sel_i(0);
  wbs_we_o  <= wbm_we_i(0);
  wbs_cyc_o <= wbm_cyc_i(0) and active;
  wbs_stb_o <= wbm_stb_i(0);
  wbs_cti_o <= wbm_cti_i(0);
  wbs_bte_o <= wbm_bte_i(0);

  generating_0 : for i in 0 to NUM_MASTERS - 1 generate
    wbm_dat_o(i) <= wbs_dat_i;
  end generate;

  wbm_ack_o <= (NUM_MASTERS-1 downto 1 => '0') & (wbs_ack_i and active) sll master_selection;
  wbm_err_o <= (NUM_MASTERS-1 downto 1 => '0') & (wbs_err_i and active) sll master_selection;
  wbm_rty_o <= (NUM_MASTERS-1 downto 1 => '0') & (wbs_rty_i and active) sll master_selection;
end RTL;
