-- Converted from rtl/vhdl/riscv_simd_peripheral_slave_port.sv
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
--              Master Slave Interconnect Slave Port                          //
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

entity riscv_simd_peripheral_slave_port is
  port (  
    HCLK    : in std_ulogic;
    HRESETn : in std_ulogic;

    --AHB Slave Interfaces (receive data from AHB Masters)
    --AHB Masters conect to these ports
    mstpriority  : in  M_2_2;
    mstHSEL      : in  std_ulogic_vector(2 downto 0);
    mstHADDR     : in  M_2_PLEN;
    mstHWDATA    : in  M_2_XLEN;
    mstHRDATA    : out std_ulogic_vector(XLEN-1 downto 0);
    mstHWRITE    : in  std_ulogic_vector(2 downto 0);
    mstHSIZE     : in  M_2_2;
    mstHBURST    : in  M_2_2;
    mstHPROT     : in  M_2_3;
    mstHTRANS    : in  M_2_1;
    mstHMASTLOCK : in  std_ulogic_vector(2 downto 0);
    mstHREADY    : in  std_ulogic_vector(2 downto 0);  --HREADY input from master-bus
    mstHREADYOUT : out std_ulogic;  --HREADYOUT output to master-bus
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

    can_switch     : in  std_ulogic_vector(2 downto 0);
    granted_master : out std_ulogic_vector(2 downto 0)
  );
end riscv_simd_peripheral_slave_port;

architecture RTL of riscv_simd_peripheral_slave_port is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant MASTER_BITS : integer := integer(log2(real(3)));

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal requested_priority_lvl : std_ulogic_vector(2 downto 0);  --requested priority level
  signal priority_masters       : std_ulogic_vector(2 downto 0);  --all masters at this priority level

  signal pending_master       : std_ulogic_vector(2 downto 0);  --next master waiting to be served
  signal last_granted_master  : std_ulogic_vector(2 downto 0);  --for requested priority level
  signal last_granted_masters : M_2_2;  --per priority level, for round-robin

  signal granted_master_idx     : std_ulogic_vector(MASTER_BITS-1 downto 0);  --granted master as index
  signal granted_master_idx_dly : std_ulogic_vector(MASTER_BITS-1 downto 0);  --deleayed granted master index (for HWDATA)

  signal can_switch_master : std_ulogic;  --Slave may switch to a new master

  signal granted_master_sgn : std_ulogic_vector(2 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Tasks
  --

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --
  function reduce_nor (
    reduce_nor_in : std_ulogic_vector
    ) return std_ulogic is
    variable reduce_nor_out : std_ulogic := '0';
  begin
    for i in reduce_nor_in'range loop
      reduce_nor_out := reduce_nor_out nor reduce_nor_in(i);
    end loop;
    return reduce_nor_out;
  end reduce_nor;

  function reduce_or (
    reduce_or_in : std_ulogic_vector
    ) return std_ulogic is
    variable reduce_or_out : std_ulogic := '0';
  begin
    for i in reduce_or_in'range loop
      reduce_or_out := reduce_or_out or reduce_or_in(i);
    end loop;
    return reduce_or_out;
  end reduce_or;

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

  function onehot2int (
    onehot : std_ulogic_vector(2 downto 0)
    ) return integer is
    variable onehot2int_return : integer := -1;

    variable onehot_return : std_ulogic_vector(2 downto 0) := onehot;
  begin
    while (reduce_or(onehot) = '1') loop
      onehot2int_return := onehot2int_return + 1;
      onehot_return     := std_ulogic_vector(unsigned(onehot_return) srl 1);
    end loop;
    return onehot2int_return;
  end onehot2int;  --onehot2int

  function highest_requested_priority (
    hsel : std_ulogic_vector(2 downto 0);
    priorities : M_2_2
  ) return std_ulogic_vector is
    variable highest_requested_priority_return : std_ulogic_vector (2 downto 0);
  begin
    highest_requested_priority_return := (others => '0');
    for n in 0 to 3 - 1 loop
      if (hsel(n) = '1' and unsigned(priorities(n)) > unsigned(highest_requested_priority_return)) then
        highest_requested_priority_return := priorities(n);
      end if;
    end loop;
    return highest_requested_priority_return;
  end highest_requested_priority;  --highest_requested_priority

  function requesters (
    hsel: std_ulogic_vector(2 downto 0);
    priorities : M_2_2;
    priority_select : std_ulogic_vector(2 downto 0)

  ) return std_ulogic_vector is
    variable requesters_return : std_ulogic_vector (2 downto 0);
  begin
    for n in 0 to 3 - 1 loop
      requesters_return(n) := to_stdlogic(priorities(n) = priority_select) and hsel(n);
    end loop;
    return requesters_return;
  end requesters;  --requesters

  function nxt_master (
    pending_masters : std_ulogic_vector(2 downto 0);  --pending masters for the requesed priority level
    last_master     : std_ulogic_vector(2 downto 0);  --last granted master for the priority level
    current_master  : std_ulogic_vector(2 downto 0)   --current granted master (indpendent of priority level)
  ) return std_ulogic_vector is
    variable offset : integer;
    variable sr : std_ulogic_vector(3*2-1 downto 0);
    variable nxt_master_return : std_ulogic_vector (2 downto 0);
  begin
    --default value, don't switch if not needed
    nxt_master_return := current_master;

    --implement round-robin
    offset := onehot2int(last_master)+1;

    sr := (pending_masters & pending_masters);
    for n in 0 to 3 - 1 loop
      if (sr(n+offset) = '1') then
        return std_ulogic_vector(to_unsigned(2**((n+offset) mod 3), 3));
      end if;
    end loop;
    return nxt_master_return;
  end nxt_master;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --  * Select which master to service
  --  * 1. Priority
  --  * 2. Round-Robin

  --get highest priority from selected masters
  requested_priority_lvl <= highest_requested_priority(mstHSEL, mstpriority);

  --get pending masters for the highest priority requested
  priority_masters <= requesters(mstHSEL, mstpriority, requested_priority_lvl);

  --get last granted master for the priority requested
  last_granted_master <= last_granted_masters(to_integer(unsigned(requested_priority_lvl)));

  --get next master to serve
  pending_master <= nxt_master(priority_masters, last_granted_master, granted_master_sgn);

  --Master port signals when it can be switched
  can_switch_master <= can_switch(to_integer(unsigned(granted_master_idx)));

  --select new master
  processing_0 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      granted_master_sgn <= std_ulogic_vector(to_unsigned(1, 3));
    elsif (rising_edge(HCLK)) then
      --else if (!slv_HSEL    ) granted_master <= pending_master;
      if (slv_HREADY = '1') then
        if (can_switch_master = '1') then
          granted_master_sgn <= pending_master;
        end if;
      end if;
    end if;
  end process;

  granted_master <= granted_master_sgn;

  --store current master (for this priority level)
  processing_1 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      last_granted_masters(to_integer(unsigned(requested_priority_lvl))) <= (0 => '1', others => '0');
    elsif (rising_edge(HCLK)) then
      --else if (!slv_HSEL    ) last_granted_masters[requested_priority_lvl] <= pending_master;
      if (slv_HREADY = '1') then
        if (can_switch_master = '1') then
          last_granted_masters(to_integer(unsigned(requested_priority_lvl))) <= pending_master;
        end if;
      end if;
    end if;
  end process;

  --Get signals from current requester
  processing_2 : process (HCLK, HRESETn)
    variable current_requester : std_ulogic_vector(2 downto 0);
  begin
    if (HRESETn = '0') then
      granted_master_idx <= (others => '0');
    elsif (rising_edge(HCLK)) then
      --else if (!slv_HSEL) granted_master_idx <= onehot2int( pending_master );
      if (slv_HREADY = '1') then
        granted_master_idx <= std_ulogic_vector(to_unsigned(onehot2int(current_requester), MASTER_BITS));
        if (can_switch_master = '1') then
          current_requester := pending_master;
        else 
          current_requester := granted_master_sgn;
        end if;
      end if;
    end if;
  end process;

  processing_3 : process (HCLK)
  begin
    if (rising_edge(HCLK)) then
      if (slv_HREADY = '1') then
        granted_master_idx_dly <= granted_master_idx;
      end if;
    end if;
  end process;

  --  * If first granted access from slave-port and HTRANS = SEQ, then change to NONSEQ
  --  * as this is most likely a burst going over a slave boundary
  --  * If it's not, then this was a bad access to start with and we're in a mess anyways
  --  *
  --  * Do NOT switch when HMASTLOCK is asserted
  --  * It is allowed to switch in the middle of a burst ... but that will get ugly pretty quick

  slv_HSEL      <= mstHSEL(to_integer(unsigned(granted_master_idx)));
  slv_HADDR     <= mstHADDR(to_integer(unsigned(granted_master_idx)));
  slv_HWDATA    <= mstHWDATA(to_integer(unsigned(granted_master_idx_dly)));
  slv_HWRITE    <= mstHWRITE(to_integer(unsigned(granted_master_idx)));
  slv_HSIZE     <= mstHSIZE(to_integer(unsigned(granted_master_idx)));
  slv_HBURST    <= mstHBURST(to_integer(unsigned(granted_master_idx)));
  slv_HPROT     <= mstHPROT(to_integer(unsigned(granted_master_idx)));
  slv_HTRANS    <= mstHTRANS(to_integer(unsigned(granted_master_idx)));
  slv_HREADYOUT <= mstHREADY(to_integer(unsigned(granted_master_idx)));  --Slave Ports HREADYOUT connects to Master Port's HREADY
  slv_HMASTLOCK <= mstHMASTLOCK(to_integer(unsigned(granted_master_idx)));

  mstHRDATA    <= slv_HRDATA;
  mstHREADYOUT <= slv_HREADY;  --Master Port's HREADYOUT is driven by Slave Port's (local) HREADY signal
  mstHRESP     <= slv_HRESP;
end RTL;
