-- Converted from rtl/vhdl/mpsoc_misd_memory_ahb3_master_port.sv
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
--              Master Slave Interface Master Port                            //
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

use work.mpsoc_pkg.all;

entity mpsoc_misd_memory_ahb3_master_port is
  generic (
    PLEN           : integer := 64;
    XLEN           : integer := 64;
    CORES_PER_MISD : integer := 8
  );
  port (
    --Common signals
    HCLK    : in std_logic;
    HRESETn : in std_logic;

    --AHB Slave Interfaces (receive data from AHB Masters)
    --AHB Masters connect to these ports
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

    --AHB Master Interfaces; send data to AHB slaves
    slvHADDRmask : in  M_CORES_PER_MISD_PLEN;
    slvHADDRbase : in  M_CORES_PER_MISD_PLEN;
    slvHSEL      : out std_logic_vector(CORES_PER_MISD-1 downto 0);
    slvHADDR     : out std_logic_vector(PLEN-1 downto 0);
    slvHWDATA    : out std_logic_vector(XLEN-1 downto 0);
    slvHRDATA    : in  M_CORES_PER_MISD_XLEN;
    slvHWRITE    : out std_logic;
    slvHSIZE     : out std_logic_vector(2 downto 0);
    slvHBURST    : out std_logic_vector(2 downto 0);
    slvHPROT     : out std_logic_vector(3 downto 0);
    slvHTRANS    : out std_logic_vector(1 downto 0);
    slvHMASTLOCK : out std_logic;
    slvHREADY    : in  std_logic_vector(CORES_PER_MISD-1 downto 0);
    slvHREADYOUT : out std_logic;
    slvHRESP     : in  std_logic_vector(CORES_PER_MISD-1 downto 0);

    --Internal signals
    can_switch     : out std_logic;
    slvpriority    : out std_logic_vector(2 downto 0);
    master_granted : in  std_logic_vector(CORES_PER_MISD-1 downto 0)
    );
end mpsoc_misd_memory_ahb3_master_port;

architecture RTL of mpsoc_misd_memory_ahb3_master_port is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant CORES_PER_MISD_BITS : integer := integer(log2(real(CORES_PER_MISD)));

  constant NO_ACCESS      : std_logic_vector(1 downto 0) := "00";
  constant ACCESS_PENDING : std_logic_vector(1 downto 0) := "01";
  constant ACCESS_GRANTED : std_logic_vector(1 downto 0) := "10";

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal access_state : std_logic_vector(1 downto 0);

  signal no_access_s      : std_logic;
  signal access_pending_s : std_logic;
  signal access_granted_s : std_logic;

  signal current_HSEL : std_logic_vector(CORES_PER_MISD-1 downto 0);
  signal pending_HSEL : std_logic_vector(CORES_PER_MISD-1 downto 0);

  signal local_HREADYOUT : std_logic;

  signal mux_sel : std_logic;

  signal slave_sel  : std_logic_vector(CORES_PER_MISD_BITS-1 downto 0);
  signal slaves2int : std_logic_vector(CORES_PER_MISD_BITS-1 downto 0);

  signal burst_cnt : std_logic_vector(3 downto 0);

  signal regpriority  : std_logic_vector(2 downto 0);
  signal regHADDR     : std_logic_vector(PLEN-1 downto 0);
  signal regHWDATA    : std_logic_vector(XLEN-1 downto 0);
  signal regHTRANS    : std_logic_vector(1 downto 0);
  signal regHWRITE    : std_logic;
  signal regHSIZE     : std_logic_vector(2 downto 0);
  signal regHBURST    : std_logic_vector(2 downto 0);
  signal regHPROT     : std_logic_vector(3 downto 0);
  signal regHMASTLOCK : std_logic;

  signal slvHSEL_sgn : std_logic_vector(CORES_PER_MISD-1 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Tasks
  --

  --//////////////////////////////////////////////////////////////
  --
  -- functions
  --
  function reduce_nor (
    reduce_nor_in : std_logic_vector
    ) return std_logic is
    variable reduce_nor_out : std_logic := '0';
  begin
    for i in reduce_nor_in'range loop
      reduce_nor_out := reduce_nor_out nor reduce_nor_in(i);
    end loop;
    return reduce_nor_out;
  end reduce_nor;

  function reduce_or (
    reduce_or_in : std_logic_vector
    ) return std_logic is
    variable reduce_or_out : std_logic := '0';
  begin
    for i in reduce_or_in'range loop
      reduce_or_out := reduce_or_out or reduce_or_in(i);
    end loop;
    return reduce_or_out;
  end reduce_or;

  function to_stdlogic (
    input : boolean
    ) return std_logic is
  begin
    if input then
      return('1');
    else
      return('0');
    end if;
  end function to_stdlogic;

  function onehot2int (
    onehot : std_logic_vector(CORES_PER_MISD-1 downto 0)
    ) return integer is
    variable onehot2int_return : integer := -1;

    variable onehot_return : std_logic_vector(CORES_PER_MISD-1 downto 0) := onehot;
  begin
    while (reduce_or(onehot) = '1') loop
      onehot2int_return := onehot2int_return + 1;
      onehot_return     := std_logic_vector(unsigned(onehot_return) srl 1);
    end loop;
    return onehot2int_return;
  end onehot2int;  --onehot2int

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Register Address Phase Signals
  processing_0 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      regHTRANS <= HTRANS_IDLE;
    elsif (rising_edge(HCLK)) then
      if (mst_HREADY = '1') then
        if (mst_HSEL = '1') then
          regHTRANS <= mst_HTRANS;
        else
          regHTRANS <= HTRANS_IDLE;
        end if;
      end if;
    end if;
  end process;

  processing_1 : process (HCLK)
  begin
    if (rising_edge(HCLK)) then
      if (mst_HREADY = '1') then
        regpriority  <= mst_priority;
        regHADDR     <= mst_HADDR;
        regHWDATA    <= mst_HWDATA;
        regHWRITE    <= mst_HWRITE;
        regHSIZE     <= mst_HSIZE;
        regHBURST    <= mst_HBURST;
        regHPROT     <= mst_HPROT;
        regHMASTLOCK <= mst_HMASTLOCK;
      end if;
    end if;
  end process;

  --Generate local HREADY response
  processing_2 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      local_HREADYOUT <= '1';
    elsif (rising_edge(HCLK)) then
      if (mst_HREADY = '1') then
        local_HREADYOUT <= to_stdlogic(mst_HTRANS = HTRANS_IDLE) or not mst_HSEL;
      end if;
    end if;
  end process;

  --  * Access granted state machine
  --  *
  --  * NO_ACCESS     : reset state
  --  *                 If there's no access requested, stay in this state
  --  *                 If there's an access requested and we get an access-grant, go to ACCESS state
  --  *                 else the access is pending
  --  *
  --  * ACCESS_PENDING: Intermediate state to hold bus-command (HTRANS, ...)
  --  * ACCESS_GRANTED: while access requested and granted stay in this state
  --  *                 else go to NO_ACCESS

  processing_3 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      access_state <= NO_ACCESS;
    elsif (rising_edge(HCLK)) then
      case (access_state) is
        when NO_ACCESS =>
          if (reduce_nor(current_HSEL) = '1' and reduce_nor(pending_HSEL) = '1') then
            access_state <= NO_ACCESS;
          elsif (reduce_or(current_HSEL and master_granted) = '1') then
            access_state <= ACCESS_GRANTED;
          else
            access_state <= ACCESS_PENDING;
          end if;
        when ACCESS_PENDING =>
          if (reduce_or(pending_HSEL and master_granted) = '1' and slvHREADY(to_integer(unsigned(slave_sel))) = '1') then
            access_state <= ACCESS_GRANTED;
          end if;
        when ACCESS_GRANTED =>
          if (mst_HREADY = '1' and reduce_nor(current_HSEL) = '1') then
            access_state <= NO_ACCESS;
          elsif (mst_HREADY = '1' and reduce_nor(current_HSEL and master_granted and slvHREADY) = '1') then
            access_state <= ACCESS_PENDING;
          end if;
        when others =>
          null;
      end case;
    end if;
  end process;

  no_access_s      <= to_stdlogic(access_state = NO_ACCESS);
  access_pending_s <= to_stdlogic(access_state = ACCESS_PENDING);
  access_granted_s <= to_stdlogic(access_state = ACCESS_GRANTED);

  --Generate burst counter
  processing_4 : process (HCLK)
  begin
    if (rising_edge(HCLK)) then
      if (mst_HREADY = '1') then
        if (mst_HTRANS = HTRANS_NONSEQ) then
          case (mst_HBURST) is
            when HBURST_WRAP4 =>
              burst_cnt <= std_logic_vector(to_unsigned(2, 4));
            when HBURST_INCR4 =>
              burst_cnt <= std_logic_vector(to_unsigned(2, 4));
            when HBURST_WRAP8 =>
              burst_cnt <= std_logic_vector(to_unsigned(6, 4));
            when HBURST_INCR8 =>
              burst_cnt <= std_logic_vector(to_unsigned(6, 4));
            when HBURST_WRAP16 =>
              burst_cnt <= std_logic_vector(to_unsigned(14, 4));
            when HBURST_INCR16 =>
              burst_cnt <= std_logic_vector(to_unsigned(14, 4));
            when others =>
              burst_cnt <= std_logic_vector(to_unsigned(0, 4));
          end case;
        end if;
      else
        burst_cnt <= std_logic_vector(unsigned(burst_cnt)-to_unsigned(1, 4));
      end if;
    end if;
  end process;

  --Indicate that the slave may switch masters on the NEXT cycle
  processing_5 : process (access_state)
  begin
    case (access_state) is
      when NO_ACCESS =>
        can_switch <= reduce_nor(current_HSEL and master_granted);
      when ACCESS_PENDING =>
        can_switch <= reduce_nor(pending_HSEL and master_granted);
      when ACCESS_GRANTED =>
        can_switch <= not mst_HSEL or (mst_HSEL and not mst_HMASTLOCK and mst_HREADY and (to_stdlogic(mst_HTRANS = HTRANS_IDLE) or (to_stdlogic(mst_HTRANS = HTRANS_NONSEQ) and to_stdlogic(mst_HBURST = HBURST_SINGLE)) or (to_stdlogic(mst_HTRANS = HTRANS_SEQ) and to_stdlogic(mst_HBURST /= HBURST_INCR) and reduce_nor(burst_cnt))));
      when others =>
        null;
    end case;
  end process;

  --  * Decode slave-request; which AHB slave (master-port) to address?
  --  *
  --  * Send out connection request to slave-port
  --  * Slave-port replies by asserting master_gnt
  --  * TODO: check for illegal combinations (more than 1 slvHSEL asserted)

  generating_0 : for s in 0 to CORES_PER_MISD - 1 generate
    current_HSEL(s) <= to_stdlogic(mst_HTRANS /= HTRANS_IDLE) and to_stdlogic((mst_HADDR and slvHADDRmask(s)) = (slvHADDRbase(s) and slvHADDRmask(s)));
    pending_HSEL(s) <= to_stdlogic(regHTRANS /= HTRANS_IDLE) and to_stdlogic((regHADDR and slvHADDRmask(s)) = (slvHADDRbase(s) and slvHADDRmask(s)));
    slvHSEL_sgn(s)  <= (pending_HSEL(s))
                      when access_pending_s = '1' else (mst_HSEL and current_HSEL(s));
  end generate;

  slvHSEL <= slvHSEL_sgn;

  --Check if granted access
  processing_6 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      slave_sel <= (others => '0');
    elsif (rising_edge(HCLK)) then
      if (mst_HREADY = '1') then
        slave_sel <= std_logic_vector(to_unsigned(onehot2int(slvHSEL_sgn), CORES_PER_MISD_BITS));
      end if;
    end if;
  end process;

  --Outgoing data (to slaves)
  mux_sel <= not access_pending_s;

  slvHADDR <= mst_HADDR
              when mux_sel = '1' else regHADDR;
  slvHWDATA <= mst_HWDATA
               when mux_sel = '1' else regHWDATA;
  slvHWRITE <= mst_HWRITE
               when mux_sel = '1' else regHWRITE;
  slvHSIZE <= mst_HSIZE
              when mux_sel = '1' else regHSIZE;
  slvHBURST <= mst_HBURST
               when mux_sel = '1' else regHBURST;
  slvHPROT <= mst_HPROT
              when mux_sel = '1' else regHPROT;
  slvHTRANS <= mst_HTRANS
               when mux_sel = '1'                                      else HTRANS_NONSEQ
               when regHTRANS = HTRANS_SEQ and regHBURST = HBURST_INCR else regHTRANS;
  slvHMASTLOCK <= mst_HMASTLOCK
                  when mux_sel = '1' else regHMASTLOCK;
  slvHREADYOUT <= mst_HREADY and reduce_or(current_HSEL and slvHREADY)
                  when mux_sel = '1' else slvHREADY(to_integer(unsigned(slave_sel)));  --slave's HREADYOUT is driven by master's HREADY (mst_HREADY -> slv_HREADYOUT)
  slvpriority <= mst_priority
                 when mux_sel = '1' else regpriority;

  --Incoming data (to masters)
  mst_HRDATA    <= slvHRDATA(to_integer(unsigned(slave_sel)));
  mst_HREADYOUT <= slvHREADY(to_integer(unsigned(slave_sel)))
                   when access_granted_s = '1' else local_HREADYOUT;  --master's HREADYOUT is driven by slave's HREADY (slv_HREADY -> mst_HREADYOUT)
  mst_HRESP <= slvHRESP(to_integer(unsigned(slave_sel)))
               when access_granted_s = '1' else HRESP_OKAY;
end RTL;
