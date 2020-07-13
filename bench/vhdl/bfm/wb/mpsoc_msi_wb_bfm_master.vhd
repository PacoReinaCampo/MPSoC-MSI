-- Converted from mpsoc_msi_wb_bfm_master.v
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
use std.textio.all;

use work.mpsoc_msi_wb_pkg.all;

entity mpsoc_msi_wb_bfm_master is
  generic (
    AW : integer := 32;
    DW : integer := 32;

    TP : time := 0 ns;

    MAX_BURST_LEN   : integer := 32;
    MAX_WAIT_STATES : integer := 8;

    VERBOSE : integer := 0
    );
  port (
    wb_clk_i : in  std_logic;
    wb_rst_i : in  std_logic;
    wb_adr_o : out std_logic_vector(AW-1 downto 0);
    wb_dat_o : out std_logic_vector(DW-1 downto 0);
    wb_sel_o : out std_logic_vector(DW/8-1 downto 0);
    wb_we_o  : out std_logic;
    wb_cyc_o : out std_logic;
    wb_stb_o : out std_logic;
    wb_cti_o : out std_logic_vector(2 downto 0);
    wb_bte_o : out std_logic_vector(1 downto 0);
    wb_dat_i : in  std_logic_vector(DW-1 downto 0);
    wb_ack_i : in  std_logic;
    wb_err_i : in  std_logic;
    wb_rty_i : in  std_logic
    );
end mpsoc_msi_wb_bfm_master;

architecture RTL of mpsoc_msi_wb_bfm_master is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant BUFFER_WIDTH : integer := integer(log2(real(MAX_BURST_LEN)));
  constant ADR_LSB      : integer := integer(log2(real(DW/8)));

  constant READ  : std_logic := '0';
  constant WRITE : std_logic := '1';

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal addr : std_logic_vector(AW-1 downto 0);
  signal data : std_logic_vector(DW-1 downto 0);
  signal mask : std_logic_vector(DW/8-1 downto 0);
  signal op   : std_logic;

  signal cycle_type      : std_logic_vector(2 downto 0);
  signal burst_type      : std_logic_vector(2 downto 0);
  signal burst_length    : std_logic_vector(31 downto 0);
  signal buffer_addr_tmp : std_logic_vector(AW-1 downto 0);
  signal buffer_addr     : std_logic_vector(BUFFER_WIDTH-1 downto 0);

  signal write_data  : std_logic_matrix(MAX_BURST_LEN-1 downto 0)(DW-1 downto 0);
  signal buffer_data : std_logic_matrix(MAX_BURST_LEN-1 downto 0)(DW-1 downto 0);

  signal wait_states     : std_logic_vector(integer(log2(real(MAX_WAIT_STATES))) downto 0);
  signal wait_states_cnt : std_logic_vector(integer(log2(real(MAX_WAIT_STATES))) downto 0);

  signal index : integer;
  signal word  : integer;

  --////////////////////////////////////////////////////////////////
  --
  -- Procedures
  --

  --Low level tasks
  procedure init_p (
    signal wb_sel_o : out std_logic_vector(DW/8-1 downto 0);
    signal wb_we_o  : out std_logic;
    signal wb_cyc_o : out std_logic;
    signal wb_cti_o : out std_logic_vector(2 downto 0);
    signal wb_bte_o : out std_logic_vector(1 downto 0)
    ) is
  begin
    if (wb_rst_i /= '0') then
      wait until falling_edge(wb_rst_i);
      wait until rising_edge(wb_clk_i);
    end if;

    wb_sel_o <= mask after TP;
    wb_we_o  <= op   after TP;
    wb_cyc_o <= '1'  after TP;

    if (cycle_type = CTI_CLASSIC) then
      if (VERBOSE > 1) then
        report "INIT: Classic Cycle";
      end if;
      wb_cti_o <= "000" after TP;
      wb_bte_o <= "00"  after TP;
    elsif (index = to_integer(unsigned(burst_length))-1) then
      if (VERBOSE > 1) then
        report "INIT: Burst - last cycle";
      end if;
      wb_cti_o <= "111" after TP;
      wb_bte_o <= "00"  after TP;
    elsif (cycle_type = CTI_CONST_BURST) then
      if (VERBOSE > 1) then
        report "INIT: Const Burst cycle";
      end if;
      wb_cti_o <= "001" after TP;
      wb_bte_o <= "00"  after TP;
    elsif (VERBOSE > 1) then
      report "INIT: Incr Burst cycle";
      wb_cti_o <= "010"      after TP;
      wb_bte_o <= burst_type after TP;
    end if;
  end init_p;

  procedure clear_write_data (
    signal write_data : out M_MAX_BURST_LEN_DW;

    signal word : in integer
    ) is
  begin
    for word in 0 to MAX_BURST_LEN-2 loop
      write_data(word) <= (others => 'X');
    end loop;
  end clear_write_data;

  procedure clear_buffer_data (
    signal buffer_data : out M_MAX_BURST_LEN_DW;

    signal word : in integer
    ) is
  begin
    for word in 0 to MAX_BURST_LEN-2 loop
      buffer_data(word) <= (others => 'X');
    end loop;
  end clear_buffer_data;

  procedure next_p (
    signal wb_adr_o : out std_logic_vector(AW-1 downto 0);
    signal wb_dat_o : out std_logic_vector(DW-1 downto 0);
    signal wb_stb_o : out std_logic;
    signal wb_cti_o : out std_logic_vector(2 downto 0)
    ) is
    variable data   : std_logic_vector(DW-1 downto 0);
    variable dat_op : std_logic_vector(DW-1 downto 0);
  begin
    if (op = WRITE) then
      dat_op := data;
    else
      dat_op := (others => '0');
    end if;

    wb_adr_o <= addr   after TP;
    wb_dat_o <= dat_op after TP;
    wb_stb_o <= '0'    after TP;  --FIXME: Add wait states

    if ((index = to_integer(unsigned(burst_length))-1) and (cycle_type /= CTI_CLASSIC)) then
      wb_cti_o <= "111" after TP;
    end if;

    wait until rising_edge(wb_clk_i);
    while (wb_ack_i /= '1') loop
      wait until rising_edge(wb_clk_i);
    end loop;
    data := wb_dat_i;
  end next_p;

  procedure insert_wait_states (
    signal wb_cyc_o : out std_logic;
    signal wb_stb_o : out std_logic;
    signal wb_we_o  : out std_logic;

    signal wb_cti_o : out std_logic_vector(2 downto 0);
    signal wb_bte_o : out std_logic_vector(1 downto 0);
    signal wb_sel_o : out std_logic_vector(DW/8-1 downto 0);
    signal wb_adr_o : out std_logic_vector(AW-1 downto 0);
    signal wb_dat_o : out std_logic_vector(DW-1 downto 0)
    ) is
  begin

    wb_cyc_o <= '0' after TP;
    wb_stb_o <= '0' after TP;
    wb_we_o  <= '0' after TP;

    wb_cti_o <= (others => '0') after TP;
    wb_bte_o <= (others => '0') after TP;
    wb_sel_o <= (others => '0') after TP;
    wb_adr_o <= (others => '0') after TP;
    wb_dat_o <= (others => '0') after TP;

    for wait_states_cnt in 0 to to_integer(unsigned(wait_states)) - 1 loop
      wait until rising_edge(wb_clk_i);
    end loop;
  end insert_wait_states;

  procedure data_compare (
    signal addr      : in std_logic_vector(AW-1 downto 0);
    signal read_data : in std_logic_vector(DW-1 downto 0);
    signal iteration : in integer;

    signal buffer_addr : in std_logic_vector(BUFFER_WIDTH-1 downto 0)
    ) is
  begin

    if (VERBOSE > 2) then
      report "Comparing Read Data for iteration" & integer'image(iteration) & " at address: " & integer'image(to_integer(unsigned(addr)));
    ----report "Read Data: " & integer'image(to_integer(unsigned(read_data))) & ", buffer data: " & integer'image(to_integer(unsigned(buffer_data(to_integer(unsigned(buffer_addr)))))) & ", buffer address: " & integer'image(to_integer(unsigned(to_integer(unsigned(buffer_addr)))));
    elsif (VERBOSE > 1) then
      report "Comparing Read Data for iteration" & integer'image(iteration) & " at address: " & integer'image(to_integer(unsigned(addr)));
    end if;

    if (buffer_data(to_integer(unsigned(buffer_addr))) /= read_data) then
      report "Read data mismatch during iteration" & integer'image(iteration) & " at address " & integer'image(to_integer(unsigned(addr)));
      report "Expected " & integer'image(to_integer(unsigned(buffer_data(to_integer(unsigned(buffer_addr))))));
      report "Got " & integer'image(to_integer(unsigned(read_data)));
    --exit after 3 ns;
    elsif (VERBOSE > 1) then
      report "Data Matched";
    end if;
  end data_compare;

  procedure reset (
    signal wb_adr_o : out std_logic_vector(AW-1 downto 0);
    signal wb_dat_o : out std_logic_vector(DW-1 downto 0);
    signal wb_sel_o : out std_logic_vector(DW/8-1 downto 0);
    signal wb_we_o  : out std_logic;
    signal wb_cyc_o : out std_logic;
    signal wb_stb_o : out std_logic;
    signal wb_cti_o : out std_logic_vector(2 downto 0);
    signal wb_bte_o : out std_logic_vector(1 downto 0)
    ) is
  begin
    wb_adr_o <= (others => '0');
    wb_dat_o <= (others => '0');
    wb_sel_o <= (others => '0');
    wb_we_o  <= '0';
    wb_cyc_o <= '0';
    wb_stb_o <= '0';
    wb_cti_o <= (others => '0');
    wb_bte_o <= (others => '0');
  end reset;

  procedure write_p (
    signal addr_i : in std_logic_vector(AW-1 downto 0);
    signal data_i : in std_logic_vector(DW-1 downto 0);
    signal mask_i : in std_logic_vector(DW/8-1 downto 0);

    signal err_o : out std_logic;

    signal addr : out std_logic_vector(AW-1 downto 0);
    signal data : out std_logic_vector(DW-1 downto 0);
    signal mask : out std_logic_vector(DW/8-1 downto 0);
    signal op   : out std_logic;

    signal cycle_type : out std_logic_vector(2 downto 0);

    signal wb_adr_o : out std_logic_vector(AW-1 downto 0);
    signal wb_dat_o : out std_logic_vector(DW-1 downto 0);

    signal wb_sel_o : out std_logic_vector(DW/8-1 downto 0);
    signal wb_we_o  : out std_logic;
    signal wb_cyc_o : out std_logic;
    signal wb_stb_o : out std_logic;
    signal wb_cti_o : out std_logic_vector(2 downto 0);
    signal wb_bte_o : out std_logic_vector(1 downto 0)
    ) is
  begin
    addr       <= addr_i;
    data       <= data_i;
    mask       <= mask_i;
    cycle_type <= CTI_CLASSIC;
    op         <= WRITE;

    init_p (
      wb_sel_o => wb_sel_o,
      wb_we_o  => wb_we_o,
      wb_cyc_o => wb_cyc_o,
      wb_cti_o => wb_cti_o,
      wb_bte_o => wb_bte_o
      );

    wait until rising_edge(wb_clk_i);

    next_p (
      wb_adr_o => wb_adr_o,
      wb_dat_o => wb_dat_o,
      wb_stb_o => wb_stb_o,
      wb_cti_o => wb_cti_o
      );

    err_o <= wb_err_i;

    insert_wait_states (
      wb_cyc_o => wb_cyc_o,
      wb_stb_o => wb_stb_o,
      wb_we_o  => wb_we_o,

      wb_cti_o => wb_cti_o,
      wb_bte_o => wb_bte_o,
      wb_sel_o => wb_sel_o,
      wb_adr_o => wb_adr_o,
      wb_dat_o => wb_dat_o
      );
  end write_p;

  procedure write_burst (
    signal base_addr      : in  std_logic_vector(AW-1 downto 0);
    signal addr_i         : in  std_logic_vector(AW-1 downto 0);
    signal mask_i         : in  std_logic_vector(DW/8-1 downto 0);
    signal cycle_type_i   : in  std_logic_vector(2 downto 0);
    signal burst_type_i   : in  std_logic_vector(1 downto 0);
    signal burst_length_i : in  std_logic_vector(31 downto 0);
    signal err_o          : out std_logic;

    signal data : out std_logic_vector(DW-1 downto 0);
    signal mask : out std_logic_vector(DW/8-1 downto 0);
    signal op   : out std_logic;

    signal buffer_data : out M_MAX_BURST_LEN_DW;

    signal wb_adr_o : out std_logic_vector(AW-1 downto 0);
    signal wb_dat_o : out std_logic_vector(DW-1 downto 0);
    signal wb_sel_o : out std_logic_vector(DW/8-1 downto 0);
    signal wb_we_o  : out std_logic;
    signal wb_cyc_o : out std_logic;
    signal wb_stb_o : out std_logic;
    signal wb_cti_o : out std_logic_vector(2 downto 0);
    signal wb_bte_o : out std_logic_vector(1 downto 0)
    ) is
    variable write_data : M_MAX_BURST_LEN_DW;

    variable cycle_type : std_logic_vector(2 downto 0);
    variable burst_type : std_logic_vector(1 downto 0);

    variable addr : std_logic_vector(AW-1 downto 0);

    variable buffer_addr_tmp : std_logic_vector(AW-1 downto 0);
    variable buffer_addr     : std_logic_vector(BUFFER_WIDTH-1 downto 0);
    variable burst_length    : std_logic_vector(31 downto 0);

    variable index : integer;
    variable word  : integer;
  begin
    addr            := addr_i;
    buffer_addr_tmp := std_logic_vector(unsigned(addr_i)-unsigned(base_addr));
    buffer_addr     := buffer_addr_tmp(ADR_LSB+BUFFER_WIDTH-1 downto ADR_LSB);
    mask            <= mask_i;
    op              <= WRITE;
    burst_length    := burst_length_i;
    cycle_type      := cycle_type_i;
    burst_type      := burst_type_i;
    index           := 0;
    err_o           <= '0';

    init_p (
      wb_sel_o => wb_sel_o,
      wb_we_o  => wb_we_o,
      wb_cyc_o => wb_cyc_o,
      wb_cti_o => wb_cti_o,
      wb_bte_o => wb_bte_o
      );

    while (index < to_integer(unsigned(burst_length))) loop
      buffer_data(to_integer(unsigned(buffer_addr))) <= write_data(index);

      data <= write_data(index);

      if (VERBOSE > 2) then
        report "Write Data " & integer'image(to_integer(unsigned(write_data(index)))) & " written to buffer at address " & integer'image(to_integer(unsigned(buffer_addr))) & " at iteration " & integer'image(index);
        report "Write Data " & integer'image(to_integer(unsigned(write_data(index)))) & " written to memory at address " & integer'image(to_integer(unsigned(addr))) & " at iteration " & integer'image(index);
      elsif (VERBOSE > 1) then
        report "Write Data " & integer'image(to_integer(unsigned(write_data(index)))) & " written to memory at address " & integer'image(to_integer(unsigned(addr))) & " at iteration " & integer'image(index);
      end if;

      next_p (
        wb_adr_o => wb_adr_o,
        wb_dat_o => wb_dat_o,
        wb_stb_o => wb_stb_o,
        wb_cti_o => wb_cti_o
        );

      addr            := wb_next_adr(addr, cycle_type, burst_type, DW);
      buffer_addr_tmp := std_logic_vector(unsigned(addr)-unsigned(base_addr));
      buffer_addr     := buffer_addr_tmp(ADR_LSB+BUFFER_WIDTH-1 downto ADR_LSB);
      index           := index+1;
    end loop;

    ----clear_write_data (
    ----write_data => write_data,
    ----word       => word
    ----);

    insert_wait_states (
      wb_cyc_o => wb_cyc_o,
      wb_stb_o => wb_stb_o,
      wb_we_o  => wb_we_o,

      wb_cti_o => wb_cti_o,
      wb_bte_o => wb_bte_o,
      wb_sel_o => wb_sel_o,
      wb_adr_o => wb_adr_o,
      wb_dat_o => wb_dat_o
      );
  end write_burst;

  procedure read_burst_comp (
    signal base_addr      : in  std_logic_vector(AW-1 downto 0);
    signal addr_i         : in  std_logic_vector(AW-1 downto 0);
    signal mask_i         : in  std_logic_vector(DW/8-1 downto 0);
    signal cycle_type_i   : in  std_logic_vector(2 downto 0);
    signal burst_type_i   : in  std_logic_vector(1 downto 0);
    signal burst_length_i : in  std_logic_vector(31 downto 0);
    signal err_o          : out std_logic;

    signal wb_adr_o : out std_logic_vector(AW-1 downto 0);
    signal wb_dat_o : out std_logic_vector(DW-1 downto 0);
    signal wb_sel_o : out std_logic_vector(DW/8-1 downto 0);
    signal wb_we_o  : out std_logic;
    signal wb_cyc_o : out std_logic;
    signal wb_stb_o : out std_logic;
    signal wb_cti_o : out std_logic_vector(2 downto 0);
    signal wb_bte_o : out std_logic_vector(1 downto 0)
    ) is
    variable addr            : std_logic_vector(AW-1 downto 0);
    variable data            : std_logic_vector(DW-1 downto 0);
    variable buffer_addr_tmp : std_logic_vector(AW-1 downto 0);
    variable buffer_addr     : std_logic_vector(BUFFER_WIDTH-1 downto 0);
    variable burst_length    : std_logic_vector(31 downto 0);
    variable mask            : std_logic_vector(DW/8-1 downto 0);
    variable op              : std_logic;

    variable cycle_type : std_logic_vector(2 downto 0);
    variable burst_type : std_logic_vector(1 downto 0);

    variable index : integer;
  begin
    addr            := addr_i;
    buffer_addr_tmp := std_logic_vector(unsigned(addr_i)-unsigned(base_addr));
    buffer_addr     := buffer_addr_tmp(ADR_LSB+BUFFER_WIDTH-1 downto ADR_LSB);
    mask            := mask_i;
    op              := READ;
    cycle_type      := cycle_type_i;
    burst_type      := burst_type_i;
    burst_length    := burst_length_i;
    index           := 0;
    err_o           <= '0';

    init_p (
      wb_sel_o => wb_sel_o,
      wb_we_o  => wb_we_o,
      wb_cyc_o => wb_cyc_o,
      wb_cti_o => wb_cti_o,
      wb_bte_o => wb_bte_o
      );

    while (index < to_integer(unsigned(burst_length))) loop
      next_p (
        wb_adr_o => wb_adr_o,
        wb_dat_o => wb_dat_o,
        wb_stb_o => wb_stb_o,
        wb_cti_o => wb_cti_o
        );

      ----data_compare (
        ----addr      => addr,
        ----read_data => data,
        ----iteration => index,

        ----buffer_addr => buffer_addr
        ----);

      addr            := wb_next_adr(addr, cycle_type, burst_type, DW);
      buffer_addr_tmp := std_logic_vector(unsigned(addr)-unsigned(base_addr));
      buffer_addr     := buffer_addr_tmp(ADR_LSB+BUFFER_WIDTH-1 downto ADR_LSB);
      index           := index+1;
    end loop;

    insert_wait_states (
      wb_cyc_o => wb_cyc_o,
      wb_stb_o => wb_stb_o,
      wb_we_o  => wb_we_o,

      wb_cti_o => wb_cti_o,
      wb_bte_o => wb_bte_o,
      wb_sel_o => wb_sel_o,
      wb_adr_o => wb_adr_o,
      wb_dat_o => wb_dat_o
      );
  end read_burst_comp;

begin
end RTL;
