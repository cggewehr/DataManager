---------------------------------------------------------------------------------------------------------
-- DESIGN UNIT  : MSG Injector (Fixed injection rate or series dependent)                              --
-- DESCRIPTION  :                                                                                      --
-- AUTHOR       : Carlos Gabriel de Araujo Gewehr                                                      --
-- CREATED      : Aug 13th, 2019                                                                       --
-- VERSION      : v0.1                                                                                 --
-- HISTORY      : Version 0.1 - Aug 13th, 2019                                                         --
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- TODO         : 
    -- Make fixed injection rate architecture
    -- Make dependent architecture
---------------------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    --use ieee.std_logic_unsigned.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all; -- for random number generation

library work;
    use work.PE_PKG.all;
    use work.JSON.all;

entity Injector is

	generic (
        PEConfigFile          : string;
        InjectorConfigFile    : string
	);

	port (

		-- Basic
		Clock : in std_logic;
		Reset : in std_logic;

		-- Input Interface
		DataIn : in DataWidth_t;
		DataInAV : in std_logic;
		InputBufferReadRequest : out std_logic;

		-- Output Interface
		DataOut : out DataWidth_t;
		DataOutAV : out std_logic;
        OutputBufferSlotAvailable : in std_logic;
		OutputBufferWriteRequest : out std_logic;
        OutputBufferWriteACK: in std_logic

	);

end entity Injector;

architecture RTL of Injector is

	-- JSON configuration file
    constant InjectorJSONConfig: T_JSON := jsonLoadFile(InjectorConfigFile);

    -- Injector type ("FXD" or "DPD")
    constant InjectorType: string(1 to 3) := jsonGetString(InjectorJSONConfig, "InjectorType");

    -- Message Flow type ("RND" or "DTM")
    constant FlowType: string(1 to 3) := jsonGetString(InjectorJSONConfig, "FlowType");

    -- Fixed injection rate injector constants
    constant InjectionRate: integer range 0 to 100 := integer'value(jsonGetString(InjectorJSONConfig, "InjectionRate"));

    -- Dependant injector constants
    constant PEPos : integer := integer'value(jsonGetString(InjectorJSONConfig, "PEPos"));
    constant AppID : integer := integer'value(jsonGetString(InjectorJSONConfig, "APPID"));
    constant ThreadID : integer := integer'value(jsonGetString(InjectorJSONConfig, "ThreadID"));
    constant AverageProcessingTimeInClockPulses : integer := integer'value(jsonGetString(InjectorJSONConfig, "AverageProcessingTimeInClockPulses"));

    -- Source PEs constants
    constant AmountOfSourcePEs : integer := integer'value(jsonGetString(InjectorJSONConfig, "AmountOfSourcePEs"));
    constant SourcePEsArray : SourcePEsArray_t(0 to AmountOfSourcePEs - 1) := FillSourcePEsArray(InjectorJSONConfig, AmountOfSourcePEs);

    -- Target PEs constants (Lower numbered targets in JSON have higher priority (target number 0 will have the highest priority)
    constant AmountOfTargetPEs : integer := integer'value(jsonGetString(InjectorJSONConfig, "AmountOfTargetPEs"));
    constant TargetPEsArray : TargetPEsArray_t(0 to AmountOfTargetPEs - 1) := FillTargetPEsArray(InjectorJSONConfig, AmountOfTargetPEs);
    constant AmountOfMessagesInBurstArray: AmountOfMessagesInBurstArray_t := FillAmountOfMessagesInBurstArrayArray(InjectorJSONConfig, AmountOfTargetPEs);

    -- Message parameters
    constant TargetPayloadSizeArray : TargetPayloadSizeArray_t(0 to AmountOfSourcePEs - 1) := FillTargetPayloadSizeArray(InjectorJSONConfig, AmountOfTargetPEs);
    constant SourcePayloadSizeArray : SourcetPayloadSizeArray_t(0 to AmountOfTargetPEs - 1) := FillSourcePayloadSizeArray(InjectorJSONConfig, AmountOfSourcePEs);

    constant HeaderSize : integer := integer'value(jsonGetString(InjectorJSONConfig, "HeaderSize"));
    constant HeaderFlits : HeaderFlits_t(0 to AmountOfTargetPEs - 1, 0 to HeaderSize - 1) := BuildHeaders(InjectorJSONConfig, HeaderSize, TargetPayloadSizeArray, TargetPEsArray);

    constant TargetMessageSizeArray : TargetMessageSize_t := FillTargetMessageSizeArray(TargetPayloadSizeArray, HeaderSize); 
    constant SourceMessageSizeArray : SourceMessageSize_t := FillSourceMessageSizeArray(SourcePayloadSizeArray, HeaderSize);

    constant MaxPayloadSize : integer := FindMaxPayloadSize(TargetPayloadSizeArray);

    constant PayloadFlits : PayloadFlits_t(TargetPayloadSizeArray'range, 0 to MaxPayloadSize - 1) := BuildPayloads(InjectorJSONConfig, TargetPayloadSizeArray, TargetPEsArray);

    -- Payload Flags
    constant timestampFlag : integer := integer'value(jsonGetString(InjectorJSONConfig, "timestampFlag"));
    constant amountOfMessagesSentFlag : integer := integer'value(jsonGetString(InjectorJSONConfig, "amountOfMessagesSentFlag"));

    -- RNG Seed
    constant RNGSeed : integer := integer'value(jsonGetString(InjectorJSONConfig, "RNGSeed"));

    -- Clock Counter
    signal ClockCounter : integer range 0 to (2**32) - 1 := 0;

    -- Semaphore for flow control if DPD injector is instantiated
    signal Semaphore : integer range 0 to (2**32) - 1 := 0;

    -- Simple increment and wrap around
    procedure incr(signal value: inout integer ; maxValue: in integer ; minValue: in integer) is

    begin

        if value = maxValue then
            value <= minValue;
        else
            value <= value + 1;
        end if;

    end procedure;

    -- Simple decrement and wrap around
    procedure decr(signal value: inout integer ; maxValue: in integer ; minValue: in integer) is

    begin

        if value = minValue then
            value <= maxValue;
        else
            value <= value - 1;
        end if;

    end procedure;


begin


    -- A simple clock rising edge counter. Wraps back to 0 once maximum allowed value is reached.
    CLKCOUNTER: process(Clock, Reset) begin

        if Reset = '1' then

            ClockCounter <= 0;

        elsif rising_edge(Clock) then

            incr(ClockCounter, ((2**32) - 1) , 0);

        end if;

    end process;


    -- Sends out messages at a constant injection rate. (Only instanciated if InjectorType is set as "FXD" on JSON config file).
    FixedRateInjetor: block (InjectorType = "FXD") is

    begin

        Transmitter: process(Clock, Reset)

            variable injectionCounter : integer := 0;
            variable injectionPeriod : integer := ((TargetMessageSizeArray(0) * 100) / InjectionRate) - TargetMessageSizeArray(0);
            variable flitTemp : DataWidth_t := (others=>'0');
            variable firstFlitOutTimestamp : DataWidth_t := (others=>'0');
            variable amountOfMessagesSent : DataWidth_t := (others=>'0');
            variable currentTargetPE : integer := 0;
            variable burstCounter : integer := 0;

            type state_t is (Sreset, Ssending, Swaiting);
            variable nextState, currentState : state_t;

        begin

            if rising_edge(clock) then

                if reset = '1' then

                    currentState := Sreset;

                else

                    currentState := nextState;

                end if;

                -- Sets default values
                if currentState = Sreset then

                    injectionCounter := 0;
                    injectionPeriod := ( (TargetMessageSizeArray(0) * 100) / InjectionRate) - TargetMessageSizeArray(0);

                    outputBufferWriteRequest <= '0';
                    dataOutAV <= '0';

                    firstFlitOutTimestamp := (others=>'0');
                    amountOfMessagesSent := (others=>'0');

                    currentTargetPE := 0;
                    burstCounter := 0;

                    -- Sets seed for RNG
                    SRAND(RNGSeed);

                    nextState := Ssending;

                -- Sends a flit to output buffer
                elsif currentState = Ssending then

                    -- Sends a flit to buffer
                    if outputBufferSlotAvailable = '1' then

                        -- Decides what flit to send (Header or Payload)
                        if injectionCounter < HeaderSize then

                            -- If this is the first flit in the message, saves current ClkCounter (to be sent as a flit when a payload flit is equal to the timestampFlag)
                            if injectionCounter = 0 then

                                firstFlitOutTimestamp := ClockCounter;

                            end if;

                            -- A Header flit will be sent
                            flitTemp := HeaderFlits(currentTargetPE)(injectionCounter);

                        -- Not a header flit
                        else

                            -- A Payload flit will be sent
                            flitTemp := PayloadFlits(currentTargetPE)(injectionCounter - HeaderSize);

                        end if;

                        -- Replaces real time flags with respective value
                        if flitTemp = timestampFlag then

                            flitTemp := firstFlitOutTimestamp;

                        elsif flitTemp = amountOfMessagesSentFlag then

                            flitTemp := amountOfMessagesSent;

                        end if;

                        -- Outbound data bus receives the flit to be sent
                        dataOut <= flitTemp;

                        -- Increments flits sent counter
                        injectionCounter := injectionCounter + 1;

                        -- Decides whether to send another flit or idle to maintain injection rate
                        if injectionCounter = TargetMessageSizeArray(currentTargetPE) then

                            -- Message has been sent, will idle next state
                            dataOutAV <= '1';
                            outputBufferWriteRequest <= '1';
                            injectionCounter := 0;
                            amountOfMessagesSent := amountOfMessagesSent + 1;
                            burstCounter := burstCounter + 1;
                            nextState := Swaiting;

                            -- Determines if burst has ended
                            if burstCounter = (AmountOfMessagesInBurstArray(currentTargetPE)) then

                                burstCounter := 0;

                                -- Determines next target PE
                                if FlowType = "RND" then

                                    -- Uses RAND function from ieee.math_real. currentTargetPE gets a value between 0 and (AmountOfTargetPEs - 1)
                                    currentTargetPE <= RAND() % AmountOfTargetPEs;

                                elsif FlowType = "DTM" then

                                    -- Next message will be sent to next sequential target as defined on TargetPEsArray
                                    incr(currentTargetPE, AmountOfTargetPEs - 1, 0);

                                end if;

                            end if;

                        else

                            -- Signals dataOut is valid. Will send another flit next sate
                            dataOutAV <= '1';
                            outputBufferWriteRequest <= '1';
                            nextState := Ssending;

                        end if;

                    else -- outputBufferSlotAvailable = '0' (Cant write to buffer)

                        -- TODO: Assert message signaling unavailable buffer
                        nextState := Ssending;

                    end if;
                    
                 -- Idles to maintain defined injection rate
                elsif currentState = Swaiting then

                    -- Signals DataOut isn't valid
                    dataOutAV <= '0';
                    outputBufferWriteRequest <= '0';

                    -- Increments flit counter
                    injectionCounter := injectionCounter + 1;

                    -- Decides whether to send another flit or idle to maintain injection rate
                    if injectionCounter = injectionPeriod then

                        injectionCounter := 0;
                        nextState := Ssending;

                        -- Gets new injection period value (according to new message)
                        injectionPeriod := ( (TargetMessageSizeArray(currentTargetPE) * 100) / InjectionRate) - TargetMessageSizeArray(currentTargetPE);

                    else

                        nextState := Swaiting;
                        
                    end if;

                end if;

            end if;

        end process;

    end block FixedRateInjetor;


    -- Waits for a specific message, then sends out messages after that message is received. (Only instanciated if InjectorType is set as "DPD" on JSON config file).
	DependantInjector: block (InjectorType = "DPD") is
        
    begin

        Transmitter: process(Clock, Reset)

            variable flitCounter : integer := 0;
            variable processingCounter : integer := 0;
            variable flitTemp : DataWidth_t := (others=>'0');
            variable firstFlitOutTimestamp : DataWidth_t;
            variable amountOfMessagesSent : DataWidth_t;
            variable currentTargetPE : integer := 0;
            variable burstCounter : integer := 0;

            type state_t is (Sreset, Swaiting, Sprocessing, Ssending);
            variable nextState, currentState : state_t;

        begin

            if rising_edge(Clock) then

                if Reset = '1' then

                    currentState := Sreset;

                else

                    currentState := nextState;

                end if;

                -- Sets default values
                if currentState = Sreset then

                    outputBufferWriteRequest <= '0';
                    dataOutAV <= '0';

                    firstFlitOutTimestamp := (others=>'0');
                    amountOfMessagesSent := (others=>'0');

                    currentTargetPE := 0;
                    burstCounter := 0;

                    -- Sets seed for RNG
                    SRAND(RNGSeed);

                    nextState := Swaiting;

                -- Waits for a message to be received
                elsif currentState = Swaiting then

                    -- Checks for a new message
                    if Semaphore > 0 then

                        -- A new message was received, goes into processing state and decreases Semaphore
                        decr(Semaphore, (2**32) - 1, 0);
                        processingCounter := 0;
                        nextState := Sprocessing;

                    -- No new message was received in the last clock period
                    else

                        -- Waits for a new message to be received
                        nextState := Swaiting;

                    end if;

                -- Idle for AverageProcessingTimeInClockPulses, and then send a message burst
                elsif currentState = Sprocessing then

                    -- (Constant value is AverageProcessingTimeInClockPulses - 1 to account for the cycle wasted in Swaiting after a message was received) 
                    if processingCounter = AverageProcessingTimeInClockPulses - 1 then

                        -- Done idling, will begin to send message next cycle
                        injectionCounter := 0;
                        nextState := Ssending;

                    else

                        -- Still not done idling, will idle next state again
                        processingCounter := processingCounter + 1;
                        nextState := Sprocessing;

                    end if;

                -- Sends a flit to output buffer
                elsif currentState = Ssending then

                    -- Sends a flit to buffer
                    if outputBufferSlotAvailable = '1' then

                        -- Decides what flit to send (Header or Payload)
                        if injectionCounter < HeaderSize then

                            -- If this is the first flit in the message, saves current ClkCounter (to be sent as a flit when a payload flit is equal to the timestampFlag)
                            if injectionCounter = 0 then

                                firstFlitOutTimestamp := ClockCounter;

                            end if;

                            -- A Header flit will be sent
                            flitTemp := HeaderFlits(currentTargetPE)(injectionCounter);

                        -- Not a header flit
                        else

                            -- A Payload flit will be sent
                            flitTemp := PayloadFlits(currentTargetPE)(injectionCounter - HeaderSize);

                        end if;

                        -- Replaces real time flags with respective value
                        if flitTemp = timestampFlag then

                            flitTemp := firstFlitOutTimestamp;

                        elsif flitTemp = amountOfMessagesSentFlag then

                            flitTemp := amountOfMessagesSent;

                        end if;

                        -- Outbound data bus receives the flit to be sent
                        dataOut <= flitTemp;

                        -- Increments flits sent counter
                        injectionCounter := injectionCounter + 1;

                        -- Decides whether to send another flit or idle to maintain injection rate
                        if injectionCounter = TargetMessageSizeArray(currentTargetPE) then

                            -- Message has been sent, will idle next state
                            dataOutAV <= '1';
                            outputBufferWriteRequest <= '1';
                            injectionCounter := 0;
                            amountOfMessagesSent := amountOfMessagesSent + 1;
                            burstCounter := burstCounter + 1;
                            nextState := Swaiting;

                            -- Determines if burst has ended
                            if burstCounter = (AmountOfMessagesInBurstArray(currentTargetPE)) then

                                burstCounter = 0;

                                -- Determines next target PE
                                if FlowType = "RND" then

                                    -- Uses RAND function from ieee.math_real. Gets a value between 0 and (AmountOfTargetPEs - 1)
                                    currentTargetPE <= RAND() % AmountOfTargetPEs;

                                elsif FlowType = "DTM" then

                                    -- Next message will be sent to next sequential target as defined on TargetPEsArray
                                    incr(currentTargetPE, AmountOfTargetPEs - 1, 0);

                                end if;

                            end if;

                        else

                            -- Signals dataOut is valid. Will send another flit next sate
                            dataOutAV <= '1';
                            outputBufferWriteRequest <= '1';
                            nextState := Ssending;

                        end if;

                    else -- outputBufferSlotAvailable = '0' (Cant write to buffer)

                        -- TODO: Assert message signaling unavailable buffer

                    end if;

                end if;

            end if;

        end process;
    
    end block DependantInjector;


    -- Assumes header = [ADDR, SIZE]
    Receiver : block is
        
    begin

        ReceiverProcess: process(Clock, Reset)
            variable flitCounter : integer := 0;
            variable messageCounter : integer := 0;
            variable currentMessageSize : integer := 0;
            variable lastMessageTimestamp : DataWidth_t := (others => '0');
        begin

            -- Read request signal will be set to '1' unless Reset = '1'
            inputBufferReadRequest <= '1';

            if Reset = '1' then

                -- Set default values and disables buffer read request
                inputBufferReadRequest <= '0';
                flitCounter := 0;
                messageCounter := 0;

            elsif rising_edge(Clock) then
                
                if dataInAV = '1' then

                    -- Checks for an ADDR flit (Assumes header = [ADDR, SIZE])
                    if flitCounter = 0 then

                        lastMessageTimestamp := ClkCounter;

                    end if;

                    -- Checks for a SIZE flit (Assumes header = [ADDR, SIZE])
                    if flitCounter = 1 then

                        currentMessageSize := dataIn;

                    end if;

                    -- Increments counter if less than current message size or SIZE flit has not yet been received
                    if (flitCounter < currentMessageSize) or (flitCounter = 0) then

                        flitCounter := flitCounter + 1;

                    -- Whole message has been received, increments message counter and reset flit counter
                    else

                        -- Signals a message has been received to DPD injector and updates counters
                        flitCounter := 0;
                        messageCounter := messageCounter + 1;
                        incr(Semaphore, (2**32) - 1, 0);

                    end if;

                end if;

            end if;

        end process;
    
    end block Receiver;

	
end architecture RTL;