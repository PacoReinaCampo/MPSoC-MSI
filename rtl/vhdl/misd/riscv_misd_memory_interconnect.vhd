-- Converted from rtl/vhdl/riscv_misd_memory_interconnect.sv
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
--              Master Slave Interconnect Top                                 //
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

entity riscv_misd_memory_interconnect is
  port (
    --Common signals
    HRESETn : in std_ulogic;
    HCLK    : in std_ulogic;

    --Master Ports; AHB masters connect to these
    -- thus these are actually AHB Slave Interfaces
    mst_priority : in M_CORES_PER_MISD_2;

    mst_HSEL      : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mst_HADDR     : in  M_CORES_PER_MISD_PLEN;
    mst_HWDATA    : in  M_CORES_PER_MISD_XLEN;
    mst_HRDATA    : out M_CORES_PER_MISD_XLEN;
    mst_HWRITE    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mst_HSIZE     : in  M_CORES_PER_MISD_2;
    mst_HBURST    : in  M_CORES_PER_MISD_2;
    mst_HPROT     : in  M_CORES_PER_MISD_3;
    mst_HTRANS    : in  M_CORES_PER_MISD_1;
    mst_HMASTLOCK : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mst_HREADYOUT : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mst_HREADY    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mst_HRESP     : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);

    --Slave Ports; AHB Slaves connect to these
    --  thus these are actually AHB Master Interfaces
    slv_addr_mask : in M_CORES_PER_MISD_PLEN;
    slv_addr_base : in M_CORES_PER_MISD_PLEN;

    slv_HSEL      : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    slv_HADDR     : out M_CORES_PER_MISD_PLEN;
    slv_HWDATA    : out M_CORES_PER_MISD_XLEN;
    slv_HRDATA    : in  M_CORES_PER_MISD_XLEN;
    slv_HWRITE    : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    slv_HSIZE     : out M_CORES_PER_MISD_2;
    slv_HBURST    : out M_CORES_PER_MISD_2;
    slv_HPROT     : out M_CORES_PER_MISD_3;
    slv_HTRANS    : out M_CORES_PER_MISD_1;
    slv_HMASTLOCK : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    slv_HREADYOUT : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
    slv_HREADY    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);  --combinatorial HREADY from all connected slaves
    slv_HRESP     : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0)
  );
end riscv_misd_memory_interconnect;

architecture RTL of riscv_misd_memory_interconnect is
  component riscv_misd_memory_master_port
    port (
      --Common signals
      HCLK    : in std_ulogic;
      HRESETn : in std_ulogic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      mst_priority : in std_ulogic_vector(2 downto 0);

      mst_HSEL      : in  std_ulogic;
      mst_HADDR     : in  std_ulogic_vector(PLEN-1 downto 0);
      mst_HWDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
      mst_HRDATA    : out std_ulogic_vector(XLEN-1 downto 0);
      mst_HWRITE    : in  std_ulogic;
      mst_HSIZE     : in  std_ulogic_vector(2 downto 0);
      mst_HBURST    : in  std_ulogic_vector(2 downto 0);
      mst_HPROT     : in  std_ulogic_vector(3 downto 0);
      mst_HTRANS    : in  std_ulogic_vector(1 downto 0);
      mst_HMASTLOCK : in  std_ulogic;
      mst_HREADYOUT : out std_ulogic;
      mst_HREADY    : in  std_ulogic;
      mst_HRESP     : out std_ulogic;

      --AHB Master Interfaces; send data to AHB slaves
      slvHADDRmask : in  M_CORES_PER_MISD_PLEN;
      slvHADDRbase : in  M_CORES_PER_MISD_PLEN;
      slvHSEL      : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      slvHADDR     : out std_ulogic_vector(PLEN-1 downto 0);
      slvHWDATA    : out std_ulogic_vector(XLEN-1 downto 0);
      slvHRDATA    : in  M_CORES_PER_MISD_XLEN;
      slvHWRITE    : out std_ulogic;
      slvHSIZE     : out std_ulogic_vector(2 downto 0);
      slvHBURST    : out std_ulogic_vector(2 downto 0);
      slvHPROT     : out std_ulogic_vector(3 downto 0);
      slvHTRANS    : out std_ulogic_vector(1 downto 0);
      slvHMASTLOCK : out std_ulogic;
      slvHREADY    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      slvHREADYOUT : out std_ulogic;
      slvHRESP     : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);

      --Internal signals
      can_switch     : out std_ulogic;
      slvpriority    : out std_ulogic_vector(2 downto 0);
      master_granted : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0)
    );
  end component;

  component riscv_misd_memory_slave_port
    port (
      HCLK    : in std_ulogic;
      HRESETn : in std_ulogic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters conect to these ports
      mstpriority  : in  M_CORES_PER_MISD_2;
      mstHSEL      : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      mstHADDR     : in  M_CORES_PER_MISD_PLEN;
      mstHWDATA    : in  M_CORES_PER_MISD_XLEN;
      mstHRDATA    : out std_ulogic_vector(XLEN-1 downto 0);
      mstHWRITE    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      mstHSIZE     : in  M_CORES_PER_MISD_2;
      mstHBURST    : in  M_CORES_PER_MISD_2;
      mstHPROT     : in  M_CORES_PER_MISD_3;
      mstHTRANS    : in  M_CORES_PER_MISD_1;
      mstHMASTLOCK : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      mstHREADY    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);  --HREADY input from master-bus
      mstHREADYOUT : out std_ulogic;    --HREADYOUT output to master-bus
      mstHRESP     : out std_ulogic;

      --AHB Master Interfaces (send data to AHB slaves)
      --AHB Slaves connect to these ports
      slv_HSEL      : out std_ulogic;
      slv_HADDR     : out std_ulogic_vector(PLEN-1 downto 0);
      slv_HWDATA    : out std_ulogic_vector(PLEN-1 downto 0);
      slv_HRDATA    : in  std_ulogic_vector(PLEN-1 downto 0);
      slv_HWRITE    : out std_ulogic;
      slv_HSIZE     : out std_ulogic_vector(2 downto 0);
      slv_HBURST    : out std_ulogic_vector(2 downto 0);
      slv_HPROT     : out std_ulogic_vector(3 downto 0);
      slv_HTRANS    : out std_ulogic_vector(1 downto 0);
      slv_HMASTLOCK : out std_ulogic;
      slv_HREADYOUT : out std_ulogic;
      slv_HREADY    : in  std_ulogic;
      slv_HRESP     : in  std_ulogic;

      can_switch     : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
      granted_master : out std_ulogic_vector(CORES_PER_MISD-1 downto 0)
    );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal frommstpriority   : M_CORES_PER_MISD_2;
  signal frommstHSEL       : M_CORES_PER_MISD_CORES_PER_MISD;
  signal frommstHADDR      : M_CORES_PER_MISD_PLEN;
  signal frommstHWDATA     : M_CORES_PER_MISD_XLEN;
  signal tomstHRDATA       : M_CORES_PER_MISD_CORES_PER_MISD_XLEN;
  signal frommstHWRITE     : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal frommstHSIZE      : M_CORES_PER_MISD_2;
  signal frommstHBURST     : M_CORES_PER_MISD_2;
  signal frommstHPROT      : M_CORES_PER_MISD_3;
  signal frommstHTRANS     : M_CORES_PER_MISD_1;
  signal frommstHMASTLOCK  : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal frommstHREADYOUT  : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal frommst_canswitch : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal tomstHREADY       : M_CORES_PER_MISD_CORES_PER_MISD;
  signal tomstHRESP        : M_CORES_PER_MISD_CORES_PER_MISD;
  signal tomstgrant        : M_CORES_PER_MISD_CORES_PER_MISD;

  signal toslvpriority    : M_CORES_PER_MISD_CORES_PER_MISD_2;
  signal toslvHSEL        : M_CORES_PER_MISD_CORES_PER_MISD;
  signal toslvHADDR       : M_CORES_PER_MISD_CORES_PER_MISD_PLEN;
  signal toslvHWDATA      : M_CORES_PER_MISD_CORES_PER_MISD_XLEN;
  signal fromslvHRDATA    : M_CORES_PER_MISD_XLEN;
  signal toslvHWRITE      : M_CORES_PER_MISD_CORES_PER_MISD;
  signal toslvHSIZE       : M_CORES_PER_MISD_CORES_PER_MISD_2;
  signal toslvHBURST      : M_CORES_PER_MISD_CORES_PER_MISD_2;
  signal toslvHPROT       : M_CORES_PER_MISD_CORES_PER_MISD_3;
  signal toslvHTRANS      : M_CORES_PER_MISD_CORES_PER_MISD_1;
  signal toslvHMASTLOCK   : M_CORES_PER_MISD_CORES_PER_MISD;
  signal toslvHREADY      : M_CORES_PER_MISD_CORES_PER_MISD;
  signal toslv_canswitch  : M_CORES_PER_MISD_CORES_PER_MISD;
  signal fromslvHREADYOUT : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal fromslvHRESP     : std_ulogic_vector(CORES_PER_MISD-1 downto 0);
  signal fromslvgrant     : M_CORES_PER_MISD_CORES_PER_MISD;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Hookup Master Interfaces
  generating_0 : for m in 0 to CORES_PER_MISD - 1 generate
    master_port : riscv_misd_memory_master_port
      port map (
        HRESETn => HRESETn,
        HCLK    => HCLK,

        --AHB Slave Interfaces (receive data from AHB Masters)
        --AHB Masters conect to these ports
        mst_priority  => mst_priority(m),
        mst_HSEL      => mst_HSEL(m),
        mst_HADDR     => mst_HADDR(m),
        mst_HWDATA    => mst_HWDATA(m),
        mst_HRDATA    => mst_HRDATA(m),
        mst_HWRITE    => mst_HWRITE(m),
        mst_HSIZE     => mst_HSIZE(m),
        mst_HBURST    => mst_HBURST(m),
        mst_HPROT     => mst_HPROT(m),
        mst_HTRANS    => mst_HTRANS(m),
        mst_HMASTLOCK => mst_HMASTLOCK(m),
        mst_HREADYOUT => mst_HREADYOUT(m),
        mst_HREADY    => mst_HREADY(m),
        mst_HRESP     => mst_HRESP(m),

        --AHB Master Interfaces (send data to AHB slaves)
        --AHB Slaves connect to these ports
        slvHADDRmask => slv_addr_mask,
        slvHADDRbase => slv_addr_base,
        slvpriority  => frommstpriority(m),
        slvHSEL      => frommstHSEL(m),
        slvHADDR     => frommstHADDR(m),
        slvHWDATA    => frommstHWDATA(m),
        slvHRDATA    => tomstHRDATA(m),
        slvHWRITE    => frommstHWRITE(m),
        slvHSIZE     => frommstHSIZE(m),
        slvHBURST    => frommstHBURST(m),
        slvHPROT     => frommstHPROT(m),
        slvHTRANS    => frommstHTRANS(m),
        slvHMASTLOCK => frommstHMASTLOCK(m),
        slvHREADY    => tomstHREADY(m),
        slvHREADYOUT => frommstHREADYOUT(m),
        slvHRESP     => tomstHRESP(m),

        can_switch     => frommst_canswitch(m),
        master_granted => tomstgrant(m)
      );
  end generate;

  --wire mangling

  --Master-->Slave
  generating_1 : for s in 0 to CORES_PER_MISD - 1 generate
    generating_2 : for m in 0 to CORES_PER_MISD - 1 generate
      toslvpriority(s)(m)   <= frommstpriority(m);
      toslvHSEL(s)(m)       <= frommstHSEL(m)(s);
      toslvHADDR(s)(m)      <= frommstHADDR(m);
      toslvHWDATA(s)(m)     <= frommstHWDATA(m);
      toslvHWRITE(s)(m)     <= frommstHWRITE(m);
      toslvHSIZE(s)(m)      <= frommstHSIZE(m);
      toslvHBURST(s)(m)     <= frommstHBURST(m);
      toslvHPROT(s)(m)      <= frommstHPROT(m);
      toslvHTRANS(s)(m)     <= frommstHTRANS(m);
      toslvHMASTLOCK(s)(m)  <= frommstHMASTLOCK(m);
      toslvHREADY(s)(m)     <= frommstHREADYOUT(m);  --feed Masters's HREADY signal to slave port
      toslv_canswitch(s)(m) <= frommst_canswitch(m);
    end generate;  --next m
  end generate;  --next s

  --wire mangling

  --Slave-->Master
  generating_3 : for m in 0 to CORES_PER_MISD - 1 generate
    generating_4 : for s in 0 to CORES_PER_MISD - 1 generate
      tomstgrant(m)(s)  <= fromslvgrant(s)(m);
      tomstHRDATA(m)(s) <= fromslvHRDATA(s);
      tomstHREADY(m)(s) <= fromslvHREADYOUT(s);
      tomstHRESP(m)(s)  <= fromslvHRESP(s);
    end generate;  --next m
  end generate;  --next s

  --Hookup Slave Interfaces
  generating_5 : for s in 0 to CORES_PER_MISD - 1 generate
    slave_port : riscv_misd_memory_slave_port
      port map (
        HRESETn => HRESETn,
        HCLK    => HCLK,

        --AHB Slave Interfaces (receive data from AHB Masters)
        --AHB Masters connect to these ports
        mstpriority  => toslvpriority(s),
        mstHSEL      => toslvHSEL(s),
        mstHADDR     => toslvHADDR(s),
        mstHWDATA    => toslvHWDATA(s),
        mstHRDATA    => fromslvHRDATA(s),
        mstHWRITE    => toslvHWRITE(s),
        mstHSIZE     => toslvHSIZE(s),
        mstHBURST    => toslvHBURST(s),
        mstHPROT     => toslvHPROT(s),
        mstHTRANS    => toslvHTRANS(s),
        mstHMASTLOCK => toslvHMASTLOCK(s),
        mstHREADY    => toslvHREADY(s),
        mstHREADYOUT => fromslvHREADYOUT(s),
        mstHRESP     => fromslvHRESP(s),

        --AHB Master Interfaces (send data to AHB slaves)
        --AHB Slaves connect to these ports
        slv_HSEL      => slv_HSEL(s),
        slv_HADDR     => slv_HADDR(s),
        slv_HWDATA    => slv_HWDATA(s),
        slv_HRDATA    => slv_HRDATA(s),
        slv_HWRITE    => slv_HWRITE(s),
        slv_HSIZE     => slv_HSIZE(s),
        slv_HBURST    => slv_HBURST(s),
        slv_HPROT     => slv_HPROT(s),
        slv_HTRANS    => slv_HTRANS(s),
        slv_HMASTLOCK => slv_HMASTLOCK(s),
        slv_HREADYOUT => slv_HREADYOUT(s),
        slv_HREADY    => slv_HREADY(s),
        slv_HRESP     => slv_HRESP(s),

        --Internal signals
        can_switch     => toslv_canswitch(s),
        granted_master => fromslvgrant(s)
      );
  end generate;
end RTL;
