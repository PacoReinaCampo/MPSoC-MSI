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
--              Master Slave Interface Top                                    --
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
use work.peripheral_biu_pkg.all;

entity peripheral_msi_interface_tl is
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
end peripheral_msi_interface_tl;

architecture rtl of peripheral_msi_interface_tl is

  ------------------------------------------------------------------------------
  -- Components
  ------------------------------------------------------------------------------

  component peripheral_msi_master_port_tl
    generic (
      PLEN    : integer := 64;
      XLEN    : integer := 64;
      MASTERS : integer := 5;
      SLAVES  : integer := 5
      );
    port (
      -- Common signals
      HCLK    : in std_logic;
      HRESETn : in std_logic;

      -- AHB Slave Interfaces (receive data from AHB Masters)
      -- AHB Masters connect to these ports
      mst_priority : in std_logic_vector(2 downto 0);

      mst_HSEL      : in  std_logic;
      mst_HADDR     : in  std_logic_vector(PLEN-1 downto 0);
      mst_HWDATA    : in  std_logic_vector(XLEN-1 downto 0);
      mst_HRDATA    : out std_logic_vector(XLEN-1 downto 0);
      mst_HWRITE    : in  std_logic;
      mst_HSIZE     : in  std_logic_vector(2 downto 0);
      mst_HBURST    : in  std_logic_vector(2 downto 0);
      mst_HPROT     : in  std_logic_vector(3 downto 0);
      mst_HTRANS    : in  std_logic_vector(1 downto 0);
      mst_HMASTLOCK : in  std_logic;
      mst_HREADYOUT : out std_logic;
      mst_HREADY    : in  std_logic;
      mst_HRESP     : out std_logic;

      -- AHB Master Interfaces; send data to AHB slaves
      slvHADDRmask : in  std_logic_matrix(SLAVES-1 downto 0)(PLEN-1 downto 0);
      slvHADDRbase : in  std_logic_matrix(SLAVES-1 downto 0)(PLEN-1 downto 0);
      slvHSEL      : out std_logic_vector(SLAVES-1 downto 0);
      slvHADDR     : out std_logic_vector(PLEN-1 downto 0);
      slvHWDATA    : out std_logic_vector(XLEN-1 downto 0);
      slvHRDATA    : in  std_logic_matrix(SLAVES-1 downto 0)(XLEN-1 downto 0);
      slvHWRITE    : out std_logic;
      slvHSIZE     : out std_logic_vector(2 downto 0);
      slvHBURST    : out std_logic_vector(2 downto 0);
      slvHPROT     : out std_logic_vector(3 downto 0);
      slvHTRANS    : out std_logic_vector(1 downto 0);
      slvHMASTLOCK : out std_logic;
      slvHREADY    : in  std_logic_vector(SLAVES-1 downto 0);
      slvHREADYOUT : out std_logic;
      slvHRESP     : in  std_logic_vector(SLAVES-1 downto 0);

      -- Internal signals
      can_switch     : out std_logic;
      slvpriority    : out std_logic_vector(2 downto 0);
      master_granted : in  std_logic_vector(SLAVES-1 downto 0)
      );
  end component;

  component peripheral_msi_slave_port_tl
    generic (
      PLEN    : integer := 64;
      XLEN    : integer := 64;
      MASTERS : integer := 5;
      SLAVES  : integer := 5
      );
    port (
      HCLK    : in std_logic;
      HRESETn : in std_logic;

      -- AHB Slave Interfaces (receive data from AHB Masters)
      -- AHB Masters conect to these ports
      mstpriority  : in  std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
      mstHSEL      : in  std_logic_vector(MASTERS-1 downto 0);
      mstHADDR     : in  std_logic_matrix(MASTERS-1 downto 0)(PLEN-1 downto 0);
      mstHWDATA    : in  std_logic_matrix(MASTERS-1 downto 0)(XLEN-1 downto 0);
      mstHRDATA    : out std_logic_vector(XLEN-1 downto 0);
      mstHWRITE    : in  std_logic_vector(MASTERS-1 downto 0);
      mstHSIZE     : in  std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
      mstHBURST    : in  std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
      mstHPROT     : in  std_logic_matrix(MASTERS-1 downto 0)(3 downto 0);
      mstHTRANS    : in  std_logic_matrix(MASTERS-1 downto 0)(1 downto 0);
      mstHMASTLOCK : in  std_logic_vector(MASTERS-1 downto 0);
      mstHREADY    : in  std_logic_vector(MASTERS-1 downto 0);  -- HREADY input from master-bus
      mstHREADYOUT : out std_logic;     -- HREADYOUT output to master-bus
      mstHRESP     : out std_logic;

      -- AHB Master Interfaces (send data to AHB slaves)
      -- AHB Slaves connect to these ports
      slv_HSEL      : out std_logic;
      slv_HADDR     : out std_logic_vector(PLEN-1 downto 0);
      slv_HWDATA    : out std_logic_vector(PLEN-1 downto 0);
      slv_HRDATA    : in  std_logic_vector(PLEN-1 downto 0);
      slv_HWRITE    : out std_logic;
      slv_HSIZE     : out std_logic_vector(2 downto 0);
      slv_HBURST    : out std_logic_vector(2 downto 0);
      slv_HPROT     : out std_logic_vector(3 downto 0);
      slv_HTRANS    : out std_logic_vector(1 downto 0);
      slv_HMASTLOCK : out std_logic;
      slv_HREADYOUT : out std_logic;
      slv_HREADY    : in  std_logic;
      slv_HRESP     : in  std_logic;

      can_switch     : in  std_logic_vector(MASTERS-1 downto 0);
      granted_master : out std_logic_vector(MASTERS-1 downto 0)
      );
  end component;

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Variables
  ------------------------------------------------------------------------------
  signal frommstpriority   : std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
  signal frommstHSEL       : std_logic_matrix(MASTERS-1 downto 0)(SLAVES-1 downto 0);
  signal frommstHADDR      : std_logic_matrix(MASTERS-1 downto 0)(PLEN-1 downto 0);
  signal frommstHWDATA     : std_logic_matrix(MASTERS-1 downto 0)(XLEN-1 downto 0);
  signal tomstHRDATA       : std_logic_3array(MASTERS-1 downto 0)(SLAVES-1 downto 0)(XLEN-1 downto 0);
  signal frommstHWRITE     : std_logic_vector(MASTERS-1 downto 0);
  signal frommstHSIZE      : std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
  signal frommstHBURST     : std_logic_matrix(MASTERS-1 downto 0)(2 downto 0);
  signal frommstHPROT      : std_logic_matrix(MASTERS-1 downto 0)(3 downto 0);
  signal frommstHTRANS     : std_logic_matrix(MASTERS-1 downto 0)(1 downto 0);
  signal frommstHMASTLOCK  : std_logic_vector(MASTERS-1 downto 0);
  signal frommstHREADYOUT  : std_logic_vector(MASTERS-1 downto 0);
  signal frommst_canswitch : std_logic_vector(MASTERS-1 downto 0);
  signal tomstHREADY       : std_logic_matrix(MASTERS-1 downto 0)(SLAVES-1 downto 0);
  signal tomstHRESP        : std_logic_matrix(MASTERS-1 downto 0)(SLAVES-1 downto 0);
  signal tomstgrant        : std_logic_matrix(MASTERS-1 downto 0)(SLAVES-1 downto 0);

  signal toslvpriority    : std_logic_3array(SLAVES-1 downto 0)(MASTERS-1 downto 0)(2 downto 0);
  signal toslvHSEL        : std_logic_matrix(SLAVES-1 downto 0)(MASTERS-1 downto 0);
  signal toslvHADDR       : std_logic_3array(SLAVES-1 downto 0)(MASTERS-1 downto 0)(PLEN-1 downto 0);
  signal toslvHWDATA      : std_logic_3array(SLAVES-1 downto 0)(MASTERS-1 downto 0)(XLEN-1 downto 0);
  signal fromslvHRDATA    : std_logic_matrix(SLAVES-1 downto 0)(XLEN-1 downto 0);
  signal toslvHWRITE      : std_logic_matrix(SLAVES-1 downto 0)(MASTERS-1 downto 0);
  signal toslvHSIZE       : std_logic_3array(SLAVES-1 downto 0)(MASTERS-1 downto 0)(2 downto 0);
  signal toslvHBURST      : std_logic_3array(SLAVES-1 downto 0)(MASTERS-1 downto 0)(2 downto 0);
  signal toslvHPROT       : std_logic_3array(SLAVES-1 downto 0)(MASTERS-1 downto 0)(3 downto 0);
  signal toslvHTRANS      : std_logic_3array(SLAVES-1 downto 0)(MASTERS-1 downto 0)(1 downto 0);
  signal toslvHMASTLOCK   : std_logic_matrix(SLAVES-1 downto 0)(MASTERS-1 downto 0);
  signal toslvHREADY      : std_logic_matrix(SLAVES-1 downto 0)(MASTERS-1 downto 0);
  signal toslv_canswitch  : std_logic_matrix(SLAVES-1 downto 0)(MASTERS-1 downto 0);
  signal fromslvHREADYOUT : std_logic_vector(SLAVES-1 downto 0);
  signal fromslvHRESP     : std_logic_vector(SLAVES-1 downto 0);
  signal fromslvgrant     : std_logic_matrix(SLAVES-1 downto 0)(MASTERS-1 downto 0);

begin
  ------------------------------------------------------------------------------
  -- Module Body
  ------------------------------------------------------------------------------

  -- Hookup Master Interfaces
  generating_0 : for m in 0 to MASTERS - 1 generate
    master_port : peripheral_msi_master_port_tl
      generic map (
        PLEN    => PLEN,
        XLEN    => XLEN,
        MASTERS => MASTERS,
        SLAVES  => SLAVES
        )
      port map (
        HRESETn => HRESETn,
        HCLK    => HCLK,

        -- AHB Slave Interfaces (receive data from AHB Masters)
        -- AHB Masters conect to these ports
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

        -- AHB Master Interfaces (send data to AHB slaves)
        -- AHB Slaves connect to these ports
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

  -- wire mangling

  -- Master-->Slave
  generating_1 : for s in 0 to SLAVES - 1 generate
    generating_2 : for m in 0 to MASTERS - 1 generate
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
      toslvHREADY(s)(m)     <= frommstHREADYOUT(m);  -- feed Masters's HREADY signal to slave port
      toslv_canswitch(s)(m) <= frommst_canswitch(m);
    end generate;  -- next m
  end generate;  -- next s

  -- wire mangling

  -- Slave-->Master
  generating_3 : for m in 0 to MASTERS - 1 generate
    generating_4 : for s in 0 to SLAVES - 1 generate
      tomstgrant(m)(s)  <= fromslvgrant(s)(m);
      tomstHRDATA(m)(s) <= fromslvHRDATA(s);
      tomstHREADY(m)(s) <= fromslvHREADYOUT(s);
      tomstHRESP(m)(s)  <= fromslvHRESP(s);
    end generate;  -- next m
  end generate;  -- next s

  -- Hookup Slave Interfaces
  generating_5 : for s in 0 to SLAVES - 1 generate
    slave_port : peripheral_msi_slave_port_tl
      generic map (
        PLEN    => PLEN,
        XLEN    => XLEN,
        MASTERS => MASTERS,
        SLAVES  => SLAVES
        )
      port map (
        HRESETn => HRESETn,
        HCLK    => HCLK,

        -- AHB Slave Interfaces (receive data from AHB Masters)
        -- AHB Masters connect to these ports
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

        -- AHB Master Interfaces (send data to AHB slaves)
        -- AHB Slaves connect to these ports
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

        -- Internal signals
        can_switch     => toslv_canswitch(s),
        granted_master => fromslvgrant(s)
        );
  end generate;
end rtl;
