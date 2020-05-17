--------------------------------------------------------------------------
-- Package containing JSON translation functions and basic type definitions
--------------------------------------------------------------------------

library IEEE;
    use IEEE.std_Logic_1164.all;
    use IEEE.numeric_std.all;
    
library work;
    use work.HeMPS_defaults.all;
    use work.JSON.all;

package HyHeMPS_PKG is

    -- Router ports (used as index in router interfaces)
    constant EAST: integer := 0;
    constant WEST: integer := 1;
    constant NORTH: integer := 2;
    constant SOUTH: integer := 3;
    constant LOCAL: integer := 4;

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

    type DataWidth_vector is array(natural range <>) of DataWidth_t;
    --subtype DataWidth_vector_2d is array(0 to AmountOfPEs - 1) of DataWidth_vector;

    -- integer_vector and real_vector as standard types are available only in VHDL-2008
    --type integer_vector is array(natural range <>) of integer;
    --type real_vector is array(natural range <>) of real;

    -- 2D array of std_logic_vector
    type slv_vector is array(natural range <>) of std_logic_vector;

    constant UINT32MaxValue: integer := 2147483646; -- Xilinx for some reason only allows an integer to go up to this value, even if range is defined as 0 to 4294967295
    --constant UINT32MaxValue: integer := 4294967295;

    -- Typedefs for headers and payloads
    type HeaderFlits_t is array(integer range <>, integer range <>) of DataWidth_t;
    type PayloadFlits_t is array(integer range <>, integer range <>) of DataWidth_t;

    -- 
    type PEInterface is record

        -- Basic
        --Clock   : std_logic;
        Reset   : std_logic;

        -- Input interface
        ClockRx : std_logic;
        Rx      : std_logic;
        DataIn  : DataWidth_t;
        CreditO : std_logic;

        -- Output interface
        ClockTx : std_logic;
        Tx      : std_logic;
        DataOut : DataWidth_t;
        CreditI : std_logic;

    end record PEInterface;

    type PEInterface_vector is array(natural range <>) of PEInterface;

    --subtype regNport is std_logic_vector(4 downto 0);
    --subtype regflit is std_logic_vector(DataWidth - 1 downto 0);
    --type array_regflit is array(4 downto 0) of regflit;

    type RouterPort is record

        -- Input Interface
        ClockRx: std_logic;
        Rx:      std_logic;
        DataIn:  DataWidth_t;
        CreditO: std_logic;

        -- Output Interface    
        ClockTx: std_logic;
        Tx:      std_logic;
        DataOut: DataWidth_t;
        CreditI: std_logic;

    end record RouterPort;

    type RouterPort_vector is array(natural range <>) of RouterPort;

    -- 
    type RouterInterface is record
    
        -- Input Interface
        ClockRx: regNport;
        Rx:      regNport;
        --DataIn:  arrayNport_regflit;
        DataIn:  arraynport_regflit;
        CreditO: regNport;

        -- Output Interface    
        ClockTx: regNport;
        Tx:      regNport;
        DataOut: arraynport_regflit;
        CreditI: regNport;

    end record RouterInterface;

    type RouterInterface_vector is array(natural range <>) of RouterInterface;

    -- Adapted functions from HeMPS_defaults
    function RouterAddress(GlobalAddress: integer; NUMBER_PROCESSORS_X: integer) return HalfDataWidth_t;

    -- Function declarations for organizing data from JSON config file
    function FillTargetMessageSizeArray(TargetPayloadSizeArray: integer_vector; HeaderSize: integer) return integer_vector;
    function FillSourceMessageSizeArray(SourcePayloadSizeArray: integer_vector; HeaderSize: integer) return integer_vector;
    function FillWrapperAddressTableArray(PlatformJSONConfig: T_JSON; TargetPEsArray: integer_vector) return integer_vector;
    function FindMaxPayloadSize(TargetPayloadSizeArray: integer_vector) return integer;
    function BuildHeaders(InjectorJSONConfig: T_JSON; PlatformJSONConfig: T_JSON; HeaderSize: integer; TargetPayloadSizeArray: integer_vector; TargetPEsArray: integer_vector) return HeaderFlits_t;
    function BuildPayloads(InjectorJSONConfig: T_JSON; TargetPayloadSizeArray: integer_vector; TargetPEsArray: integer_vector) return PayloadFlits_t;
    function getPEPosInBus(PlatformJSONConfig: T_JSON; PEID: integer; BusID: integer) return integer;
    function getPEPosInCrossbar(PlatformJSONConfig: T_JSON; PEID: integer; CrossbarID: integer) return integer;

    -- Misc functions
    procedure UNIFORM (SEED1, SEED2 : inout POSITIVE; X : out REAL); -- Used for random number generation
    function incr(value: integer; maxValue: in integer; minValue: in integer) return integer;
    function decr(value: integer; maxValue: in integer; minValue: in integer) return integer;

end package HyHeMPS_PKG;


package body HyHeMPS_PKG is


    -- Translates global address to router xy coordinates (ADAPTED FROM "HeMPS_defaults" PKG)
    function RouterAddress(GlobalAddress: integer ; NUMBER_PROCESSORS_X: integer) return HalfDataWidth_t is
            variable posX, posY: QuarterDataWidth_t;
            variable addr: HalfDataWidth_t; 
    begin 

            posX := std_logic_vector(to_unsigned((GlobalAddress mod NUMBER_PROCESSORS_X), QuarterDataWidth));
            posY := std_logic_vector(to_unsigned((GlobalAddress / NUMBER_PROCESSORS_X), QuarterDataWidth));
            
            addr := (posX & posY);

            return addr;

    end function RouterAddress;


    -- Fills array of source message size for each source PE
    function FillSourceMessageSizeArray(SourcePayloadSizeArray: integer_vector ; HeaderSize: integer) return integer_vector is
        variable SourceMessageSizeArray : integer_vector(SourcePayloadSizeArray'range);
    begin

        FillSourceMessageSizeLoop: for i in SourcePayloadSizeArray'range loop 
            SourceMessageSizeArray(i) := SourcePayloadSizeArray(i) + HeaderSize;
        end loop FillSourceMessageSizeLoop;

        return SourceMessageSizeArray;

    end function;


    -- Fills array of target message size (Payload + Header) for each target PE
    function FillTargetMessageSizeArray(TargetPayloadSizeArray: integer_vector ; HeaderSize: integer) return integer_vector is
        variable TargetMessageSizeArray: integer_vector(TargetPayloadSizeArray'range);
    begin

        FillTargetMessageSizeLoop : for i in TargetPayloadSizeArray'range loop
            TargetMessageSizeArray(i) := TargetPayloadSizeArray(i) + HeaderSize;
        end loop;
        
        return TargetMessageSizeArray;
        
    end function FillTargetMessageSizeArray;


    -- Fills array containing address of associated wrapper for each global address (To find the address of a global address's associated wrapper)
    function FillWrapperAddressTableArray(PlatformJSONConfig: T_JSON ; TargetPEsArray: integer_vector) return integer_vector is
        variable WrapperAddressTableArray: integer_vector(TargetPEsArray'range);
    begin

        FillWrapperAddressTableArrayLoop: for i in TargetPEsArray'range loop
            WrapperAddressTableArray(i) := jsonGetInteger(PlatformJSONConfig, ("WrapperAddresses/" & integer'image(TargetPEsArray(i))));
        end loop FillWrapperAddressTableArrayLoop;

        return WrapperAddressTableArray;

    end function FillWrapperAddressTableArray;


    -- Builds header for each target PE
    function BuildHeaders(InjectorJSONConfig: T_JSON ; PlatformJSONConfig: T_JSON ; HeaderSize: integer ; TargetPayloadSizeArray: integer_vector ; TargetPEsArray: integer_vector) return HeaderFlits_t is
        
        variable Headers: HeaderFlits_t(TargetPEsArray'range, 0 to HeaderSize - 1);
        variable headerFlitString: string(1 to 4);
        variable wrapperAddress: integer;
        variable timestampFlag: integer := jsonGetInteger(InjectorJSONConfig, "timestampFlag");
        constant NUMBER_PROCESSORS_X: integer := jsonGetInteger(PlatformJSONConfig, "NUMBER_PROCESSORS_X");
	    
        -- Bus Adaptations
	    variable myID:		integer := jsonGetInteger(InjectorJSONConfig, "PEPos");
        variable myWrapper:	integer := jsonGetInteger(PlatformJSONConfig, "WrapperAddresses/" & integer'image(myID));

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

                    -- Get the wrapper address
                    wrapperAddress := jsonGetInteger(PlatformJSONConfig, "WrapperAddresses/" & integer'image(TargetPEsArray(target)));

                    if wrapperAddress = 0 or wrapperAddress = myWrapper then --If the target is: In NoC OR In the same structure

        	         	Headers(target, flit)((DataWidth/2) - 1 downto 0):= RouterAddress(TargetPEsArray(target), NUMBER_PROCESSORS_X);
            		    Headers(target, flit)(DataWidth - 1 downto DataWidth/2) := (others => '0');

            	    else  -- Combine the wrapper address with the PE address			

            		    -- Global XY coordinates @ most significative bits (X coordinate @ most significative parts, & Y coordinates @ least significative parts)
            		    Headers(target, flit)(DataWidth - 1 downto DataWidth/2) := RouterAddress(TargetPEsArray(target), NUMBER_PROCESSORS_X);

            		    -- Wrapper XY coordinates @ lets significative bits
            		    Headers(target, flit)((DataWidth/2) - 1 downto 0) := RouterAddress(wrapperAddress, NUMBER_PROCESSORS_X);

            	    end if;

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
    function BuildPayloads(InjectorJSONConfig: T_JSON ; TargetPayloadSizeArray: integer_vector ; TargetPEsArray: integer_vector) return PayloadFlits_t is

        variable MaxPayloadSize : integer := FindMaxPayloadSize(TargetPayloadSizeArray);
        variable Payloads : PayloadFlits_t(TargetPEsArray'range, 0 to MaxPayloadSize - 1);
        variable payloadFlitString : string(1 to 5);
        variable timestampFlag : integer := jsonGetInteger(InjectorJSONConfig, "timestampFlag");
        variable amountOfMessagesSentFlag : integer := jsonGetInteger(InjectorJSONConfig, "amountOfMessagesSentFlag");

        -- RNG
        variable RNGSeed1: integer := 22;
        variable RNGSeed2: integer := 32;
        variable RandomNumber: real;

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
                --                         "RANDO" (Randomize every bit)
                --                         "BLANK" (Fills with zeroes)
                
                if payloadFlitString = "PEPOS" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(jsonGetInteger(InjectorJSONConfig, "PEPos"), DataWidth));

                elsif payloadFlitString = "APPID" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(jsonGetInteger(InjectorJSONConfig, "APPID"), DataWidth));

                elsif payloadFlitString = "THDID" then

                    Payloads(target, flit) := std_logic_vector(to_unsigned(jsonGetInteger(InjectorJSONConfig, "ThreadID"), DataWidth));

                elsif payloadFlitString = "AVGPT" then

                    --Payloads(target, flit) := std_logic_vector(to_unsigned(jsonGetInteger(InjectorJSONConfig, "AverageProcessingTimeInClockPulses"), DataWidth));
                    Payloads(target, flit) := (others => '1');

                elsif payloadFlitString = "TMSTP" then

                    -- Flags for "real time" processing
                    Payloads(target, flit) := std_logic_vector(to_unsigned(timestampFlag, DataWidth));

                elsif payloadFlitString = "AMMSG" then 

                    -- Flags for "real time" processing
                    Payloads(target, flit) := std_logic_vector(to_unsigned(amountOfMessagesSentFlag, DataWidth));

                elsif payloadFlitString = "RANDO" then

                    -- Randomizes each bit of current flit
                    for i in 0 to DataWidth - 1 loop

                        -- RandomNumber <= (0.0 < RNG < 1.0)
                        Uniform(RNGSeed1, RNGSeed2, RandomNumber);

                        if RandomNumber < 0.5 then

                            Payloads(target, flit)(i) := '0';

                        else

                            Payloads(target, flit)(i) := '1';

                        end if;

                    end loop;

                elsif payloadFlitString = "BLANK" then

                    Payloads(target, flit) := (others=>'0');

                end if;

                report "        Flit " & integer'image(flit) & " of payload of message to be delivered to PE ID " & integer'image(TargetPEsArray(target)) & " is " & payloadFlitString & " = " & integer'image(to_integer(unsigned(Payloads(target, flit)))) severity note;

            end loop BuildFlitLoop;

        end loop BuildPayloadLoop;

        return Payloads;

    end function BuildPayloads;


    -- Returns highest value in the TargetPayloadSizeArray array
    function FindMaxPayloadSize(TargetPayloadSizeArray : integer_vector) return integer is
        variable MaxPayloadSize : integer := 0;
    begin

        FindMaxPayloadSizeLoop : for i in TargetPayloadSizeArray'range loop
            
            if TargetPayloadSizeArray(i) > MaxPayloadSize then

                MaxPayloadSize := TargetPayloadSizeArray(i);

            end if;

        end loop FindMaxPayloadSizeLoop;

        return MaxPayloadSize;

    end function FindMaxPayloadSize;
    
    
    -- Returns index of a given PE ID located in a given bus
    function getPEPosInBus(PlatformJSONConfig: T_JSON; PEID: integer; BusID: integer) return integer is begin

        for i in 0 to jsonGetInteger(PlatformJSONConfig, "AmountOfPEsInBuses/" & integer'image(BusID)) - 1 loop
        
            if PEID = jsonGetInteger(PlatformJSONConfig, "BusPEIDs/" & integer'image(BusID) & "/" & integer'image(i)) then
                return i + 1;  -- Adds 1 to account for wrapper placed @ i = 0
            end if;
        
        end loop;
        
        report "PEID " & integer'image(PEID) & "not found in bus ID" & integer'image(BusID) severity failure;

    end function getPEPosInBus;
    
    
    -- Returns index of a given PE ID located in a given crossbar
    function getPEPosInCrossbar(PlatformJSONConfig: T_JSON; PEID: integer; CrossbarID: integer) return integer is begin

        for i in 0 to jsonGetInteger(PlatformJSONConfig, "AmountOfPEsInCrossbars/" & integer'image(CrossbarID)) - 1 loop
        
            if PEID = jsonGetInteger(PlatformJSONConfig, "CrossbarPEIDs/" & integer'image(CrossbarID) & "/" & integer'image(i)) then
                return i + 1;  -- Adds 1 to account for wrapper placed @ i = 0
            end if;
        
        end loop;
        
        report "PEID " & integer'image(PEID) & "not found in crossbar ID" & integer'image(CrossbarID) severity failure;

    end function getPEPosInCrossbar;


    -- Borrowed from GHDL ieee.math_real implementation (https://github.com/ghdl/ghdl/blob/master/libraries/openieee/math_real-body.vhdl)
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


end package body HyHeMPS_PKG;

