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
    subtype SourcePayloadSize_t is array(integer range <>) of integer;
    subtype TargetPEsArray_t is array(integer range <>) of integer;
    subtype TargetPayloadSize_t is array(integer range <>) of integer;
    subtype TargetMessageSize_t is array(integer range <>) of integer;
    subtype HeaderFlits_t is array(integer range <>, integer range <>) of DataWidth_t;

    function FillSourcePEsArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePEsArray_t;
    function FillSourcePayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePayloadSize_t;
	function FillTargetPEsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPEsArray_t;
    function FillTargetPayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return PayloadSize_t;
    function FillTargetMessageSizeArray(TargetPayloadSizeArray : TargetPayloadSize_t ; HeaderSize : integer ; AmountOfTargetPEs : integer) return TargetMessageSize_t;
    function BuildHeaders(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer ; HeaderSize : integer ; TargetPEsArray : TargetPEsArray_t ; TargetPayloadSize : TargetPayloadSize_t) return HeaderFlits_t;

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
    function FillSourcePayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : integer) return SourcePayloadSize_t is
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
    function FillTargetPayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer) return TargetPayloadSize_t is
        variable tempArray : TargetPayloadSize_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetPayloadSizeLoop: for i in 0 to (AmountOfTargetPEs - 1) loop 
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "TargetPayloadSize/" & integer'image(i) ) );
        end loop FillTargetPayloadSizeLoop;

        return tempArray;

    end function;

    function FillTargetMessageSizeArray(TargetPayloadSizeArray : TargetPayloadSize_t ; HeaderSize : integer ; AmountOfTargetPEs : integer) return TargetMessageSize_t is
        variable tempArray : TargetMessageSize_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetMessageSizeLoop : for i in 0 to AmountOfTargetPEs loop
            
            tempArray(i) <= TargetPayloadSize(i) + HeaderSize;

        end loop;
        
    end function FillTargetMessageSizeArray;

    -- Builds header for each target PE
    function BuildHeaders(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : integer ; HeaderSize : integer ; TargetPEsArray : TargetPEsArray_t ; TargetPayloadSize : TargetPayloadSize_t) return HeaderFlits_t is
        variable tempArray : HeaderFlits_t(0 to AmountOfTargetPEs - 1, 0 to HeaderSize - 1);
    begin

        BuildHeaderLoop: for target in 0 to (AmountOfTargetPEs - 1) loop

            BuildFlitLoop: for flit in 0 to (HeaderSize - 1) loop

                headerFlitString := jsonGetString(InjectorJSONConfig, ( "Header/" & integer'image(target) & "/" & integer'image(flit) ) );

                if headerFlitString = "ADDR" then 

                    tempArray(target)(flit) := TargetPEsArray(target);

                elsif headerFlitString = "SIZE" then

                    tempArray(target)(flit) := TargetPayloadSize(target);

                end if;
                                
            end loop BuildFlitLoop;

        end loop BuildHeaderLoop;

        return tempArray;

    end function BuildHeaders;

    function BuildPayloads() return PayloadFlits_t is

    begin
        
    end function BuildPayloads;

end package body PE_PKG;
