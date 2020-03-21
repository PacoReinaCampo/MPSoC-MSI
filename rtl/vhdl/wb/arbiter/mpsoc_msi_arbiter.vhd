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
-- *   Francisco Javier Reina Campo <frareicam@gmail.com>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

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
  -- Types
  --
  type M_NUM_PORTS_NUM_PORTS is array (NUM_PORTS-1 downto 0) of std_logic_vector(NUM_PORTS-1 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal next_s : std_logic;
  signal order  : std_logic_vector(NUM_PORTS-1 downto 0);

  signal token_lookahead : M_NUM_PORTS_NUM_PORTS;
  signal token           : std_logic_vector(NUM_PORTS-1 downto 0);
  signal token_wrap      : std_logic_vector(WRAP_LENGTH-1 downto 0);

  --//////////////////////////////////////////////////////////////
  --
  -- functions
  --
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

  function reduce_nor (
    reduce_nor_in : std_logic_vector
    ) return std_logic is
    variable reduce_nor_out : std_logic := '0';
  begin
    for i in reduce_nor_in'range loop
      reduce_nor_out := reduce_nor_out nor reduce_nor_in(i);
    end loop;
    return reduce_nor_out;
  end reduce_nor;

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

  generating_0 : for xx in 0 to NUM_PORTS - 1 generate
    token_wrap((xx+1)*NUM_PORTS-1 downto xx*NUM_PORTS) <= token;

    token_lookahead(xx) <= token_wrap((xx+1)*NUM_PORTS-1 downto xx*NUM_PORTS);
    order(xx)           <= reduce_or(token_lookahead(xx) and request);
  end generate;
end RTL;
