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
        outputBufferWriteACK: in std_logic;

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
    subtype SourcePEsArray_t is array(0 to AmountOfSourcePEs - 1) of integer;

    function FillSourcePEsArray return sourcePEsArray_t is
        variable tempArray : SourcePEsArray_t;
    begin

        FillSourcesLoop: for i in 0 to (AmountOfSourcePEs - 1) loop
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ("SourcePEs/" & i'image) ); 
        end loop;

        return tempArray;

    end function FillSourcePEsArray;

    constant SourcePEsArray : SourcePEsArray_t := FillSourcePEsArray;

    -- Target PEs constants (Lower numbered targets in JSON have higher priority (target number 0 will have the highest priority) )
    constant AmountOfTargetPEs : integer := jsonGetInteger(InjectorJSONConfig, "AmountOfTargetPEs");
    subtype TargetPEsArray_t is array(0 to AmountOfTargetPEs - 1) of integer;

    function FillTargetPEsArray return TargetPEsArray_t is
        variable tempArray : TargetPEsArray_t;
    begin

        FillTargetsLoop: for i in 0 to (AmountOfTargetPEs - 1) loop
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ("TargetPEs/" & i'image) ); 
        end loop;

        return tempArray;

    end function FillTargetPEsArray;

    constant TargetPEsArray : TargetPEsArray_t := FillTargetPEsArray;

    -- Message parameters
    constant HeaderSize : integer := jsonGetInteger(InjectorJSONConfig, "HeaderSize");

    subtype PayloadSize_t is array(0 to AmountOfTargetPEs - 1) of std_logic_vector(dataWidth - 1 downto 0);

    function FillPayloadSizeArray return PayloadSize_t is
        variable tempArray : PayloadSize_t;
    begin

        FillPayloadSizeLoop: for i in 0 to (AmountOfTargetPEs - 1) loop 
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, "PayloadSize/" & i'image);
        end loop FillPayloadSizeLoop;

        return tempArray;

    end function;

    constant PayloadSize : PayloadSize_t := FillPayloadSizeArray;

    subtype HeaderFlits_t is array(0 to AmountOfTargetPEs - 1, 0 to HeaderSize - 1) of std_logic_vector(dataWidth - 1 downto 0);

    function FillHeaderFlitsArray return HeaderFlits_t is
        variable tempArray : HeaderFlits_t;
        variable headerFlit : string(1 to 4);
    begin

        BuildHeaderLoop: for i in 0 to (AmountOfTargetPEs - 1) loop

            BuildFlitLoop: for j in 0 to (HeaderSize - 1) loop

                headerFlit := jsonGetString(InjectorJSONConfig, "Header/" & i'image & "/" & j'image);

                if headerFlit = "ADDR" then 

                    tempArray(i)(j) := TargetPEsArray(i);

                elsif headerFlit = "SIZE" then

                    tempArray(i)(j) := PayloadSize(i);

                end if;
                                
            end loop BuildFlitLoop;

        end loop BuildHeaderLoop;

        return tempArray;

    end function FillHeaderFlitsArray;

    constant HeaderFlits: HeaderFlits_t := FillHeaderFlitsArray;

begin

	
	
end architecture RTL;