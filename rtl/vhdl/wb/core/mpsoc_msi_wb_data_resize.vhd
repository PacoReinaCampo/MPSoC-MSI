-- Converted from core/mpsoc_msi_wb_data_resize.v
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

entity mpsoc_msi_wb_data_resize is
  generic (
    AW  : integer := 32;  --Address width
    MDW : integer := 32;  --Master Data Width
    SDW : integer := 8    --Slave Data Width
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
end mpsoc_msi_wb_data_resize;

architecture RTL of mpsoc_msi_wb_data_resize is
begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  wbs_adr_o(AW-1 downto 2) <= wbm_adr_i(AW-1 downto 2);

  wbs_adr_o(1 downto 0) <= "00"
                        when wbm_sel_i(3) = '1' else "01"
                        when wbm_sel_i(2) = '1' else "10"
                        when wbm_sel_i(1) = '1' else "11";

  wbs_dat_o <= wbm_dat_i(31 downto 24)
               when wbm_sel_i(3) = '1' else wbm_dat_i(23 downto 16)
               when wbm_sel_i(2) = '1' else wbm_dat_i(15 downto 8)
               when wbm_sel_i(1) = '1' else wbm_dat_i(7 downto 0)
               when wbm_sel_i(0) = '1' else X"00";

  wbs_we_o <= wbm_we_i;

  wbs_cyc_o <= wbm_cyc_i;
  wbs_stb_o <= wbm_stb_i;

  wbs_cti_o <= wbm_cti_i;
  wbs_bte_o <= wbm_bte_i;

  wbm_dat_o <= (wbs_dat_i & X"000000")
               when (wbm_sel_i(3) = '1') else (X"00" & wbs_dat_i & X"0000")
               when (wbm_sel_i(2) = '1') else (X"0000" & wbs_dat_i & X"00")
               when (wbm_sel_i(1) = '1') else (X"000000" & wbs_dat_i);

  wbm_ack_o <= wbs_ack_i;
  wbm_err_o <= wbs_err_i;
  wbm_rty_o <= wbs_rty_i;
end RTL;
