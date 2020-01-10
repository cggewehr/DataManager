---------------------------------------------------------------------------------------------------------
-- DESIGN UNIT  : MSG Injector (Fixed injection rate or dependent)                                     --
-- DESCRIPTION  :                                                                                      --
-- AUTHOR       : Carlos Gabriel de Araujo Gewehr                                                      --
-- CREATED      : Aug 13th, 2019                                                                       --
-- VERSION      : v0.1                                                                                 --
-- HISTORY      : Version 0.1 - Aug 13th, 2019                                                         --
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- TODO         : 
    -- Make more JSON test cases
    -- Support task migration emulation
    -- Generalize message bursts to any number of targets
---------------------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.trunc; -- for random number generation
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_std.all;

library std;
    use std.textio.all;

library work;
    use work.PE_PKG.all;
    use work.JSON.all;

entity Injector is

	generic (
        PEConfigFile          : string := "PESample.json";
        InjectorConfigFile    : string := "InjectorSample.json";
        PlatformConfigFile    : string := "PlatformSample.json";
        InboundLogFilename    : string := "InLogTest.txt"; 
        OutboundLogFilename   : string := "OutLogTest.txt"
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
    constant InjectorJSONConfig: T_JSON := jsonLoad(InjectorConfigFile);
    constant PEJSONConfig: T_JSON := jsonLoad(PEConfigFile);
    constant PlatformJSONConfig: T_JSON := jsonLoad(PlatformConfigFile);

    -- Injector type ("FXD" or "DPD")
    constant InjectorType: string(1 to 3) := jsonGetString(InjectorJSONConfig, "InjectorType");

    -- Message Flow type ("RND" or "DTM")
    constant FlowType: string(1 to 3) := jsonGetString(InjectorJSONConfig, "FlowType");

    -- Fixed injection rate injector constants
    constant InjectionRate: integer range 0 to 100 := jsonGetInteger(InjectorJSONConfig, "InjectionRate");

    -- Dependant injector constants
    constant PEPos: integer := jsonGetInteger(PEJSONConfig, "PEPos");
    constant AppID: integer := jsonGetInteger(PEJSONConfig, "APPID");
    constant ThreadID: integer := jsonGetInteger(PEJSONConfig, "ThreadID");
    constant AverageProcessingTimeInClockPulses: integer := jsonGetInteger(PEJSONConfig, "AverageProcessingTimeInClockPulses");

    -- Source PEs constants
    --constant AmountOfSourcePEs: integer := jsonGetInteger(InjectorJSONConfig, "AmountOfSourcePEs");
    --constant SourcePEsArray: SourcePEsArray_t(0 to AmountOfSourcePEs - 1) := FillSourcePEsArray(InjectorJSONConfig, AmountOfSourcePEs);

    -- Target PEs constants (Lower numbered targets in JSON have higher priority (target number 0 will have the highest priority)
    constant AmountOfTargetPEs: integer := jsonGetInteger(InjectorJSONConfig, "AmountOfTargetPEs");
    constant TargetPEsArray: TargetPEsArray_t(0 to AmountOfTargetPEs - 1) := FillTargetPEsArray(InjectorJSONConfig, AmountOfTargetPEs);
    constant AmountOfMessagesInBurstArray: AmountOfMessagesInBurstArray_t(0 to AmountOfTargetPEs - 1) := FillAmountOfMessagesInBurstArray(InjectorJSONConfig, AmountOfTargetPEs);
    --constant WrapperAddressTableArray: WrapperAddressTableArray_t(0 to AmountOfTargetPEs - 1) := FillWrapperAddressTableArray(PlatformJSONConfig, TargetPEsArray);

    -- Message parameters
    constant TargetPayloadSizeArray: TargetPayloadSizeArray_t(0 to AmountOfTargetPEs - 1) := FillTargetPayloadSizeArray(InjectorJSONConfig, AmountOfTargetPEs);
    --constant SourcePayloadSizeArray: SourcePayloadSizeArray_t(0 to AmountOfSourcePEs - 1) := FillSourcePayloadSizeArray(InjectorJSONConfig, AmountOfSourcePEs);
    constant MaxPayloadSize: integer := FindMaxPayloadSize(TargetPayloadSizeArray);

    constant HeaderSize: integer := jsonGetInteger(InjectorJSONConfig, "HeaderSize");
    constant HeaderFlits: HeaderFlits_t(0 to AmountOfTargetPEs - 1, 0 to HeaderSize - 1) := BuildHeaders(InjectorJSONConfig, PlatformJSONConfig, HeaderSize, TargetPayloadSizeArray, TargetPEsArray);

    constant TargetMessageSizeArray: TargetMessageSizeArray_t(0 to AmountOfTargetPEs - 1) := FillTargetMessageSizeArray(TargetPayloadSizeArray, HeaderSize); 
    --constant SourceMessageSizeArray : SourceMessageSizeArray_t := FillSourceMessageSizeArray(SourcePayloadSizeArray, HeaderSize);

    constant PayloadFlits: PayloadFlits_t(TargetPayloadSizeArray'range, 0 to MaxPayloadSize - 1) := BuildPayloads(InjectorJSONConfig, TargetPayloadSizeArray, TargetPEsArray);

    -- Payload Flags
    constant timestampFlag: integer := jsonGetInteger(InjectorJSONConfig, "timestampFlag");
    constant amountOfMessagesSentFlag: integer := jsonGetInteger(InjectorJSONConfig, "amountOfMessagesSentFlag");

    -- Clock Counter
    signal clockCounter: integer range 0 to UINT32MaxValue := 0;

    -- Semaphore for flow control if DPD injector is instantiated
    signal semaphore: integer range 0 to UINT32MaxValue := 0;

begin

    -- A simple clock rising edge counter. Wraps back to 0 once maximum allowed value is reached.
    CLKCOUNTER: process(Clock, Reset) begin

        if Reset = '1' then

            clockCounter <= 0;

        elsif rising_edge(Clock) then

            clockCounter <= incr(clockCounter, UINT32MaxValue , 0);

        end if;

    end process;


    -- Generates dependent injector (waits for a message to send another message)
    DependantInjector: if (InjectorType = "DPD") generate

        -- Waits for a specific message, then sends out messages after that message is received. (Only instanciated if InjectorType is set as "DPD" on JSON config file).
        DPD: block is

            type state_t is (Sreset, Swaiting, Sprocessing, Ssending);
            signal currentState: state_t;
            
            file OutboundLog: text open write_mode is OutboundLogFilename;
            
        begin

            DependantInjectorProcess: process(Clock)

                variable flitCounter: integer := 0;
                variable processingCounter: integer := 0;
                variable flitTemp: DataWidth_t := (others=>'0');
                variable firstFlitOutTimestamp: DataWidth_t;
                variable amountOfMessagesSent: DataWidth_t;
                variable currentTargetPE: integer := 0;
                variable burstCounter: integer := 0;

                -- RNG (Used by the Uniform function)
                variable RNGSeed1 : integer := jsonGetInteger(InjectorJSONConfig, "RNGSeed1");
                variable RNGSeed2 : integer := jsonGetInteger(InjectorJSONConfig, "RNGSeed2");
                variable randomNumber : real;
                
                variable OutboundLogLine: line;

            begin

                if rising_edge(Clock) then

                    if Reset = '1' then

                        currentState <= Sreset;

                    else

                        -- Sets default values
                        if currentState = Sreset then

                            OutputBufferWriteRequest <= '0';
                            DataOutAV <= '0';

                            firstFlitOutTimestamp := (others=>'0');
                            amountOfMessagesSent := (others=>'0');

                            currentTargetPE := 0;
                            flitCounter := 0;
                            burstCounter := 0;

                            -- Generates new (real) random number between 0 and 1
                            Uniform(RNGSeed1, RNGSeed2, RandomNumber);

                            currentState <= Swaiting;

                        -- Waits for a message to be received
                        elsif currentState = Swaiting then

                            -- Checks for a new message
                            if semaphore > 0 then

                                -- A new message was received, goes into processing state and decreases Semaphore
                                Semaphore <= decr(Semaphore, UINT32MaxValue, 0);
                                processingCounter := 0;
                                currentState <= Sprocessing;

                            -- No new message was received in the last clock period
                            else

                                -- Waits for a new message to be received
                                currentState <= Swaiting;

                            end if;

                        -- Idle for AverageProcessingTimeInClockPulses, and then send a message burst
                        elsif currentState = Sprocessing then

                            -- (Constant value is AverageProcessingTimeInClockPulses - 1 to account for the cycle wasted in Swaiting after a message was received) 
                            if processingCounter = AverageProcessingTimeInClockPulses - 1 then

                                -- Done idling, will begin to send message next cycle
                                flitCounter := 0;
                                currentState <= Ssending;

                            else

                                -- Still not done idling, will idle next state again
                                processingCounter := processingCounter + 1;
                                currentState <= Sprocessing;

                            end if;

                        -- Sends a flit to output buffer
                        elsif currentState = Ssending then

                            -- Sends a flit to buffer
                            if OutputBufferSlotAvailable = '1' then

                                -- Decides what flit to send (Header or Payload)
                                if flitCounter < HeaderSize then

                                    -- If this is the first flit in the message, saves current ClkCounter (to be sent as a flit when a payload flit is equal to the timestampFlag)
                                    if flitCounter = 0 then

                                        firstFlitOutTimestamp := std_logic_vector(to_unsigned(ClockCounter, DataWidth));

                                        -- Write to log file ( | # of msgs sent | target | msg size | timestamp | )
                                        write(OutboundLogLine, integer'image(to_integer(unsigned(amountOfMessagesSent))) & " ");
                                        write(OutboundLogLine, integer'image(TargetPEsArray(currentTargetPE)) & " ");
                                        write(OutboundLogLine, integer'image(TargetMessageSizeArray(currentTargetPE)) & " ");
                                        write(OutboundLogLine, integer'image(clockCounter));
                                        writeline(OutboundLog, OutboundLogLine);

                                        amountOfMessagesSent := amountOfMessagesSent + 1;

                                    end if;

                                    -- A Header flit will be sent
                                    flitTemp := HeaderFlits(currentTargetPE, flitCounter);

                                -- Not a header flit
                                else

                                    -- A Payload flit will be sent
                                    flitTemp := PayloadFlits(currentTargetPE, flitCounter - HeaderSize);

                                end if;

                                -- Replaces real time flags with respective value
                                if flitTemp = timestampFlag then

                                    flitTemp := firstFlitOutTimestamp;

                                elsif flitTemp = amountOfMessagesSentFlag then

                                    flitTemp := amountOfMessagesSent;

                                end if;

                                -- Outbound data bus receives the flit to be sent
                                DataOut <= flitTemp;
                                DataOutAV <= '1';
                                OutputBufferWriteRequest <= '1';

                                -- Increments flits sent counter
                                flitCounter := flitCounter + 1;

                                -- Decides whether to send another flit or idle to maintain injection rate
                                if flitCounter = TargetMessageSizeArray(currentTargetPE) then

                                    -- Message has been sent, will send next message in burst
                                    flitCounter := 0;
                                    amountOfMessagesSent := amountOfMessagesSent + 1;
                                    burstCounter := burstCounter + 1;

                                    -- Determines if burst has ended
                                    if burstCounter = (AmountOfMessagesInBurstArray(currentTargetPE)) then

                                        -- Bust has ended, will wait for a new message to send another burst
                                        burstCounter := 0;
                                        currentState <= Swaiting;

                                        -- Determines next target PE
                                        if FlowType = "RND" then

                                            -- Uses Uniform procedure from ieee.math_real. currentTargetPE gets a value between 0 and (AmountOfTargetPEs - 1)
                                            currentTargetPE := integer(trunc(RandomNumber * real(AmountOfTargetPEs + 1))) mod AmountOfTargetPEs;

                                            -- Generates a new random number
                                            Uniform(RNGSeed1, RNGSeed2, RandomNumber);
                                            
                                        elsif FlowType = "DTM" then

                                            -- Next message will be sent to next sequential target as defined on TargetPEsArray
                                            currenttargetPE := incr(currentTargetPE, AmountOfTargetPEs - 1, 0);

                                        end if;

                                    else

                                        -- Burst has not ended, will begin to send another message next state
                                        currentState <= Ssending;

                                    end if;

                                else

                                    -- Message has not ended, wil send another flit next state
                                    currentState <= Ssending;

                                end if;

                            else -- outputBufferSlotAvailable = '0' (Cant write to buffer)

                                -- Buffer not available, will try again next state
                                currentState <= Ssending;

                                report "No available slot on output buffer at injector ID:" & integer'image(PEPOS) severity warning;
                                
                            end if;

                        end if;

                    end if;

                end if;

            end process;
        
        end block DPD;
        
    end generate DependantInjector;


    -- Generates fixed rate injector (injects flit at a fixed rate)
    FixedRateInjector: if (InjectorType = "FXD") generate

        -- Generates messages at a specific rate. (Only instanciated if InjectorType is set as "FXD" on JSON config file).
        FXD: block is

            type state_t is (Sreset, Swaiting, Ssending);
            signal currentState: state_t;

            signal currentTargetPE: integer := 0;
            signal injectionCounter: integer := 0;
            signal injectionPeriod: integer := ((TargetMessageSizeArray(0) * 100) / InjectionRate) - TargetMessageSizeArray(0);
            signal burstCounter: integer := 0;

            file OutboundLog: text open write_mode is OutboundLogFilename;

        begin

            -- Sends out messages at a constant injection rate. (Only instanciated if InjectorType is set as "FXD" on JSON config file).
            FixedRateInjetorProcess: process(Clock)

                variable flitTemp: DataWidth_t := (others=>'0');
                variable firstFlitOutTimestamp: DataWidth_t := (others=>'0');
                variable amountOfMessagesSent: DataWidth_t := (others=>'0');

                -- RNG (Used by the Uniform function)
                variable RNGSeed1 : integer := jsonGetInteger(InjectorJSONConfig, "RNGSeed1");
                variable RNGSeed2 : integer := jsonGetInteger(InjectorJSONConfig, "RNGSeed2");
                variable randomNumber : real;

                variable OutboundLogLine: line;

            begin

                if rising_edge(Clock) then

                    if Reset = '1' then

                        currentState <= Sreset;

                    else

                        if currentState = Sreset then

                            injectionCounter <= 0;
                            injectionPeriod <= ( (TargetMessageSizeArray(0) * 100) / InjectionRate) - TargetMessageSizeArray(0);

                            OutputBufferWriteRequest <= '0';
                            DataOutAV <= '0';

                            firstFlitOutTimestamp := (others=>'0');
                            amountOfMessagesSent := (others=>'0');

                            currentTargetPE <= 0;
                            burstCounter <= 0;

                            -- Generates a new random number
                            Uniform(RNGSeed1, RNGSeed2, RandomNumber);

                            currentState <= Ssending;

                        -- Sends a flit to output buffer
                        elsif currentState = Ssending then

                            -- Sends a flit to buffer
                            if OutputBufferSlotAvailable = '1' then

                                -- If this is the first flit in the message, saves current ClkCounter (to be sent as a flit when a payload flit is equal to the timestampFlag)
                                if injectionCounter = 0 then

                                    firstFlitOutTimestamp := std_logic_vector(to_unsigned(clockCounter, DataWidth));

                                    -- Write to log file ( | target ID | source ID | msg size | timestamp | )
                                    --write(OutboundLogLine, integer'image(to_integer(unsigned(amountOfMessagesSent))) & " ");
                                    write(OutboundLogLine, integer'image(TargetPEsArray(currentTargetPE)) & " ");
                                    write(OutboundLogLine, integer'image(PEPos) & " ");
                                    write(OutboundLogLine, integer'image(TargetMessageSizeArray(currentTargetPE)) & " ");
                                    write(OutboundLogLine, integer'image(clockCounter));
                                    writeline(OutboundLog, OutboundLogLine);

                                    amountOfMessagesSent := amountOfMessagesSent + 1;

                                end if;

                                -- Decides what flit to send (Header or Payload)
                                if injectionCounter < HeaderSize then

                                    -- A Header flit will be sent
                                    flitTemp := HeaderFlits(currentTargetPE, injectionCounter);

                                -- Not a header flit
                                else

                                    -- A Payload flit will be sent
                                    flitTemp := PayloadFlits(currentTargetPE, injectionCounter - HeaderSize);

                                end if;

                                -- Replaces real time flags with respective value
                                if flitTemp = timestampFlag then

                                    flitTemp := firstFlitOutTimestamp;

                                elsif flitTemp = amountOfMessagesSentFlag then

                                    flitTemp := amountOfMessagesSent;

                                end if;

                                -- Outbound data bus receives the flit to be sent
                                DataOut <= flitTemp;
                                DataOutAV <= '1';
                                OutputBufferWriteRequest <= '1';

                                -- Increments flits sent counter
                                injectionCounter <= injectionCounter + 1;
                                
                                -- Decides whether to send another flit or idle to maintain injection rate (Checks if message has ended)
                                if (injectionCounter + 1) = TargetMessageSizeArray(currentTargetPE) then

                                    -- Message has been sent
                                    injectionCounter <= 0;
                                    burstCounter <= burstCounter + 1;

                                    -- If injection rate = 100%, dont idle next state, else, do idle to maintain injection rate
                                    if InjectionRate = 100 then
                                    	currentState <= Ssending;
                                    else
                                    	currentState <= Swaiting;
                                    end if; 
    
                                    -- Determines if burst has ended
                                    if (burstCounter + 1) = AmountOfMessagesInBurstArray(currentTargetPE) then

                                        burstCounter <= 0;

                                        -- Determines next target PE
                                        if FlowType = "RND" then

                                            -- Uses Uniform procedure from ieee.math_real. currentTargetPE gets a value between 0 and (AmountOfTargetPEs - 1)
                                            currentTargetPE <= integer(trunc(RandomNumber * real(AmountOfTargetPEs + 1))) mod AmountOfTargetPEs;

                                            -- Generates a new random number
                                            Uniform(RNGSeed1, RNGSeed2, RandomNumber);

                                        elsif FlowType = "DTM" then

                                            -- Next message will be sent to next sequential target as defined on TargetPEsArray
                                            currentTargetPE <= incr(currentTargetPE, AmountOfTargetPEs - 1, 0);

                                        end if;

                                    end if;

                                else

                                    -- Message has not ended, will send another flit next state
                                    currentState <= Ssending;

                                end if;

                            else -- outputBufferSlotAvailable = '0' (Cant write to buffer)

                                report "No available slot on output buffer at network address: " & integer'image(PEPOS) severity warning;
                                currentState <= Ssending;

                            end if;
                            
                         -- Idles to maintain defined injection rate
                        elsif currentState = Swaiting then

                            -- Signals DataOut isn't valid
                            DataOutAV <= '0';
                            OutputBufferWriteRequest <= '0';

                            -- Increments flit counter
                            injectionCounter <= injectionCounter + 1;

                            -- Decides whether to send another flit or idle to maintain injection rate
                            if injectionCounter = injectionPeriod + 1 then

                                injectionCounter <= 0;
                                currentState <= Ssending;

                                -- Gets new injection period value (according to new message)
                                injectionPeriod <= ( (TargetMessageSizeArray(currentTargetPE) * 100) / InjectionRate) - TargetMessageSizeArray(currentTargetPE);

                            else

                                currentState <= Swaiting;
                                
                            end if;

                        end if;

                    end if;

                end if;

            end process;

        end block FXD;

    end generate FixedRateInjector;


    -- Assumes header = [ADDR, SIZE]
    Receiver: block is

        signal messageCounter: integer range 0 to UINT32MaxValue := 0;
        signal flitCounter: integer := 0;
        signal currentMessageSize: integer := 0;
        signal latestMessageTimestamp: DataWidth_t := (others => '0');
        signal latestSourceID: integer := 0;
        signal outputTimestamp: integer := 0;

        file InboundLog: text open write_mode is InboundLogFilename;
        
    begin

        ReceiverProcess: process(Clock, Reset)
            variable InboundLogLine: line;
        begin

            -- Read request signal will always be set to '1' unless Reset = '1'
            InputBufferReadRequest <= '1';

            if Reset = '1' then

                -- Set default values and disables buffer read request
                InputBufferReadRequest <= '0';
                flitCounter <= 0;
                messageCounter <= 0;

            elsif rising_edge(Clock) then
                
                -- Checks for a new flit available on input buffer
                if DataInAV = '1' then

                    -- Checks for an ADDR flit (Assumes header = [ADDR, SIZE])
                    if flitCounter = 0 then

                        latestMessageTimestamp <= std_logic_vector(to_unsigned(clockCounter, DataWidth));

                    -- Checks for a SIZE flit (Assumes header = [ADDR, SIZE])
                    elsif flitCounter = 1 then

                        currentMessageSize <= to_integer(unsigned(DataIn));

                    -- Saves source ID (Assumes first payload flit containts PEPOS of sender)
                    elsif flitCounter = 2 then

                        latestSourceID <= to_integer(unsigned(DataIn));

                    elsif flitCounter = 3 then

                        outputTimestamp <= to_integer(unsigned(DataIn));

                    end if;

                    -- Increments counter if its less than current message size or SIZE flit has not yet been received
                    -- "HeaderSize" is read from injector JSON config
                    if (flitCounter < currentMessageSize) or (flitCounter < HeaderSize) then

                        flitCounter <= flitCounter + 1;

                    -- Whole message has been received, increments message counter and reset flit counter
                    else

                        -- TODO: Find if received message fits an expected pattern, and if so, inform DPD injector

                        -- Write to log file ( | target ID | source ID | msg size | output timestamp | input timestamp | )
                        --write(InboundLogLine, integer'image(messageCounter) & " ");
                        write(InboundLogLine, integer'image(PEPos) & " ");
                        write(InboundLogLine, integer'image(latestSourceID) & " ");
                        write(InboundLogLine, integer'image(currentMessageSize) & " ");
                        write(InboundLogLine, integer'image(outputTimestamp) & " ");
                        write(InboundLogLine, integer'image(clockCounter));
                        writeline(InboundLog, InboundLogLine);

                        -- Signals a message has been received to DPD injector and updates counters
                        messageCounter <= incr(messageCounter, UINT32MaxValue, 0);
                        semaphore <= incr(Semaphore, UINT32MaxValue, 0);
                        flitCounter <= 0;

                    end if;

                end if;

            end if;

        end process;
    
    end block Receiver;

end architecture RTL;
