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
-- *   Francisco Javier Reina Campo <frareicam@gmail.com>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

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
    wbs_adr_o : out std_logic_vector(NUM_SLAVES*AW-1 downto 0);
    wbs_dat_o : out std_logic_vector(NUM_SLAVES*DW-1 downto 0);
    wbs_sel_o : out std_logic_vector(NUM_SLAVES*4-1 downto 0);
    wbs_we_o  : out std_logic_vector(NUM_SLAVES-1 downto 0);
    wbs_cyc_o : out std_logic_vector(NUM_SLAVES-1 downto 0);
    wbs_stb_o : out std_logic_vector(NUM_SLAVES-1 downto 0);
    wbs_cti_o : out std_logic_vector(NUM_SLAVES*3-1 downto 0);
    wbs_bte_o : out std_logic_vector(NUM_SLAVES*2-1 downto 0);
    wbs_dat_i : in  std_logic_vector(NUM_SLAVES*DW-1 downto 0);
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
  signal match_cyc : std_logic_vector(NUM_SLAVES-1 downto 0);

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

  function reduce_or (
    reduce_or_in : std_logic_vector
    ) return std_logic is
    variable reduce_or_out : std_logic := '0';
  begin
    for i in reduce_or_in'range loop
      reduce_or_out := reduce_or_out or reduce_or_in(i);
    end loop;
    return reduce_or_out;
  end reduce_or;

  function to_stdlogic (
    input : boolean
    ) return std_logic is
  begin
    if input then
      return('1');
    else
      return('0');
    end if;
  end function to_stdlogic;

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
    wbs_adr_o((idx+1)*AW-1 downto idx*AW) <= wbm_adr_i;
    wbs_dat_o((idx+1)*DW-1 downto idx*DW) <= wbm_dat_i;
    wbs_sel_o((idx+1)*4-1 downto idx*4) <= wbm_sel_i;
    wbs_cti_o((idx+1)*3-1 downto idx*3) <= wbm_cti_i;
    wbs_bte_o((idx+1)*2-1 downto idx*2) <= wbm_bte_i;
  end generate;

  wbs_we_o  <= (others => wbm_we_i);

  match_cyc(NUM_SLAVES-1 downto 1) <= (others => '0');
  match_cyc(0) <= wbm_cyc_i;

  wbs_cyc_o <= match and std_logic_vector(unsigned(match_cyc) sll to_integer(unsigned(slave_sel)));

  wbs_stb_o <= (others => wbm_stb_i);

  wbm_dat_o <= wbs_dat_i((to_integer(unsigned(slave_sel))+1)*DW-1 downto to_integer(unsigned(slave_sel))*DW);
  wbm_ack_o <= wbs_ack_i(to_integer(unsigned(slave_sel)));
  wbm_err_o <= wbs_err_i(to_integer(unsigned(slave_sel))) or wbm_err;
  wbm_rty_o <= wbs_rty_i(to_integer(unsigned(slave_sel)));
end RTL;
