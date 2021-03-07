-- Converted from core/mpsoc_msi_wb_cdc.v
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

entity mpsoc_msi_wb_cdc is
  generic (
    AW : integer := 32
    );
  port (
    wbm_clk   : in  std_logic;
    wbm_rst   : in  std_logic;
    wbm_adr_i : in  std_logic_vector(AW-1 downto 0);
    wbm_dat_i : in  std_logic_vector(31 downto 0);
    wbm_sel_i : in  std_logic_vector(3 downto 0);
    wbm_we_i  : in  std_logic;
    wbm_cyc_i : in  std_logic;
    wbm_stb_i : in  std_logic;
    wbm_dat_o : out std_logic_vector(31 downto 0);
    wbm_ack_o : out std_logic;
    wbs_clk   : in  std_logic;
    wbs_rst   : in  std_logic;
    wbs_adr_o : out std_logic_vector(AW-1 downto 0);
    wbs_dat_o : out std_logic_vector(31 downto 0);
    wbs_sel_o : out std_logic_vector(3 downto 0);
    wbs_we_o  : out std_logic;
    wbs_cyc_o : out std_logic;
    wbs_stb_o : out std_logic;
    wbs_dat_i : in  std_logic_vector(31 downto 0);
    wbs_ack_i : in  std_logic
    );
end mpsoc_msi_wb_cdc;

architecture RTL of mpsoc_msi_wb_cdc is
  component mpsoc_msi_wb_cc561
    generic (
      DW : integer := 0
      );
    port (
      aclk  : in  std_logic;
      arst  : in  std_logic;
      adata : in  std_logic_vector(DW-1 downto 0);
      aen   : in  std_logic;
      bclk  : in  std_logic;
      bdata : out std_logic_vector(DW-1 downto 0);
      ben   : out std_logic
      );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal wbm_m2s_bdata : std_logic_vector(AW+32+4 downto 0);

  signal wbm_m2s_en : std_logic;
  signal wbm_busy   : std_logic;
  signal wbm_cs     : std_logic;
  signal wbm_done   : std_logic;

  signal wbs_m2s_en : std_logic;
  signal wbs_cs     : std_logic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  wbm_busy <= '0';
  wbs_cs   <= '0';

  cdc_m2s : mpsoc_msi_wb_cc561
    generic map (
      DW => AW+32+4+1
      )
    port map (
      aclk  => wbm_clk,
      arst  => wbm_rst,
      adata => (wbm_adr_i & wbm_dat_i & wbm_sel_i & wbm_we_i),
      aen   => wbm_m2s_en,
      bclk  => wbs_clk,
      bdata => wbm_m2s_bdata,
      ben   => wbs_m2s_en
      );

  wbm_cs        <= wbm_cyc_i and wbm_stb_i;
  wbm_m2s_en    <= wbm_cs and not wbm_busy;
  wbm_m2s_bdata <= wbs_adr_o & wbs_dat_o & wbs_sel_o & wbs_we_o;

  processing_0 : process (wbm_clk)
  begin
    if (rising_edge(wbm_clk)) then
      if (wbm_ack_o = '1' or wbm_rst = '1') then
        wbm_busy <= '0';
      elsif (wbm_cs = '1') then
        wbm_busy <= '1';
      end if;
    end if;
  end process;

  processing_1 : process (wbs_clk)
  begin
    if (rising_edge(wbs_clk)) then
      if (wbs_ack_i = '1') then
        wbs_cs <= '0';
      elsif (wbs_m2s_en = '1') then
        wbs_cs <= '1';
      end if;
    end if;
  end process;

  wbs_cyc_o <= wbs_m2s_en or wbs_cs;
  wbs_stb_o <= wbs_m2s_en or wbs_cs;

  cdc_s2m : mpsoc_msi_wb_cc561
    generic map (
      DW => 32
      )
    port map (
      aclk  => wbs_clk,
      arst  => wbs_rst,
      adata => wbs_dat_i,
      aen   => wbs_ack_i,
      bclk  => wbm_clk,
      bdata => wbm_dat_o,
      ben   => wbm_ack_o
      );
end RTL;
