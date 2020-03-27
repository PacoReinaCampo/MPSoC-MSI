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
-- *   Francisco Javier Reina Campo <frareicam@gmail.com>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mpsoc_msi_wb_bfm_transactor is
  port (
    wb_clk_i : in std_logic;
    wb_rst_i : in std_logic;
    wb_adr_o : out std_logic_vector(AW-1 downto 0);
    wb_dat_o : out std_logic_vector(DW-1 downto 0);
    wb_sel_o : out std_logic_vector(DW/8-1 downto 0);
    wb_we_o : out std_logic;
    wb_cyc_o : out std_logic;
    wb_stb_o : out std_logic;
    wb_cti_o : out std_logic_vector(2 downto 0);
    wb_bte_o : out std_logic_vector(1 downto 0);
    wb_dat_i : in std_logic_vector(DW-1 downto 0);
    wb_ack_i : in std_logic;
    wb_err_i : in std_logic;
    wb_rty_i : in std_logic 
    done : out std_logic
  );
  constant AW : integer := 32;
  constant DW : integer := 32;
  constant AUTORUN : integer := 1;
  constant MEM_HIGH : std_logic_vector(31 downto 0) := X"ffffffff";
  constant MEM_LOW : integer := 0;
  constant TRANSACTIONS_PARAM : integer := 1000;
  constant SEGMENT_SIZE : integer := 0;
  constant NUM_SEGMENTS : integer := 0;
  constant SUBTRANSACTIONS_PARAM : integer := 100;
  constant VERBOSE : integer := 0;
  constant MAX_BURST_LEN : integer := 32;
  constant MAX_WAIT_STATES : integer := 8;
  constant CLASSIC_PROB : integer := 33;
  constant CONST_BURST_PROB : integer := 33;
  constant INCR_BURST_PROB : integer := 34;
  constant SEED_PARAM : integer := 0;
end mpsoc_msi_wb_bfm_transactor;

architecture RTL of mpsoc_msi_wb_bfm_transactor is
  component mpsoc_msi_wb_bfm_master
  generic (
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?;
    ? : std_logic_vector(? downto 0) := ?
  );
  port (
    wb_clk_i : std_logic_vector(? downto 0);
    wb_rst_i : std_logic_vector(? downto 0);
    wb_adr_o : std_logic_vector(? downto 0);
    wb_dat_o : std_logic_vector(? downto 0);
    wb_sel_o : std_logic_vector(? downto 0);
    wb_we_o : std_logic_vector(? downto 0);
    wb_cyc_o : std_logic_vector(? downto 0);
    wb_stb_o : std_logic_vector(? downto 0);
    wb_cti_o : std_logic_vector(? downto 0);
    wb_bte_o : std_logic_vector(? downto 0);
    wb_dat_i : std_logic_vector(? downto 0);
    wb_ack_i : std_logic_vector(? downto 0);
    wb_err_i : std_logic_vector(? downto 0);
    wb_rty_i : std_logic_vector(? downto 0)
  );
  end component;



  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  use work."mpsoc_msi_wb_pkg.v".all;


  constant ADR_LSB : integer := (null)(DW/8);

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  constant SEED : integer := SEED_PARAM;
  constant TRANSACTIONS : integer := TRANSACTIONS_PARAM;
  constant SUBTRANSACTIONS : integer := SUBTRANSACTIONS_PARAM;


  constant cnt_cti_classic : integer := 0;
  constant cnt_cti_const_burst : integer := 0;
  constant cnt_cti_inc_burst : integer := 0;
  constant cnt_cti_invalid : integer := 0;


  constant cnt_bte_linear : integer := 0;
  constant cnt_bte_wrap_4 : integer := 0;
  constant cnt_bte_wrap_8 : integer := 0;
  constant cnt_bte_wrap_16 : integer := 0;


  constant burst_length : integer;


  signal burst_type : std_logic_vector(1 downto 0);

  signal cycle_type : std_logic_vector(2 downto 0);

  constant transaction : integer;
  constant subtransaction : integer;


  signal err : std_logic;

  signal t_address : std_logic_vector(AW-1 downto 0);
  signal t_adr_high : std_logic_vector(AW-1 downto 0);
  signal t_adr_low : std_logic_vector(AW-1 downto 0);
  signal st_address : std_logic_vector(AW-1 downto 0);
  signal st_type : std_logic;

  constant mem_lo : integer;
  constant mem_hi : integer;
  constant segment : integer;


  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --
  function gen_adr (
    low : std_logic;
    high : std_logic
  ) return std_logic_vector is
    variable gen_adr_return : std_logic_vector (AW-1 downto 0);
  begin
    gen_adr_return <= (low+(((null)(SEED)) mod (high-low))) and (concatenate(AW-ADR_LSB, '1') & concatenate(ADR_LSB, '0'));
    return gen_adr_return;
  end gen_adr;



  function gen_cycle_type (
    cycle_type_prob : std_logic
  ) return std_logic_vector is
    variable gen_cycle_type_return : std_logic_vector (2 downto 0);
  begin
    if (cycle_type_prob <= CLASSIC_PROB) then
      gen_cycle_type_return <= "000";
    elsif (cycle_type_prob <= (CLASSIC_PROB+CONST_BURST_PROB)) then
      gen_cycle_type_return <= CTI_CONST_BURST;
    else
      gen_cycle_type_return <= CTI_INC_BURST;
    end if;
    return gen_cycle_type_return;
  end gen_cycle_type;



  function gen_cycle_params (
    adr_min_i : std_logic_vector(AW-1 downto 0);
    adr_max_i : std_logic_vector(AW-1 downto 0);

    signal adr_low : std_logic_vector(AW-1 downto 0);
    signal adr_high : std_logic_vector(AW-1 downto 0);

    signal address : std_logic_vector(AW-1 downto 0);
    signal cycle_type : std_logic_vector(2 downto 0);
    signal burst_type : std_logic_vector(1 downto 0);
    signal burst_length : std_logic_vector(31 downto 0);

  ) return std_logic_vector is
    variable gen_cycle_params_return : std_logic_vector (AW+3+2+32-1 downto 0);
  begin
    adr_low <= 0;
    adr_high <= 0;
    -- Repeat check for MEM_LOW/MEM_HIGH bounds until satisfied
    while ((adr_high > adr_max_i) or (adr_low < adr_min_i) or (adr_high = adr_low)) loop
      address <= (null)(adr_min_i, adr_max_i);
      cycle_type <= (null)(((null)(SEED)) mod 100);

      burst_type <= (((null)(SEED)) mod 4)
      when (cycle_type = CTI_INC_BURST) else 0;

      burst_length <= 1
      when (cycle_type = CTI_CLASSIC) else (((null)(SEED)) mod MAX_BURST_LEN)+1;

      (adr_high & adr_low) <= (null)(address, burst_length, cycle_type, burst_type);
    end loop;
    gen_cycle_params_return <= (address & cycle_type & burst_type & burst_length);
    return gen_cycle_params_return;
  end gen_cycle_params;



  --Return a 2*AW array with the highest and lowest accessed addresses
--    based on starting address and burst type
--    TODO: Account for short wrap bursts. Fix for 8-bit mode*/
  function adr_range (
    constant BPW : integer := DW/8;  --Bytes per word

    adr_i : std_logic_vector(AW-1 downto 0);
    cti_i : std_logic_vector(2 downto 0);
    bte_i : std_logic_vector(1 downto 0);
    len_i : std_logic_vector((null)(MAX_BURST_LEN+1) downto 0);

    signal adr : std_logic_vector(AW-1 downto 0);
    signal adr_high : std_logic_vector(AW-1 downto 0);
    signal adr_low : std_logic_vector(AW-1 downto 0);

    constant shift : integer;
  ) return std_logic_vector is
    variable adr_range_return : std_logic_vector (2*AW-1 downto 0);
  begin


    --if (BPW == 4) begin
    BROKEN_CLOG2_GENERATING_0 : if (BROKEN_CLOG2 = '1') generate
      shift <= (null)(BPW);
    elsif (BROKEN_CLOG2 = '0') generate
      shift <= (null)(BPW);
    end generate;
    adr <= adr_i srl shift;
    if (cti_i = CTI_INC_BURST) then
      case ((bte_i)) is
      when BTE_LINEAR =>
        adr_high <= adr+len_i;
        adr_low <= adr;
      when BTE_WRAP_4 =>
        adr_high <= adr(AW-1 downto 2)*4+4;
        adr_low <= adr(AW-1 downto 2)*4;
      when BTE_WRAP_8 =>
        adr_high <= adr(AW-1 downto 3)*8+8;
        adr_low <= adr(AW-1 downto 3)*8;
      when BTE_WRAP_16 =>
        adr_high <= adr(AW-1 downto 4)*16+16;
        adr_low <= adr(AW-1 downto 4)*16;
      when others =>
        (null)("%d : Illegal burst type (%b)", timing(), bte_i);
        adr_range_return <= concatenate(2*AW, 'x');
      end case;
    else    -- case (bte_i)
      adr_high <= adr+1;
      adr_low <= adr;
    end if;


    adr_high <= (adr_high sll shift)-1;
    adr_low <= adr_low sll shift;
    adr_range_return <= (adr_high & adr_low);
    return adr_range_return;
  end adr_range;

  --end


  --////////////////////////////////////////////////////////////////
  --
  -- Tasks
  --

  --Gather transaction statistics
  --TODO: Record shortest/longest bursts.
  procedure update_stats (
    cti : in std_logic_vector(2 downto 0);
    bte : in std_logic_vector(1 downto 0);
    burst_length : in std_logic
  ) is
  begin
    case ((cti)) is
    when CTI_CLASSIC =>
      cnt_cti_classic <= cnt_cti_classic+1;
    when CTI_CONST_BURST =>
      cnt_cti_const_burst <= cnt_cti_const_burst+1;
    when CTI_INC_BURST =>
      cnt_cti_inc_burst <= cnt_cti_inc_burst+1;
    when others =>
      cnt_cti_invalid <= cnt_cti_invalid+1;
    end case;
    -- case (cti)
    if (cti = CTI_INC_BURST) then
      case ((bte)) is
      when BTE_LINEAR =>
        cnt_bte_linear <= cnt_bte_linear+1;
      when BTE_WRAP_4 =>
        cnt_bte_wrap_4 <= cnt_bte_wrap_4+1;
      when BTE_WRAP_8 =>
        cnt_bte_wrap_8 <= cnt_bte_wrap_8+1;
      when BTE_WRAP_16 =>
        cnt_bte_wrap_16 <= cnt_bte_wrap_16+1;
      when others =>
        (null)("Invalid BTE %2b", bte);
      end case;
    end if;
  end update_stats;

  -- case (bte)


  procedure display_stats (
  ) is
  begin
    (null)("#################################");
    (null)("##### Cycle Type Statistics #####");
    (null)("#################################");
    (null)("Invalid cycle types   : %0d", cnt_cti_invalid);
    (null)("Classic cycles        : %0d", cnt_cti_classic);
    (null)("Constant burst cycles : %0d", cnt_cti_const_burst);
    (null)("Increment burst cycles: %0d", cnt_cti_inc_burst);
    (null)("   Linear bursts      : %0d", cnt_bte_linear);
    (null)("   4-beat bursts      : %0d", cnt_bte_wrap_4);
    (null)("   8-beat bursts      : %0d", cnt_bte_wrap_8);
    (null)("  16-beat bursts      : %0d", cnt_bte_wrap_16);
  end display_stats;



  procedure display_subtransaction (
    address : in std_logic_vector(AW-1 downto 0);
    cycle_type : in std_logic_vector(2 downto 0);
    burst_type : in std_logic_vector(1 downto 0);
    burst_length : in std_logic;
    wr : in std_logic

  ) is
  begin
    if (VERBOSE > 0) then
      (null)("  Subtransaction %0d.%0d ", transaction, subtransaction);
      if (wr) then
        (null)("(Write)");
      else
        (null)("(Read) ");
      end if;
      (null)(": Start Address: %h, Cycle Type: %b, Burst Type: %b, Burst Length: %0d", address, cycle_type, burst_type, burst_length);
    end if;
  end display_subtransaction;



  procedure set_transactions (
    transactions_i : in std_logic
  ) is
  begin
    TRANSACTIONS <= transactions_i;
  end set_transactions;



  procedure set_subtransactions (
    transactions_i : in std_logic
  ) is
  begin
    SUBTRANSACTIONS <= transactions_i;
  end set_subtransactions;



  -- Task to fill Write Data array.
  -- random data will be used.
  procedure fill_wdata_array (
    burst_length : in std_logic_vector(31 downto 0);

    constant word : integer;
  ) is
  begin


    -- Fill write data array
    for word in 0 to burst_length-1 loop
      bfm.write_data(word) <= random;
    end loop;
  end fill_wdata_array;



  procedure display_settings (
  ) is
  begin
    (null)("##############################################################");
    (null)("############# Wishbone Master Test Configuration #############");
    (null)("##############################################################");
    (null)("");
    (null)("%m:");
    if (NUM_SEGMENTS > 0) then
      (null)("  Number of segments    : %0d", NUM_SEGMENTS);
      (null)("  Segment size          : %h", SEGMENT_SIZE);
      (null)("  Memory High Address   : %h", MEM_LOW+NUM_SEGMENTS*SEGMENT_SIZE-1);
      (null)("  Memory Low Address    : %h", MEM_LOW);
    else
      (null)("  Memory High Address   : %h", MEM_HIGH);
      (null)("  Memory Low Address    : %h", MEM_LOW);
    end if;
    (null)("  Transactions          : %0d", TRANSACTIONS);
    (null)("  Subtransactions       : %0d", SUBTRANSACTIONS);
    (null)("  Max Burst Length      : %0d", MAX_BURST_LEN);
    (null)("  Max Wait States       : %0d", MAX_WAIT_STATES);
    (null)("  Classic Cycle Prob    : %0d", CLASSIC_PROB);
    (null)("  Const Addr Cycle Prob : %0d", CONST_BURST_PROB);
    (null)("  Incr Addr Cycle Prob  : %0d", INCR_BURST_PROB);
    (null)("  Write Data            : Random");
    (null)("  Buffer Data           : Mirrors RAM");
    (null)("  $random Seed          : %0d", SEED);
    (null)("  Verbosity             : %0d", VERBOSE);
    (null)("");
    (null)("############# Starting Wishbone Master Tests...  #############");
    (null)("");
  end display_settings;

  procedure run (
  ) is
  begin
    if (TRANSACTIONS < 1) then
      (null)("%0d transactions requested. Number of transactions must be set to > 0", TRANSACTIONS);
      finish;
    end if;
    bfm.reset;
    done <= 0;
    st_type <= 0;
    err <= 0;

    for transaction in 1 to TRANSACTIONS loop
      if (VERBOSE > 0) then
        (null)("%m : Transaction: %0d/%0d", transaction, TRANSACTIONS);
      elsif (not (transaction mod (SUBTRANSACTIONS/10))) then
        (null)("%m : Transaction: %0d/%0d", transaction, TRANSACTIONS);

      end if;
      -- Generate the random value for the number of wait states. This will
      -- be used for all of this transaction
      bfm.wait_states <= ((null)(SEED)) mod (MAX_WAIT_STATES+1);
      if (VERBOSE > 2) then
        (null)("  Number of Wait States for Transaction %0d is %0d", transaction, bfm.wait_states);

      end if;
      --If running in segment mode, cap mem_high/mem_low to a segment
      if (NUM_SEGMENTS > 0) then
        segment <= ((null)(SEED)) mod NUM_SEGMENTS;
        mem_lo <= MEM_LOW+segment*SEGMENT_SIZE;
        mem_hi <= MEM_LOW+(segment+1)*SEGMENT_SIZE-1;
      else
        mem_lo <= MEM_LOW;
        mem_hi <= MEM_HIGH;
      end if;


      -- Check if initial base address and max burst length lie within
      -- mem_hi/mem_lo bounds. If not, regenerate random values until condition met.
      t_adr_high <= 0;
      t_adr_low <= 0;
      while ((t_adr_high > mem_hi) or (t_adr_low < mem_lo) or (t_adr_high = t_adr_low)) loop
        t_address <= (null)(mem_lo, mem_hi);
        (t_adr_high & t_adr_low) <= (null)(t_address, MAX_BURST_LEN, CTI_INC_BURST, BTE_LINEAR);
      end loop;


      -- Write Transaction
      if (VERBOSE > 0) then
        (null)("  Transaction %0d Initialisation (Write): Start Address: %h, Burst Length: %0d", transaction, t_address, MAX_BURST_LEN);

      end if;
      -- Fill Write Array then Send the Write Transaction
      (null)(MAX_BURST_LEN);
      (null)(t_address, t_address, concatenate(DW/8, '1'), CTI_INC_BURST, BTE_LINEAR, MAX_BURST_LEN, err);
      (null)(cycle_type, burst_type, burst_length);

      -- Read data can be read back from wishbone memory.
      if (VERBOSE > 0) then
        (null)("  Transaction %0d Initialisation (Read): Start Address: %h, Burst Length: %0d", transaction, t_address, MAX_BURST_LEN);
      end if;
      (null)(t_address, t_address, concatenate(DW/8, '1'), CTI_INC_BURST, BTE_LINEAR, MAX_BURST_LEN, err);
      (null)(cycle_type, burst_type, burst_length);

      if (VERBOSE > 0) then
        (null)("Transaction %0d initialisation ok (Start Address: %h, Cycle Type: %b, Burst Type: %b, Burst Length: %0d)", transaction, t_address, CTI_INC_BURST, BTE_LINEAR, MAX_BURST_LEN);

      end if;
      -- Start subtransaction loop.
      for subtransaction in 1 to SUBTRANSACTIONS loop

        -- Transaction Type: 0=Read, 1=Write
        st_type <= ((null)(SEED)) mod 2;

        (st_address & cycle_type & burst_type & burst_length) <= (null)(t_adr_low, t_adr_high);

        (null)(st_address, cycle_type, burst_type, burst_length, st_type);

        if (not st_type) then

          -- Send Read Transaction
          (null)(t_address, st_address, concatenate(DW/8, '1'), cycle_type, burst_type, burst_length, err);

        else

        -- Fill Write Array then Send the Write Transaction
          (null)(burst_length);
          (null)(t_address, st_address, concatenate(DW/8, '1'), cycle_type, burst_type, burst_length, err);

        end if;
        -- if (st_type)
        (null)(cycle_type, burst_type, burst_length);
      end loop;
      -- for (subtransaction=0;...

      -- Final consistency check...
      if (VERBOSE > 0) then
        (null)("Transaction %0d Buffer Consistency Check: Start Address: %h, Burst Length: %0d", transaction, t_address, MAX_BURST_LEN);
      end if;
      (null)(t_address, t_address, X"f", CTI_INC_BURST, BTE_LINEAR, MAX_BURST_LEN, err);

      if (VERBOSE > 0) then
        (null)("Transaction %0d Completed Successfully", transaction);

      end if;
      -- Clear Buffer Data before next transaction
      bfm.clear_buffer_data;
    end loop;
    -- for (transaction=0;...
    done <= 1;
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
      (null)("ERROR: Wishbone Cycle Probability values must total 100. Current values total %0d:", (CLASSIC_PROB+CONST_BURST_PROB+INCR_BURST_PROB));
      (null)("         Classic Cycle Probability                    : %0d", CLASSIC_PROB);
      (null)("         Constant Address Burst Cycle Probability     : %0d", CONST_BURST_PROB);
      (null)("         Incrementing Address Burst Cycle Probability : %0d", INCR_BURST_PROB);
      (null)(1);
    end if;
    if (AUTORUN) then
      display_settings;
      run;
      display_stats;
      done <= 1;
    end if;
  end process;


  bfm : mpsoc_msi_wb_bfm_master
  generic map (
    DW, 
    MAX_BURST_LEN, 
    MAX_WAIT_STATES, 
    VERBOSE
  )
  port map (
    wb_clk_i => wb_clk_i,
    wb_rst_i => wb_rst_i,
    wb_adr_o => wb_adr_o,
    wb_dat_o => wb_dat_o,
    wb_sel_o => wb_sel_o,
    wb_we_o => wb_we_o,
    wb_cyc_o => wb_cyc_o,
    wb_stb_o => wb_stb_o,
    wb_cti_o => wb_cti_o,
    wb_bte_o => wb_bte_o,
    wb_dat_i => wb_dat_i,
    wb_ack_i => wb_ack_i,
    wb_err_i => wb_err_i,
    wb_rty_i => wb_rty_i
  );
end RTL;
