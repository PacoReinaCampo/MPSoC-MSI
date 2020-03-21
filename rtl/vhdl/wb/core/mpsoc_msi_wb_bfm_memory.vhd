-- Converted from core/mpsoc_msi_wb_bfm_memory.v
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

entity mpsoc_msi_wb_bfm_memory is
  port (
  --Wishbone parameters
  -- Memory parameters
  -- 32KBytes
    wb_clk_i : in std_logic;
    wb_rst_i : in std_logic;

    wb_adr_i : in std_logic_vector(AW-1 downto 0);
    wb_dat_i : in std_logic_vector(DW-1 downto 0);
    wb_sel_i : in std_logic_vector(DW/8-1 downto 0);
    wb_we_i : in std_logic;
    wb_bte_i : in std_logic_vector(1 downto 0);
    wb_cti_i : in std_logic_vector(2 downto 0);
    wb_cyc_i : in std_logic;
    wb_stb_i : in std_logic;

    wb_ack_o : out std_logic;
    wb_err_o : out std_logic;
    wb_rty_o : out std_logic 
    wb_dat_o : out std_logic_vector(DW-1 downto 0)
  );
  constant DW : integer := 32;
  constant AW : integer := 32;
  constant DEBUG : integer := 0;
  constant MEMORY_FILE : integer := "";
  constant MEM_SIZE_BYTES : std_logic_vector(31 downto 0) := X"0000_8000";
  constant RD_MIN_DELAY : integer := 0;
  constant RD_MAX_DELAY : integer := 4;
end mpsoc_msi_wb_bfm_memory;

architecture RTL of mpsoc_msi_wb_bfm_memory is
  component mpsoc_msi_wb_bfm_slave
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    wb_clk : std_logic_vector(? downto 0);
    wb_rst : std_logic_vector(? downto 0);
    wb_adr_i : std_logic_vector(? downto 0);
    wb_dat_i : std_logic_vector(? downto 0);
    wb_sel_i : std_logic_vector(? downto 0);
    wb_we_i : std_logic_vector(? downto 0);
    wb_cyc_i : std_logic_vector(? downto 0);
    wb_stb_i : std_logic_vector(? downto 0);
    wb_cti_i : std_logic_vector(? downto 0);
    wb_bte_i : std_logic_vector(? downto 0);
    wb_dat_o : std_logic_vector(? downto 0);
    wb_ack_o : std_logic_vector(? downto 0);
    wb_err_o : std_logic_vector(? downto 0);
    wb_rty_o : std_logic_vector(? downto 0)
  );
  end component;



  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  use work."mpsoc_msi_wb_pkg.v".all;


  constant bytes_per_dw : integer := (DW/8);
  constant mem_words : integer := (MEM_SIZE_BYTES/bytes_per_dw);

  constant ADR_LSB : integer := (null)(bytes_per_dw);

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Counters for read and write accesses
  constant reads : integer := 0;
  constant writes : integer := 0;


  -- synthesis attribute ram_style of mem is block
  signal mem : array (0 downto mem_words-1) of std_logic_vector(DW-1 downto 0);  -- verilator public */  -- synthesis ram_style = no_rw_check */

  signal address : std_logic_vector(AW-1 downto 0);
  signal data : std_logic_vector(DW-1 downto 0);

  constant i : integer;
  constant delay : integer;
  constant seed : integer;
begin


  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  bfm0 : mpsoc_msi_wb_bfm_slave
  generic map (
    AW, 
    DW, 
    DEBUG
  )
  port map (
    wb_clk => wb_clk_i,
    wb_rst => wb_rst_i,
    wb_adr_i => wb_adr_i,
    wb_dat_i => wb_dat_i,
    wb_sel_i => wb_sel_i,
    wb_we_i => wb_we_i,
    wb_cyc_i => wb_cyc_i,
    wb_stb_i => wb_stb_i,
    wb_cti_i => wb_cti_i,
    wb_bte_i => wb_bte_i,
    wb_dat_o => wb_dat_o,
    wb_ack_o => wb_ack_o,
    wb_err_o => wb_err_o,
    wb_rty_o => wb_rty_o
  );


  processing_0 : process
  begin
    (null)();
    address <= bfm0.address;    --Fetch start address

    if (bfm0.op = WRITE) then
      writes <= writes+1;
    else
      reads <= reads+1;
    end if;
    while (bfm0.has_next) loop
      --Set error on out of range accesses
      if (address(31 downto ADR_LSB) > mem_words) then
        (null)("%0d : Error : Attempt to access %x, which is outside of memory", timing(), address);
        (null)();
      elsif (bfm0.op = WRITE) then
        (null)(data);
        if (DEBUG) then
          (null)("%d : ram Write 0x%h = 0x%h %b", timing(), address, data, bfm0.mask);
        end if;
        for i in 0 to DW/8 - 1 loop
          if (bfm0.mask(i)) then
            mem(address(31 downto ADR_LSB))(i*8+8) <= data(i*8+8);
          end if;
        end loop;
      else
        data <= concatenate(AW, '0');
        for i in 0 to DW/8 - 1 loop
          if (bfm0.mask(i)) then
            data(i*8+8) <= mem(address(31 downto ADR_LSB))(i*8+8);
          end if;
        end loop;
        if (DEBUG) then
          (null)("%d : ram Read  0x%h = 0x%h %b", timing(), address, data, bfm0.mask);
        end if;
        delay <= (null)(seed, RD_MIN_DELAY, RD_MAX_DELAY);
        for repeat in 1 to delay loop
          wait until rising_edge(wb_clk_i);
        end loop;
        (null)(data);
      end if;
      if (bfm0.cycle_type = BURST_CYCLE) then
        address <= (null)(address, wb_cti_i, wb_bte_i, DW);
      end if;
    end loop;
  end process;
end RTL;
