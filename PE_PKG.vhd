--------------------------------------------------------------------------
-- Package com tipos basicos
--------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use work.HeMPS_defaults.all;
use work.JSON.all;

package PE_PKG is

    -- COMMON CONSTANTS
    constant DataWidth: integer := TAM_FLIT;
    subtype DataWidth_t is std_logic_vector(DataWidth - 1 downto 0);

    function FillSourcePEsArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : natural) return SourcePEsArray_t;
    function FillSourcePayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : natural) return SourcePayloadSize_t;
	function FillTargetPEsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : natural) return TargetPEsArray_t;
    function FillTargetPayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : natural) return PayloadSize_t;
    function FillHeaderFlitsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : natural ; HeaderSize : natural) return HeaderFlits_t;

end package PE_PKG;

package body PE_PKG is


    -- Fills array of source PEs 
    subtype SourcePEsArray_t is array(natural range <>) of natural;

    function FillSourcePEsArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : natural) return SourcePEsArray_t is
        variable tempArray : SourcePEsArray_t(0 to AmountOfSourcePEs - 1);
    begin

        FillSourcesLoop: for i in 0 to (AmountOfSourcePEs - 1) loop
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "SourcePEs/" & integer'image(i) ) ); 
        end loop;

        return tempArray;

    end function FillSourcePEsArray;


    -- Fills array of source payload size for each source PE
    subtype SourcePayloadSize_t is array(natural range <>) of natural;

    function FillSourcePayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfSourcePEs : natural) return SourcePayloadSize_t is
        variable tempArray : SourcePayloadSize_t(0 to AmountOfSourcePEs - 1);
    begin

        FillSourcePayloadSizeLoop: for i in 0 to (AmountOfSourcePEs - 1) loop 
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "SourcePayloadSize/" & integer'image(i) ) );
        end loop FillSourcePayloadSizeLoop;

        return tempArray;

    end function;


	-- Fills array of target PEs
    subtype TargetPEsArray_t is array(natural range <>) of natural;

    function FillTargetPEsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : natural) return TargetPEsArray_t is
        variable tempArray : TargetPEsArray_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetsLoop: for i in 0 to (AmountOfTargetPEs - 1) loop
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "TargetPEs/" & integer'image(i) ) ); 
        end loop;

        return tempArray;

    end function FillTargetPEsArray;


    -- Fills array of target payload size for each target PE
    subtype TargetPayloadSize_t is array(natural range <>) of natural;

    function FillTargetPayloadSizeArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : natural) return TargetPayloadSize_t is
        variable tempArray : TargetPayloadSize_t(0 to AmountOfTargetPEs - 1);
    begin

        FillTargetPayloadSizeLoop: for i in 0 to (AmountOfTargetPEs - 1) loop 
            tempArray(i) := jsonGetInteger(InjectorJSONConfig, ( "TargetPayloadSize/" & integer'image(i) ) );
        end loop FillTargetPayloadSizeLoop;

        return tempArray;

    end function;


    -- Builds header for each target PE
    subtype HeaderFlits_t is array(natural range <>, natural range <>) of DataWidth_t;

    function FillHeaderFlitsArray(InjectorJSONConfig : T_JSON ; AmountOfTargetPEs : natural ; HeaderSize : natural) return HeaderFlits_t is
        variable tempArray : HeaderFlits_t(0 to AmountOfTargetPEs - 1, 0 to HeaderSize - 1);
    begin

        BuildHeaderLoop: for target in 0 to (AmountOfTargetPEs - 1) loop

            BuildFlitLoop: for flit in 0 to (HeaderSize - 1) loop

                headerFlitString := jsonGetString(InjectorJSONConfig, ( "Header/" & integer'image(target) & "/" & integer'image(flit) ) );

                if headerFlitString = "ADDR" then 

                    tempArray(target)(flit) := TargetPEsArray(target);

                elsif headerFlitString = "SIZE" then

                    tempArray(target)(flit) := PayloadSize(target);

                end if;
                                
            end loop BuildFlitLoop;

        end loop BuildHeaderLoop;

        return tempArray;

    end function FillHeaderFlitsArray;


end package body PE_PKG;
