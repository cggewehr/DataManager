---------------------------------------------------------------------------------------------------------
-- DESIGN UNIT  : MSG Injector (Fixed injection rate, series dependant or parallel dependant)          --
-- DESCRIPTION  :                                                                                      --
-- AUTHOR       : Carlos Gabriel de Araujo Gewehr                                                      --
-- CREATED      : Aug 13th, 2019                                                                        --
-- VERSION      : v0.1                                                                                 --
-- HISTORY      : Version 0.1 - Aug 13th, 2019                                                          --
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- TODO         : 
    -- Finish entity interface
    -- Make fixed injection rate architecture
    -- Make series dependant architecture
    -- Make parallel dependant architecture
---------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.HeMPS_defaults.all;
use work.HemPS_PKG.all;

entity Injector is

	generic (
        PEConfigFile          : string;
        InjectorConfigFile    : string
	);

	port (

		-- Basic
		clock : std_logic;
		reset : std_logic;

		-- Input Interface
		dataIn : std_logic_vector(dataWidth - 1 downto 0);
		dataInAV : std_logic;
		inputBufferReadRequest : std_logic;

		-- Output Interface
		dataOut : std_logic_vector(dataWidth - 1 downto 0);
		dataOutAV : std_logic;
		outputBufferWriteRequest : std_logic;

	);

end entity Injector;

architecture RTL of Injector is

begin
	
end architecture RTL;