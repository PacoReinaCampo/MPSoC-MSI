-- Converted from arbiter/mpsoc_msi_arbiter.v
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

entity mpsoc_msi_arbiter is
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
end mpsoc_msi_arbiter;

architecture RTL of mpsoc_msi_arbiter is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant WRAP_LENGTH : integer := NUM_PORTS*NUM_PORTS;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal next_s : std_logic;
  signal order  : std_logic_vector(NUM_PORTS-1 downto 0);

  signal token_lookahead : std_logic_matrix(NUM_PORTS-1 downto 0)(NUM_PORTS-1 downto 0);
  signal token           : std_logic_vector(NUM_PORTS-1 downto 0);
  signal token_wrap      : std_logic_vector(WRAP_LENGTH-1 downto 0);

  --//////////////////////////////////////////////////////////////
  --
  -- functions
  --

  -- Find First 1
  -- Start from MSB and count downwards, returns 0 when no bit set
  function ff1 (
    input : std_logic_vector(NUM_PORTS-1 downto 0)
    ) return std_logic_vector is
    variable ff1_return : std_logic_vector(integer(log2(real(NUM_PORTS)))-1 downto 0);
  begin
    ff1_return := (others => '0');
    for i in NUM_PORTS-1 downto 0 loop
      if (input(i) = '1') then
        ff1_return := std_logic_vector(to_unsigned(i, integer(log2(real(NUM_PORTS)))));
      end if;
    end loop;
    return ff1_return;
  end ff1;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  next_s <= reduce_nor(token and request);

  processing_0 : process (clk)
  begin
    if (rising_edge(clk)) then
      grant     <= token and request;
      selection <= ff1(token and request);
      active    <= reduce_or(token and request);
    end if;
  end process;

  processing_1 : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        token <= std_logic_vector(to_unsigned(1, NUM_PORTS));
      elsif (next_s = '1') then
        for yy in 0 to NUM_PORTS - 1 loop
          if (order(yy) = '1') then
            token <= token_lookahead(yy);
          end if;
        end loop;
      end if;
    end if;
  end process;

  generating_0 : for i in 0 to NUM_PORTS - 1 generate
    token_wrap((i+1)*NUM_PORTS-1 downto i*NUM_PORTS) <= token;

    token_lookahead(i) <= token_wrap((i+1)*NUM_PORTS-1 downto i*NUM_PORTS);
    order(i)           <= reduce_or(token_lookahead(i) and request);
  end generate;
end RTL;
