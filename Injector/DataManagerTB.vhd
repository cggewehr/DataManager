--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:49:48 06/05/2019
-- Design Name:   
-- Module Name:   /home/carlos/Desktop/GitKraken/DataManager/DataManagerTB.vhd
-- Project Name:  DataManager_MPEG
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: DataManager_NOC
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY DataManagerTB IS
END DataManagerTB;
 
ARCHITECTURE behavior OF DataManagerTB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT DataManager_NOC
        GENERIC(
            taskID      : integer;      -- Allocated task ID
            threadId    : integer;      -- Allocated thread ID
            PEPos       : integer;      -- PE position in network (PE ID)
            targetPos   : integer;      -- Target PE position in network
            targetID    : integer       -- Target thread ID
        );
        PORT(
             clock    : IN  std_logic;
             reset    : IN  std_logic;
             clock_tx : OUT  std_logic;
             tx       : OUT  std_logic;
             data_out : OUT  std_logic_vector(31 downto 0);
             credit_i : IN  std_logic;
             clock_rx : IN  std_logic;
             rx       : IN  std_logic;
             data_in  : IN  std_logic_vector(31 downto 0);
             credit_o : OUT  std_logic
         );
    END COMPONENT;

   --Inputs
   signal clock    : std_logic := '0';
   signal reset    : std_logic := '0';
   signal credit_i : std_logic := '0';
   signal clock_rx : std_logic := '0';
   signal rx       : std_logic := '0';
   signal data_in  : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal clock_tx : std_logic;
   signal tx       : std_logic;
   signal data_out : std_logic_vector(31 downto 0);
   signal credit_o : std_logic;

   -- Clock period definitions
   constant clock_period    : time := 10 ns;
   constant clock_tx_period : time := 10 ns;
   constant clock_rx_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: DataManager_NOC 
        GENERIC MAP(
            taskID      => 0,      -- Allocated task ID
            threadId    => 1,      -- Allocated thread ID
            PEPos       => 2,      -- PE position in network (PE ID)
            targetPos   => 8,      -- Target PE position in network
            targetID    => 0       -- Target thread ID
        )
        PORT MAP (
          clock    => clock,
          reset    => reset,
          clock_tx => clock_tx,
          tx       => tx,
          data_out => data_out,
          credit_i => credit_i,
          clock_rx => clock_rx,
          rx       => rx,
          data_in  => data_in,
          credit_o => credit_o
        );

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;
 
   clock_rx <= clock;
   clock_tx <= not clock;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      reset <= '1';
      wait for 100 ns;	
      reset <= '0';

      wait for clock_period*10;

      
      -- insert stimulus here 

      wait;
   end process;

END;
