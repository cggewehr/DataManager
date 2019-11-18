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
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    
library work;
    use work.PE_PKG.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
entity PE_TB is
end PE_TB;
 
architecture testbench OF PE_TB is 

    --Inputs
    signal Clock : std_logic := '0';
    signal Reset : std_logic := '0';
    signal Credit_i  : std_logic := '0';
    signal Clock_rx : std_logic := '0';
    signal Rx : std_logic := '0';
    signal Data_in : std_logic_vector(31 downto 0) := (others => '0');
 
    --Outputs
    signal Clock_tx : std_logic;
    signal Tx : std_logic;
    signal Data_out : std_logic_vector(31 downto 0);
    signal Credit_o : std_logic;

    -- Clock period definitions
    constant clock_period : time := 10 ns;
 
begin
 
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.PE 
        generic map(
            --PEConfigFile => "C:\Projetos Vivado\Injetor\PESample.json",
            PEConfigFile => "C:\Users\CarlosGabriel\Documents\GitKraken\DataManager\PESample.json",
            --InjectorConfigFile => "C:\Projetos Vivado\Injetor\InjectorSample.json"
            InjectorConfigFile => "C:\Users\CarlosGabriel\Documents\GitKraken\DataManager\InjectorSample.json"
        )
        port map (

            -- Basic
            Clock => Clock,
            Reset => Reset,

            -- NoC Interface      
            Clock_tx => Clock_tx,
            Tx => Tx,
            Data_out => Data_out,
            Credit_i => Credit_i,
            Clock_rx => Clock_rx,    
            Rx => Rx,
            Data_in => Data_in,
            Credit_o => Credit_o  -- Debug MC
        );

    -- Clock process definitions
    clockProcess: process
    begin

		    Clock <= '0';
		    wait for clock_period/2;
		    Clock <= '1';
		    wait for clock_period/2;
        
    end process;
 
    -- Stimulus process
    stimProcess: process
    begin		

        -- hold reset state for 100 ns.
        Reset <= '1';
        wait for 100 ns;	
        Reset <= '0';
      
        -- insert stimulus here 
        Credit_i <= '1';

        wait;
    end process;

end architecture testbench;