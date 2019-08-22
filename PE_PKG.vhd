--------------------------------------------------------------------------
-- Package com tipos basicos
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_Logic_1164.all;
use IEEE.numeric_std.all;
use work.HeMPS_defaults.all;
use work.JSON.all;

        --inj_period := ((INJ_PKGSIZE * 100) / INJ_RATE) - INJ_PKGSIZE;
        --inj_count := INJ_PKGSIZE;

package PE_PKG is

    constant DataWidth: integer := TAM_FLIT;
    subtype DataWidth_t is std_logic_vector(DataWidth - 1 downto 0);

    subtype SourcePEsArray_t is array(integer range <>) of integer;
    subtype SourcePayloadSizeArray_t is array(integer range <>) of integer;
    subtype TargetPEsArray_t is array(integer range <>) of integer;
    subtype TargetPayloadSizeArray_t is array(integer range <>) of integer;
    subtype TargetMessageSizeArray_t is array(integer range <>) of integer;
    subtype HeaderFlits_t is array(integer range <>, integer range <>) of DataWidth_t;
    subtype PayloadFlits_t is array integer range <>, integer range <>) of DataWidth_t;

    function FillSourcePEsArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePEsArray_t;
    function FillSourcePayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePayloadSize_t;
	function FillTargetPEsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPEsArray_t;
    function FillTargetPayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return PayloadSize_t;
    function FillTargetMessageSizeArray(TargetPayloadSizeArray : TargetPayloadSizeArray_t ; HeaderSize : integer ; AmountOfTargetPEs : integer) return TargetMessageSize_t;
    function BuildHeaders(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer ; HeaderSize : integer ; TargetPEsArray : TargetPEsArray_t ; TargetPayloadSize : TargetPayloadSizeArray_t) return HeaderFlits_t;

end package PE_PKG;

package body PE_PKG is


    -- Fills array of source PEs 
    function FillSourcePEsArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePEsArray_t is
        variable tempArray : SourcePEsArray_t(0 to AmountOfSourcePEs - 1);
    begin

        FillSourcesLoop: for i in 0 to (AmountOfSourcePEs - 1) loop
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "SourcePEs/" & integer'image(i) ) ); 
        end loop;

        return tempArray;

    end function FillSourcePEsArray;


    -- Fills array of source payload size for each source PE
    function FillSourcePayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePayloadSizeArray_t is
        variable tempArray : SourcePayloadSize_t(0 to AmountOfSourcePEs - 1);
    begin

        FillSourcePayloadSizeLoop: for i in 0 to (AmountOfSourcePEs - 1) loop 
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "SourcePayloadSize/" & integer'image(i) ) );
        end loop FillSourcePayloadSizeLoop;

        return tempArray;

    end function;


	-- Fills array of target PEs
    function FillTargetPEsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPEsArray_t is
        variable tempArray : TargetPEsArray_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetsLoop: for i in 0 to (AmountOfTargetPEs - 1) loop
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "TargetPEs/" & integer'image(i) ) ); 
        end loop;

        return tempArray;

    end function FillTargetPEsArray;


    -- Fills array of target payload size for each target PE
    function FillTargetPayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPayloadSizeArray_t is
        variable tempArray : TargetPayloadSize_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetPayloadSizeLoop: for i in 0 to (AmountOfTargetPEs - 1) loop 
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "TargetPayloadSize/" & integer'image(i) ) );
        end loop FillTargetPayloadSizeLoop;

        return tempArray;

    end function;

    function FillTargetMessageSizeArray(TargetPayloadSizeArray : TargetPayloadSizeArray_t ; HeaderSize : integer ; AmountOfTargetPEs : integer) return TargetMessageSize_t is
        variable tempArray : TargetMessageSize_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetMessageSizeLoop : for i in 0 to AmountOfTargetPEs loop
            
            tempArray(i) <= TargetPayloadSizeArray(i) + HeaderSize;

        end loop;
        
    end function FillTargetMessageSizeArray;

    -- Builds header for each target PE
    function BuildHeaders(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer ; HeaderSize : integer ; TargetPEsArray : TargetPEsArray_t ; TargetPayloadSizeArray : TargetPayloadSizeArray_t) return HeaderFlits_t is
        variable tempHeader : HeaderFlits_t(0 to AmountOfTargetPEs - 1, 0 to HeaderSize - 1);
        variable headerFlitString : string(1 to 4);
    begin

        BuildHeaderLoop: for target in 0 to (AmountOfTargetPEs - 1) loop

            BuildFlitLoop: for flit in 0 to (HeaderSize - 1) loop

                headerFlitString := jsonGetString(InjectorJSONConfig, ( "Header/" & integer'image(target) & "/" & integer'image(flit) ) );

                if headerFlitString = "ADDR" then 

                    tempHeader(target)(flit) := TargetPEsArray(target);

                elsif headerFlitString = "SIZE" then

                    tempHeader(target)(flit) := TargetPayloadSizeArray(target);

                end if;
                                
            end loop BuildFlitLoop;

        end loop BuildHeaderLoop;

        return tempHeader;

    end function BuildHeaders;

    function BuildPayloads(InjectorJSONConfig : T_JSON ; TargetPayloadSizeArray : TargetPayloadSizeArray_t ; HeaderSize : integer ; ) return PayloadFlits_t is
        variable MaxPayloadSize : integer := FindMaxPayloadSize(TargetPayloadSizeArray);
        variable tempPayload : PayloadFlits_t(TargetPayloadSizeArray'range, 0 to MaxPayloadSize - 1);
        variable payloadFlitString : string(1 to 5);
    begin
        
        BuildPayloadLoop: for target in 0 to (TargetPayloadSize'range) loop

            BuildFlitLoop: for flit in 0 to (MaxPayloadSize - 1) loop 

                payloadFlitString := jsonGetString(InjectorJSONConfig, "Payload/" & integer'image(target) & "/" & integer'image(flit) );

                -- Payload flit can be : "PEPOS" (PE position in network), 
                --                       "APPID" (ID of app being emulated by this injector), 
                --                       "THDID" (ID of thread of the app being emulated in this PE),
                --                       "AVGPT" (Average processing time of a message received by the app being emulated by this PE),
                --                       "TMSTP" (Timestamp of message being sent (to be set in real time, not in this function)),
                --                       "AMMSG" (Amount of messages sent by this PE (also to be se in real time)),
                --                       "BLANK" (Fills with zeroes)
                
                if payloadFlitString = "PEPOS" then

                    tempPayload(target)(flit) := jsonGetInteger(InjectorJSONConfig, "PEPos");

                elsif payloadFlitString = "APPID" then

                    tempPayload(target)(flit) := jsonGetInteger(InjectorJSONConfig, "APPID");

                elsif payloadFlitString = "THDID" then

                    tempPayload(target)(flit) := jsonGetInteger(InjectorJSONConfig, "ThreadID");

                elsif payloadFlitString = "AVGPT" then

                    tempPayload(target)(flit) := jsonGetInteger(InjectorJSONConfig, "AverageProcessingTimeInClockPulses");

                elsif payloadFlitString = "TMSTP" then

                    -- Flags for "real time" processing
                    tempPayload(target)(flit) := (others=>'1');

                elsif payloadFlitString = "AMMSG" then 

                    -- Flags for "real time" processing
                    tempPayload(target)(flit) := (0=>'0', others=>'1');

                elsif payloadFlitString = "BLANK" then

                    tempPayload(target)(flit) := (others=>'0');

                else 

                    tempPayload(target)(flit) := (others=>'0');

                end if;

            end loop;

        end loop;

    return tempPayload;

    end function BuildPayloads;

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
