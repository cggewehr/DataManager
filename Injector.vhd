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
		dataIn : in DataWidth_t;
		dataInAV : in std_logic;
		inputBufferReadRequest : out std_logic;

		-- Output Interface
		dataOut : out DataWidth_t;
		dataOutAV : out std_logic;
        outputBufferSlotAvailable : in std_logic;
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
    constant AppID : integer := jsonGetInteger(InjectorJSONConfig, "APPID");
    constant ThreadID : integer := jsonGetInteger(InjectorJSONConfig, "ThreadID");
    constant AverageProcessingTimeInClockPulses : integer := jsonGetInteger(InjectorJSONConfig, "AverageProcessingTimeInClockPulses");

    -- Source PEs constants
    constant AmountOfSourcePEs : integer := jsonGetInteger(InjectorJSONConfig, "AmountOfSourcePEs");
    constant SourcePEsArray : SourcePEsArray_t(0 to AmountOfSourcePEs - 1) := FillSourcePEsArray(InjectorJSONConfig, AmountOfSourcePEs);

    -- Target PEs constants (Lower numbered targets in JSON have higher priority (target number 0 will have the highest priority)
    constant AmountOfTargetPEs : integer := jsonGetInteger(InjectorJSONConfig, "AmountOfTargetPEs");
    constant TargetPEsArray : TargetPEsArray_t(0 to AmountOfTargetPEs - 1) := FillTargetPEsArray(InjectorJSONConfig, AmountOfTargetPEs);

    -- Message parameters
    constant TargetPayloadSizeArray : TargetPayloadSize_t(0 to AmountOfSourcePEs - 1) := FillTargetPayloadSizeArray(InjectorJSONConfig, AmountOfTargetPEs);
    constant SourcePayloadSizeArray : SourcetPayloadSize_t(0 to AmountOfTargetPEs - 1) := FillSourcePayloadSizeArray(InjectorJSONConfig, AmountOfSourcePEs);

    constant HeaderSize : integer := jsonGetInteger(InjectorJSONConfig, "HeaderSize");
    constant HeaderFlits: HeaderFlits_t(0 to AmountOfTargetPEs - 1, 0 to HeaderSize - 1) := BuildHeaders(InjectorJSONConfig, AmountOfTargetPEs, HeaderSize, TargetPEsArray, TargetPayloadSize);

    constant TargetMessageSizeArray : TargetMessageSize_t := FillTargetMessageSizeArray(TargetPayloadSize, HeaderSize, AmountOfTargetPEs); 

    constant MaxPayloadSize : integer := FindMaxPayloadSize(TargetPayloadSizeArray);

    constant PayloadFlits : PayloadFlits_t := BuildPayloads(InjectorJSONConfig, TargetPayloadSizeArray);

begin

    inputBufferReadRequest <= '1';

    FixedRateInjetor: block (InjectorType = "FXD") is

        type state_t is (Sreset, Ssending, Swaiting);
        signal nextState, currentState : state_t;

    begin

        process(clock, reset) begin

            if rising_edge(clock) then

                if reset = '1' then

                    currentState <= Sreset;

                else

                    currentState <= nextState;

                end if;

            end if;

        end process;

        process(clock)
            variable injectionCounter := 0;
            variable injectionPeriod := ((TargetMessageSizeArray(0) * 100) / InjectionRate) - TargetMessageSizeArray(0);
        begin

            if rising_edge(clock) then

                if currentState = Sreset then

                    injectionCounter := 0;
                    injectionPeriod := ((TargetMessageSizeArray(0) * 100) / InjectionRate) - TargetMessageSizeArray(0);

                    inputBufferReadRequest <= '0';
                    outputBufferWriteRequest <= '0';
                    dataOutAV <= '0';

                    nextState <= Ssending;

                elsif currentState = Ssending then

                    -- Sends a flit to buffer

                    if outputBufferSlotAvailable = '1' then

                        dataOutAV <= '1';
                        outputBufferWriteRequest <= '1';

                        if injectionCounter < HeaderSize then

                            dataOut <= HeaderFlits(0)(injectionCounter);

                        elsif injectionCounter < TargetMessageSizeArray(0) then

                            dataOut <= PayloadFlits(0)(injectionCounter - HeaderSize);

                        end if;

                        injectionCounter := injectionCounter + 1;

                        if injectionCounter = TargetMessageSizeArray(0) then
                            injectionCounter := 0;
                            nextState <= Swaiting;
                        else
                            nextState <= Ssending;
                        end if;

                    else -- outputBufferSlotAvailable = '0' (Cant write to buffer)

                        nextState <= Ssending;

                    end if;
                    
                elsif currentState = Swaiting then -- Idles to mantain defined injection rate

                    outputBufferWriteRequest <= '0';

                    injectionCounter := injectionCounter + 1;

                    if injectionCounter = injectionPeriod then
                        injectionCounter := 0;
                        nextState <= Ssending;
                    else
                        nextState <= Swaiting;
                    end if;

                end if;

            end if;

        end process;

    end block FixedRateInjetor;

	DependantInjector : block (InjectorType = "DPD") is
        
    begin
    
    end block DependantInjector;
	
end architecture RTL;