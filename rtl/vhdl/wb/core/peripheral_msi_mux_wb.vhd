-- Converted from core/mpsoc_msi_wb_mux.v
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

entity mpsoc_msi_wb_mux is
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
end mpsoc_msi_wb_mux;

architecture RTL of mpsoc_msi_wb_mux is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant SLAVE_SEL_BITS : integer := integer(log2(real(NUM_SLAVES)));

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal wbm_err   : std_logic;
  signal slave_sel : std_logic_vector(SLAVE_SEL_BITS-1 downto 0);
  signal match     : std_logic_vector(NUM_SLAVES-1 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --

  -- Find First 1
  -- Start from MSB and count downwards, returns 0 when no bit set
  function ff1 (
    input : std_logic_vector(NUM_SLAVES-1 downto 0)
    ) return std_logic_vector is
    variable ff1_return : std_logic_vector (SLAVE_SEL_BITS-1 downto 0);
  begin
    ff1_return := (others => '0');
    for i in NUM_SLAVES-1 downto 0 loop
      if (input(i) = '1') then
        ff1_return := std_logic_vector(to_unsigned(i, SLAVE_SEL_BITS));
      end if;
    end loop;
    return ff1_return;
  end ff1;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  generating_0 : for idx in 0 to NUM_SLAVES - 1 generate
    match(idx) <= to_stdlogic((wbm_adr_i and MATCH_MASK((idx+1)*AW-1 downto idx*AW)) = MATCH_ADDR((idx+1)*AW-1 downto idx*AW));
  end generate;

  slave_sel <= ff1(match);

  processing_0 : process (wb_clk_i)
  begin
    if (rising_edge(wb_clk_i)) then
      wbm_err <= wbm_cyc_i and not (reduce_or(match));
    end if;
  end process;

  generating_1 : for idx in 0 to NUM_SLAVES - 1 generate
    wbs_adr_o(idx) <= wbm_adr_i;
    wbs_dat_o(idx) <= wbm_dat_i;
    wbs_sel_o(idx) <= wbm_sel_i;
    wbs_we_o(idx)  <= wbm_we_i;
    wbs_stb_o(idx) <= wbm_stb_i;
    wbs_cti_o(idx) <= wbm_cti_i;
    wbs_bte_o(idx) <= wbm_bte_i;
  end generate;

  wbs_cyc_o <= match and ((NUM_SLAVES-1 downto 1 => '0') & wbm_cyc_i sll to_integer(unsigned(slave_sel)));

  wbm_dat_o <= wbs_dat_i(to_integer(unsigned(slave_sel)));
  wbm_ack_o <= wbs_ack_i(to_integer(unsigned(slave_sel)));
  wbm_err_o <= wbs_err_i(to_integer(unsigned(slave_sel))) or wbm_err;
  wbm_rty_o <= wbs_rty_i(to_integer(unsigned(slave_sel)));
end RTL;
