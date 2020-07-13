-- Converted from cdc_utils/mpsoc_msi_wb_cc561.v
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

entity mpsoc_msi_wb_cc561 is
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
end mpsoc_msi_wb_cc561;

architecture RTL of mpsoc_msi_wb_cc561 is
  component mpsoc_msi_wb_sync2_pgen
    port (
      c : in  std_logic;
      d : in  std_logic;
      p : out std_logic;
      q : out std_logic
      );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal adata_r : std_logic_vector(DW-1 downto 0);
  signal aen_r   : std_logic;
  signal bpulse  : std_logic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  aen_r <= '0';

  processing_0 : process (aclk)
  begin
    if (rising_edge(aclk)) then
      if (aen) then
        adata_r <= adata;
      end if;
      aen_r <= aen xor aen_r;
      if (arst) then
        aen_r <= '0';
      end if;
    end if;
  end process;

  processing_1 : process (bclk)
  begin
    if (rising_edge(bclk)) then
      if (bpulse) then
        bdata <= adata_r;  --CDC
      end if;
      ben <= bpulse;
    end if;
  end process;

  sync2_pgen : mpsoc_msi_wb_sync2_pgen
    port map (
      c => bclk,
      d => aen_r,  --CDC
      p => bpulse,
      q => open
      );
end RTL;
