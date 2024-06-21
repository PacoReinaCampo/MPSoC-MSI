--------------------------------------------------------------------------------
--                                            __ _      _     _               --
--                                           / _(_)    | |   | |              --
--                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              --
--               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              --
--              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              --
--               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              --
--                  | |                                                       --
--                  |_|                                                       --
--                                                                            --
--                                                                            --
--              MPSoC-RISCV CPU                                               --
--              Master Slave Interface                                        --
--              Wishbone Bus Interface                                        --
--                                                                            --
--------------------------------------------------------------------------------

-- Copyright (c) 2018-2019 by the author(s)
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
--------------------------------------------------------------------------------
-- Author(s):
--   Olof Kindgren <olof.kindgren@gmail.com>
--   Paco Reina Campo <pacoreinacampo@queenfield.tech>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity peripheral_msi_bfm_slave_apb4 is
  generic (
    DW : integer := 32;
    AW : integer := 32;

    DEBUG : std_logic := '0'
    );
  port (
    apb4_clk   : in  std_logic;
    apb4_rst   : in  std_logic;
    apb4_adr_i : in  std_logic_vector(AW-1 downto 0);
    apb4_dat_i : in  std_logic_vector(DW-1 downto 0);
    apb4_sel_i : in  std_logic_vector(DW/8-1 downto 0);
    apb4_we_i  : in  std_logic;
    apb4_cyc_i : in  std_logic;
    apb4_stb_i : in  std_logic;
    apb4_cti_i : in  std_logic_vector(2 downto 0);
    apb4_bte_i : in  std_logic_vector(1 downto 0);
    apb4_dat_o : out std_logic_vector(DW-1 downto 0);
    apb4_ack_o : out std_logic;
    apb4_err_o : out std_logic;
    apb4_rty_o : out std_logic
    );
end peripheral_msi_bfm_slave_apb4;

architecture rtl of peripheral_msi_bfm_slave_apb4 is
  ------------------------------------------------------------------------------
  --  Constants
  ------------------------------------------------------------------------------
  constant TP : time := 1 ns;

  constant CLASSIC_CYCLE : std_logic := '0';
  constant BURST_CYCLE   : std_logic := '1';

  constant READ  : std_logic := '0';
  constant WRITE : std_logic := '1';

  constant CTI_CLASSIC      : std_logic_vector(2 downto 0) := "000";
  constant CTI_CONST_BURST  : std_logic_vector(2 downto 0) := "001";
  constant CTI_INC_BURST    : std_logic_vector(2 downto 0) := "010";
  constant CTI_END_OF_BURST : std_logic_vector(2 downto 0) := "111";

  ------------------------------------------------------------------------------
  -- Variables
  ------------------------------------------------------------------------------
  signal has_next : std_logic;

  signal op         : std_logic;
  signal address    : std_logic_vector(AW-1 downto 0);
  signal data       : std_logic_vector(DW-1 downto 0);
  signal mask       : std_logic_vector(DW/8-1 downto 0);
  signal cycle_type : std_logic;
  signal burst_type : std_logic_vector(2 downto 0);

  signal err : std_logic;

  ------------------------------------------------------------------------------
  -- Tasks
  --
  procedure init_p (
    signal apb4_clk_i : in std_logic;
    signal apb4_rst_i : in std_logic;

    signal apb4_cyc_i : in std_logic;
    signal apb4_we_i  : in std_logic;
    signal apb4_cti_i : in std_logic_vector(2 downto 0);
    signal apb4_adr_i : in std_logic_vector(AW-1 downto 0);
    signal apb4_dat_i : in std_logic_vector(DW-1 downto 0);
    signal apb4_sel_i : in std_logic_vector(DW/8-1 downto 0);

    signal apb4_ack_o : out std_logic;
    signal apb4_err_o : out std_logic;
    signal apb4_rty_o : out std_logic;
    signal apb4_dat_o : out std_logic_vector(DW-1 downto 0)
    ) is
    variable has_next   : std_logic;
    variable cycle_type : std_logic;
    variable op         : std_logic;
    variable address    : std_logic_vector(AW-1 downto 0);
    variable mask       : std_logic_vector(DW/8-1 downto 0);
  begin
    apb4_ack_o <= '0' after TP;
    apb4_err_o <= '0' after TP;
    apb4_rty_o <= '0' after TP;

    apb4_dat_o <= (others => '0') after TP;

    if (apb4_rst_i /= '0') then
      if (DEBUG = '1') then
        report "Waiting for reset release";
      end if;
      wait until falling_edge(apb4_rst_i);
      wait until rising_edge(apb4_clk_i);
      if (DEBUG = '1') then
        report "Reset was released";
      end if;
    end if;

    -- Catch start of next cycle
    if (apb4_cyc_i = '1') then
      wait until rising_edge(apb4_cyc_i);
    end if;
    wait until rising_edge(apb4_clk_i);

    -- Make sure that apb4_cyc_i is still asserted at next clock edge to avoid glitches
    while (apb4_cyc_i /= '1') loop
      wait until rising_edge(apb4_clk_i);
    end loop;
    if (DEBUG = '1') then
      report "Got apb4_cyc_i";
    end if;

    cycle_type := get_cycle_type(apb4_cti_i);

    op      := apb4_we_i;
    address := apb4_adr_i;
    mask    := apb4_sel_i;

    has_next := '1';
  end init_p;

  procedure next_p (
    signal apb4_clk_i : in std_logic;

    signal apb4_cti_i : in std_logic_vector(2 downto 0);
    signal apb4_dat_i : in std_logic_vector(DW-1 downto 0);

    signal apb4_ack_o : out std_logic;
    signal apb4_err_o : out std_logic;
    signal apb4_rty_o : out std_logic;
    signal apb4_dat_o : out std_logic_vector(DW-1 downto 0);

    signal err : in std_logic;
    signal op  : in std_logic
    ) is

    variable has_next : std_logic;
    variable address  : std_logic_vector(AW-1 downto 0);
    variable data     : std_logic_vector(DW-1 downto 0);
    variable mask     : std_logic_vector(DW/8-1 downto 0);
  begin
    if (DEBUG = '1') then
      report "next address = " & integer'image(to_integer(unsigned(address))) &
        "data = " & integer'image(to_integer(unsigned(data))) &
        "op = " & std_logic'image(op);
    end if;
    apb4_dat_o <= (others => '0') after TP;

    apb4_ack_o <= '0' after TP;
    apb4_err_o <= '0' after TP;
    apb4_rty_o <= '0' after TP;           -- TO-DO: rty not supported

    if (err = '1') then
      if (DEBUG = '1') then
        report "Error";
      end if;
      apb4_err_o <= '1' after TP;
      has_next := '0';
    elsif (op = READ) then
      apb4_dat_o <= data after TP;
    else
      apb4_ack_o <= '1' after TP;
    end if;

    wait until rising_edge(apb4_clk_i);

    apb4_ack_o <= '0' after TP;
    apb4_err_o <= '0' after TP;

    has_next := not apb4_is_last(apb4_cti_i) and not err;

    if (op = WRITE) then
      data := apb4_dat_i;
      mask := apb4_sel_i;
    end if;

    address := apb4_adr_i;
  end next_p;

  procedure error_response (
    signal apb4_clk_i : in std_logic;

    signal apb4_cti_i : in std_logic_vector(2 downto 0);
    signal apb4_dat_i : in std_logic_vector(DW-1 downto 0);

    signal apb4_ack_o : out std_logic;
    signal apb4_err_o : out std_logic;
    signal apb4_rty_o : out std_logic;
    signal apb4_dat_o : out std_logic_vector(DW-1 downto 0);

    signal err : inout std_logic;
    signal op  : in    std_logic
    ) is
  begin
    err <= '1';

    next_p (
      apb4_clk_i => apb4_clk_i,

      apb4_cti_i => apb4_cti_i,
      apb4_dat_i => apb4_dat_i,

      apb4_ack_o => apb4_ack_o,
      apb4_err_o => apb4_err_o,
      apb4_rty_o => apb4_rty_o,
      apb4_dat_o => apb4_dat_o,

      err => err,
      op  => op
      );

    err <= '0';
  end error_response;

  procedure read_ack (
    signal apb4_clk_i : in std_logic;

    signal apb4_cti_i : in std_logic_vector(2 downto 0);
    signal apb4_dat_i : in std_logic_vector(DW-1 downto 0);

    signal apb4_ack_o : out std_logic;
    signal apb4_err_o : out std_logic;
    signal apb4_rty_o : out std_logic;
    signal apb4_dat_o : out std_logic_vector(DW-1 downto 0);

    signal err : in std_logic;
    signal op  : in std_logic;

    signal data : out std_logic_vector(DW-1 downto 0);

    signal data_i : in std_logic_vector(DW-1 downto 0)
    ) is
  begin
    data <= data_i;

    next_p (
      apb4_clk_i => apb4_clk_i,

      apb4_cti_i => apb4_cti_i,
      apb4_dat_i => apb4_dat_i,

      apb4_ack_o => apb4_ack_o,
      apb4_err_o => apb4_err_o,
      apb4_rty_o => apb4_rty_o,
      apb4_dat_o => apb4_dat_o,

      err => err,
      op  => op
      );
  end read_ack;

  procedure write_ack (
    signal apb4_clk_i : in std_logic;

    signal apb4_cti_i : in std_logic_vector(2 downto 0);
    signal apb4_dat_i : in std_logic_vector(DW-1 downto 0);

    signal apb4_ack_o : out std_logic;
    signal apb4_err_o : out std_logic;
    signal apb4_rty_o : out std_logic;
    signal apb4_dat_o : out std_logic_vector(DW-1 downto 0);

    signal err : in std_logic;
    signal op  : in std_logic;

    signal data_o : out std_logic_vector(DW-1 downto 0)
    ) is
  begin
    if (DEBUG = '1') then
      report "Write ack";
    end if;

    next_p (
      apb4_clk_i => apb4_clk_i,

      apb4_cti_i => apb4_cti_i,
      apb4_dat_i => apb4_dat_i,

      apb4_ack_o => apb4_ack_o,
      apb4_err_o => apb4_err_o,
      apb4_rty_o => apb4_rty_o,
      apb4_dat_o => apb4_dat_o,

      err => err,
      op  => op
      );

    data_o <= data;
  end write_ack;

begin
end rtl;