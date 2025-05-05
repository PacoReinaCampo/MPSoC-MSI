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
--              Master Slave Interface Tesbench                               --
--              AMBA4 AHB-Lite Bus Interface                                  --
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
--   Paco Reina Campo <pacoreinacampo@queenfield.tech>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vhdl_pkg.all;
use work.peripheral_ahb4_pkg.all;

entity peripheral_msi_testbench is
end peripheral_msi_testbench;

architecture rtl of peripheral_msi_testbench is

  ------------------------------------------------------------------------------
  -- Components
  ------------------------------------------------------------------------------

  component peripheral_msi_interface_ahb4
    generic (
      PLEN    : integer := 64;
      XLEN    : integer := 64;
      MASTERS : integer := 5;
      SLAVES  : integer := 5
      );
    port (
      -- Common signals
      HRESETn : in std_logic;
      HCLK    : in std_logic;

      -- Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority : in std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);

      mst_HSEL      : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HADDR     : in  std_logic_matrix(MASTERS-1 downto 0)(PLEN-1 downto 0);
      mst_HWDATA    : in  std_logic_matrix(MASTERS-1 downto 0)(XLEN-1 downto 0);
      mst_HRDATA    : out std_logic_matrix(MASTERS-1 downto 0)(XLEN-1 downto 0);
      mst_HWRITE    : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HSIZE     : in  std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
      mst_HBURST    : in  std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
      mst_HPROT     : in  std_logic_matrix(MASTERS-1 downto 0)(3 downto 0);
      mst_HTRANS    : in  std_logic_matrix(MASTERS-1 downto 0)(1 downto 0);
      mst_HMASTLOCK : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HREADYOUT : out std_logic_vector(MASTERS-1 downto 0);
      mst_HREADY    : in  std_logic_vector(MASTERS-1 downto 0);
      mst_HRESP     : out std_logic_vector(MASTERS-1 downto 0);

      -- Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask : in std_logic_matrix(SLAVES-1 downto 0)(PLEN-1 downto 0);
      slv_addr_base : in std_logic_matrix(SLAVES-1 downto 0)(PLEN-1 downto 0);

      slv_HSEL      : out std_logic_vector(SLAVES-1 downto 0);
      slv_HADDR     : out std_logic_matrix(SLAVES-1 downto 0)(PLEN-1 downto 0);
      slv_HWDATA    : out std_logic_matrix(SLAVES-1 downto 0)(XLEN-1 downto 0);
      slv_HRDATA    : in  std_logic_matrix(SLAVES-1 downto 0)(XLEN-1 downto 0);
      slv_HWRITE    : out std_logic_vector(SLAVES-1 downto 0);
      slv_HSIZE     : out std_logic_matrix(SLAVES-1 downto 0)(2 downto 0);
      slv_HBURST    : out std_logic_matrix(SLAVES-1 downto 0)(2 downto 0);
      slv_HPROT     : out std_logic_matrix(SLAVES-1 downto 0)(3 downto 0);
      slv_HTRANS    : out std_logic_matrix(SLAVES-1 downto 0)(1 downto 0);
      slv_HMASTLOCK : out std_logic_vector(SLAVES-1 downto 0);
      slv_HREADYOUT : out std_logic_vector(SLAVES-1 downto 0);  -- HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_HREADY    : in  std_logic_vector(SLAVES-1 downto 0);  -- combinatorial HREADY from all connected slaves
      slv_HRESP     : in  std_logic_vector(SLAVES-1 downto 0)
      );
  end component;

  ------------------------------------------------------------------------------
  --  Constants
  ------------------------------------------------------------------------------

  constant PLEN : integer := 64;
  constant XLEN : integer := 64;

  constant MASTERS : integer := 3;
  constant SLAVES  : integer := 5;

  ------------------------------------------------------------------------------
  -- Variables
  ------------------------------------------------------------------------------

  -- Common signals
  signal HRESETn : std_logic;
  signal HCLK    : std_logic;

  -- AHB4 signals
  signal mst_priority : std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);

  signal mst_HSEL      : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HADDR     : std_logic_matrix(MASTERS-1 downto 0)(PLEN-1 downto 0);
  signal mst_HWDATA    : std_logic_matrix(MASTERS-1 downto 0)(XLEN-1 downto 0);
  signal mst_HRDATA    : std_logic_matrix(MASTERS-1 downto 0)(XLEN-1 downto 0);
  signal mst_HWRITE    : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HSIZE     : std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
  signal mst_HBURST    : std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
  signal mst_HPROT     : std_logic_matrix(MASTERS-1 downto 0)(3 downto 0);
  signal mst_HTRANS    : std_logic_matrix(MASTERS-1 downto 0)(1 downto 0);
  signal mst_HMASTLOCK : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HREADY    : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HREADYOUT : std_logic_vector(MASTERS-1 downto 0);
  signal mst_HRESP     : std_logic_vector(MASTERS-1 downto 0);

  signal slv_addr_mask : std_logic_matrix(SLAVES-1 downto 0)(PLEN-1 downto 0);
  signal slv_addr_base : std_logic_matrix(SLAVES-1 downto 0)(PLEN-1 downto 0);
  signal slv_HSEL      : std_logic_vector(SLAVES-1 downto 0);
  signal slv_HADDR     : std_logic_matrix(SLAVES-1 downto 0)(PLEN-1 downto 0);
  signal slv_HWDATA    : std_logic_matrix(SLAVES-1 downto 0)(XLEN-1 downto 0);
  signal slv_HRDATA    : std_logic_matrix(SLAVES-1 downto 0)(XLEN-1 downto 0);
  signal slv_HWRITE    : std_logic_vector(SLAVES-1 downto 0);
  signal slv_HSIZE     : std_logic_matrix(SLAVES-1 downto 0)(2 downto 0);
  signal slv_HBURST    : std_logic_matrix(SLAVES-1 downto 0)(2 downto 0);
  signal slv_HPROT     : std_logic_matrix(SLAVES-1 downto 0)(3 downto 0);
  signal slv_HTRANS    : std_logic_matrix(SLAVES-1 downto 0)(1 downto 0);
  signal slv_HMASTLOCK : std_logic_vector(SLAVES-1 downto 0);
  signal slv_HREADY    : std_logic_vector(SLAVES-1 downto 0);
  signal slv_HRESP     : std_logic_vector(SLAVES-1 downto 0);

begin
  ------------------------------------------------------------------------------
  -- Module Body
  ------------------------------------------------------------------------------

  -- DUT AHB4
  peripheral_interface_ahb4 : peripheral_msi_interface_ahb4
    generic map (
      PLEN    => PLEN,
      XLEN    => XLEN,
      MASTERS => MASTERS,
      SLAVES  => SLAVES
      )
    port map (
      -- Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      -- Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
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

      -- Slave Ports; AHB Slaves connect to these
      -- thus these are actually AHB Master Interfaces
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
end rtl;
