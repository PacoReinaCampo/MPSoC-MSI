-- Converted from mpsoc_msi_wb_bfm_transactor.v
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

use work.mpsoc_msi_wb_pkg.all;

entity mpsoc_msi_wb_bfm_transactor is
  generic (
    AW : integer := 32;
    DW : integer := 32;

    AUTORUN : std_logic := '1';

    MEM_LOW  : integer := 0;
    MEM_HIGH : integer := 32;

    TRANSACTIONS_PARAM    : integer := 1000;
    SEGMENT_SIZE          : integer := 0;
    NUM_SEGMENTS          : integer := 0;
    SUBTRANSACTIONS_PARAM : integer := 100;
    VERBOSE               : integer := 0;
    MAX_BURST_LEN         : integer := 32;
    MAX_WAIT_STATES       : integer := 8;
    CLASSIC_PROB          : integer := 33;
    CONST_BURST_PROB      : integer := 33;
    INCR_BURST_PROB       : integer := 34;
    SEED_PARAM            : integer := 0
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
    wb_rty_i : in  std_logic;
    done     : out std_logic
    );
end mpsoc_msi_wb_bfm_transactor;

architecture RTL of mpsoc_msi_wb_bfm_transactor is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant ADR_LSB : integer := integer(log2(real(DW/8)));

  constant BROKEN_CLOG2 : std_logic := '1';

  constant CTI_CLASSIC      : std_logic_vector(2 downto 0) := "000";
  constant CTI_CONST_BURST  : std_logic_vector(2 downto 0) := "001";
  constant CTI_INC_BURST    : std_logic_vector(2 downto 0) := "010";
  constant CTI_END_OF_BURST : std_logic_vector(2 downto 0) := "111";

  constant BTE_LINEAR  : std_logic_vector(1 downto 0) := "00";
  constant BTE_WRAP_4  : std_logic_vector(1 downto 0) := "01";
  constant BTE_WRAP_8  : std_logic_vector(1 downto 0) := "10";
  constant BTE_WRAP_16 : std_logic_vector(1 downto 0) := "11";

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal SEED            : integer;
  signal TRANSACTIONS    : integer;
  signal SUBTRANSACTIONS : integer;

  signal cnt_cti_classic     : integer;
  signal cnt_cti_const_burst : integer;
  signal cnt_cti_inc_burst   : integer;
  signal cnt_cti_invalid     : integer;

  signal cnt_bte_linear  : integer;
  signal cnt_bte_wrap_4  : integer;
  signal cnt_bte_wrap_8  : integer;
  signal cnt_bte_wrap_16 : integer;

  signal burst_length : integer;

  signal burst_type : std_logic_vector(1 downto 0);

  signal cycle_type : std_logic_vector(2 downto 0);

  signal transaction    : integer;
  signal subtransaction : integer;

  signal err : std_logic;

  signal t_address  : std_logic_vector(AW-1 downto 0);
  signal t_adr_high : std_logic_vector(AW-1 downto 0);
  signal t_adr_low  : std_logic_vector(AW-1 downto 0);
  signal st_address : std_logic_vector(AW-1 downto 0);
  signal st_type    : std_logic;

  signal mem_lo  : integer;
  signal mem_hi  : integer;
  signal segment : integer;

  signal wait_states : std_logic_vector(integer(log2(real(MAX_WAIT_STATES))) downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --
  function gen_adr (
    low  : integer;
    high : integer
    ) return std_logic_vector is
    variable gen_adr_return : std_logic_vector (AW-1 downto 0);
  begin
    --gen_adr_return <= (low+(((null)(SEED)) mod (high-low))) and (concatenate(AW-ADR_LSB, '1') & concatenate(ADR_LSB, '0'));
    return gen_adr_return;
  end gen_adr;

  function gen_cycle_type (
    cycle_type_prob : integer
    ) return std_logic_vector is
    variable gen_cycle_type_return : std_logic_vector (2 downto 0);
  begin
    if (cycle_type_prob <= CLASSIC_PROB) then
      gen_cycle_type_return := "000";
    elsif (cycle_type_prob <= (CLASSIC_PROB+CONST_BURST_PROB)) then
      gen_cycle_type_return := CTI_CONST_BURST;
    else
      gen_cycle_type_return := CTI_INC_BURST;
    end if;
    return gen_cycle_type_return;
  end gen_cycle_type;

  --Return a 2*AW array with the highest and lowest accessed addresses
  --  based on starting address and burst type
  --  TODO: Account for short wrap bursts. Fix for 8-bit mode
  function adr_range (
    adr_i : std_logic_vector(AW-1 downto 0);
    cti_i : std_logic_vector(2 downto 0);
    bte_i : std_logic_vector(1 downto 0);
    len_i : std_logic_vector(integer(log2(real(MAX_BURST_LEN+1))) downto 0)
    ) return std_logic_vector is
    constant BPW : integer := DW/8;  --Bytes per word

    variable adr      : std_logic_vector(AW-1 downto 0);
    variable adr_high : std_logic_vector(AW-1 downto 0);
    variable adr_low  : std_logic_vector(AW-1 downto 0);

    variable shift : integer;

    variable adr_range_return : std_logic_vector (2*AW-1 downto 0);
  begin
    if (BROKEN_CLOG2 = '1') then
      shift := integer(log2(real(BPW)));
    elsif (BROKEN_CLOG2 = '0') then
      shift := integer(log2(real(BPW)));
    end if;
    adr := std_logic_vector(unsigned(adr_i) srl shift);
    if (cti_i = CTI_INC_BURST) then
      case (bte_i) is
        when BTE_LINEAR =>
          adr_high := std_logic_vector(unsigned(adr)+unsigned(len_i));
          adr_low  := adr;
        when BTE_WRAP_4 =>
          adr_high := std_logic_vector(unsigned(adr(AW-1 downto 2))*to_unsigned(4, 2)+to_unsigned(4, AW));
          adr_low  := std_logic_vector(unsigned(adr(AW-1 downto 2))*to_unsigned(4, 2));
        when BTE_WRAP_8 =>
          adr_high := std_logic_vector(unsigned(adr(AW-1 downto 2))*to_unsigned(4, 2)+to_unsigned(8, AW));
          adr_low  := std_logic_vector(unsigned(adr(AW-1 downto 3))*to_unsigned(8, 3));
        when BTE_WRAP_16 =>
          adr_high := std_logic_vector(unsigned(adr(AW-1 downto 2))*to_unsigned(4, 2)+to_unsigned(16, AW));
          adr_low  := std_logic_vector(unsigned(adr(AW-1 downto 4))*to_unsigned(16, 4));
        when others =>
          report "Illegal burst type " & integer'image(to_integer(unsigned(bte_i)));
          adr_range_return := (others => 'X');
      end case;
    else
      adr_high := std_logic_vector(unsigned(adr)+to_unsigned(1, AW));
      adr_low  := adr;
    end if;

    adr_high         := std_logic_vector((unsigned(adr_high) sll shift)-to_unsigned(1, AW));
    adr_low          := std_logic_vector(unsigned(adr_low) sll shift);
    adr_range_return := (adr_high & adr_low);
    return adr_range_return;
  end adr_range;

  function gen_cycle_params (
    adr_min_i : std_logic_vector(AW-1 downto 0);
    adr_max_i : std_logic_vector(AW-1 downto 0)
    ) return std_logic_vector is
    variable adr_low  : std_logic_vector(AW-1 downto 0);
    variable adr_high : std_logic_vector(AW-1 downto 0);

    variable address      : std_logic_vector(AW-1 downto 0);
    variable cycle_type   : std_logic_vector(2 downto 0);
    variable burst_type   : std_logic_vector(1 downto 0);
    variable burst_length : std_logic_vector(integer(log2(real(MAX_BURST_LEN+1))) downto 0);

    variable gen_cycle_params_return : std_logic_vector (AW+3+2+32-1 downto 0);

    variable adr_range_return : std_logic_vector (2*AW-1 downto 0);
  begin
    adr_low  := (others => '0');
    adr_high := (others => '0');
    -- Repeat check for MEM_LOW/MEM_HIGH bounds until satisfied
    while ((adr_high > adr_max_i) or (adr_low < adr_min_i) or (adr_high = adr_low)) loop
      address := gen_adr(to_integer(unsigned(adr_min_i)), to_integer(unsigned(adr_max_i)));
      ----cycle_type <= (null)(((null)(SEED)) mod 100);

      ----burst_type <= (((null)(SEED)) mod 4)
      ----              when (cycle_type = CTI_INC_BURST) else 0;

      ----burst_length <= 1
      ----                when (cycle_type = CTI_CLASSIC) else (((null)(SEED)) mod MAX_BURST_LEN)+1;

      adr_range_return := adr_range(address, cycle_type, burst_type, burst_length);

      adr_low  := adr_range_return(AW-1 downto 0);
      adr_high := adr_range_return(2*AW-1 downto AW-2);
    end loop;
    gen_cycle_params_return := (address & cycle_type & burst_type & burst_length);
    return gen_cycle_params_return;
  end gen_cycle_params;

  --////////////////////////////////////////////////////////////////
  --
  -- Procedures
  --

  --Gather transaction statistics
  --TODO: Record shortest/longest bursts.
  procedure update_stats (
    signal cti : in std_logic_vector(2 downto 0);
    signal bte : in std_logic_vector(1 downto 0);

    signal cnt_cti_classic     : inout integer;
    signal cnt_cti_const_burst : inout integer;
    signal cnt_cti_inc_burst   : inout integer;
    signal cnt_cti_invalid     : inout integer;

    signal cnt_bte_linear  : inout integer;
    signal cnt_bte_wrap_4  : inout integer;
    signal cnt_bte_wrap_8  : inout integer;
    signal cnt_bte_wrap_16 : inout integer;

    signal burst_length : in std_logic
    ) is
  begin
    case (cti) is
      when CTI_CLASSIC =>
        cnt_cti_classic <= cnt_cti_classic+1;
      when CTI_CONST_BURST =>
        cnt_cti_const_burst <= cnt_cti_const_burst+1;
      when CTI_INC_BURST =>
        cnt_cti_inc_burst <= cnt_cti_inc_burst+1;
      when others =>
        cnt_cti_invalid <= cnt_cti_invalid+1;
    end case;
    if (cti = CTI_INC_BURST) then
      case (bte) is
        when BTE_LINEAR =>
          cnt_bte_linear <= cnt_bte_linear+1;
        when BTE_WRAP_4 =>
          cnt_bte_wrap_4 <= cnt_bte_wrap_4+1;
        when BTE_WRAP_8 =>
          cnt_bte_wrap_8 <= cnt_bte_wrap_8+1;
        when BTE_WRAP_16 =>
          cnt_bte_wrap_16 <= cnt_bte_wrap_16+1;
        when others =>
          report "Invalid BTE b" & integer'image(to_integer(unsigned(bte)));
      end case;
    end if;
  end update_stats;

  procedure display_stats (
    signal cnt_cti_classic     : in integer;
    signal cnt_cti_const_burst : in integer;
    signal cnt_cti_inc_burst   : in integer;
    signal cnt_cti_invalid     : in integer;

    signal cnt_bte_linear  : in integer;
    signal cnt_bte_wrap_4  : in integer;
    signal cnt_bte_wrap_8  : in integer;
    signal cnt_bte_wrap_16 : in integer
    ) is
  begin
    report "#################################";
    report "##### Cycle Type Statistics #####";
    report "#################################";
    report "Invalid cycle types   : " & integer'image(cnt_cti_invalid);
    report "Classic cycles        : " & integer'image(cnt_cti_classic);
    report "Constant burst cycles : " & integer'image(cnt_cti_const_burst);
    report "Increment burst cycles: " & integer'image(cnt_cti_inc_burst);
    report "   Linear bursts      : " & integer'image(cnt_bte_linear);
    report "   4-beat bursts      : " & integer'image(cnt_bte_wrap_4);
    report "   8-beat bursts      : " & integer'image(cnt_bte_wrap_8);
    report "  16-beat bursts      : " & integer'image(cnt_bte_wrap_16);
  end display_stats;

  procedure display_subtransaction (
    signal address      : in std_logic_vector(AW-1 downto 0);
    signal cycle_type   : in std_logic_vector(2 downto 0);
    signal burst_type   : in std_logic_vector(1 downto 0);
    signal burst_length : in std_logic;
    signal wr           : in std_logic
    ) is
  begin
    if (VERBOSE > 0) then
      report "  Subtransaction " & integer'image(transaction) & "." & integer'image(subtransaction);
      if (wr = '1') then
        report "(Write)";
      else
        report "(Read) ";
      end if;
      report ": Start Address: " & integer'image(to_integer(unsigned(address))) & ", Cycle Type: " & integer'image(to_integer(unsigned(cycle_type))) & ", Burst Type: " & integer'image(to_integer(unsigned(burst_type))) & ", Burst Length: " & std_logic'image(burst_length);
    end if;
  end display_subtransaction;

  procedure set_transactions (
    signal transactions_i : in integer;

    signal TRANSACTIONS : out integer
    ) is
  begin
    TRANSACTIONS <= transactions_i;
  end set_transactions;

  procedure set_subtransactions (
    signal transactions_i : in integer;

    signal SUBTRANSACTIONS : out integer
    ) is
  begin
    SUBTRANSACTIONS <= transactions_i;
  end set_subtransactions;

  -- Task to fill Write Data array.
  -- random data will be used.
  procedure fill_wdata_array (
    signal burst_length : in std_logic_vector(31 downto 0);

    signal word : integer
    ) is
  begin
    -- Fill write data array
    for word in 0 to to_integer(unsigned(burst_length))-1 loop
    ----bfm.write_data(word) <= random;
    end loop;
  end fill_wdata_array;

  procedure display_settings (
    signal SEED            : integer;
    signal TRANSACTIONS    : integer;
    signal SUBTRANSACTIONS : integer
    ) is
  begin
    report "##############################################################";
    report "############# Wishbone Master Test Configuration #############";
    report "##############################################################";
    report "";
    report "%m:";
    if (NUM_SEGMENTS > 0) then
      report "  Number of segments    : " & integer'image(NUM_SEGMENTS);
      report "  Segment size          : " & integer'image(SEGMENT_SIZE);
      report "  Memory High Address   : " & integer'image(MEM_LOW+NUM_SEGMENTS*SEGMENT_SIZE-1);
      report "  Memory Low Address    : " & integer'image(MEM_LOW);
    else
      report "  Memory High Address   : " & integer'image(MEM_HIGH);
      report "  Memory Low Address    : " & integer'image(MEM_LOW);
    end if;
    report "  Transactions          : " & integer'image(TRANSACTIONS);
    report "  Subtransactions       : " & integer'image(SUBTRANSACTIONS);
    report "  Max Burst Length      : " & integer'image(MAX_BURST_LEN);
    report "  Max Wait States       : " & integer'image(MAX_WAIT_STATES);
    report "  Classic Cycle Prob    : " & integer'image(CLASSIC_PROB);
    report "  Const Addr Cycle Prob : " & integer'image(CONST_BURST_PROB);
    report "  Incr Addr Cycle Prob  : " & integer'image(INCR_BURST_PROB);
    report "  Write Data            : Random";
    report "  Buffer Data           : Mirrors RAM";
    report "  $random Seed          : " & integer'image(SEED);
    report "  Verbosity             : " & integer'image(VERBOSE);
    report "";
    report "############# Starting Wishbone Master Tests...  #############";
    report "";
  end display_settings;

  procedure run (
    signal transaction : in integer;

    signal done : out std_logic;
    signal err  : out std_logic
    ) is

    variable st_type : std_logic;

    variable mem_lo : integer;
    variable mem_hi : integer;

    variable t_address  : std_logic_vector(AW-1 downto 0);

    variable t_adr_high : std_logic_vector(AW-1 downto 0);
    variable t_adr_low  : std_logic_vector(AW-1 downto 0);
  begin
    if (TRANSACTIONS < 1) then
      report integer'image(TRANSACTIONS) & " transactions requested. Number of transactions must be set to > 0";
    end if;
    ----bfm.reset;
    done <= '0';
    err  <= '0';

    st_type := '0';

    for transaction in 1 to TRANSACTIONS loop
      if (VERBOSE > 0) then
        report "Transaction: " & integer'image(transaction) & "/" & integer'image(TRANSACTIONS);
      elsif ((transaction mod (SUBTRANSACTIONS/10)) < 0) then
        report "Transaction: " & integer'image(transaction) & "/" & integer'image(TRANSACTIONS);
      end if;
      -- Generate the random value for the number of wait states. This will
      -- be used for all of this transaction
      ----bfm.wait_states <= ((null)(SEED)) mod (MAX_WAIT_STATES+1);
      if (VERBOSE > 2) then
        report "Number of Wait States for Transaction " & integer'image(transaction) & " is " & integer'image(to_integer(unsigned(wait_states)));
      end if;
      --If running in segment mode, cap mem_high/mem_low to a segment
      if (NUM_SEGMENTS > 0) then
        ----segment <= ((null)(SEED)) mod NUM_SEGMENTS;
        mem_lo := MEM_LOW+segment*SEGMENT_SIZE;
        mem_hi := MEM_LOW+(segment+1)*SEGMENT_SIZE-1;
      else
        mem_lo := MEM_LOW;
        mem_hi := MEM_HIGH;
      end if;

      -- Check if initial base address and max burst length lie within
      -- mem_hi/mem_lo bounds. If not, regenerate random values until condition met.
      t_adr_high := (others => '0');
      t_adr_low  := (others => '0');
      while ((to_integer(unsigned(t_adr_high)) > mem_hi) or (to_integer(unsigned(t_adr_low)) < mem_lo) or (to_integer(unsigned(t_adr_high)) = to_integer(unsigned(t_adr_low)))) loop
        t_address := gen_adr(mem_lo, mem_hi);
      ----(t_adr_high & t_adr_low) <= (null)(t_address, MAX_BURST_LEN, CTI_INC_BURST, BTE_LINEAR);
      end loop;

      -- Write Transaction
      if (VERBOSE > 0) then
        report "Transaction " & integer'image(transaction) & " Initialisation (Write): Start Address: " & integer'image(to_integer(unsigned(t_address))) & ", Burst Length: " & integer'image(MAX_BURST_LEN);

      end if;
      -- Fill Write Array then Send the Write Transaction
      ----(null)(MAX_BURST_LEN);
      ----(null)(t_address, t_address, concatenate(DW/8, '1'), CTI_INC_BURST, BTE_LINEAR, MAX_BURST_LEN, err);
      ----(null)(cycle_type, burst_type, burst_length);

      -- Read data can be read back from wishbone memory.
      if (VERBOSE > 0) then
        report "Transaction " & integer'image(transaction) & " Initialisation (Read): Start Address: " & integer'image(to_integer(unsigned(t_address))) & ", Burst Length: " & integer'image(MAX_BURST_LEN);
      end if;

      ----(null)(t_address, t_address, concatenate(DW/8, '1'), CTI_INC_BURST, BTE_LINEAR, MAX_BURST_LEN, err);
      ----(null)(cycle_type, burst_type, burst_length);

      if (VERBOSE > 0) then
        report "Transaction " & integer'image(transaction) & " initialisation ok (Start Address: " & integer'image(to_integer(unsigned(t_address))) & ", Cycle Type: " & integer'image(to_integer(unsigned(CTI_INC_BURST))) & ", Burst Type: " & integer'image(to_integer(unsigned(BTE_LINEAR))) & ", Burst Length: " & integer'image(MAX_BURST_LEN) & ")";
      end if;
      -- Start subtransaction loop.
      for subtransaction in 1 to SUBTRANSACTIONS loop
        -- Transaction Type: 0=Read, 1=Write
        ----st_type                                               <= ((null)(SEED)) mod 2;
        ----(st_address & cycle_type & burst_type & burst_length) <= (null)(t_adr_low, t_adr_high);
        ----(null)(st_address, cycle_type, burst_type, burst_length, st_type);

        if (st_type = '0') then
        -- Send Read Transaction
        ----(null)(t_address, st_address, concatenate(DW/8, '1'), cycle_type, burst_type, burst_length, err);
        else
        -- Fill Write Array then Send the Write Transaction
        ----(null)(burst_length);
        ----(null)(t_address, st_address, concatenate(DW/8, '1'), cycle_type, burst_type, burst_length, err);
        end if;
      -- if (st_type)
      ----(null)(cycle_type, burst_type, burst_length);
      end loop;
      -- for (subtransaction=0;...
      -- Final consistency check...
      if (VERBOSE > 0) then
        report "Transaction " & integer'image(transaction) & " Buffer Consistency Check: Start Address: " & integer'image(to_integer(unsigned(t_address))) & " Burst Length: " & integer'image(MAX_BURST_LEN);
      end if;
      ----(null)(t_address, t_address, X"f", CTI_INC_BURST, BTE_LINEAR, MAX_BURST_LEN, err);
      if (VERBOSE > 0) then
        report "Transaction %0d Completed Successfully" & integer'image(transaction);
      end if;
    -- Clear Buffer Data before next transaction
    ----bfm.clear_buffer_data;
    end loop;
    done <= '1';
  end run;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  -- Check Cycle Probability values add up to 100
  processing_0 : process
  begin
    if ((CLASSIC_PROB+CONST_BURST_PROB+INCR_BURST_PROB) /= 100) then
      report "ERROR: Wishbone Cycle Probability values must total 100. Current values total : " & integer'image(CLASSIC_PROB+CONST_BURST_PROB+INCR_BURST_PROB);
      report "         Classic Cycle Probability                    : " & integer'image(CLASSIC_PROB);
      report "         Constant Address Burst Cycle Probability     : " & integer'image(CONST_BURST_PROB);
      report "         Incrementing Address Burst Cycle Probability : " & integer'image(INCR_BURST_PROB);

      wait;
    end if;
    if (AUTORUN = '1') then
      display_settings (
        SEED            => SEED,
        TRANSACTIONS    => TRANSACTIONS,
        SUBTRANSACTIONS => SUBTRANSACTIONS
        );

      run (
        transaction => transaction,

        done => done,
        err  => err
        );

      display_stats (
        cnt_cti_classic     => cnt_cti_classic,
        cnt_cti_const_burst => cnt_cti_const_burst,
        cnt_cti_inc_burst   => cnt_cti_inc_burst,
        cnt_cti_invalid     => cnt_cti_invalid,

        cnt_bte_linear  => cnt_bte_linear,
        cnt_bte_wrap_4  => cnt_bte_wrap_4,
        cnt_bte_wrap_8  => cnt_bte_wrap_8,
        cnt_bte_wrap_16 => cnt_bte_wrap_16
        );

      done <= '1';
    end if;
  end process;
end RTL;
