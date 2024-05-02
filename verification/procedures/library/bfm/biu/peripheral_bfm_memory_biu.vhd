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
use ieee.math_real.all;

entity peripheral_msi_bfm_memory_biu is
  generic (
    -- Wishbone parameters
    DW : integer := 32;
    AW : integer := 32;

    DEBUG : std_logic := '0';

    -- Memory parameters
    RD_MIN_DELAY : integer := 0;
    RD_MAX_DELAY : integer := 4;

    MEM_SIZE_BYTES : std_logic_vector(31 downto 0) := X"00008000";  -- 32KBytes

    MEMORY_FILE : string := ""
    );
  port (
    biu_clk_i : in std_logic;
    biu_rst_i : in std_logic;

    biu_adr_i : in std_logic_vector(AW-1 downto 0);
    biu_dat_i : in std_logic_vector(DW-1 downto 0);
    biu_sel_i : in std_logic_vector(DW/8-1 downto 0);
    biu_we_i  : in std_logic;
    biu_bte_i : in std_logic_vector(1 downto 0);
    biu_cti_i : in std_logic_vector(2 downto 0);
    biu_cyc_i : in std_logic;
    biu_stb_i : in std_logic;

    biu_ack_o : out std_logic;
    biu_err_o : out std_logic;
    biu_rty_o : out std_logic;
    biu_dat_o : out std_logic_vector(DW-1 downto 0)
    );
end peripheral_msi_bfm_memory_biu;

architecture rtl of peripheral_msi_bfm_memory_biu is
  ------------------------------------------------------------------------------
  --  Constants
  ------------------------------------------------------------------------------
  constant BYTES_PER_DW : integer := DW/8;
  constant MEM_WORDS    : integer := to_integer(unsigned(MEM_SIZE_BYTES))/BYTES_PER_DW;

  constant ADR_LSB : integer := integer(log2(real(BYTES_PER_DW)));

  constant TP : time := 1 ns;

  constant CLASSIC_CYCLE : std_logic := '0';
  constant BURST_CYCLE   : std_logic := '1';

  constant READ  : std_logic := '0';
  constant WRITE : std_logic := '1';

  constant CTI_CLASSIC      : std_logic_vector(2 downto 0) := "000";
  constant CTI_CONST_BURST  : std_logic_vector(2 downto 0) := "001";
  constant CTI_INC_BURST    : std_logic_vector(2 downto 0) := "010";
  constant CTI_END_OF_BURST : std_logic_vector(2 downto 0) := "111";

  constant BTE_LINEAR  : std_logic_vector(1 downto 0) := "00";
  constant BTE_WRAP_4  : std_logic_vector(1 downto 0) := "01";
  constant BTE_WRAP_8  : std_logic_vector(1 downto 0) := "10";
  constant BTE_WRAP_16 : std_logic_vector(1 downto 0) := "11";

  ------------------------------------------------------------------------------
  -- Variables
  ------------------------------------------------------------------------------

  -- Counters for read and write accesses
  signal reads  : integer;
  signal writes : integer;

  -- synthesis attribute ram_style of mem is block
  signal mem : std_logic_matrix(MEM_WORDS-1 downto 0)(DW-1 downto 0);

  signal address : std_logic_vector(AW-1 downto 0);
  signal data    : std_logic_vector(DW-1 downto 0);

  signal delay : integer;
  signal seed  : integer;

  signal has_next   : std_logic;
  signal cycle_type : std_logic;
  signal op         : std_logic;
  signal mask       : std_logic_vector(DW/8-1 downto 0);

  signal err : std_logic;

  ------------------------------------------------------------------------------
  -- Procedures
  --
  procedure init_p (
    signal biu_clk_i : in std_logic;
    signal biu_rst_i : in std_logic;

    signal biu_cyc_i : in std_logic;
    signal biu_we_i  : in std_logic;
    signal biu_cti_i : in std_logic_vector(2 downto 0);
    signal biu_adr_i : in std_logic_vector(AW-1 downto 0);
    signal biu_dat_i : in std_logic_vector(DW-1 downto 0);
    signal biu_sel_i : in std_logic_vector(DW/8-1 downto 0);

    signal biu_ack_o : out std_logic;
    signal biu_err_o : out std_logic;
    signal biu_rty_o : out std_logic;
    signal biu_dat_o : out std_logic_vector(DW-1 downto 0)
    ) is
    variable has_next   : std_logic;
    variable cycle_type : std_logic;
    variable op         : std_logic;
    variable address    : std_logic_vector(AW-1 downto 0);
    variable mask       : std_logic_vector(DW/8-1 downto 0);
  begin
    biu_ack_o <= '0' after TP;
    biu_err_o <= '0' after TP;
    biu_rty_o <= '0' after TP;

    biu_dat_o <= (others => '0') after TP;

    if (biu_rst_i /= '0') then
      if (DEBUG = '1') then
        report "Waiting for reset release";
      end if;
      wait until falling_edge(biu_rst_i);
      wait until rising_edge(biu_clk_i);
      if (DEBUG = '1') then
        report "Reset was released";
      end if;
    end if;

    -- Catch start of next cycle
    if (biu_cyc_i = '1') then
      wait until rising_edge(biu_cyc_i);
    end if;
    wait until rising_edge(biu_clk_i);

    -- Make sure that biu_cyc_i is still asserted at next clock edge to avoid glitches
    while (biu_cyc_i /= '1') loop
      wait until rising_edge(biu_clk_i);
    end loop;
    if (DEBUG = '1') then
      report "Got biu_cyc_i";
    end if;

    cycle_type := get_cycle_type(biu_cti_i);

    op      := biu_we_i;
    address := biu_adr_i;
    mask    := biu_sel_i;

    has_next := '1';
  end init_p;

  procedure next_p (
    signal biu_clk_i : in std_logic;

    signal biu_cti_i : in std_logic_vector(2 downto 0);
    signal biu_dat_i : in std_logic_vector(DW-1 downto 0);

    signal biu_ack_o : out std_logic;
    signal biu_err_o : out std_logic;
    signal biu_rty_o : out std_logic;
    signal biu_dat_o : out std_logic_vector(DW-1 downto 0);

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
    biu_dat_o <= (others => '0') after TP;

    biu_ack_o <= '0' after TP;
    biu_err_o <= '0' after TP;
    biu_rty_o <= '0' after TP;           -- TO-DO: rty not supported

    if (err = '1') then
      if (DEBUG = '1') then
        report "Error";
      end if;
      biu_err_o <= '1' after TP;
      has_next := '0';
    elsif (op = READ) then
      biu_dat_o <= data after TP;
    else
      biu_ack_o <= '1' after TP;
    end if;

    wait until rising_edge(biu_clk_i);

    biu_ack_o <= '0' after TP;
    biu_err_o <= '0' after TP;

    has_next := not biu_is_last(biu_cti_i) and not err;

    if (op = WRITE) then
      data := biu_dat_i;
      mask := biu_sel_i;
    end if;

    address := biu_adr_i;
  end next_p;

  procedure error_response (
    signal biu_clk_i : in std_logic;

    signal biu_cti_i : in std_logic_vector(2 downto 0);
    signal biu_dat_i : in std_logic_vector(DW-1 downto 0);

    signal biu_ack_o : out std_logic;
    signal biu_err_o : out std_logic;
    signal biu_rty_o : out std_logic;
    signal biu_dat_o : out std_logic_vector(DW-1 downto 0);

    signal err : inout std_logic;
    signal op  : in    std_logic
    ) is
  begin
    err <= '1';

    next_p (
      biu_clk_i => biu_clk_i,

      biu_cti_i => biu_cti_i,
      biu_dat_i => biu_dat_i,

      biu_ack_o => biu_ack_o,
      biu_err_o => biu_err_o,
      biu_rty_o => biu_rty_o,
      biu_dat_o => biu_dat_o,

      err => err,
      op  => op
      );

    err <= '0';
  end error_response;

  procedure read_ack (
    signal biu_clk_i : in std_logic;

    signal biu_cti_i : in std_logic_vector(2 downto 0);
    signal biu_dat_i : in std_logic_vector(DW-1 downto 0);

    signal biu_ack_o : out std_logic;
    signal biu_err_o : out std_logic;
    signal biu_rty_o : out std_logic;
    signal biu_dat_o : out std_logic_vector(DW-1 downto 0);

    signal err : in std_logic;
    signal op  : in std_logic;

    signal data : out std_logic_vector(DW-1 downto 0);

    signal data_i : in std_logic_vector(DW-1 downto 0)
    ) is
  begin
    data <= data_i;

    next_p (
      biu_clk_i => biu_clk_i,

      biu_cti_i => biu_cti_i,
      biu_dat_i => biu_dat_i,

      biu_ack_o => biu_ack_o,
      biu_err_o => biu_err_o,
      biu_rty_o => biu_rty_o,
      biu_dat_o => biu_dat_o,

      err => err,
      op  => op
      );
  end read_ack;

  procedure write_ack (
    signal biu_clk_i : in std_logic;

    signal biu_cti_i : in std_logic_vector(2 downto 0);
    signal biu_dat_i : in std_logic_vector(DW-1 downto 0);

    signal biu_ack_o : out std_logic;
    signal biu_err_o : out std_logic;
    signal biu_rty_o : out std_logic;
    signal biu_dat_o : out std_logic_vector(DW-1 downto 0);

    signal err : in std_logic;
    signal op  : in std_logic;

    signal data_o : out std_logic_vector(DW-1 downto 0)
    ) is
  begin
    if (DEBUG = '1') then
      report "Write ack";
    end if;

    next_p (
      biu_clk_i => biu_clk_i,

      biu_cti_i => biu_cti_i,
      biu_dat_i => biu_dat_i,

      biu_ack_o => biu_ack_o,
      biu_err_o => biu_err_o,
      biu_rty_o => biu_rty_o,
      biu_dat_o => biu_dat_o,

      err => err,
      op  => op
      );

    data_o <= data;
  end write_ack;

begin
  ------------------------------------------------------------------------------
  -- Module Body
  ------------------------------------------------------------------------------
  processing_0 : process
  begin
    init_p (
      biu_clk_i => biu_clk_i,
      biu_rst_i => biu_rst_i,

      biu_cyc_i => biu_cyc_i,
      biu_we_i  => biu_we_i,
      biu_cti_i => biu_cti_i,
      biu_adr_i => biu_adr_i,
      biu_dat_i => biu_dat_i,
      biu_sel_i => biu_sel_i,

      biu_ack_o => biu_ack_o,
      biu_err_o => biu_err_o,
      biu_rty_o => biu_rty_o,
      biu_dat_o => biu_dat_o
      );

    if (op = WRITE) then
      writes <= writes+1;
    else
      reads <= reads+1;
    end if;
    while (has_next = '1') loop
      -- Set error on out of range accesses
      if (unsigned(address(31 downto ADR_LSB)) > to_unsigned(MEM_WORDS, 31-ADR_LSB+1)) then
        report "Error : Attempt to access " & integer'image(to_integer(unsigned(address))) & ", which is outside of memory";

        error_response (
          biu_clk_i => biu_clk_i,

          biu_cti_i => biu_cti_i,
          biu_dat_i => biu_dat_i,

          biu_ack_o => biu_ack_o,
          biu_err_o => biu_err_o,
          biu_rty_o => biu_rty_o,
          biu_dat_o => biu_dat_o,

          err => err,
          op  => op
          );
      elsif (op = WRITE) then
        write_ack (
          biu_clk_i => biu_clk_i,

          biu_cti_i => biu_cti_i,
          biu_dat_i => biu_dat_i,

          biu_ack_o => biu_ack_o,
          biu_err_o => biu_err_o,
          biu_rty_o => biu_rty_o,
          biu_dat_o => biu_dat_o,

          err => err,
          op  => op,

          data_o => data
          );
        if (DEBUG = '1') then
          report "RAM Write " & integer'image(to_integer(unsigned(address))) & " = " & integer'image(to_integer(unsigned(data))) & integer'image(to_integer(unsigned(mask)));
        end if;
        for i in 0 to DW/8 - 1 loop
          if (mask(i) = '1') then
            mem(to_integer(unsigned(address(31 downto ADR_LSB))))((i+1)*8-1 downto i*8) <= data((i+1)*8-1 downto i*8);
          end if;
        end loop;
      else
        data <= (others => '0');
        for i in 0 to DW/8 - 1 loop
          if (mask(i) = '1') then
            data((i+1)*8-1 downto i*8) <= mem(to_integer(unsigned(address(31 downto ADR_LSB))))((i+1)*8-1 downto i*8);
          end if;
        end loop;

        if (DEBUG = '1') then
          report "RAM Read " & integer'image(to_integer(unsigned(address))) & " = " & integer'image(to_integer(unsigned(data))) & integer'image(to_integer(unsigned(mask)));
        end if;

        ---- delay <= rand_uniform(seed, RD_MIN_DELAY, RD_MAX_DELAY);

        for repeat in 1 to delay loop
          wait until rising_edge(biu_clk_i);
        end loop;

        read_ack (
          biu_clk_i => biu_clk_i,

          biu_cti_i => biu_cti_i,
          biu_dat_i => biu_dat_i,

          biu_ack_o => biu_ack_o,
          biu_err_o => biu_err_o,
          biu_rty_o => biu_rty_o,
          biu_dat_o => biu_dat_o,

          err => err,
          op  => op,

          data   => data,
          data_i => data
          );
      end if;
      if (cycle_type = BURST_CYCLE) then
        address <= biu_next_adr(address, biu_cti_i, biu_bte_i, DW);
      end if;
    end loop;
  end process;
end rtl;
