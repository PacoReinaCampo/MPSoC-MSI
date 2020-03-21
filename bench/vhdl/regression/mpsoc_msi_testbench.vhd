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

  component mpsoc_msi_wb_interface
    port (
      wb_clk_i        : in  std_logic;
      wb_rst_i        : in  std_logic;
      wb_or1k_d_adr_i : in  std_logic_vector(31 downto 0);
      wb_or1k_d_dat_i : in  std_logic_vector(31 downto 0);
      wb_or1k_d_sel_i : in  std_logic_vector(3 downto 0);
      wb_or1k_d_we_i  : in  std_logic;
      wb_or1k_d_cyc_i : in  std_logic;
      wb_or1k_d_stb_i : in  std_logic;
      wb_or1k_d_cti_i : in  std_logic_vector(2 downto 0);
      wb_or1k_d_bte_i : in  std_logic_vector(1 downto 0);
      wb_or1k_d_dat_o : out std_logic_vector(31 downto 0);
      wb_or1k_d_ack_o : out std_logic;
      wb_or1k_d_err_o : out std_logic;
      wb_or1k_d_rty_o : out std_logic;
      wb_or1k_i_adr_i : in  std_logic_vector(31 downto 0);
      wb_or1k_i_dat_i : in  std_logic_vector(31 downto 0);
      wb_or1k_i_sel_i : in  std_logic_vector(3 downto 0);
      wb_or1k_i_we_i  : in  std_logic;
      wb_or1k_i_cyc_i : in  std_logic;
      wb_or1k_i_stb_i : in  std_logic;
      wb_or1k_i_cti_i : in  std_logic_vector(2 downto 0);
      wb_or1k_i_bte_i : in  std_logic_vector(1 downto 0);
      wb_or1k_i_dat_o : out std_logic_vector(31 downto 0);
      wb_or1k_i_ack_o : out std_logic;
      wb_or1k_i_err_o : out std_logic;
      wb_or1k_i_rty_o : out std_logic;
      wb_dbg_adr_i    : in  std_logic_vector(31 downto 0);
      wb_dbg_dat_i    : in  std_logic_vector(31 downto 0);
      wb_dbg_sel_i    : in  std_logic_vector(3 downto 0);
      wb_dbg_we_i     : in  std_logic;
      wb_dbg_cyc_i    : in  std_logic;
      wb_dbg_stb_i    : in  std_logic;
      wb_dbg_cti_i    : in  std_logic_vector(2 downto 0);
      wb_dbg_bte_i    : in  std_logic_vector(1 downto 0);
      wb_dbg_dat_o    : out std_logic_vector(31 downto 0);
      wb_dbg_ack_o    : out std_logic;
      wb_dbg_err_o    : out std_logic;
      wb_dbg_rty_o    : out std_logic;
      wb_mem_adr_o    : out std_logic_vector(31 downto 0);
      wb_mem_dat_o    : out std_logic_vector(31 downto 0);
      wb_mem_sel_o    : out std_logic_vector(3 downto 0);
      wb_mem_we_o     : out std_logic;
      wb_mem_cyc_o    : out std_logic;
      wb_mem_stb_o    : out std_logic;
      wb_mem_cti_o    : out std_logic_vector(2 downto 0);
      wb_mem_bte_o    : out std_logic_vector(1 downto 0);
      wb_mem_dat_i    : in  std_logic_vector(31 downto 0);
      wb_mem_ack_i    : in  std_logic;
      wb_mem_err_i    : in  std_logic;
      wb_mem_rty_i    : in  std_logic;
      wb_uart_adr_o   : out std_logic_vector(31 downto 0);
      wb_uart_dat_o   : out std_logic_vector(7 downto 0);
      wb_uart_sel_o   : out std_logic_vector(3 downto 0);
      wb_uart_we_o    : out std_logic;
      wb_uart_cyc_o   : out std_logic;
      wb_uart_stb_o   : out std_logic;
      wb_uart_cti_o   : out std_logic_vector(2 downto 0);
      wb_uart_bte_o   : out std_logic_vector(1 downto 0);
      wb_uart_dat_i   : in  std_logic_vector(7 downto 0);
      wb_uart_ack_i   : in  std_logic;
      wb_uart_err_i   : in  std_logic;
      wb_uart_rty_i   : in  std_logic
      );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Common signals
  signal HRESETn : std_logic;
  signal HCLK    : std_logic;

  --AHB3 signals
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

  --WB signals
  signal wb_or1k_d_adr_i : std_logic_vector(31 downto 0);
  signal wb_or1k_d_dat_i : std_logic_vector(31 downto 0);
  signal wb_or1k_d_sel_i : std_logic_vector(3 downto 0);
  signal wb_or1k_d_we_i  : std_logic;
  signal wb_or1k_d_cyc_i : std_logic;
  signal wb_or1k_d_stb_i : std_logic;
  signal wb_or1k_d_cti_i : std_logic_vector(2 downto 0);
  signal wb_or1k_d_bte_i : std_logic_vector(1 downto 0);
  signal wb_or1k_d_dat_o : std_logic_vector(31 downto 0);
  signal wb_or1k_d_ack_o : std_logic;
  signal wb_or1k_d_err_o : std_logic;
  signal wb_or1k_d_rty_o : std_logic;
  signal wb_or1k_i_adr_i : std_logic_vector(31 downto 0);
  signal wb_or1k_i_dat_i : std_logic_vector(31 downto 0);
  signal wb_or1k_i_sel_i : std_logic_vector(3 downto 0);
  signal wb_or1k_i_we_i  : std_logic;
  signal wb_or1k_i_cyc_i : std_logic;
  signal wb_or1k_i_stb_i : std_logic;
  signal wb_or1k_i_cti_i : std_logic_vector(2 downto 0);
  signal wb_or1k_i_bte_i : std_logic_vector(1 downto 0);
  signal wb_or1k_i_dat_o : std_logic_vector(31 downto 0);
  signal wb_or1k_i_ack_o : std_logic;
  signal wb_or1k_i_err_o : std_logic;
  signal wb_or1k_i_rty_o : std_logic;
  signal wb_dbg_adr_i    : std_logic_vector(31 downto 0);
  signal wb_dbg_dat_i    : std_logic_vector(31 downto 0);
  signal wb_dbg_sel_i    : std_logic_vector(3 downto 0);
  signal wb_dbg_we_i     : std_logic;
  signal wb_dbg_cyc_i    : std_logic;
  signal wb_dbg_stb_i    : std_logic;
  signal wb_dbg_cti_i    : std_logic_vector(2 downto 0);
  signal wb_dbg_bte_i    : std_logic_vector(1 downto 0);
  signal wb_dbg_dat_o    : std_logic_vector(31 downto 0);
  signal wb_dbg_ack_o    : std_logic;
  signal wb_dbg_err_o    : std_logic;
  signal wb_dbg_rty_o    : std_logic;
  signal wb_mem_adr_o    : std_logic_vector(31 downto 0);
  signal wb_mem_dat_o    : std_logic_vector(31 downto 0);
  signal wb_mem_sel_o    : std_logic_vector(3 downto 0);
  signal wb_mem_we_o     : std_logic;
  signal wb_mem_cyc_o    : std_logic;
  signal wb_mem_stb_o    : std_logic;
  signal wb_mem_cti_o    : std_logic_vector(2 downto 0);
  signal wb_mem_bte_o    : std_logic_vector(1 downto 0);
  signal wb_mem_dat_i    : std_logic_vector(31 downto 0);
  signal wb_mem_ack_i    : std_logic;
  signal wb_mem_err_i    : std_logic;
  signal wb_mem_rty_i    : std_logic;
  signal wb_uart_adr_o   : std_logic_vector(31 downto 0);
  signal wb_uart_dat_o   : std_logic_vector(7 downto 0);
  signal wb_uart_sel_o   : std_logic_vector(3 downto 0);
  signal wb_uart_we_o    : std_logic;
  signal wb_uart_cyc_o   : std_logic;
  signal wb_uart_stb_o   : std_logic;
  signal wb_uart_cti_o   : std_logic_vector(2 downto 0);
  signal wb_uart_bte_o   : std_logic_vector(1 downto 0);
  signal wb_uart_dat_i   : std_logic_vector(7 downto 0);
  signal wb_uart_ack_i   : std_logic;
  signal wb_uart_err_i   : std_logic;
  signal wb_uart_rty_i   : std_logic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --DUT AHB3
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

  --DUT WB
  msi_wb_interface : mpsoc_msi_wb_interface
    port map (
      wb_clk_i => HRESETn,
      wb_rst_i => HCLK,

      wb_or1k_d_adr_i => wb_or1k_d_adr_i,
      wb_or1k_d_dat_i => wb_or1k_d_dat_i,
      wb_or1k_d_sel_i => wb_or1k_d_sel_i,
      wb_or1k_d_we_i  => wb_or1k_d_we_i,
      wb_or1k_d_cyc_i => wb_or1k_d_cyc_i,
      wb_or1k_d_stb_i => wb_or1k_d_stb_i,
      wb_or1k_d_cti_i => wb_or1k_d_cti_i,
      wb_or1k_d_bte_i => wb_or1k_d_bte_i,
      wb_or1k_d_dat_o => wb_or1k_d_dat_o,
      wb_or1k_d_ack_o => wb_or1k_d_ack_o,
      wb_or1k_d_err_o => wb_or1k_d_err_o,
      wb_or1k_d_rty_o => wb_or1k_d_rty_o,
      wb_or1k_i_adr_i => wb_or1k_i_adr_i,
      wb_or1k_i_dat_i => wb_or1k_i_dat_i,
      wb_or1k_i_sel_i => wb_or1k_i_sel_i,
      wb_or1k_i_we_i  => wb_or1k_i_we_i,
      wb_or1k_i_cyc_i => wb_or1k_i_cyc_i,
      wb_or1k_i_stb_i => wb_or1k_i_stb_i,
      wb_or1k_i_cti_i => wb_or1k_i_cti_i,
      wb_or1k_i_bte_i => wb_or1k_i_bte_i,
      wb_or1k_i_dat_o => wb_or1k_i_dat_o,
      wb_or1k_i_ack_o => wb_or1k_i_ack_o,
      wb_or1k_i_err_o => wb_or1k_i_err_o,
      wb_or1k_i_rty_o => wb_or1k_i_rty_o,
      wb_dbg_adr_i    => wb_dbg_adr_i,
      wb_dbg_dat_i    => wb_dbg_dat_i,
      wb_dbg_sel_i    => wb_dbg_sel_i,
      wb_dbg_we_i     => wb_dbg_we_i,
      wb_dbg_cyc_i    => wb_dbg_cyc_i,
      wb_dbg_stb_i    => wb_dbg_stb_i,
      wb_dbg_cti_i    => wb_dbg_cti_i,
      wb_dbg_bte_i    => wb_dbg_bte_i,
      wb_dbg_dat_o    => wb_dbg_dat_o,
      wb_dbg_ack_o    => wb_dbg_ack_o,
      wb_dbg_err_o    => wb_dbg_err_o,
      wb_dbg_rty_o    => wb_dbg_rty_o,
      wb_mem_adr_o    => wb_mem_adr_o,
      wb_mem_dat_o    => wb_mem_dat_o,
      wb_mem_sel_o    => wb_mem_sel_o,
      wb_mem_we_o     => wb_mem_we_o,
      wb_mem_cyc_o    => wb_mem_cyc_o,
      wb_mem_stb_o    => wb_mem_stb_o,
      wb_mem_cti_o    => wb_mem_cti_o,
      wb_mem_bte_o    => wb_mem_bte_o,
      wb_mem_dat_i    => wb_mem_dat_i,
      wb_mem_ack_i    => wb_mem_ack_i,
      wb_mem_err_i    => wb_mem_err_i,
      wb_mem_rty_i    => wb_mem_rty_i,
      wb_uart_adr_o   => wb_uart_adr_o,
      wb_uart_dat_o   => wb_uart_dat_o,
      wb_uart_sel_o   => wb_uart_sel_o,
      wb_uart_we_o    => wb_uart_we_o,
      wb_uart_cyc_o   => wb_uart_cyc_o,
      wb_uart_stb_o   => wb_uart_stb_o,
      wb_uart_cti_o   => wb_uart_cti_o,
      wb_uart_bte_o   => wb_uart_bte_o,
      wb_uart_dat_i   => wb_uart_dat_i,
      wb_uart_ack_i   => wb_uart_ack_i,
      wb_uart_err_i   => wb_uart_err_i,
      wb_uart_rty_i   => wb_uart_rty_i
      );
end RTL;
