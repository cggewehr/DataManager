--------------------------------------------------------------------------
-- Package containing JSON translation functions and basic type definitions
--------------------------------------------------------------------------

library IEEE;
    use IEEE.std_Logic_1164.all;
    use IEEE.numeric_std.all;
    
library work;
    --use work.HeMPS_defaults.all;
    use work.JSON.all;

package PE_PKG is

    -- Common constants (used by all project files)
    --constant DataWidth: integer := TAM_FLIT; -- TAM_FLIT is declared in HeMPS_defaults, defaulted to 32
    --constant HalfDataWidth: integer := TAM_FLIT/2;
    --constant QuarterDataWidth: integer := TAM_FLIT/4;
    constant DataWidth: integer := 32; 
    constant HalfDataWidth: integer := DataWidth/2;
    constant QuarterDataWidth: integer := DataWidth/4;

    subtype DataWidth_t is std_logic_vector(DataWidth - 1 downto 0);
    subtype HalfDataWidth_t is std_logic_vector(HalfDataWidth - 1 downto 0);
    subtype QuarterDataWidth_t is std_logic_vector(QuarterDataWidth - 1 downto 0);

    constant UINT32MaxValue: integer := 2147483646; -- Xilinx for some reason only allows an integer to go up to this value, even if range is defined as 0 to 4294967295
    --constant UINT32MaxValue: integer := 4294967295;

    -- Typedefs for injector parameters types
    type SourcePEsArray_t is array(natural range <>) of integer;
    type SourcePayloadSizeArray_t is array(integer range <>) of integer;
    type SourceMessageSizeArray_t is array(integer range <>) of integer;
    type TargetPEsArray_t is array(integer range <>) of integer;
    type TargetPayloadSizeArray_t is array(integer range <>) of integer;
    type TargetMessageSizeArray_t is array(integer range <>) of integer;
    type AmountOfMessagesInBurstArray_t is array(integer range <>) of integer;
    type WrapperAddressTableArray_t is array(integer range <>) of integer;
    type HeaderFlits_t is array(integer range <>, integer range <>) of DataWidth_t;
    type PayloadFlits_t is array (integer range <>, integer range <>) of DataWidth_t;

    -- Adapted functions from HeMPS_defaults
    function RouterAddress(GlobalAddress: integer ; NUMBER_PROCESSORS_X: integer) return HalfDataWidth_t;

    -- Function declarations for organizing data from JSON config file
    function FillSourcePEsArray(InjectorJSONConfig: T_JSON ; AmountOfSourcePEs: integer) return SourcePEsArray_t;
    function FillSourcePayloadSizeArray(InjectorJSONConfig: T_JSON ; AmountOfSourcePEs: integer) return SourcePayloadSizeArray_t;
	function FillTargetPEsArray(InjectorJSONConfig: T_JSON ; AmountOfTargetPEs: integer) return TargetPEsArray_t;
    function FillTargetPayloadSizeArray(InjectorJSONConfig: T_JSON ; AmountOfTargetPEs: integer) return TargetPayloadSizeArray_t;
    function FillTargetMessageSizeArray(TargetPayloadSizeArray: TargetPayloadSizeArray_t ; HeaderSize: integer) return TargetMessageSizeArray_t;
    function FillAmountOfMessagesInBurstArray(InjectorJSONConfig: T_JSON ; AmountOfTargetPEs: integer) return AmountOfMessagesInBurstArray_t;
    --function FillWrapperAddressTableArray(WrapperAddressTableJSON: T_JSON ; TargetPEsArray: TargetPEsArray_t) return WrapperAddressTableArray_t;
function FillWrapperAddressTableArray(PlatformJSONConfig: T_JSON ; TargetPEsArray: TargetPEsArray_t) return WrapperAddressTableArray_t;
    function BuildHeaders(InjectorJSONConfig: T_JSON ; PlatformJSONConfig: T_JSON ; HeaderSize: integer ; TargetPayloadSizeArray: TargetPayloadSizeArray_t ; TargetPEsArray: TargetPEsArray_t) return HeaderFlits_t;
    function BuildPayloads(InjectorJSONConfig: T_JSON ; TargetPayloadSizeArray: TargetPayloadSizeArray_t ; TargetPEsArray: TargetPEsArray_t) return PayloadFlits_t;
    function FindMaxPayloadSize(TargetPayloadSizeArray: TargetPayloadSizeArray_t) return integer;

    -- Misc functions
    procedure UNIFORM (SEED1, SEED2 : inout POSITIVE; X : out REAL); -- Used for random number generation
    function incr(value: integer ; maxValue: in integer ; minValue: in integer) return integer;
    function decr(value: integer ; maxValue: in integer ; minValue: in integer) return integer;

end package PE_PKG;


package body PE_PKG is


    -- Translates global address to router xy coordinates (ADAPTED FROM "HeMPS_defaults" PKG)
    function RouterAddress(GlobalAddress: integer ; NUMBER_PROCESSORS_X: integer) return HalfDataWidth_t is
            variable posX, posY : QuarterDataWidth_t;
            variable addr: HalfDataWidth_t; 
    begin 

            posX := std_logic_vector(to_unsigned((GlobalAddress mod NUMBER_PROCESSORS_X), QuarterDataWidth));
            posY := std_logic_vector(to_unsigned((GlobalAddress / NUMBER_PROCESSORS_X), QuarterDataWidth));
            
            addr := (posX & posY);

            return addr;

    end function RouterAddress;


    -- Fills array of source PEs 
    function FillSourcePEsArray(InjectorJSONConfig: T_JSON ; AmountOfSourcePEs: integer) return SourcePEsArray_t is
        variable SourcePEsArray : SourcePEsArray_t(0 to AmountOfSourcePEs - 1);
    begin

        FillSourcesLoop: for i in 0 to (AmountOfSourcePEs - 1) loop
            SourcePEsArray(i) := jsonGetInteger(InjectorJSONConfig, ( "SourcePEs/" & integer'image(i) ) ); 
        end loop;

        return SourcePEsArray;

    end function FillSourcePEsArray;


    -- Fills array of source payload size for each source PE
    function FillSourcePayloadSizeArray(InjectorJSONConfig: T_JSON ; AmountOfSourcePEs: integer) return SourcePayloadSizeArray_t is
        variable SourcePayloadSizeArray : SourcePayloadSizeArray_t(0 to AmountOfSourcePEs - 1);
    begin

        FillSourcePayloadSizeLoop: for i in 0 to (AmountOfSourcePEs - 1) loop 
            SourcePayloadSizeArray(i) := jsonGetInteger(InjectorJSONConfig, ( "SourcePayloadSize/" & integer'image(i) ) );
        end loop FillSourcePayloadSizeLoop;

        return SourcePayloadSizeArray;

    end function;


    -- Fills array of source message size for each source PE
    function FillSourceMessageSizeArray(SourcePayloadSizeArray: TargetPayloadSizeArray_t ; HeaderSize: integer) return SourceMessageSizeArray_t is
        variable SourceMessageSizeArray : SourceMessageSizeArray_t(SourcePayloadSizeArray'range);
    begin

        FillSourceMessageSizeLoop: for i in SourcePayloadSizeArray'range loop 
            SourceMessageSizeArray(i) := SourcePayloadSizeArray(i) + HeaderSize;
        end loop FillSourceMessageSizeLoop;

        return SourceMessageSizeArray;

    end function;


	-- Fills array of target PEs 
    function FillTargetPEsArray(InjectorJSONConfig: T_JSON ; AmountOfTargetPEs: integer) return TargetPEsArray_t is
        variable TargetPEsArray : TargetPEsArray_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetsLoop: for i in 0 to (AmountOfTargetPEs - 1) loop
            TargetPEsArray(i) := jsonGetInteger(InjectorJSONConfig, ( "TargetPEs/" & integer'image(i) ) ); 
        end loop;

        return TargetPEsArray;

    end function FillTargetPEsArray;


    -- Fills array of target payload size for each target PE
    function FillTargetPayloadSizeArray(InjectorJSONConfig: T_JSON ; AmountOfTargetPEs: integer) return TargetPayloadSizeArray_t is
        variable TargetPayloadSizeArray : TargetPayloadSizeArray_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetPayloadSizeLoop: for i in 0 to (AmountOfTargetPEs - 1) loop
            TargetPayloadSizeArray(i) := jsonGetInteger(InjectorJSONConfig, ("TargetPayloadSize/" & integer'image(i)));
        end loop FillTargetPayloadSizeLoop;

        return TargetPayloadSizeArray;

    end function;


    -- Fills array of target message size (Payload + Header) for each target PE
    function FillTargetMessageSizeArray(TargetPayloadSizeArray: TargetPayloadSizeArray_t ; HeaderSize: integer) return TargetMessageSizeArray_t is
        variable TargetMessageSizeArray: TargetMessageSizeArray_t(TargetPayloadSizeArray'range);
    begin

        FillTargetMessageSizeLoop : for i in TargetPayloadSizeArray'range loop
            TargetMessageSizeArray(i) := TargetPayloadSizeArray(i) + HeaderSize;
        end loop;
        
        return TargetMessageSizeArray;
        
    end function FillTargetMessageSizeArray;


    -- Fills array of amount of messages in a burst for each target PE
    function FillAmountOfMessagesInBurstArray(InjectorJSONConfig: T_JSON ; AmountOfTargetPEs: integer) return AmountOfMessagesInBurstArray_t is
        variable AmountOfMessagesInBurstArray: AmountOfMessagesInBurstArray_t(0 to AmountOfTargetPEs - 1);
    begin

        FillAmountOfMessagesInBurstArrayLoop : for i in 0 to (AmountOfTargetPEs - 1) loop
            AmountOfMessagesInBurstArray(i) := jsonGetInteger(InjectorJSONConfig, ("AmountOfMessagesInBurst/" & integer'image(i)));
        end loop;
        
        return AmountOfMessagesInBurstArray;        

    end function FillAmountOfMessagesInBurstArray;


    -- Fills array containing address of associated wrapper for each global address (To find the address of a global address's associated wrapper)
    function FillWrapperAddressTableArray(PlatformJSONConfig: T_JSON ; TargetPEsArray: TargetPEsArray_t) return WrapperAddressTableArray_t is
        variable WrapperAddressTableArray: WrapperAddressTableArray_t(TargetPEsArray'range);
    begin

        FillWrapperAddressTableArrayLoop: for i in TargetPEsArray'range loop
            WrapperAddressTableArray(i) := jsonGetInteger(PlatformJSONConfig, ("WrapperAddresses/" & integer'image(TargetPEsArray(i))));
        end loop FillWrapperAddressTableArrayLoop;

        return WrapperAddressTableArray;

    end function FillWrapperAddressTableArray;


    -- Builds header for each target PE
    function BuildHeaders(InjectorJSONConfig: T_JSON ; PlatformJSONConfig: T_JSON ; HeaderSize: integer ; TargetPayloadSizeArray: TargetPayloadSizeArray_t ; TargetPEsArray: TargetPEsArray_t) return HeaderFlits_t is
        variable Headers: HeaderFlits_t(TargetPEsArray'range, 0 to HeaderSize - 1);
        variable headerFlitString: string(1 to 4);
        variable wrapperAddress: integer;
        variable timestampFlag: integer := jsonGetInteger(InjectorJSONConfig, "timestampFlag");
        constant NUMBER_PROCESSORS_X: integer := jsonGetInteger(PlatformJSONConfig, "NUMBER_PROCESSORS_X");
    begin

    	report "Compiling header flits" severity note;

        BuildHeaderLoop: for target in TargetPEsArray'range loop

        	report "    Compiling header for target PE " & integer'image(TargetPEsArray(target)) severity note;

            BuildFlitLoop: for flit in 0 to (HeaderSize - 1) loop

                --                                                                               Translates loop iterator to PE ID
                headerFlitString := jsonGetString(InjectorJSONConfig, ( "Headers/" & "Header" & integer'image(TargetPEsArray(target)) & "/" & integer'image(flit)));

                -- A header flit can be : "ADDR" (Address of target PE in network)
                --                        "SIZE" (Size of payload in this message)
                --                        "TIME" (Timestamp (in clock cycles) of when first flit of message leaves the injector)
                --                        "BLNK" (Fills with zeroes)

                if headerFlitString = "ADDR" then 
                    
		    -- Works only for NoCs 
                    Headers(target, flit)((DataWidth/2) - 1 downto 0 ):= RouterAddress(TargetPEsArray(target), NUMBER_PROCESSORS_X);
		    Headers(target, flit)(DataWidth - 1 downto DataWidth/2) := (others => '0');

		    -- TODO Ajustar a geração do endereço. Se tiver wrapper, funciona tal qual o código abaixo. MAS se NÃO tiver no wrapper, o ADDR deve ficar nos LSBits
                    -- Global XY coordinates @ most significative bits (X coordinate @ most significative parts, & Y coordinates @ least significative parts)
                    --Headers(target, flit)(DataWidth - 1 downto DataWidth/2) := RouterAddress(TargetPEsArray(target), NUMBER_PROCESSORS_X);

                    -- Wrapper XY coordinates @ lets significative bits
                    --wrapperAddress := jsonGetInteger(PlatformJSONConfig, "WrapperAddresses/" & integer'image(TargetPEsArray(target)));
                    --Headers(target, flit)((DataWidth/2) - 1 downto 0) := RouterAddress(wrapperAddress, NUMBER_PROCESSORS_X);

                elsif headerFlitString = "SIZE" then

                    Headers(target, flit) := std_logic_vector(to_unsigned(TargetPayloadSizeArray(target), DataWidth));

                elsif headerFlitString = "TIME" then

                    Headers(target, flit) := std_logic_vector(to_unsigned(timestampFlag, DataWidth));

                elsif headerFlitString = "BLNK" then

                    Headers(target, flit) := (others => '0');

                else

                     report "        Flit " & integer'image(flit) & " of header of message to be delivered to PE ID " & integer'image(TargetPEsArray(target)) & " is not defined" severity warning;

                end if;

                report "        Flit " & integer'image(flit) & " of header of message to be delivered to PE ID " & integer'image(TargetPEsArray(target)) & " is " & headerFlitString & " = " & integer'image(to_integer(unsigned(Headers(target, flit)))) severity note;

            end loop BuildFlitLoop;

        end loop BuildHeaderLoop;

        return Headers;

    end function BuildHeaders;


    -- Builds payload for each target PE
    function BuildPayloads(InjectorJSONConfig: T_JSON ; TargetPayloadSizeArray: TargetPayloadSizeArray_t ; TargetPEsArray: TargetPEsArray_t) return PayloadFlits_t is
        variable MaxPayloadSize : integer := FindMaxPayloadSize(TargetPayloadSizeArray);
        variable Payloads : PayloadFlits_t(TargetPEsArray'range, 0 to MaxPayloadSize - 1);
        variable payloadFlitString : string(1 to 5);
        variable timestampFlag : integer := jsonGetInteger(InjectorJSONConfig, "timestampFlag");
        variable amountOfMessagesSentFlag : integer := jsonGetInteger(InjectorJSONConfig, "amountOfMessagesSentFlag");
    begin

    	report "Compiling payload flits" severity note;

        BuildPayloadLoop: for target in TargetPayloadSizeArray'range loop

        	report "    Compiling payload for target PE " & integer'image(TargetPEsArray(target)) severity note;

            BuildFlitLoop: for flit in 0 to (MaxPayloadSize - 1) loop 


                -- Checks if current target has had its payload fully compiled (if the inner loop iterator > PayloadSize(target), break inner loop)
                if flit = TargetPayloadSizeArray(target) then
                    exit;
                end if;

                --                                                                                Translates loop iterator to PE ID
                payloadFlitString := jsonGetString(InjectorJSONConfig, "Payloads/" & "Payload" & integer'image(TargetPEsArray(target)) & "/" & integer'image(flit) );

                -- A payload flit can be : "PEPOS" (PE position in network), 
                --                         "APPID" (ID of app being emulated by this injector), 
                --                         "THDID" (ID of thread of the app being emulated in this PE),
                --                         "AVGPT" (Average processing time of a message received by the app being emulated by this PE),
                --                         "TMSTP" (Timestamp of message being sent (to be set in real time, not in this function)),
                --                         "AMMSG" (Amount of messages sent by this PE (also to be se in real time)),
                --                         "BLANK" (Fills with zeroes)
                
                if payloadFlitString = "PEPOS" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(jsonGetInteger(InjectorJSONConfig, "PEPos"), DataWidth));

                elsif payloadFlitString = "APPID" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(jsonGetInteger(InjectorJSONConfig, "APPID"), DataWidth));

                elsif payloadFlitString = "THDID" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(jsonGetInteger(InjectorJSONConfig, "ThreadID"), DataWidth));

                elsif payloadFlitString = "AVGPT" then

                    --Payloads(target, flit) := std_logic_vector(to_unsigned(jsonGetInteger(InjectorJSONConfig, "AverageProcessingTimeInClockPulses"), DataWidth));
                    Payloads(target, flit) := (others => '1'); -- DEBUG 
                elsif payloadFlitString = "TMSTP" then

                    -- Flags for "real time" processing
                    Payloads(target, flit) := std_logic_vector(to_unsigned(timestampFlag, DataWidth));

                elsif payloadFlitString = "AMMSG" then 

                    -- Flags for "real time" processing
                    Payloads(target, flit) := std_logic_vector(to_unsigned(amountOfMessagesSentFlag, DataWidth));

                elsif payloadFlitString = "BLANK" then

                    Payloads(target, flit) := (others=>'0');

                end if;

                report "        Flit " & integer'image(flit) & " of payload of message to be delivered to PE ID " & integer'image(TargetPEsArray(target)) & " is " & payloadFlitString & " = " & integer'image(to_integer(unsigned(Payloads(target, flit)))) severity note;

            end loop BuildFlitLoop;

        end loop BuildPayloadLoop;

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


    -- Uniform procedure, stolen from GHDL ieee.math_real (https://github.com/ghdl/ghdl/blob/master/libraries/openieee/math_real-body.vhdl)
    -- Returns a pseudo-random value between 0 and 1 (Algorithm from: Pierre L'Ecuyer, CACM June 1988 Volume 31 Number 6 page 747 figure 3)
    procedure UNIFORM (SEED1, SEED2: inout POSITIVE; X: out REAL) is
        variable z, k : Integer;
        variable s1, s2 : Integer;
    begin

        k := seed1 / 53668;
        s1 := 40014 * (seed1 - k * 53668) - k * 12211;

        if s1 < 0 then
            seed1 := s1 + 2147483563;
        else
            seed1 := s1;
        end if;

        k := seed2 / 52774;
        s2 := 40692 * (seed2 - k * 52774) - k * 3791;

        if s2 < 0 then
            seed2 := s2 + 2147483399;
        else
            seed2 := s2;
        end if;

        z := seed1 - seed2;

        if z < 1 then
            z := z + 2147483562;
        end if;

        x := real(z) * 4.656613e-10;

    end procedure UNIFORM;


    -- Simple increment and wrap around
    function incr(value: integer ; maxValue: in integer ; minValue: in integer) return integer is

    begin

        if value = maxValue then
            return minValue;
        else
            return value + 1;
        end if;

    end function incr;


    -- Simple decrement and wrap around
    function decr(value: integer ; maxValue: in integer ; minValue: in integer) return integer is

    begin

        if value = minValue then
            return maxValue;
        else
            return value - 1;
        end if;

    end function decr;


end package body PE_PKG;


