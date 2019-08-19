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
use work.PE_PKG.all;
use work.JSON.all;

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

		-- Output Interface
		dataOut : out std_logic_vector(dataWidth - 1 downto 0);
		dataOutAV : out std_logic;
		outputBufferWriteRequest : out std_logic;
        outputBufferWriteACK: in std_logic

	);

end entity Injector;

architecture RTL of Injector is

	-- JSON configuration file
    constant InjectorJSONConfig: T_JSON := jsonLoadFile(InjectorConfigFile);

    -- Injector type
    constant InjectorType: string(1 to 3) := jsonGetString(InjectorJSONConfig, "InjectorType");

    -- Fixed injection rate injector constants
    constant InjectionRate: integer range 0 to 100 := jsonGetInteger(InjectorJSONConfig, "InjectionRate");
    constant AmountOfMessagesInBurst: integer := jsonGetInteger(InjectorJSONConfig, "AmountOfMessagesInBurst");

    -- Dependant injector constants
    constant PEPos : integer := jsonGetInteger(InjectorJSONConfig, "PEPos");
    constant TaskID : integer := jsonGetInteger(InjectorJSONConfig, "TaskID");
    constant ThreadNumber : integer := jsonGetInteger(InjectorJSONConfig, "ThreadNumber");
    constant AverageProcessingTimeInClockPulses : integer := jsonGetInteger(InjectorJSONConfig, "AverageProcessingTimeInClockPulses");

    -- Source PEs constants
    constant AmountOfSourcePEs : integer := jsonGetInteger(InjectorJSONConfig, "AmountOfSourcePEs");
    constant SourcePEsArray : SourcePEsArray_t(0 to AmountOfSourcePEs - 1) := FillSourcePEsArray(InjectorJSONConfig, AmountOfSourcePEs);

    -- Target PEs constants (Lower numbered targets in JSON have higher priority (target number 0 will have the highest priority) )
    constant AmountOfTargetPEs : integer := jsonGetInteger(InjectorJSONConfig, "AmountOfTargetPEs");
    constant TargetPEsArray : TargetPEsArray_t(0 to AmountOfTargetPEs - 1) := FillTargetPEsArray(InjectorJSONConfig, AmountOfTargetPEs);

    -- Message parameters
    constant TargetPayloadSize : TargetPayloadSize_t(0 to AmountOfSourcePEs - 1) := FillTargetPayloadSizeArray(InjectorJSONConfig, AmountOfTargetPEs);
    constant SourcePayloadSize : SourcetPayloadSize_t(0 to AmountOfTargetPEs - 1) := FillTargetPayloadSizeArray(InjectorJSONConfig, AmountOfSourcePEs);

    constant HeaderSize : integer := jsonGetInteger(InjectorJSONConfig, "HeaderSize");
    constant HeaderFlits: HeaderFlits_t(0 to AmountOfTargetPEs - 1, 0 to HeaderSize - 1) := FillHeaderFlitsArray(InjectorJSONConfig, AmountOfTargetPEs, HeaderSize, TargetPEsArray, TargetPayloadSize);

begin

	
	
end architecture RTL;