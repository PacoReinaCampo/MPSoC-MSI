-- Converted from bench/verilog/regression/riscv_msi_testbench.sv
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
--              Master Slave Interconnect Tesbench                            //
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

use work.riscv_mpsoc_pkg.all;
use work.riscv_msi_pkg.all;

entity riscv_msi_testbench is
end riscv_msi_testbench;

architecture RTL of riscv_msi_testbench is
  component riscv_interconnect
    generic (
      PLEN    : integer := 64;
      XLEN    : integer := 64;
      MASTERS : integer := 3;
      SLAVES  : integer := 8
    );
    port (
      --Common signals
      HRESETn : in std_ulogic;
      HCLK    : in std_ulogic;

      --Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority : in M_MASTERS_2;

      mst_HSEL      : in  std_ulogic_vector(MASTERS-1 downto 0);
      mst_HADDR     : in  M_MASTERS_PLEN;
      mst_HWDATA    : in  M_MASTERS_XLEN;
      mst_HRDATA    : out M_MASTERS_XLEN;
      mst_HWRITE    : in  std_ulogic_vector(MASTERS-1 downto 0);
      mst_HSIZE     : in  M_MASTERS_2;
      mst_HBURST    : in  M_MASTERS_2;
      mst_HPROT     : in  M_MASTERS_3;
      mst_HTRANS    : in  M_MASTERS_1;
      mst_HMASTLOCK : in  std_ulogic_vector(MASTERS-1 downto 0);
      mst_HREADYOUT : out std_ulogic_vector(MASTERS-1 downto 0);
      mst_HREADY    : in  std_ulogic_vector(MASTERS-1 downto 0);
      mst_HRESP     : out std_ulogic_vector(MASTERS-1 downto 0);

      --Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask : in M_SLAVES_PLEN;
      slv_addr_base : in M_SLAVES_PLEN;

      slv_HSEL      : out std_ulogic_vector(SLAVES-1 downto 0);
      slv_HADDR     : out M_SLAVES_PLEN;
      slv_HWDATA    : out M_SLAVES_XLEN;
      slv_HRDATA    : in  M_SLAVES_XLEN;
      slv_HWRITE    : out std_ulogic_vector(SLAVES-1 downto 0);
      slv_HSIZE     : out M_SLAVES_2;
      slv_HBURST    : out M_SLAVES_2;
      slv_HPROT     : out M_SLAVES_3;
      slv_HTRANS    : out M_SLAVES_1;
      slv_HMASTLOCK : out std_ulogic_vector(SLAVES-1 downto 0);
      slv_HREADYOUT : out std_ulogic_vector(SLAVES-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_HREADY    : in  std_ulogic_vector(SLAVES-1 downto 0);  --combinatorial HREADY from all connected slaves
      slv_HRESP     : in  std_ulogic_vector(SLAVES-1 downto 0)
    );
  end component;

  component riscv_bridge
    generic (
      HADDR_SIZE : integer := 32;
      HDATA_SIZE : integer := 32;
      PADDR_SIZE : integer := 10;
      PDATA_SIZE : integer := 8;
      SYNC_DEPTH : integer := 3
    );
    port (
      --AHB Slave Interface
      HRESETn   : in  std_ulogic;
      HCLK      : in  std_ulogic;
      HSEL      : in  std_ulogic;
      HADDR     : in  std_ulogic_vector(HADDR_SIZE-1 downto 0);
      HWDATA    : in  std_ulogic_vector(HDATA_SIZE-1 downto 0);
      HRDATA    : out std_ulogic_vector(HDATA_SIZE-1 downto 0);
      HWRITE    : in  std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      HSIZE     : in  std_ulogic_vector(2 downto 0);
      HBURST    : in  std_ulogic_vector(2 downto 0);
      HPROT     : in  std_ulogic_vector(3 downto 0);
      HTRANS    : in  std_ulogic_vector(1 downto 0);
      HMASTLOCK : in  std_ulogic;
      HREADYOUT : out std_ulogic;
      HREADY    : in  std_ulogic;
      HRESP     : out std_ulogic;

      --APB Master Interface
      PRESETn : in  std_ulogic;
      PCLK    : in  std_ulogic;
      PSEL    : out std_ulogic;
      PENABLE : out std_ulogic;
      PPROT   : out std_ulogic_vector(2 downto 0);
      PWRITE  : out std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      PSTRB   : out std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      PADDR   : out std_ulogic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
      PRDATA  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : in  std_ulogic;
      PSLVERR : in  std_ulogic
    );
  end component;

  component riscv_gpio
    generic (
      PADDR_SIZE : integer := 64;
      PDATA_SIZE : integer := 64
    );
    port (
      PRESETn : in std_ulogic;
      PCLK    : in std_ulogic;

      PSEL    : in  std_ulogic;
      PENABLE : in  std_ulogic;
      PWRITE  : in  std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      PSTRB   : in  std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      PADDR   : in  std_ulogic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
      PRDATA  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : out std_ulogic;
      PSLVERR : out std_ulogic;

      gpio_i  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
      gpio_o  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
      gpio_oe : out std_ulogic_vector(PDATA_SIZE-1 downto 0)
    );
  end component;

  component riscv_misd_mpram
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
      HSEL      : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      HADDR     : in  M_CORES_PER_MISD_PLEN;
      HWDATA    : in  M_CORES_PER_MISD_XLEN;
      HRDATA    : out M_CORES_PER_MISD_XLEN;
      HWRITE    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      HSIZE     : in  M_CORES_PER_MISD_2;
      HBURST    : in  M_CORES_PER_MISD_2;
      HPROT     : in  M_CORES_PER_MISD_3;
      HTRANS    : in  M_CORES_PER_MISD_1;
      HMASTLOCK : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      HREADYOUT : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      HREADY    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      HRESP     : out std_ulogic_vector(CORES_PER_MISD-1 downto 0)
    );
  end component;

  component riscv_simd_mpram
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
      HSEL      : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HADDR     : in  M_CORES_PER_SIMD_PLEN;
      HWDATA    : in  M_CORES_PER_SIMD_XLEN;
      HRDATA    : out M_CORES_PER_SIMD_XLEN;
      HWRITE    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HSIZE     : in  M_CORES_PER_SIMD_2;
      HBURST    : in  M_CORES_PER_SIMD_2;
      HPROT     : in  M_CORES_PER_SIMD_3;
      HTRANS    : in  M_CORES_PER_SIMD_1;
      HMASTLOCK : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HREADYOUT : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HREADY    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HRESP     : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0)
    );
  end component;

  component riscv_spram
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
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Common signals
  signal HRESETn : std_ulogic;
  signal HCLK    : std_ulogic;

  signal mst_priority : M_MASTERS_2;

  signal mst_HSEL      : std_ulogic_vector(MASTERS-1 downto 0);
  signal mst_HADDR     : M_MASTERS_PLEN;
  signal mst_HWDATA    : M_MASTERS_XLEN;
  signal mst_HRDATA    : M_MASTERS_XLEN;
  signal mst_HWRITE    : std_ulogic_vector(MASTERS-1 downto 0);
  signal mst_HSIZE     : M_MASTERS_2;
  signal mst_HBURST    : M_MASTERS_2;
  signal mst_HPROT     : M_MASTERS_3;
  signal mst_HTRANS    : M_MASTERS_1;
  signal mst_HMASTLOCK : std_ulogic_vector(MASTERS-1 downto 0);
  signal mst_HREADY    : std_ulogic_vector(MASTERS-1 downto 0);
  signal mst_HREADYOUT : std_ulogic_vector(MASTERS-1 downto 0);
  signal mst_HRESP     : std_ulogic_vector(MASTERS-1 downto 0);

  signal slv_addr_mask : M_SLAVES_PLEN;
  signal slv_addr_base : M_SLAVES_PLEN;
  signal slv_HSEL      : std_ulogic_vector(SLAVES-1 downto 0);
  signal slv_HADDR     : M_SLAVES_PLEN;
  signal slv_HWDATA    : M_SLAVES_XLEN;
  signal slv_HRDATA    : M_SLAVES_XLEN;
  signal slv_HWRITE    : std_ulogic_vector(SLAVES-1 downto 0);
  signal slv_HSIZE     : M_SLAVES_2;
  signal slv_HBURST    : M_SLAVES_2;
  signal slv_HPROT     : M_SLAVES_3;
  signal slv_HTRANS    : M_SLAVES_1;
  signal slv_HMASTLOCK : std_ulogic_vector(SLAVES-1 downto 0);
  signal slv_HREADY    : std_ulogic_vector(SLAVES-1 downto 0);
  signal slv_HRESP     : std_ulogic_vector(SLAVES-1 downto 0);

  signal mst_gpio_HSEL      : std_ulogic;
  signal mst_gpio_HADDR     : std_ulogic_vector(PLEN-1 downto 0);
  signal mst_gpio_HWDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_gpio_HRDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_gpio_HWRITE    : std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
  signal mst_gpio_HSIZE     : std_ulogic_vector(2 downto 0);
  signal mst_gpio_HBURST    : std_ulogic_vector(2 downto 0);
  signal mst_gpio_HPROT     : std_ulogic_vector(3 downto 0);
  signal mst_gpio_HTRANS    : std_ulogic_vector(1 downto 0);
  signal mst_gpio_HMASTLOCK : std_ulogic;
  signal mst_gpio_HREADY    : std_ulogic;
  signal mst_gpio_HREADYOUT : std_ulogic;
  signal mst_gpio_HRESP     : std_ulogic;

  signal gpio_PSEL    : std_ulogic;
  signal gpio_PENABLE : std_ulogic;
  signal gpio_PWRITE  : std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
  signal gpio_PSTRB   : std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
  signal gpio_PADDR   : std_ulogic_vector(PADDR_SIZE-1 downto 0);
  signal gpio_PWDATA  : std_ulogic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_PRDATA  : std_ulogic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_PREADY  : std_ulogic;
  signal gpio_PSLVERR : std_ulogic;

  --GPIO Interface
  signal gpio_i  : std_ulogic_vector(PADDR_SIZE-1 downto 0);
  signal gpio_o  : std_ulogic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_oe : std_ulogic_vector(PDATA_SIZE-1 downto 0);

  signal mst_sram_HSEL      : std_ulogic;
  signal mst_sram_HADDR     : std_ulogic_vector(PLEN-1 downto 0);
  signal mst_sram_HWDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_sram_HRDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_sram_HWRITE    : std_ulogic;
  signal mst_sram_HSIZE     : std_ulogic_vector(2 downto 0);
  signal mst_sram_HBURST    : std_ulogic_vector(2 downto 0);
  signal mst_sram_HPROT     : std_ulogic_vector(3 downto 0);
  signal mst_sram_HTRANS    : std_ulogic_vector(1 downto 0);
  signal mst_sram_HMASTLOCK : std_ulogic;
  signal mst_sram_HREADY    : std_ulogic;
  signal mst_sram_HREADYOUT : std_ulogic;
  signal mst_sram_HRESP     : std_ulogic;

  signal mst_misd_mram_HSEL      : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HADDR     : M_CORES_PER_MISD_PLEN;
  signal mst_misd_mram_HWDATA    : M_CORES_PER_MISD_XLEN;
  signal mst_misd_mram_HRDATA    : M_CORES_PER_MISD_XLEN;
  signal mst_misd_mram_HWRITE    : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HSIZE     : M_CORES_PER_MISD_2;
  signal mst_misd_mram_HBURST    : M_CORES_PER_MISD_2;
  signal mst_misd_mram_HPROT     : M_CORES_PER_MISD_3;
  signal mst_misd_mram_HTRANS    : M_CORES_PER_MISD_1;
  signal mst_misd_mram_HMASTLOCK : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HREADY    : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HREADYOUT : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HRESP     : std_ulogic_vector(CORES_PER_MISD-1 downto 0);

  signal mst_simd_mram_HSEL      : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HADDR     : M_CORES_PER_SIMD_PLEN;
  signal mst_simd_mram_HWDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_simd_mram_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_simd_mram_HWRITE    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HSIZE     : M_CORES_PER_SIMD_2;
  signal mst_simd_mram_HBURST    : M_CORES_PER_SIMD_2;
  signal mst_simd_mram_HPROT     : M_CORES_PER_SIMD_3;
  signal mst_simd_mram_HTRANS    : M_CORES_PER_SIMD_1;
  signal mst_simd_mram_HMASTLOCK : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HREADY    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HREADYOUT : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HRESP     : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --DUT
  peripheral_interconnect : riscv_interconnect
    generic map (
      PLEN    => PLEN,
      XLEN    => XLEN,
      MASTERS => MASTERS,
      SLAVES  => SLAVES
    )
    port map (
      --Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      --Master Ports; AHB masters connect to these
      --thus these are actually AHB Slave Interfaces
      mst_priority => mst_priority,

      mst_HSEL      => mst_HSEL,
      mst_HADDR     => mst_HADDR,
      mst_HWDATA    => mst_HWDATA,
      mst_HRDATA    => mst_HRDATA,
      mst_HWRITE    => mst_HWRITE,
      mst_HSIZE     => mst_HSIZE,
      mst_HBURST    => mst_HBURST,
      mst_HPROT     => mst_HPROT,
      mst_HTRANS    => mst_HTRANS,
      mst_HMASTLOCK => mst_HMASTLOCK,
      mst_HREADYOUT => mst_HREADYOUT,
      mst_HREADY    => mst_HREADY,
      mst_HRESP     => mst_HRESP,

      --Slave Ports; AHB Slaves connect to these
      --thus these are actually AHB Master Interfaces
      slv_addr_mask => slv_addr_mask,
      slv_addr_base => slv_addr_base,

      slv_HSEL      => slv_HSEL,
      slv_HADDR     => slv_HADDR,
      slv_HWDATA    => slv_HWDATA,
      slv_HRDATA    => slv_HRDATA,
      slv_HWRITE    => slv_HWRITE,
      slv_HSIZE     => slv_HSIZE,
      slv_HBURST    => slv_HBURST,
      slv_HPROT     => slv_HPROT,
      slv_HTRANS    => slv_HTRANS,
      slv_HMASTLOCK => slv_HMASTLOCK,
      slv_HREADYOUT => open,
      slv_HREADY    => slv_HREADY,
      slv_HRESP     => slv_HRESP
    );

  --Instantiate RISC-V GPIO
  gpio_bridge : riscv_bridge
    generic map (
      HADDR_SIZE => PLEN,
      HDATA_SIZE => XLEN,
      PADDR_SIZE => PADDR_SIZE,
      PDATA_SIZE => PDATA_SIZE,
      SYNC_DEPTH => SYNC_DEPTH
    )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_gpio_HSEL,
      HADDR     => mst_gpio_HADDR,
      HWDATA    => mst_gpio_HWDATA,
      HRDATA    => mst_gpio_HRDATA,
      HWRITE    => mst_gpio_HWRITE,
      HSIZE     => mst_gpio_HSIZE,
      HBURST    => mst_gpio_HBURST,
      HPROT     => mst_gpio_HPROT,
      HTRANS    => mst_gpio_HTRANS,
      HMASTLOCK => mst_gpio_HMASTLOCK,
      HREADYOUT => mst_gpio_HREADYOUT,
      HREADY    => mst_gpio_HREADY,
      HRESP     => mst_gpio_HRESP,

      --APB Master Interface
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => gpio_PSEL,
      PENABLE => gpio_PENABLE,
      PPROT   => open,
      PWRITE  => gpio_PWRITE,
      PSTRB   => gpio_PSTRB,
      PADDR   => gpio_PADDR,
      PWDATA  => gpio_PWDATA,
      PRDATA  => gpio_PRDATA,
      PREADY  => gpio_PREADY,
      PSLVERR => gpio_PSLVERR
    );

  gpio : riscv_gpio
    generic map (
      PADDR_SIZE => PLEN,
      PDATA_SIZE => XLEN
    )
    port map (
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => gpio_PSEL,
      PENABLE => gpio_PENABLE,
      PWRITE  => gpio_PWRITE,
      PSTRB   => gpio_PSTRB,
      PADDR   => gpio_PADDR,
      PWDATA  => gpio_PWDATA,
      PRDATA  => gpio_PRDATA,
      PREADY  => gpio_PREADY,
      PSLVERR => gpio_PSLVERR,

      gpio_i  => gpio_i,
      gpio_o  => gpio_o,
      gpio_oe => gpio_oe
    );

  --Instantiate RISC-V RAM
  misd_mpram : riscv_misd_mpram
    generic map (
      MEM_SIZE          => 256,
      MEM_DEPTH         => 256,
      PLEN              => PLEN,
      XLEN              => XLEN,
      TECHNOLOGY        => TECHNOLOGY,
      REGISTERED_OUTPUT => "NO"
    )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_misd_mram_HSEL,
      HADDR     => mst_misd_mram_HADDR,
      HWDATA    => mst_misd_mram_HWDATA,
      HRDATA    => mst_misd_mram_HRDATA,
      HWRITE    => mst_misd_mram_HWRITE,
      HSIZE     => mst_misd_mram_HSIZE,
      HBURST    => mst_misd_mram_HBURST,
      HPROT     => mst_misd_mram_HPROT,
      HTRANS    => mst_misd_mram_HTRANS,
      HMASTLOCK => mst_misd_mram_HMASTLOCK,
      HREADYOUT => mst_misd_mram_HREADYOUT,
      HREADY    => mst_misd_mram_HREADY,
      HRESP     => mst_misd_mram_HRESP
    );

  simd_mpram : riscv_simd_mpram
    generic map (
      MEM_SIZE          => 256,
      MEM_DEPTH         => 256,
      PLEN              => PLEN,
      XLEN              => XLEN,
      TECHNOLOGY        => TECHNOLOGY,
      REGISTERED_OUTPUT => "NO"
    )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_simd_mram_HSEL,
      HADDR     => mst_simd_mram_HADDR,
      HWDATA    => mst_simd_mram_HWDATA,
      HRDATA    => mst_simd_mram_HRDATA,
      HWRITE    => mst_simd_mram_HWRITE,
      HSIZE     => mst_simd_mram_HSIZE,
      HBURST    => mst_simd_mram_HBURST,
      HPROT     => mst_simd_mram_HPROT,
      HTRANS    => mst_simd_mram_HTRANS,
      HMASTLOCK => mst_simd_mram_HMASTLOCK,
      HREADYOUT => mst_simd_mram_HREADYOUT,
      HREADY    => mst_simd_mram_HREADY,
      HRESP     => mst_simd_mram_HRESP
    );

  spram : riscv_spram
    generic map (
      MEM_SIZE          => 256,
      MEM_DEPTH         => 256,
      PLEN              => PLEN,
      XLEN              => XLEN,
      TECHNOLOGY        => TECHNOLOGY,
      REGISTERED_OUTPUT => "NO"
    )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_sram_HSEL,
      HADDR     => mst_sram_HADDR,
      HWDATA    => mst_sram_HWDATA,
      HRDATA    => mst_sram_HRDATA,
      HWRITE    => mst_sram_HWRITE,
      HSIZE     => mst_sram_HSIZE,
      HBURST    => mst_sram_HBURST,
      HPROT     => mst_sram_HPROT,
      HTRANS    => mst_sram_HTRANS,
      HMASTLOCK => mst_sram_HMASTLOCK,
      HREADYOUT => mst_sram_HREADYOUT,
      HREADY    => mst_sram_HREADY,
      HRESP     => mst_sram_HRESP
    );
end RTL;
