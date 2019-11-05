--------------------------------------------------------------------------
-- Package containing JSON translation functions and basic type definitions
--------------------------------------------------------------------------

library IEEE;
    use IEEE.std_Logic_1164.all;
    use IEEE.numeric_std.all;
    
library work;
    use work.HeMPS_defaults.all;
    use work.JSON.all;

package PE_PKG is

    -- Common constants (used by all project files)
    constant DataWidth: integer := TAM_FLIT;
    subtype DataWidth_t is std_logic_vector(DataWidth - 1 downto 0);

    -- Typedefs for injector parameters
    type SourcePEsArray_t is array(natural range <>) of integer;
    type SourcePayloadSizeArray_t is array(integer range <>) of integer;
    type SourceMessageSizeArray_t is array(integer range <>) of integer;
    type TargetPEsArray_t is array(integer range <>) of integer;
    type TargetPayloadSizeArray_t is array(integer range <>) of integer;
    type TargetMessageSizeArray_t is array(integer range <>) of integer;
    type AmountOfMessagesInBurst_t is array(integer range <>) of integer;
    type HeaderFlits_t is array(integer range <>, integer range <>) of DataWidth_t;
    type PayloadFlits_t is array (integer range <>, integer range <>) of DataWidth_t;

    -- Function declarations for organizing data from JSON config file
    function FillSourcePEsArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePEsArray_t;
    function FillSourcePayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePayloadSizeArray_t;
	function FillTargetPEsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPEsArray_t;
    function FillTargetPayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPayloadSizeArray_t;
    function FillTargetMessageSizeArray(TargetPayloadSizeArray : TargetPayloadSizeArray_t ; HeaderSize : integer) return TargetMessageSizeArray_t;
    function FillAmountOfMessagesInBurstArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return AmountOfMessagesInBurst_t;
    function BuildHeaders(InjectorJSONConfig : T_JSON ; HeaderSize : integer ; TargetPayloadSizeArray : TargetPayloadSizeArray_t ; TargetPEsArray : TargetPEsArray_t) return HeaderFlits_t;
    function BuildPayloads(InjectorJSONConfig : T_JSON ; TargetPayloadSizeArray : TargetPayloadSizeArray_t ; TargetPEsArray : TargetPEsArray_t) return PayloadFlits_t;
    function FindMaxPayloadSize(TargetPayloadSizeArray : TargetPayloadSizeArray_t) return integer;

end package PE_PKG;

package body PE_PKG is


    -- Fills array of source PEs 
    function FillSourcePEsArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePEsArray_t is
        variable SourcePEsArray : SourcePEsArray_t(0 to AmountOfSourcePEs - 1);
    begin

        FillSourcesLoop: for i in 0 to (AmountOfSourcePEs - 1) loop
            SourcePEsArray(i) := integer'value(jsonGetString(InjectorJSONConfig, ( "SourcePEs/" & integer'image(i) ) ) ); 
        end loop;

        return SourcePEsArray;

    end function FillSourcePEsArray;


    -- Fills array of source payload size for each source PE
    function FillSourcePayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePayloadSizeArray_t is
        variable SourcePayloadSizeArray : SourcePayloadSizeArray_t(0 to AmountOfSourcePEs - 1);
    begin

        FillSourcePayloadSizeLoop: for i in 0 to (AmountOfSourcePEs - 1) loop 
            SourcePayloadSizeArray(i) := integer'value(jsonGetString(InjectorJSONConfig, ( "SourcePayloadSize/" & integer'image(i) ) ) );
        end loop FillSourcePayloadSizeLoop;

        return SourcePayloadSizeArray;

    end function;


    -- Fills array of source message size for each source PE
    function FillSourceMessageSizeArray(SourcePayloadSizeArray : TargetPayloadSizeArray_t ; HeaderSize : integer) return SourceMessageSizeArray_t is
        variable SourceMessageSizeArray : SourceMessageSizeArray_t(SourcePayloadSizeArray'range);
    begin

        FillSourceMessageSizeLoop: for i in SourcePayloadSizeArray'range loop 
            SourceMessageSizeArray(i) := SourcePayloadSizeArray(i) + HeaderSize;
        end loop FillSourceMessageSizeLoop;

        return SourceMessageSizeArray;

    end function;


	-- Fills array of target PEs 
    function FillTargetPEsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPEsArray_t is
        variable TargetPEsArray : TargetPEsArray_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetsLoop: for i in 0 to (AmountOfTargetPEs - 1) loop
            TargetPEsArray(i) := integer'value(jsonGetString(InjectorJSONConfig, ( "TargetPEs/" & integer'image(i) ) ) ); 
        end loop;

        return TargetPEsArray;

    end function FillTargetPEsArray;


    -- Fills array of target payload size for each target PE
    function FillTargetPayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPayloadSizeArray_t is
        variable TargetPayloadSizeArray : TargetPayloadSizeArray_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetPayloadSizeLoop: for i in 0 to (AmountOfTargetPEs - 1) loop
            TargetPayloadSizeArray(i) := integer'value(jsonGetString(InjectorJSONConfig, ( "TargetPayloadSize/" & integer'image(i) ) ) );
        end loop FillTargetPayloadSizeLoop;

        return TargetPayloadSizeArray;

    end function;


    -- Fills array of target message size (Payload + Header) for each target PE
    function FillTargetMessageSizeArray(TargetPayloadSizeArray : TargetPayloadSizeArray_t ; HeaderSize : integer) return TargetMessageSizeArray_t is
        variable TargetMessageSizeArray : TargetMessageSizeArray_t(TargetPayloadSizeArray'range);
    begin

        FillTargetMessageSizeLoop : for i in TargetPayloadSizeArray'range loop
            TargetMessageSizeArray(i) := TargetPayloadSizeArray(i) + HeaderSize;
        end loop;
        
        return TargetMessageSizeArray;
        
    end function FillTargetMessageSizeArray;


    -- Fills array of amount of messages in a burst for each target PE
    function FillAmountOfMessagesInBurstArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return AmountOfMessagesInBurst_t is
        variable AmountOfMessagesInBurstArray : AmountOfMessagesInBurst_t(0 to AmountOfTargetPEs - 1);
    begin

        FillAmountOfMessagesInBurstArrayLoop : for i in 0 to (AmountOfTargetPEs - 1) loop
            AmountOfMessagesInBurstArray(i) := integer'value(jsonGetString(InjectorJSONConfig, ( "AmountOfMessagesInBurst/" & integer'image(i) ) ) );
        end loop;
        
        return AmountOfMessagesInBurstArray;        

    end function FillAmountOfMessagesInBurstArray;


    -- Builds header for each target PE
    function BuildHeaders(InjectorJSONConfig : T_JSON ; HeaderSize : integer ; TargetPayloadSizeArray : TargetPayloadSizeArray_t ; TargetPEsArray : TargetPEsArray_t) return HeaderFlits_t is
        variable Headers : HeaderFlits_t(TargetPEsArray'range, 0 to HeaderSize - 1);
        variable headerFlitString : string(1 to 4);
    begin

        BuildHeaderLoop: for target in TargetPEsArray'range loop

            BuildFlitLoop: for flit in 0 to (HeaderSize - 1) loop

                --                                                                    Translates loop iterator to PE ID
                headerFlitString := jsonGetString(InjectorJSONConfig, ( "Headers/" & "Header" & integer'image(TargetPEsArray(target)) & "/" & integer'image(flit) ) );

                -- A header flit can be : "ADDR" (Address of target PE in network)
                --                        "SIZE" (Size of payload in this message)
                --                        "BLNK" (Fills with zeroes)

                if headerFlitString = "ADDR" then 

                    Headers(target, flit) := std_logic_vector(to_unsigned(TargetPEsArray(target), DataWidth));

                elsif headerFlitString = "SIZE" then

                    Headers(target, flit) := std_logic_vector(to_unsigned(TargetPayloadSizeArray(target), DataWidth));

                elsif headerFlitString = "BLNK" then

                    Headers(target, flit) := (others => '0');

                else 

                    Headers(target, flit) := (others => '1');

                end if;
                                
            end loop BuildFlitLoop;

        end loop BuildHeaderLoop;

        return Headers;

    end function BuildHeaders;


    -- Builds payload for each target PE
    function BuildPayloads(InjectorJSONConfig : T_JSON ; TargetPayloadSizeArray : TargetPayloadSizeArray_t ; TargetPEsArray : TargetPEsArray_t) return PayloadFlits_t is
        variable MaxPayloadSize : integer := FindMaxPayloadSize(TargetPayloadSizeArray);
        variable Payloads : PayloadFlits_t(TargetPEsArray'range, 0 to MaxPayloadSize - 1);
        variable payloadFlitString : string(1 to 5);
        variable timestampFlag : integer := integer'value(jsonGetString(InjectorJSONConfig, "timestampFlag"));
        variable amountOfMessagesSentFlag : integer := integer'value(jsonGetString(InjectorJSONConfig, "amountOfMessagesSentFlag"));
    begin

        BuildPayloadLoop: for target in TargetPayloadSizeArray'range loop

            BuildFlitLoop: for flit in 0 to (MaxPayloadSize - 1) loop 

                --                                                                    Translates loop iterator to PE ID
                payloadFlitString := jsonGetString(InjectorJSONConfig, "Payloads/" & "Payload" & integer'image(TargetPEsArray(target)) & "/" & integer'image(flit) );

                -- A payload flit can be : "PEPOS" (PE position in network), 
                --                         "APPID" (ID of app being emulated by this injector), 
                --                         "THDID" (ID of thread of the app being emulated in this PE),
                --                         "AVGPT" (Average processing time of a message received by the app being emulated by this PE),
                --                         "TMSTP" (Timestamp of message being sent (to be set in real time, not in this function)),
                --                         "AMMSG" (Amount of messages sent by this PE (also to be se in real time)),
                --                         "BLANK" (Fills with zeroes)
                
                if payloadFlitString = "PEPOS" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(integer'value(jsonGetString(InjectorJSONConfig, "PEPos")), DataWidth));

                elsif payloadFlitString = "APPID" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(integer'value(jsonGetString(InjectorJSONConfig, "APPID")), DataWidth));

                elsif payloadFlitString = "THDID" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(integer'value(jsonGetString(InjectorJSONConfig, "ThreadID")), DataWidth));

                elsif payloadFlitString = "AVGPT" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(integer'value(jsonGetString(InjectorJSONConfig, "AverageProcessingTimeInClockPulses")), DataWidth));

                elsif payloadFlitString = "TMSTP" then

                    -- Flags for "real time" processing
                    Payloads(target, flit) := std_logic_vector(to_unsigned(timestampFlag, DataWidth - 1));

                elsif payloadFlitString = "AMMSG" then 

                    -- Flags for "real time" processing
                    Payloads(target, flit) := std_logic_vector(to_unsigned(amountOfMessagesSentFlag, DataWidth - 1));

                elsif payloadFlitString = "BLANK" then

                    Payloads(target, flit) := (others=>'0');

                else 

                    Payloads(target, flit) := (others=>'1');

                end if;

            end loop;

        end loop;

        return Payloads;

    end function BuildPayloads;


    -- Returns highest value in the TargetPayloadSizeArray array
    function FindMaxPayloadSize(TargetPayloadSizeArray : TargetPayloadSizeArray_t) return integer is
        variable MaxPayloadSize : integer := 0;
    begin

        FindMaxPayloadSizeLoop : for i in TargetPayloadSizeArray'range loop
            
            if TargetPayloadSizeArray(i) > MaxPayloadSize then

                MaxPayloadSize := TargetPayloadSizeArray(i);

            end if;

        end loop FindMaxPayloadSizeLoop;

        return MaxPayloadSize;

    end function FindMaxPayloadSize;


end package body PE_PKG;

