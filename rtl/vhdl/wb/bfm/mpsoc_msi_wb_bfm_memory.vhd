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
use ieee.math_real.all;

entity mpsoc_msi_wb_bfm_memory is
  generic (
    --Wishbone parameters
    DW    : integer := 32;
    AW    : integer := 32;
    DEBUG : integer := 0;

    -- Memory parameters
    RD_MIN_DELAY : integer := 0;
    RD_MAX_DELAY : integer := 4;

    MEM_SIZE_BYTES : std_logic_vector(31 downto 0) := X"00008000";  -- 32KBytes

    MEMORY_FILE : string := ""
    );
  port (
    wb_clk_i : in std_logic;
    wb_rst_i : in std_logic;

    wb_adr_i : in std_logic_vector(AW-1 downto 0);
    wb_dat_i : in std_logic_vector(DW-1 downto 0);
    wb_sel_i : in std_logic_vector(DW/8-1 downto 0);
    wb_we_i  : in std_logic;
    wb_bte_i : in std_logic_vector(1 downto 0);
    wb_cti_i : in std_logic_vector(2 downto 0);
    wb_cyc_i : in std_logic;
    wb_stb_i : in std_logic;

    wb_ack_o : out std_logic;
    wb_err_o : out std_logic;
    wb_rty_o : out std_logic;
    wb_dat_o : out std_logic_vector(DW-1 downto 0)
    );
end mpsoc_msi_wb_bfm_memory;

architecture RTL of mpsoc_msi_wb_bfm_memory is
  component mpsoc_msi_wb_bfm_slave
    generic (
      DW : integer := 32;
      AW : integer := 32;

      DEBUG : std_logic := '0'
      );
    port (
      wb_clk   : in  std_logic;
      wb_rst   : in  std_logic;
      wb_adr_i : in  std_logic_vector(AW-1 downto 0);
      wb_dat_i : in  std_logic_vector(DW-1 downto 0);
      wb_sel_i : in  std_logic_vector(DW/8-1 downto 0);
      wb_we_i  : in  std_logic;
      wb_cyc_i : in  std_logic;
      wb_stb_i : in  std_logic;
      wb_cti_i : in  std_logic_vector(2 downto 0);
      wb_bte_i : in  std_logic_vector(1 downto 0);
      wb_dat_o : out std_logic_vector(DW-1 downto 0);
      wb_ack_o : out std_logic;
      wb_err_o : out std_logic;
      wb_rty_o : out std_logic
      );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant BYTES_PER_DW : integer := (DW/8);
  constant MEM_WORDS    : integer := (MEM_SIZE_BYTES/BYTES_PER_DW);

  constant ADR_LSB : integer := integer(log2(real(BYTES_PER_DW)));

  --////////////////////////////////////////////////////////////////
  --
  -- Types
  --
  type M_MEM_WORDS_DW is array (MEM_WORDS-1 downto 0) of std_logic_vector(DW-1 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Counters for read and write accesses
  constant reads  : integer := 0;
  constant writes : integer := 0;

  -- synthesis attribute ram_style of mem is block
  signal mem : M_MEM_WORDS_DW;

  signal address : std_logic_vector(AW-1 downto 0);
  signal data    : std_logic_vector(DW-1 downto 0);

  constant i     : integer;
  constant delay : integer;
  constant seed  : integer;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --
  bfm0 : mpsoc_msi_wb_bfm_slave
    generic map (
      AW => AW,
      DW => AW,

      DEBUG => DEBUG
      )
    port map (
      wb_clk   => wb_clk_i,
      wb_rst   => wb_rst_i,
      wb_adr_i => wb_adr_i,
      wb_dat_i => wb_dat_i,
      wb_sel_i => wb_sel_i,
      wb_we_i  => wb_we_i,
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
    address <= bfm0.address;  --Fetch start address

    if (bfm0.op = WRITE) then
      writes <= writes+1;
    else
      reads <= reads+1;
    end if;
    while (bfm0.has_next) loop
      --Set error on out of range accesses
      if (address(31 downto ADR_LSB) > MEM_WORDS) then
        (null)("%0d : Error : Attempt to access %x, which is outside of memory", timing(), address);
        (null)();
      elsif (bfm0.op = WRITE) then
        (null)(data);
        if (DEBUG = '1') then
          (null)("%d : ram Write 0x%h = 0x%h %b", timing(), address, data, bfm0.mask);
        end if;
        for i in 0 to DW/8 - 1 loop
          if (bfm0.mask(i)) then
            mem(address(31 downto ADR_LSB))((i+1)*8-1 downto i*8) <= data((i+1)*8-1 downto i*8);
          end if;
        end loop;
      else
        data <= (others => '0');
        for i in 0 to DW/8 - 1 loop
          if (bfm0.mask(i)) then
            data((i+1)*8-1 downto i*8) <= mem(address(31 downto ADR_LSB))((i+1)*8-1 downto i*8);
          end if;
        end loop;
        if (DEBUG = '1') then
          (null)("%d : ram Read  0x%h = 0x%h %b", timing(), address, data, bfm0.mask);
        end if;
        delay <= (null)(seed, RD_MIN_DELAY, RD_MAX_DELAY);
        for repeat in 1 to delay loop
          wait until rising_edge(wb_clk_i);
        end loop;
        (null)(data);
      end if;
      if (bfm0.cycle_type = BURST_CYCLE) then
        address <= wb_next_adr(address, wb_cti_i, wb_bte_i, DW);
      end if;
    end loop;
  end process;
end RTL;
