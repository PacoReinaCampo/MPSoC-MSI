-- Converted from bench/verilog/regression/mpsoc_msi_testbench.sv
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
--              Master Slave Interface Tesbench                               //
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

use work.mpsoc_pkg.all;
use work.mpsoc_msi_pkg.all;

entity mpsoc_msi_testbench is
end mpsoc_msi_testbench;

architecture RTL of mpsoc_msi_testbench is
  component mpsoc_msi_ahb3_interface
    generic (
      PLEN    : integer := 64;
      XLEN    : integer := 64;
      MASTERS : integer := 5;
      SLAVES  : integer := 5
      );
    port (
      --Common signals
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority : in M_MASTERS_2;

      mst_HSEL      : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HADDR     : in  M_MASTERS_PLEN;
      mst_HWDATA    : in  M_MASTERS_XLEN;
      mst_HRDATA    : out M_MASTERS_XLEN;
      mst_HWRITE    : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HSIZE     : in  M_MASTERS_2;
      mst_HBURST    : in  M_MASTERS_2;
      mst_HPROT     : in  M_MASTERS_3;
      mst_HTRANS    : in  M_MASTERS_1;
      mst_HMASTLOCK : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HREADYOUT : out std_logic_vector(MASTERS-1 downto 0);
      mst_HREADY    : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HRESP     : out std_logic_vector(MASTERS-1 downto 0);

      --Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask : in M_SLAVES_PLEN;
      slv_addr_base : in M_SLAVES_PLEN;

      slv_HSEL      : out std_logic_vector(SLAVES-1 downto 0);
      slv_HADDR     : out M_SLAVES_PLEN;
      slv_HWDATA    : out M_SLAVES_XLEN;
      slv_HRDATA    : in  M_SLAVES_XLEN;
      slv_HWRITE    : out std_logic_vector(SLAVES-1 downto 0);
      slv_HSIZE     : out M_SLAVES_2;
      slv_HBURST    : out M_SLAVES_2;
      slv_HPROT     : out M_SLAVES_3;
      slv_HTRANS    : out M_SLAVES_1;
      slv_HMASTLOCK : out std_logic_vector(SLAVES-1 downto 0);
      slv_HREADYOUT : out std_logic_vector(SLAVES-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_HREADY    : in  std_logic_vector(SLAVES-1 downto 0);  --combinatorial HREADY from all connected slaves
      slv_HRESP     : in  std_logic_vector(SLAVES-1 downto 0)
      );
  end component;

  component mpsoc_msi_wb_interface
    generic (
      PLEN    : integer := 64;
      XLEN    : integer := 64;
      MASTERS : integer := 5;
      SLAVES  : integer := 5
      );
    port (
      --Common signals
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority : in M_MASTERS_2;

      mst_HSEL      : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HADDR     : in  M_MASTERS_PLEN;
      mst_HWDATA    : in  M_MASTERS_XLEN;
      mst_HRDATA    : out M_MASTERS_XLEN;
      mst_HWRITE    : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HSIZE     : in  M_MASTERS_2;
      mst_HBURST    : in  M_MASTERS_2;
      mst_HPROT     : in  M_MASTERS_3;
      mst_HTRANS    : in  M_MASTERS_1;
      mst_HMASTLOCK : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HREADYOUT : out std_logic_vector(MASTERS-1 downto 0);
      mst_HREADY    : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HRESP     : out std_logic_vector(MASTERS-1 downto 0);

      --Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask : in M_SLAVES_PLEN;
      slv_addr_base : in M_SLAVES_PLEN;

      slv_HSEL      : out std_logic_vector(SLAVES-1 downto 0);
      slv_HADDR     : out M_SLAVES_PLEN;
      slv_HWDATA    : out M_SLAVES_XLEN;
      slv_HRDATA    : in  M_SLAVES_XLEN;
      slv_HWRITE    : out std_logic_vector(SLAVES-1 downto 0);
      slv_HSIZE     : out M_SLAVES_2;
      slv_HBURST    : out M_SLAVES_2;
      slv_HPROT     : out M_SLAVES_3;
      slv_HTRANS    : out M_SLAVES_1;
      slv_HMASTLOCK : out std_logic_vector(SLAVES-1 downto 0);
      slv_HREADYOUT : out std_logic_vector(SLAVES-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_HREADY    : in  std_logic_vector(SLAVES-1 downto 0);  --combinatorial HREADY from all connected slaves
      slv_HRESP     : in  std_logic_vector(SLAVES-1 downto 0)
      );
  end component;

  component mpsoc_misd_memory_ahb3_interface
    generic (
      PLEN           : integer := 64;
      XLEN           : integer := 64;
      CORES_PER_MISD : integer := 8
      );
    port (
      --Common signals
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority : in M_CORES_PER_MISD_2;

      mst_HSEL      : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HADDR     : in  M_CORES_PER_MISD_PLEN;
      mst_HWDATA    : in  M_CORES_PER_MISD_XLEN;
      mst_HRDATA    : out M_CORES_PER_MISD_XLEN;
      mst_HWRITE    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HSIZE     : in  M_CORES_PER_MISD_2;
      mst_HBURST    : in  M_CORES_PER_MISD_2;
      mst_HPROT     : in  M_CORES_PER_MISD_3;
      mst_HTRANS    : in  M_CORES_PER_MISD_1;
      mst_HMASTLOCK : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HREADYOUT : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HREADY    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HRESP     : out std_logic_vector(CORES_PER_MISD-1 downto 0);

      --Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask : in M_CORES_PER_MISD_PLEN;
      slv_addr_base : in M_CORES_PER_MISD_PLEN;

      slv_HSEL      : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      slv_HADDR     : out M_CORES_PER_MISD_PLEN;
      slv_HWDATA    : out M_CORES_PER_MISD_XLEN;
      slv_HRDATA    : in  M_CORES_PER_MISD_XLEN;
      slv_HWRITE    : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      slv_HSIZE     : out M_CORES_PER_MISD_2;
      slv_HBURST    : out M_CORES_PER_MISD_2;
      slv_HPROT     : out M_CORES_PER_MISD_3;
      slv_HTRANS    : out M_CORES_PER_MISD_1;
      slv_HMASTLOCK : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      slv_HREADYOUT : out std_logic_vector(CORES_PER_MISD-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_HREADY    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);  --combinatorial HREADY from all connected slaves
      slv_HRESP     : in  std_logic_vector(CORES_PER_MISD-1 downto 0)
      );
  end component;

  component mpsoc_misd_memory_wb_interface
    generic (
      PLEN           : integer := 64;
      XLEN           : integer := 64;
      CORES_PER_MISD : integer := 8
      );
    port (
      --Common signals
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority : in M_CORES_PER_MISD_2;

      mst_HSEL      : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HADDR     : in  M_CORES_PER_MISD_PLEN;
      mst_HWDATA    : in  M_CORES_PER_MISD_XLEN;
      mst_HRDATA    : out M_CORES_PER_MISD_XLEN;
      mst_HWRITE    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HSIZE     : in  M_CORES_PER_MISD_2;
      mst_HBURST    : in  M_CORES_PER_MISD_2;
      mst_HPROT     : in  M_CORES_PER_MISD_3;
      mst_HTRANS    : in  M_CORES_PER_MISD_1;
      mst_HMASTLOCK : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HREADYOUT : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HREADY    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      mst_HRESP     : out std_logic_vector(CORES_PER_MISD-1 downto 0);

      --Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask : in M_CORES_PER_MISD_PLEN;
      slv_addr_base : in M_CORES_PER_MISD_PLEN;

      slv_HSEL      : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      slv_HADDR     : out M_CORES_PER_MISD_PLEN;
      slv_HWDATA    : out M_CORES_PER_MISD_XLEN;
      slv_HRDATA    : in  M_CORES_PER_MISD_XLEN;
      slv_HWRITE    : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      slv_HSIZE     : out M_CORES_PER_MISD_2;
      slv_HBURST    : out M_CORES_PER_MISD_2;
      slv_HPROT     : out M_CORES_PER_MISD_3;
      slv_HTRANS    : out M_CORES_PER_MISD_1;
      slv_HMASTLOCK : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      slv_HREADYOUT : out std_logic_vector(CORES_PER_MISD-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_HREADY    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);  --combinatorial HREADY from all connected slaves
      slv_HRESP     : in  std_logic_vector(CORES_PER_MISD-1 downto 0)
      );
  end component;

  component mpsoc_simd_memory_ahb3_interface
    generic (
      PLEN           : integer := 64;
      XLEN           : integer := 64;
      CORES_PER_SIMD : integer := 8
      );
    port (
      --Common signals
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority : in M_CORES_PER_SIMD_2;

      mst_HSEL      : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HADDR     : in  M_CORES_PER_SIMD_PLEN;
      mst_HWDATA    : in  M_CORES_PER_SIMD_XLEN;
      mst_HRDATA    : out M_CORES_PER_SIMD_XLEN;
      mst_HWRITE    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HSIZE     : in  M_CORES_PER_SIMD_2;
      mst_HBURST    : in  M_CORES_PER_SIMD_2;
      mst_HPROT     : in  M_CORES_PER_SIMD_3;
      mst_HTRANS    : in  M_CORES_PER_SIMD_1;
      mst_HMASTLOCK : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HREADYOUT : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HREADY    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HRESP     : out std_logic_vector(CORES_PER_SIMD-1 downto 0);

      --Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask : in M_CORES_PER_SIMD_PLEN;
      slv_addr_base : in M_CORES_PER_SIMD_PLEN;

      slv_HSEL      : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      slv_HADDR     : out M_CORES_PER_SIMD_PLEN;
      slv_HWDATA    : out M_CORES_PER_SIMD_XLEN;
      slv_HRDATA    : in  M_CORES_PER_SIMD_XLEN;
      slv_HWRITE    : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      slv_HSIZE     : out M_CORES_PER_SIMD_2;
      slv_HBURST    : out M_CORES_PER_SIMD_2;
      slv_HPROT     : out M_CORES_PER_SIMD_3;
      slv_HTRANS    : out M_CORES_PER_SIMD_1;
      slv_HMASTLOCK : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      slv_HREADYOUT : out std_logic_vector(CORES_PER_SIMD-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_HREADY    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);  --combinatorial HREADY from all connected slaves
      slv_HRESP     : in  std_logic_vector(CORES_PER_SIMD-1 downto 0)
      );
  end component;

  component mpsoc_simd_memory_wb_interface
    generic (
      PLEN           : integer := 64;
      XLEN           : integer := 64;
      CORES_PER_SIMD : integer := 8
      );
    port (
      --Common signals
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority : in M_CORES_PER_SIMD_2;

      mst_HSEL      : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HADDR     : in  M_CORES_PER_SIMD_PLEN;
      mst_HWDATA    : in  M_CORES_PER_SIMD_XLEN;
      mst_HRDATA    : out M_CORES_PER_SIMD_XLEN;
      mst_HWRITE    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HSIZE     : in  M_CORES_PER_SIMD_2;
      mst_HBURST    : in  M_CORES_PER_SIMD_2;
      mst_HPROT     : in  M_CORES_PER_SIMD_3;
      mst_HTRANS    : in  M_CORES_PER_SIMD_1;
      mst_HMASTLOCK : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HREADYOUT : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HREADY    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      mst_HRESP     : out std_logic_vector(CORES_PER_SIMD-1 downto 0);

      --Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask : in M_CORES_PER_SIMD_PLEN;
      slv_addr_base : in M_CORES_PER_SIMD_PLEN;

      slv_HSEL      : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      slv_HADDR     : out M_CORES_PER_SIMD_PLEN;
      slv_HWDATA    : out M_CORES_PER_SIMD_XLEN;
      slv_HRDATA    : in  M_CORES_PER_SIMD_XLEN;
      slv_HWRITE    : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      slv_HSIZE     : out M_CORES_PER_SIMD_2;
      slv_HBURST    : out M_CORES_PER_SIMD_2;
      slv_HPROT     : out M_CORES_PER_SIMD_3;
      slv_HTRANS    : out M_CORES_PER_SIMD_1;
      slv_HMASTLOCK : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      slv_HREADYOUT : out std_logic_vector(CORES_PER_SIMD-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_HREADY    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);  --combinatorial HREADY from all connected slaves
      slv_HRESP     : in  std_logic_vector(CORES_PER_SIMD-1 downto 0)
      );
  end component;

  component mpsoc_ahb3_peripheral_bridge
    generic (
      HADDR_SIZE : integer := 32;
      HDATA_SIZE : integer := 32;
      PADDR_SIZE : integer := 10;
      PDATA_SIZE : integer := 8;
      SYNC_DEPTH : integer := 3
      );
    port (
      --AHB Slave Interface
      HRESETn   : in  std_logic;
      HCLK      : in  std_logic;
      HSEL      : in  std_logic;
      HADDR     : in  std_logic_vector(HADDR_SIZE-1 downto 0);
      HWDATA    : in  std_logic_vector(HDATA_SIZE-1 downto 0);
      HRDATA    : out std_logic_vector(HDATA_SIZE-1 downto 0);
      HWRITE    : in  std_logic;
      HSIZE     : in  std_logic_vector(2 downto 0);
      HBURST    : in  std_logic_vector(2 downto 0);
      HPROT     : in  std_logic_vector(3 downto 0);
      HTRANS    : in  std_logic_vector(1 downto 0);
      HMASTLOCK : in  std_logic;
      HREADYOUT : out std_logic;
      HREADY    : in  std_logic;
      HRESP     : out std_logic;

      --APB Master Interface
      PRESETn : in  std_logic;
      PCLK    : in  std_logic;
      PSEL    : out std_logic;
      PENABLE : out std_logic;
      PPROT   : out std_logic_vector(2 downto 0);
      PWRITE  : out std_logic;
      PSTRB   : out std_logic;
      PADDR   : out std_logic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : out std_logic_vector(PDATA_SIZE-1 downto 0);
      PRDATA  : in  std_logic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : in  std_logic;
      PSLVERR : in  std_logic
      );
  end component;

  component mpsoc_wb_peripheral_bridge
    generic (
      HADDR_SIZE : integer := 32;
      HDATA_SIZE : integer := 32;
      PADDR_SIZE : integer := 10;
      PDATA_SIZE : integer := 8;
      SYNC_DEPTH : integer := 3
      );
    port (
      --AHB Slave Interface
      HRESETn   : in  std_logic;
      HCLK      : in  std_logic;
      HSEL      : in  std_logic;
      HADDR     : in  std_logic_vector(HADDR_SIZE-1 downto 0);
      HWDATA    : in  std_logic_vector(HDATA_SIZE-1 downto 0);
      HRDATA    : out std_logic_vector(HDATA_SIZE-1 downto 0);
      HWRITE    : in  std_logic;
      HSIZE     : in  std_logic_vector(2 downto 0);
      HBURST    : in  std_logic_vector(2 downto 0);
      HPROT     : in  std_logic_vector(3 downto 0);
      HTRANS    : in  std_logic_vector(1 downto 0);
      HMASTLOCK : in  std_logic;
      HREADYOUT : out std_logic;
      HREADY    : in  std_logic;
      HRESP     : out std_logic;

      --APB Master Interface
      PRESETn : in  std_logic;
      PCLK    : in  std_logic;
      PSEL    : out std_logic;
      PENABLE : out std_logic;
      PPROT   : out std_logic_vector(2 downto 0);
      PWRITE  : out std_logic;
      PSTRB   : out std_logic;
      PADDR   : out std_logic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : out std_logic_vector(PDATA_SIZE-1 downto 0);
      PRDATA  : in  std_logic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : in  std_logic;
      PSLVERR : in  std_logic
      );
  end component;

  component mpsoc_apb_gpio
    generic (
      PADDR_SIZE : integer := 64;
      PDATA_SIZE : integer := 64
      );
    port (
      PRESETn : in std_logic;
      PCLK    : in std_logic;

      PSEL    : in  std_logic;
      PENABLE : in  std_logic;
      PWRITE  : in  std_logic;
      PSTRB   : in  std_logic;
      PADDR   : in  std_logic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : in  std_logic_vector(PDATA_SIZE-1 downto 0);
      PRDATA  : out std_logic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : out std_logic;
      PSLVERR : out std_logic;

      gpio_i  : in  std_logic_vector(PDATA_SIZE-1 downto 0);
      gpio_o  : out std_logic_vector(PDATA_SIZE-1 downto 0);
      gpio_oe : out std_logic_vector(PDATA_SIZE-1 downto 0)
      );
  end component;

  component mpsoc_ahb3_uart
    generic (
      APB_ADDR_WIDTH : integer := 12;   --APB slaves are 4KB by default
      APB_DATA_WIDTH : integer := 32    --APB slaves are 4KB by default
      );
    port (
      CLK     : in  std_logic;
      RSTN    : in  std_logic;
      PADDR   : in  std_logic_vector(APB_ADDR_WIDTH-1 downto 0);
      PWDATA  : in  std_logic_vector(APB_DATA_WIDTH-1 downto 0);
      PWRITE  : in  std_logic;
      PSEL    : in  std_logic;
      PENABLE : in  std_logic;
      PRDATA  : out std_logic_vector(APB_DATA_WIDTH-1 downto 0);
      PREADY  : out std_logic;
      PSLVERR : out std_logic;

      rx_i : in  std_logic;             -- Receiver input
      tx_o : out std_logic;             -- Transmitter output

      event_o : out std_logic           -- interrupt/event output
      );
  end component;

  component mpsoc_wb_uart
    generic (
      APB_ADDR_WIDTH : integer := 12;   --APB slaves are 4KB by default
      APB_DATA_WIDTH : integer := 32    --APB slaves are 4KB by default
      );
    port (
      CLK     : in  std_logic;
      RSTN    : in  std_logic;
      PADDR   : in  std_logic_vector(APB_ADDR_WIDTH-1 downto 0);
      PWDATA  : in  std_logic_vector(APB_DATA_WIDTH-1 downto 0);
      PWRITE  : in  std_logic;
      PSEL    : in  std_logic;
      PENABLE : in  std_logic;
      PRDATA  : out std_logic_vector(APB_DATA_WIDTH-1 downto 0);
      PREADY  : out std_logic;
      PSLVERR : out std_logic;

      rx_i : in  std_logic;             -- Receiver input
      tx_o : out std_logic;             -- Transmitter output

      event_o : out std_logic           -- interrupt/event output
      );
  end component;

  component mpsoc_misd_ahb3_mpram
    generic (
      MEM_SIZE          : integer := 256;  --Memory in Bytes
      MEM_DEPTH         : integer := 256;  --Memory depth
      PLEN              : integer := 64;
      XLEN              : integer := 64;
      TECHNOLOGY        : string  := "GENERIC";
      REGISTERED_OUTPUT : string  := "NO"
      );
    port (
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      HSEL      : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      HADDR     : in  M_CORES_PER_MISD_PLEN;
      HWDATA    : in  M_CORES_PER_MISD_XLEN;
      HRDATA    : out M_CORES_PER_MISD_XLEN;
      HWRITE    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      HSIZE     : in  M_CORES_PER_MISD_2;
      HBURST    : in  M_CORES_PER_MISD_2;
      HPROT     : in  M_CORES_PER_MISD_3;
      HTRANS    : in  M_CORES_PER_MISD_1;
      HMASTLOCK : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      HREADYOUT : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      HREADY    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      HRESP     : out std_logic_vector(CORES_PER_MISD-1 downto 0)
      );
  end component;

  component mpsoc_misd_wb_mpram
    generic (
      MEM_SIZE          : integer := 256;  --Memory in Bytes
      MEM_DEPTH         : integer := 256;  --Memory depth
      PLEN              : integer := 64;
      XLEN              : integer := 64;
      TECHNOLOGY        : string  := "GENERIC";
      REGISTERED_OUTPUT : string  := "NO"
      );
    port (
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      HSEL      : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      HADDR     : in  M_CORES_PER_MISD_PLEN;
      HWDATA    : in  M_CORES_PER_MISD_XLEN;
      HRDATA    : out M_CORES_PER_MISD_XLEN;
      HWRITE    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      HSIZE     : in  M_CORES_PER_MISD_2;
      HBURST    : in  M_CORES_PER_MISD_2;
      HPROT     : in  M_CORES_PER_MISD_3;
      HTRANS    : in  M_CORES_PER_MISD_1;
      HMASTLOCK : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      HREADYOUT : out std_logic_vector(CORES_PER_MISD-1 downto 0);
      HREADY    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
      HRESP     : out std_logic_vector(CORES_PER_MISD-1 downto 0)
      );
  end component;

  component mpsoc_simd_ahb3_mpram
    generic (
      MEM_SIZE          : integer := 256;  --Memory in Bytes
      MEM_DEPTH         : integer := 256;  --Memory depth
      PLEN              : integer := 64;
      XLEN              : integer := 64;
      TECHNOLOGY        : string  := "GENERIC";
      REGISTERED_OUTPUT : string  := "NO"
      );
    port (
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      HSEL      : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HADDR     : in  M_CORES_PER_SIMD_PLEN;
      HWDATA    : in  M_CORES_PER_SIMD_XLEN;
      HRDATA    : out M_CORES_PER_SIMD_XLEN;
      HWRITE    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HSIZE     : in  M_CORES_PER_SIMD_2;
      HBURST    : in  M_CORES_PER_SIMD_2;
      HPROT     : in  M_CORES_PER_SIMD_3;
      HTRANS    : in  M_CORES_PER_SIMD_1;
      HMASTLOCK : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HREADYOUT : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HREADY    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HRESP     : out std_logic_vector(CORES_PER_SIMD-1 downto 0)
      );
  end component;

  component mpsoc_simd_wb_mpram
    generic (
      MEM_SIZE          : integer := 256;  --Memory in Bytes
      MEM_DEPTH         : integer := 256;  --Memory depth
      PLEN              : integer := 64;
      XLEN              : integer := 64;
      TECHNOLOGY        : string  := "GENERIC";
      REGISTERED_OUTPUT : string  := "NO"
      );
    port (
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      HSEL      : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HADDR     : in  M_CORES_PER_SIMD_PLEN;
      HWDATA    : in  M_CORES_PER_SIMD_XLEN;
      HRDATA    : out M_CORES_PER_SIMD_XLEN;
      HWRITE    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HSIZE     : in  M_CORES_PER_SIMD_2;
      HBURST    : in  M_CORES_PER_SIMD_2;
      HPROT     : in  M_CORES_PER_SIMD_3;
      HTRANS    : in  M_CORES_PER_SIMD_1;
      HMASTLOCK : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HREADYOUT : out std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HREADY    : in  std_logic_vector(CORES_PER_SIMD-1 downto 0);
      HRESP     : out std_logic_vector(CORES_PER_SIMD-1 downto 0)
      );
  end component;

  component mpsoc_ahb3_spram
    generic (
      MEM_SIZE          : integer := 256;  --Memory in Bytes
      MEM_DEPTH         : integer := 256;  --Memory depth
      PLEN              : integer := 64;
      XLEN              : integer := 64;
      TECHNOLOGY        : string  := "GENERIC";
      REGISTERED_OUTPUT : string  := "NO"
      );
    port (
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      HSEL      : in  std_logic;
      HADDR     : in  std_logic_vector(PLEN-1 downto 0);
      HWDATA    : in  std_logic_vector(XLEN-1 downto 0);
      HRDATA    : out std_logic_vector(XLEN-1 downto 0);
      HWRITE    : in  std_logic;
      HSIZE     : in  std_logic_vector(2 downto 0);
      HBURST    : in  std_logic_vector(2 downto 0);
      HPROT     : in  std_logic_vector(3 downto 0);
      HTRANS    : in  std_logic_vector(1 downto 0);
      HMASTLOCK : in  std_logic;
      HREADYOUT : out std_logic;
      HREADY    : in  std_logic;
      HRESP     : out std_logic
      );
  end component;

  component mpsoc_wb_spram
    generic (
      MEM_SIZE          : integer := 256;  --Memory in Bytes
      MEM_DEPTH         : integer := 256;  --Memory depth
      PLEN              : integer := 64;
      XLEN              : integer := 64;
      TECHNOLOGY        : string  := "GENERIC";
      REGISTERED_OUTPUT : string  := "NO"
      );
    port (
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      HSEL      : in  std_logic;
      HADDR     : in  std_logic_vector(PLEN-1 downto 0);
      HWDATA    : in  std_logic_vector(XLEN-1 downto 0);
      HRDATA    : out std_logic_vector(XLEN-1 downto 0);
      HWRITE    : in  std_logic;
      HSIZE     : in  std_logic_vector(2 downto 0);
      HBURST    : in  std_logic_vector(2 downto 0);
      HPROT     : in  std_logic_vector(3 downto 0);
      HTRANS    : in  std_logic_vector(1 downto 0);
      HMASTLOCK : in  std_logic;
      HREADYOUT : out std_logic;
      HREADY    : in  std_logic;
      HRESP     : out std_logic
      );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Common signals
  signal HRESETn : std_logic;
  signal HCLK    : std_logic;

  signal mst_priority : M_MASTERS_2;

  signal mst_HSEL      : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HADDR     : M_MASTERS_PLEN;
  signal mst_HWDATA    : M_MASTERS_XLEN;
  signal mst_HRDATA    : M_MASTERS_XLEN;
  signal mst_HWRITE    : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HSIZE     : M_MASTERS_2;
  signal mst_HBURST    : M_MASTERS_2;
  signal mst_HPROT     : M_MASTERS_3;
  signal mst_HTRANS    : M_MASTERS_1;
  signal mst_HMASTLOCK : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HREADY    : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HREADYOUT : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HRESP     : std_logic_vector(MASTERS-1 downto 0);

  signal slv_addr_mask : M_SLAVES_PLEN;
  signal slv_addr_base : M_SLAVES_PLEN;
  signal slv_HSEL      : std_logic_vector(SLAVES-1 downto 0);
  signal slv_HADDR     : M_SLAVES_PLEN;
  signal slv_HWDATA    : M_SLAVES_XLEN;
  signal slv_HRDATA    : M_SLAVES_XLEN;
  signal slv_HWRITE    : std_logic_vector(SLAVES-1 downto 0);
  signal slv_HSIZE     : M_SLAVES_2;
  signal slv_HBURST    : M_SLAVES_2;
  signal slv_HPROT     : M_SLAVES_3;
  signal slv_HTRANS    : M_SLAVES_1;
  signal slv_HMASTLOCK : std_logic_vector(SLAVES-1 downto 0);
  signal slv_HREADY    : std_logic_vector(SLAVES-1 downto 0);
  signal slv_HRESP     : std_logic_vector(SLAVES-1 downto 0);

  signal mst_misd_memory_priority : M_CORES_PER_MISD_2;

  signal mst_misd_memory_HSEL      : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_memory_HADDR     : M_CORES_PER_MISD_PLEN;
  signal mst_misd_memory_HWDATA    : M_CORES_PER_MISD_XLEN;
  signal mst_misd_memory_HRDATA    : M_CORES_PER_MISD_XLEN;
  signal mst_misd_memory_HWRITE    : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_memory_HSIZE     : M_CORES_PER_MISD_2;
  signal mst_misd_memory_HBURST    : M_CORES_PER_MISD_2;
  signal mst_misd_memory_HPROT     : M_CORES_PER_MISD_3;
  signal mst_misd_memory_HTRANS    : M_CORES_PER_MISD_1;
  signal mst_misd_memory_HMASTLOCK : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_memory_HREADY    : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_memory_HREADYOUT : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_memory_HRESP     : std_logic_vector(CORES_PER_MISD-1 downto 0);

  signal slv_misd_memory_addr_mask : M_CORES_PER_MISD_PLEN;
  signal slv_misd_memory_addr_base : M_CORES_PER_MISD_PLEN;
  signal slv_misd_memory_HSEL      : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal slv_misd_memory_HADDR     : M_CORES_PER_MISD_PLEN;
  signal slv_misd_memory_HWDATA    : M_CORES_PER_MISD_XLEN;
  signal slv_misd_memory_HRDATA    : M_CORES_PER_MISD_XLEN;
  signal slv_misd_memory_HWRITE    : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal slv_misd_memory_HSIZE     : M_CORES_PER_MISD_2;
  signal slv_misd_memory_HBURST    : M_CORES_PER_MISD_2;
  signal slv_misd_memory_HPROT     : M_CORES_PER_MISD_3;
  signal slv_misd_memory_HTRANS    : M_CORES_PER_MISD_1;
  signal slv_misd_memory_HMASTLOCK : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal slv_misd_memory_HREADY    : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal slv_misd_memory_HRESP     : std_logic_vector(CORES_PER_MISD-1 downto 0);

  signal mst_simd_memory_priority : M_CORES_PER_SIMD_2;

  signal mst_simd_memory_HSEL      : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_memory_HADDR     : M_CORES_PER_SIMD_PLEN;
  signal mst_simd_memory_HWDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_simd_memory_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_simd_memory_HWRITE    : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_memory_HSIZE     : M_CORES_PER_SIMD_2;
  signal mst_simd_memory_HBURST    : M_CORES_PER_SIMD_2;
  signal mst_simd_memory_HPROT     : M_CORES_PER_SIMD_3;
  signal mst_simd_memory_HTRANS    : M_CORES_PER_SIMD_1;
  signal mst_simd_memory_HMASTLOCK : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_memory_HREADY    : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_memory_HREADYOUT : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_memory_HRESP     : std_logic_vector(CORES_PER_SIMD-1 downto 0);

  signal slv_simd_memory_addr_mask : M_CORES_PER_SIMD_PLEN;
  signal slv_simd_memory_addr_base : M_CORES_PER_SIMD_PLEN;
  signal slv_simd_memory_HSEL      : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal slv_simd_memory_HADDR     : M_CORES_PER_SIMD_PLEN;
  signal slv_simd_memory_HWDATA    : M_CORES_PER_SIMD_XLEN;
  signal slv_simd_memory_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal slv_simd_memory_HWRITE    : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal slv_simd_memory_HSIZE     : M_CORES_PER_SIMD_2;
  signal slv_simd_memory_HBURST    : M_CORES_PER_SIMD_2;
  signal slv_simd_memory_HPROT     : M_CORES_PER_SIMD_3;
  signal slv_simd_memory_HTRANS    : M_CORES_PER_SIMD_1;
  signal slv_simd_memory_HMASTLOCK : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal slv_simd_memory_HREADY    : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal slv_simd_memory_HRESP     : std_logic_vector(CORES_PER_SIMD-1 downto 0);

  signal mst_sram_HSEL      : std_logic;
  signal mst_sram_HADDR     : std_logic_vector(PLEN-1 downto 0);
  signal mst_sram_HWDATA    : std_logic_vector(XLEN-1 downto 0);
  signal mst_sram_HRDATA    : std_logic_vector(XLEN-1 downto 0);
  signal mst_sram_HWRITE    : std_logic;
  signal mst_sram_HSIZE     : std_logic_vector(2 downto 0);
  signal mst_sram_HBURST    : std_logic_vector(2 downto 0);
  signal mst_sram_HPROT     : std_logic_vector(3 downto 0);
  signal mst_sram_HTRANS    : std_logic_vector(1 downto 0);
  signal mst_sram_HMASTLOCK : std_logic;
  signal mst_sram_HREADY    : std_logic;
  signal mst_sram_HREADYOUT : std_logic;
  signal mst_sram_HRESP     : std_logic;

  signal mst_misd_mram_HSEL      : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HADDR     : M_CORES_PER_MISD_PLEN;
  signal mst_misd_mram_HWDATA    : M_CORES_PER_MISD_XLEN;
  signal mst_misd_mram_HRDATA    : M_CORES_PER_MISD_XLEN;
  signal mst_misd_mram_HWRITE    : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HSIZE     : M_CORES_PER_MISD_2;
  signal mst_misd_mram_HBURST    : M_CORES_PER_MISD_2;
  signal mst_misd_mram_HPROT     : M_CORES_PER_MISD_3;
  signal mst_misd_mram_HTRANS    : M_CORES_PER_MISD_1;
  signal mst_misd_mram_HMASTLOCK : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HREADY    : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HREADYOUT : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal mst_misd_mram_HRESP     : std_logic_vector(CORES_PER_MISD-1 downto 0);

  signal mst_simd_mram_HSEL      : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HADDR     : M_CORES_PER_SIMD_PLEN;
  signal mst_simd_mram_HWDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_simd_mram_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_simd_mram_HWRITE    : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HSIZE     : M_CORES_PER_SIMD_2;
  signal mst_simd_mram_HBURST    : M_CORES_PER_SIMD_2;
  signal mst_simd_mram_HPROT     : M_CORES_PER_SIMD_3;
  signal mst_simd_mram_HTRANS    : M_CORES_PER_SIMD_1;
  signal mst_simd_mram_HMASTLOCK : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HREADY    : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HREADYOUT : std_logic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_simd_mram_HRESP     : std_logic_vector(CORES_PER_SIMD-1 downto 0);

  --GPIO Interface
  signal mst_gpio_HSEL      : std_logic;
  signal mst_gpio_HADDR     : std_logic_vector(PLEN-1 downto 0);
  signal mst_gpio_HWDATA    : std_logic_vector(XLEN-1 downto 0);
  signal mst_gpio_HRDATA    : std_logic_vector(XLEN-1 downto 0);
  signal mst_gpio_HWRITE    : std_logic;
  signal mst_gpio_HSIZE     : std_logic_vector(2 downto 0);
  signal mst_gpio_HBURST    : std_logic_vector(2 downto 0);
  signal mst_gpio_HPROT     : std_logic_vector(3 downto 0);
  signal mst_gpio_HTRANS    : std_logic_vector(1 downto 0);
  signal mst_gpio_HMASTLOCK : std_logic;
  signal mst_gpio_HREADY    : std_logic;
  signal mst_gpio_HREADYOUT : std_logic;
  signal mst_gpio_HRESP     : std_logic;

  signal gpio_PSEL    : std_logic;
  signal gpio_PENABLE : std_logic;
  signal gpio_PWRITE  : std_logic;
  signal gpio_PSTRB   : std_logic;
  signal gpio_PADDR   : std_logic_vector(PADDR_SIZE-1 downto 0);
  signal gpio_PWDATA  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_PRDATA  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_PREADY  : std_logic;
  signal gpio_PSLVERR : std_logic;

  signal gpio_i  : std_logic_vector(PADDR_SIZE-1 downto 0);
  signal gpio_o  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_oe : std_logic_vector(PDATA_SIZE-1 downto 0);

  --UART Interface
  signal mst_uart_HSEL      : std_logic;
  signal mst_uart_HADDR     : std_logic_vector(PLEN-1 downto 0);
  signal mst_uart_HWDATA    : std_logic_vector(XLEN-1 downto 0);
  signal mst_uart_HRDATA    : std_logic_vector(XLEN-1 downto 0);
  signal mst_uart_HWRITE    : std_logic;
  signal mst_uart_HSIZE     : std_logic_vector(2 downto 0);
  signal mst_uart_HBURST    : std_logic_vector(2 downto 0);
  signal mst_uart_HPROT     : std_logic_vector(3 downto 0);
  signal mst_uart_HTRANS    : std_logic_vector(1 downto 0);
  signal mst_uart_HMASTLOCK : std_logic;
  signal mst_uart_HREADY    : std_logic;
  signal mst_uart_HREADYOUT : std_logic;
  signal mst_uart_HRESP     : std_logic;

  signal uart_PADDR   : std_logic_vector(APB_ADDR_WIDTH-1 downto 0);
  signal uart_PWDATA  : std_logic_vector(APB_DATA_WIDTH-1 downto 0);
  signal uart_PWRITE  : std_logic;
  signal uart_PSEL    : std_logic;
  signal uart_PENABLE : std_logic;
  signal uart_PRDATA  : std_logic_vector(APB_DATA_WIDTH-1 downto 0);
  signal uart_PREADY  : std_logic;
  signal uart_PSLVERR : std_logic;

  signal uart_rx_i : std_logic;         -- Receiver input
  signal uart_tx_o : std_logic;         -- Transmitter output

  signal uart_event_o : std_logic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --DUT
  peripheral_ahb3_interface : mpsoc_msi_ahb3_interface
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

  peripheral_wb_interface : mpsoc_msi_wb_interface
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
      mst_HRDATA    => open,
      mst_HWRITE    => mst_HWRITE,
      mst_HSIZE     => mst_HSIZE,
      mst_HBURST    => mst_HBURST,
      mst_HPROT     => mst_HPROT,
      mst_HTRANS    => mst_HTRANS,
      mst_HMASTLOCK => mst_HMASTLOCK,
      mst_HREADYOUT => open,
      mst_HREADY    => mst_HREADY,
      mst_HRESP     => open,

      --Slave Ports; AHB Slaves connect to these
      --thus these are actually AHB Master Interfaces
      slv_addr_mask => slv_addr_mask,
      slv_addr_base => slv_addr_base,

      slv_HSEL      => open,
      slv_HADDR     => open,
      slv_HWDATA    => open,
      slv_HRDATA    => slv_HRDATA,
      slv_HWRITE    => open,
      slv_HSIZE     => open,
      slv_HBURST    => open,
      slv_HPROT     => open,
      slv_HTRANS    => open,
      slv_HMASTLOCK => open,
      slv_HREADYOUT => open,
      slv_HREADY    => slv_HREADY,
      slv_HRESP     => slv_HRESP
      );


  misd_memory_ahb3_interface : mpsoc_misd_memory_ahb3_interface
    generic map (
      PLEN           => PLEN,
      XLEN           => XLEN,
      CORES_PER_MISD => CORES_PER_MISD
      )
    port map (
      --Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      --Master Ports; AHB masters connect to these
      --thus these are actually AHB Slave Interfaces
      mst_priority => mst_misd_memory_priority,

      mst_HSEL      => mst_misd_memory_HSEL,
      mst_HADDR     => mst_misd_memory_HADDR,
      mst_HWDATA    => mst_misd_memory_HWDATA,
      mst_HRDATA    => mst_misd_memory_HRDATA,
      mst_HWRITE    => mst_misd_memory_HWRITE,
      mst_HSIZE     => mst_misd_memory_HSIZE,
      mst_HBURST    => mst_misd_memory_HBURST,
      mst_HPROT     => mst_misd_memory_HPROT,
      mst_HTRANS    => mst_misd_memory_HTRANS,
      mst_HMASTLOCK => mst_misd_memory_HMASTLOCK,
      mst_HREADYOUT => mst_misd_memory_HREADYOUT,
      mst_HREADY    => mst_misd_memory_HREADY,
      mst_HRESP     => mst_misd_memory_HRESP,

      --Slave Ports; AHB Slaves connect to these
      --thus these are actually AHB Master Interfaces
      slv_addr_mask => slv_misd_memory_addr_mask,
      slv_addr_base => slv_misd_memory_addr_base,

      slv_HSEL      => slv_misd_memory_HSEL,
      slv_HADDR     => slv_misd_memory_HADDR,
      slv_HWDATA    => slv_misd_memory_HWDATA,
      slv_HRDATA    => slv_misd_memory_HRDATA,
      slv_HWRITE    => slv_misd_memory_HWRITE,
      slv_HSIZE     => slv_misd_memory_HSIZE,
      slv_HBURST    => slv_misd_memory_HBURST,
      slv_HPROT     => slv_misd_memory_HPROT,
      slv_HTRANS    => slv_misd_memory_HTRANS,
      slv_HMASTLOCK => slv_misd_memory_HMASTLOCK,
      slv_HREADYOUT => open,
      slv_HREADY    => slv_misd_memory_HREADY,
      slv_HRESP     => slv_misd_memory_HRESP
      );
  misd_memory_wb_interface : mpsoc_misd_memory_wb_interface
    generic map (
      PLEN           => PLEN,
      XLEN           => XLEN,
      CORES_PER_MISD => CORES_PER_MISD
      )
    port map (
      --Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      --Master Ports; AHB masters connect to these
      --thus these are actually AHB Slave Interfaces
      mst_priority => mst_misd_memory_priority,

      mst_HSEL      => mst_misd_memory_HSEL,
      mst_HADDR     => mst_misd_memory_HADDR,
      mst_HWDATA    => mst_misd_memory_HWDATA,
      mst_HRDATA    => open,
      mst_HWRITE    => mst_misd_memory_HWRITE,
      mst_HSIZE     => mst_misd_memory_HSIZE,
      mst_HBURST    => mst_misd_memory_HBURST,
      mst_HPROT     => mst_misd_memory_HPROT,
      mst_HTRANS    => mst_misd_memory_HTRANS,
      mst_HMASTLOCK => mst_misd_memory_HMASTLOCK,
      mst_HREADYOUT => open,
      mst_HREADY    => mst_misd_memory_HREADY,
      mst_HRESP     => open,

      --Slave Ports; AHB Slaves connect to these
      --thus these are actually AHB Master Interfaces
      slv_addr_mask => slv_misd_memory_addr_mask,
      slv_addr_base => slv_misd_memory_addr_base,

      slv_HSEL      => open,
      slv_HADDR     => open,
      slv_HWDATA    => open,
      slv_HRDATA    => slv_misd_memory_HRDATA,
      slv_HWRITE    => open,
      slv_HSIZE     => open,
      slv_HBURST    => open,
      slv_HPROT     => open,
      slv_HTRANS    => open,
      slv_HMASTLOCK => open,
      slv_HREADYOUT => open,
      slv_HREADY    => slv_misd_memory_HREADY,
      slv_HRESP     => slv_misd_memory_HRESP
      );

  simd_memory_ahb3_interface : mpsoc_simd_memory_ahb3_interface
    generic map (
      PLEN           => PLEN,
      XLEN           => XLEN,
      CORES_PER_SIMD => CORES_PER_SIMD
      )
    port map (
      --Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      --Master Ports; AHB masters connect to these
      --thus these are actually AHB Slave Interfaces
      mst_priority => mst_simd_memory_priority,

      mst_HSEL      => mst_simd_memory_HSEL,
      mst_HADDR     => mst_simd_memory_HADDR,
      mst_HWDATA    => mst_simd_memory_HWDATA,
      mst_HRDATA    => mst_simd_memory_HRDATA,
      mst_HWRITE    => mst_simd_memory_HWRITE,
      mst_HSIZE     => mst_simd_memory_HSIZE,
      mst_HBURST    => mst_simd_memory_HBURST,
      mst_HPROT     => mst_simd_memory_HPROT,
      mst_HTRANS    => mst_simd_memory_HTRANS,
      mst_HMASTLOCK => mst_simd_memory_HMASTLOCK,
      mst_HREADYOUT => mst_simd_memory_HREADYOUT,
      mst_HREADY    => mst_simd_memory_HREADY,
      mst_HRESP     => mst_simd_memory_HRESP,

      --Slave Ports; AHB Slaves connect to these
      --thus these are actually AHB Master Interfaces
      slv_addr_mask => slv_simd_memory_addr_mask,
      slv_addr_base => slv_simd_memory_addr_base,

      slv_HSEL      => slv_simd_memory_HSEL,
      slv_HADDR     => slv_simd_memory_HADDR,
      slv_HWDATA    => slv_simd_memory_HWDATA,
      slv_HRDATA    => slv_simd_memory_HRDATA,
      slv_HWRITE    => slv_simd_memory_HWRITE,
      slv_HSIZE     => slv_simd_memory_HSIZE,
      slv_HBURST    => slv_simd_memory_HBURST,
      slv_HPROT     => slv_simd_memory_HPROT,
      slv_HTRANS    => slv_simd_memory_HTRANS,
      slv_HMASTLOCK => slv_simd_memory_HMASTLOCK,
      slv_HREADYOUT => open,
      slv_HREADY    => slv_simd_memory_HREADY,
      slv_HRESP     => slv_simd_memory_HRESP
      );

  simd_memory_wb_interface : mpsoc_simd_memory_wb_interface
    generic map (
      PLEN           => PLEN,
      XLEN           => XLEN,
      CORES_PER_SIMD => CORES_PER_SIMD
      )
    port map (
      --Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      --Master Ports; AHB masters connect to these
      --thus these are actually AHB Slave Interfaces
      mst_priority => mst_simd_memory_priority,

      mst_HSEL      => mst_simd_memory_HSEL,
      mst_HADDR     => mst_simd_memory_HADDR,
      mst_HWDATA    => mst_simd_memory_HWDATA,
      mst_HRDATA    => open,
      mst_HWRITE    => mst_simd_memory_HWRITE,
      mst_HSIZE     => mst_simd_memory_HSIZE,
      mst_HBURST    => mst_simd_memory_HBURST,
      mst_HPROT     => mst_simd_memory_HPROT,
      mst_HTRANS    => mst_simd_memory_HTRANS,
      mst_HMASTLOCK => mst_simd_memory_HMASTLOCK,
      mst_HREADYOUT => open,
      mst_HREADY    => mst_simd_memory_HREADY,
      mst_HRESP     => open,

      --Slave Ports; AHB Slaves connect to these
      --thus these are actually AHB Master Interfaces
      slv_addr_mask => slv_simd_memory_addr_mask,
      slv_addr_base => slv_simd_memory_addr_base,

      slv_HSEL      => open,
      slv_HADDR     => open,
      slv_HWDATA    => open,
      slv_HRDATA    => slv_simd_memory_HRDATA,
      slv_HWRITE    => open,
      slv_HSIZE     => open,
      slv_HBURST    => open,
      slv_HPROT     => open,
      slv_HTRANS    => open,
      slv_HMASTLOCK => open,
      slv_HREADYOUT => open,
      slv_HREADY    => slv_simd_memory_HREADY,
      slv_HRESP     => slv_simd_memory_HRESP
      );

  --Instantiate RISC-V GPIO
  gpio_ahb3_bridge : mpsoc_ahb3_peripheral_bridge
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

  gpio_wb_bridge : mpsoc_wb_peripheral_bridge
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
      HRDATA    => open,
      HWRITE    => mst_gpio_HWRITE,
      HSIZE     => mst_gpio_HSIZE,
      HBURST    => mst_gpio_HBURST,
      HPROT     => mst_gpio_HPROT,
      HTRANS    => mst_gpio_HTRANS,
      HMASTLOCK => mst_gpio_HMASTLOCK,
      HREADYOUT => open,
      HREADY    => mst_gpio_HREADY,
      HRESP     => open,

      --APB Master Interface
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => open,
      PENABLE => open,
      PPROT   => open,
      PWRITE  => open,
      PSTRB   => open,
      PADDR   => open,
      PWDATA  => open,
      PRDATA  => gpio_PRDATA,
      PREADY  => gpio_PREADY,
      PSLVERR => gpio_PSLVERR
      );

  gpio : mpsoc_apb_gpio
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

  --Instantiate RISC-V UART
  uart_ahb3_bridge : mpsoc_ahb3_peripheral_bridge
    generic map (
      HADDR_SIZE => PLEN,
      HDATA_SIZE => XLEN,
      PADDR_SIZE => APB_ADDR_WIDTH,
      PDATA_SIZE => APB_DATA_WIDTH,
      SYNC_DEPTH => SYNC_DEPTH
      )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_uart_HSEL,
      HADDR     => mst_uart_HADDR,
      HWDATA    => mst_uart_HWDATA,
      HRDATA    => mst_uart_HRDATA,
      HWRITE    => mst_uart_HWRITE,
      HSIZE     => mst_uart_HSIZE,
      HBURST    => mst_uart_HBURST,
      HPROT     => mst_uart_HPROT,
      HTRANS    => mst_uart_HTRANS,
      HMASTLOCK => mst_uart_HMASTLOCK,
      HREADYOUT => mst_uart_HREADYOUT,
      HREADY    => mst_uart_HREADY,
      HRESP     => mst_uart_HRESP,

      --APB Master Interface
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => uart_PSEL,
      PENABLE => uart_PENABLE,
      PPROT   => open,
      PWRITE  => uart_PWRITE,
      PSTRB   => open,
      PADDR   => uart_PADDR,
      PWDATA  => uart_PWDATA,
      PRDATA  => uart_PRDATA,
      PREADY  => uart_PREADY,
      PSLVERR => uart_PSLVERR
      );

  uart_wb_bridge : mpsoc_wb_peripheral_bridge
    generic map (
      HADDR_SIZE => PLEN,
      HDATA_SIZE => XLEN,
      PADDR_SIZE => APB_ADDR_WIDTH,
      PDATA_SIZE => APB_DATA_WIDTH,
      SYNC_DEPTH => SYNC_DEPTH
      )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_uart_HSEL,
      HADDR     => mst_uart_HADDR,
      HWDATA    => mst_uart_HWDATA,
      HRDATA    => open,
      HWRITE    => mst_uart_HWRITE,
      HSIZE     => mst_uart_HSIZE,
      HBURST    => mst_uart_HBURST,
      HPROT     => mst_uart_HPROT,
      HTRANS    => mst_uart_HTRANS,
      HMASTLOCK => mst_uart_HMASTLOCK,
      HREADYOUT => open,
      HREADY    => mst_uart_HREADY,
      HRESP     => open,

      --APB Master Interface
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => open,
      PENABLE => open,
      PPROT   => open,
      PWRITE  => open,
      PSTRB   => open,
      PADDR   => open,
      PWDATA  => open,
      PRDATA  => uart_PRDATA,
      PREADY  => uart_PREADY,
      PSLVERR => uart_PSLVERR
      );

  ahb3_uart : mpsoc_ahb3_uart
    generic map (
      APB_ADDR_WIDTH => APB_ADDR_WIDTH,
      APB_DATA_WIDTH => APB_DATA_WIDTH
      )
    port map (
      CLK     => HCLK,
      RSTN    => HRESETn,
      PADDR   => uart_PADDR,
      PWDATA  => uart_PWDATA,
      PWRITE  => uart_PWRITE,
      PSEL    => uart_PSEL,
      PENABLE => uart_PENABLE,
      PRDATA  => uart_PRDATA,
      PREADY  => uart_PREADY,
      PSLVERR => uart_PSLVERR,

      rx_i => uart_rx_i,
      tx_o => uart_tx_o,

      event_o => uart_event_o
      );

  wb_uart : mpsoc_wb_uart
    generic map (
      APB_ADDR_WIDTH => APB_ADDR_WIDTH,
      APB_DATA_WIDTH => APB_DATA_WIDTH
      )
    port map (
      CLK     => HCLK,
      RSTN    => HRESETn,
      PADDR   => uart_PADDR,
      PWDATA  => uart_PWDATA,
      PWRITE  => uart_PWRITE,
      PSEL    => uart_PSEL,
      PENABLE => uart_PENABLE,
      PRDATA  => open,
      PREADY  => open,
      PSLVERR => open,

      rx_i => uart_rx_i,
      tx_o => open,

      event_o => open
      );

  --Instantiate RISC-V RAM
  misd_ahb3_mpram : mpsoc_misd_ahb3_mpram
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

  misd_wb_mpram : mpsoc_misd_wb_mpram
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
      HRDATA    => open,
      HWRITE    => mst_misd_mram_HWRITE,
      HSIZE     => mst_misd_mram_HSIZE,
      HBURST    => mst_misd_mram_HBURST,
      HPROT     => mst_misd_mram_HPROT,
      HTRANS    => mst_misd_mram_HTRANS,
      HMASTLOCK => mst_misd_mram_HMASTLOCK,
      HREADYOUT => open,
      HREADY    => mst_misd_mram_HREADY,
      HRESP     => open
      );

  simd_ahb3_mpram : mpsoc_simd_ahb3_mpram
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

  simd_wb_mpram : mpsoc_simd_wb_mpram
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
      HRDATA    => open,
      HWRITE    => mst_simd_mram_HWRITE,
      HSIZE     => mst_simd_mram_HSIZE,
      HBURST    => mst_simd_mram_HBURST,
      HPROT     => mst_simd_mram_HPROT,
      HTRANS    => mst_simd_mram_HTRANS,
      HMASTLOCK => mst_simd_mram_HMASTLOCK,
      HREADYOUT => open,
      HREADY    => mst_simd_mram_HREADY,
      HRESP     => open
      );

  ahb3_spram : mpsoc_ahb3_spram
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

  wb_spram : mpsoc_wb_spram
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
      HRDATA    => open,
      HWRITE    => mst_sram_HWRITE,
      HSIZE     => mst_sram_HSIZE,
      HBURST    => mst_sram_HBURST,
      HPROT     => mst_sram_HPROT,
      HTRANS    => mst_sram_HTRANS,
      HMASTLOCK => mst_sram_HMASTLOCK,
      HREADYOUT => open,
      HREADY    => mst_sram_HREADY,
      HRESP     => open
      );
end RTL;
