-- Converted from core/mpsoc_msi_wb_bfm_slave.v
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

entity mpsoc_msi_wb_bfm_slave is
  port (
    wb_clk : in std_logic;
    wb_rst : in std_logic;
    wb_adr_i : in std_logic_vector(AW-1 downto 0);
    wb_dat_i : in std_logic_vector(DW-1 downto 0);
    wb_sel_i : in std_logic_vector(DW/8-1 downto 0);
    wb_we_i : in std_logic;
    wb_cyc_i : in std_logic;
    wb_stb_i : in std_logic;
    wb_cti_i : in std_logic_vector(2 downto 0);
    wb_bte_i : in std_logic_vector(1 downto 0);
    wb_dat_o : out std_logic_vector(DW-1 downto 0);
    wb_ack_o : out std_logic;
    wb_err_o : out std_logic 
    wb_rty_o : out std_logic
  );
  constant DW : integer := 32;
  constant AW : integer := 32;
  constant DEBUG : integer := 0;
end mpsoc_msi_wb_bfm_slave;

architecture RTL of mpsoc_msi_wb_bfm_slave is


  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  use work."mpsoc_msi_wb_pkg.v".all;


  constant TP : integer := 1;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal has_next : std_logic;

  signal op : std_logic;
  signal address : std_logic_vector(AW-1 downto 0);
  signal data : std_logic_vector(DW-1 downto 0);
  signal mask : std_logic_vector(DW/8-1 downto 0);
  signal cycle_type : std_logic;
  signal burst_type : std_logic_vector(2 downto 0);

  signal err : std_logic;

  --////////////////////////////////////////////////////////////////
  --
  -- Tasks
  --
  procedure init (
  ) is
  begin
    wb_ack_o <= '0' after TP ns;
    wb_dat_o <= concatenate(DW, '0') after TP ns;
    wb_err_o <= '0' after TP ns;
    wb_rty_o <= '0' after TP ns;

    if (wb_rst /= '0') then
      if (DEBUG) then
        (null)("%0d : waiting for reset release", timing());
      end if;
      wait until falling_edge(wb_rst);
      wait until rising_edge(wb_clk);
      if (DEBUG) then
        (null)("%0d : Reset was released", timing());
      end if;
    end if;


    --Catch start of next cycle
    if (not wb_cyc_i) then
      wait until rising_edge(wb_cyc_i);
    end if;
    wait until rising_edge(wb_clk);

    --Make sure that wb_cyc_i is still asserted at next clock edge to avoid glitches
    while (wb_cyc_i /= '1') loop
      wait until rising_edge(wb_clk);
    end loop;
    if (DEBUG) then

      (null)("%0d : Got wb_cyc_i", timing());
    end if;
    cycle_type <= (null)(wb_cti_i);

    op <= wb_we_i;
    address <= wb_adr_i;
    mask <= wb_sel_i;

    has_next <= '1';
  end init;



  procedure error_response (
  ) is
  begin
    err <= '1';
    (null)();
    err <= '0';
  end error_response;



  procedure read_ack (
    data_i : in std_logic_vector(DW-1 downto 0)
  ) is
  begin


    data <= data_i;
    (null)();
  end read_ack;



  procedure write_ack (
    data_o : out std_logic_vector(DW-1 downto 0)
  ) is
  begin
    if (DEBUG) then
      (null)("%0d : Write ack", timing());
    end if;
    (null)();
    data_o <= data;
  end write_ack;



  procedure next (
  ) is
  begin
    if (DEBUG) then

      (null)("%0d : next address=0x%h, data=0x%h, op=%b", timing(), address, data, op);
    end if;
    wb_dat_o <= concatenate(DW, '0') after TP ns;
    wb_ack_o <= '0' after TP ns;
    wb_err_o <= '0' after TP ns;
    wb_rty_o <= '0' after TP ns;    --TODO : rty not supported

    if (err) then
      if (DEBUG) then
        (null)("%0d, Error", timing());
      end if;
      wb_err_o <= '1' after TP ns;
      has_next <= '0';
    elsif (op = READ) then
      wb_dat_o <= data after TP ns;
    wb_ack_o <= '1' after TP ns;
    end if;


    wait until rising_edge(wb_clk);

    wb_ack_o <= '0' after TP ns;
    wb_err_o <= '0' after TP ns;

    has_next <= not ((null)(wb_cti_i) = '1') and not err;

    if (op = WRITE) then
      data <= wb_dat_i;
      mask <= wb_sel_i;
    end if;


    address <= wb_adr_i;
  end next;

begin
  has_next <= '0';
  op <= READ;
  err <= 0;
end RTL;
