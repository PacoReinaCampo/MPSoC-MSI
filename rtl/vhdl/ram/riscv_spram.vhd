-- Converted from verilog/riscv_ram/riscv_spram.sv
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
--              Single Port SRAM                                              //
--              AMBA3 AHB-Lite Bus Interface                                  //
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

use work.riscv_mpsoc_pkg.all;

entity riscv_spram is
  generic (
    MEM_SIZE          : integer := 256;  --Memory in Bytes
    MEM_DEPTH         : integer := 256;  --Memory depth
    PLEN              : integer := 64;
    XLEN              : integer := 64;
    TECHNOLOGY        : string  := "GENERIC";
    REGISTERED_OUTPUT : string  := "NO"
    );
  port (
    HRESETn : in std_ulogic;
    HCLK    : in std_ulogic;

    --AHB Slave Interfaces (receive data from AHB Masters)
    --AHB Masters connect to these ports
    HSEL      : in  std_ulogic;
    HADDR     : in  std_ulogic_vector(PLEN-1 downto 0);
    HWDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
    HRDATA    : out std_ulogic_vector(XLEN-1 downto 0);
    HWRITE    : in  std_ulogic;
    HSIZE     : in  std_ulogic_vector(2 downto 0);
    HBURST    : in  std_ulogic_vector(2 downto 0);
    HPROT     : in  std_ulogic_vector(3 downto 0);
    HTRANS    : in  std_ulogic_vector(1 downto 0);
    HMASTLOCK : in  std_ulogic;
    HREADYOUT : out std_ulogic;
    HREADY    : in  std_ulogic;
    HRESP     : out std_ulogic
    );
end riscv_spram;

architecture RTL of riscv_spram is
  component riscv_ram_1r1w
    generic (
      ABITS      : integer := 10;
      DBITS      : integer := 32;
      TECHNOLOGY : string  := "GENERIC"
      );
    port (
      rst_ni : in std_ulogic;
      clk_i  : in std_ulogic;

      --Write side
      waddr_i : in std_ulogic_vector(ABITS-1 downto 0);
      din_i   : in std_ulogic_vector(DBITS-1 downto 0);
      we_i    : in std_ulogic;
      be_i    : in std_ulogic_vector((DBITS+7)/8-1 downto 0);

      --Read side
      raddr_i : in  std_ulogic_vector(ABITS-1 downto 0);
      re_i    : in  std_ulogic;
      dout_o  : out std_ulogic_vector(DBITS-1 downto 0)
      );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant BE_SIZE : integer := (XLEN+7)/8;

  constant MEM_SIZE_DEPTH : integer := 8*MEM_SIZE/XLEN;
  constant REAL_MEM_DEPTH : integer := MEM_SIZE_DEPTH;
  constant MEM_ABITS      : integer := integer(log2(real(REAL_MEM_DEPTH)));
  constant MEM_ABITS_LSB  : integer := integer(log2(real(BE_SIZE)));

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal we         : std_ulogic;
  signal be         : std_ulogic_vector(BE_SIZE-1 downto 0);
  signal waddr      : std_ulogic_vector(PLEN-1 downto 0);
  signal contention : std_ulogic;
  signal ready      : std_ulogic;

  signal dout : std_ulogic_vector(XLEN-1 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --
  function gen_be (
    hsize : std_ulogic_vector(2 downto 0);
    haddr : std_ulogic_vector(PLEN-1 downto 0)
    ) return std_ulogic_vector is

    variable full_be        : std_ulogic_vector(127 downto 0);
    variable haddr_masked   : std_ulogic_vector(6 downto 0);
    variable address_offset : std_ulogic_vector (6 downto 0);

    variable gen_be_return : std_ulogic_vector (BE_SIZE-1 downto 0);
  begin
    --get number of active lanes for a 1024bit databus (max width) for this HSIZE
    case (hsize) is
      when HSIZE_B1024 =>
        full_be := X"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
      when HSIZE_B512 =>
        full_be := X"0000000000000000FFFFFFFFFFFFFFFF";
      when HSIZE_B256 =>
        full_be := X"000000000000000000000000FFFFFFFF";
      when HSIZE_B128 =>
        full_be := X"0000000000000000000000000000FFFF";
      when HSIZE_DWORD =>
        full_be := X"000000000000000000000000000000FF";
      when HSIZE_WORD =>
        full_be := X"0000000000000000000000000000000F";
      when HSIZE_HWORD =>
        full_be := X"00000000000000000000000000000003";
      when others =>
        full_be := X"00000000000000000000000000000001";
    end case;

    --What are the lesser bits in HADDR?
    case (XLEN) is
      when 1024 =>
        address_offset := "1111111";
      when 0512 =>
        address_offset := "0111111";
      when 0256 =>
        address_offset := "0011111";
      when 0128 =>
        address_offset := "0001111";
      when 0064 =>
        address_offset := "0000111";
      when 0032 =>
        address_offset := "0000011";
      when 0016 =>
        address_offset := "0000001";
      when others =>
        address_offset := "0000000";
    end case;

    --generate masked address
    haddr_masked := haddr and address_offset;

    --create byte-enable
    gen_be_return := std_ulogic_vector(unsigned(full_be(BE_SIZE-1 downto 0)) sll to_integer(unsigned(haddr_masked)));
    return gen_be_return;
  end gen_be;  --gen_be

  function reduce_nand (
    reduce_nand_in : std_ulogic_vector
    ) return std_ulogic is
    variable reduce_nand_out : std_ulogic := '0';
  begin
    for i in reduce_nand_in'range loop
      reduce_nand_out := reduce_nand_out nand reduce_nand_in(i);
    end loop;
    return reduce_nand_out;
  end reduce_nand;

  function to_stdlogic (
    input : boolean
    ) return std_ulogic is
  begin
    if input then
      return('1');
    else
      return('0');
    end if;
  end function to_stdlogic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --generate internal write signal
  --This causes read/write contention, which is handled by memory
  processing_0 : process (HCLK)
  begin
    if (rising_edge(HCLK)) then
      if (HREADY = '1') then
        we <= HSEL and HWRITE and to_stdlogic(HTRANS /= HTRANS_BUSY) and to_stdlogic(HTRANS /= HTRANS_IDLE);
      else
        we <= '0';
      end if;
    end if;
  end process;

  --decode Byte-Enables
  processing_1 : process (HCLK)
  begin
    if (rising_edge(HCLK)) then
      if (HREADY = '1') then
        be <= gen_be(HSIZE, HADDR);
      end if;
    end if;
  end process;

  --store write address
  processing_2 : process (HCLK)
  begin
    if (rising_edge(HCLK)) then
      if (HREADY = '1') then
        waddr <= HADDR;
      end if;
    end if;
  end process;

  --Is there read/write contention on the memory?
  contention <= to_stdlogic(waddr(MEM_ABITS+MEM_ABITS_LSB-1 downto MEM_ABITS_LSB) = HADDR(MEM_ABITS+MEM_ABITS_LSB-1 downto MEM_ABITS_LSB)) and we and HSEL and HREADY and not HWRITE and to_stdlogic(HTRANS /= HTRANS_BUSY) and to_stdlogic(HTRANS /= HTRANS_IDLE);

  --if all bytes were written contention is/can be handled by memory
  --otherwise stall a cycle (forced by N3S)
  --We could do an exception for N3S here, but this file should be technology agnostic
  ready <= not (contention and reduce_nand(be));

  --  * Hookup Memory Wrapper
  --  * Use two-port memory, due to pipelined AHB bus;
  --  *   the actual write to memory is 1 cycle late, causing read/write overlap
  --  * This assumes there are input registers on the memory

  ram_1r1w : riscv_ram_1r1w
    generic map (
      ABITS      => MEM_ABITS,
      DBITS      => XLEN,
      TECHNOLOGY => TECHNOLOGY
      )
    port map (
      rst_ni => HRESETn,
      clk_i  => HCLK,

      waddr_i => waddr(MEM_ABITS+MEM_ABITS_LSB-1 downto MEM_ABITS_LSB),
      we_i    => we,
      be_i    => be,
      din_i   => HWDATA,

      re_i    => '0',
      raddr_i => HADDR(MEM_ABITS+MEM_ABITS_LSB-1 downto MEM_ABITS_LSB),
      dout_o  => dout
      );

  --AHB bus response
  HRESP <= HRESP_OKAY;                  --always OK

  processing_3 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      HREADYOUT <= '1';
    elsif (rising_edge(HCLK)) then
      if (REGISTERED_OUTPUT = "NO") then
        HREADYOUT <= ready;
      elsif (REGISTERED_OUTPUT /= "NO") then
        if (HTRANS = HTRANS_NONSEQ and HWRITE = '0') then
          HREADYOUT <= '0';
        else
          HREADYOUT <= '1';
        end if;
      end if;
    end if;
  end process;

  processing_4 : process (HCLK, dout)
  begin
    if (REGISTERED_OUTPUT = "NO") then
      HRDATA <= dout;
    elsif (REGISTERED_OUTPUT /= "NO") then
      if (rising_edge(HCLK)) then
        if (HREADY = '1') then
          HRDATA <= dout;
        end if;
      end if;
    end if;
  end process;
end RTL;
