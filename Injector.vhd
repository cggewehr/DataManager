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
		clock : in std_logic;
		reset : in std_logic;

		-- Input Interface
		dataIn : in std_logic_vector(dataWidth - 1 downto 0);
		dataInAV : in std_logic;
		inputBufferReadRequest : out std_logic;
		inputBufferWriteACK: in std_logic;

		-- Output Interface
		dataOut : out std_logic_vector(dataWidth - 1 downto 0);
		dataOutAV : out std_logic;
		outputBufferWriteRequest : out std_logic;

	);

end entity Injector;

architecture RTL of Injector is

begin
	
end architecture RTL;