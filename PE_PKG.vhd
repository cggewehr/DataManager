--------------------------------------------------------------------------
-- Package com tipos basicos
--------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use work.HeMPS_defaults.all;

package PE_PKG is

    -- JSON config files
    constant PEJSONConfig: T_JSON := jsonLoadFile(PEConfigFile);
    constant InjectorJSONConfig: T_JSON := jsonLoadFile(InjectorConfigFile);

    -- COMM STRUCTURE INTERFACE CONSTANTS ("NOC", "XBR", "BUS")
    constant CommStructure: string(1 to 3) := jsonGetString(PEJSONConfig, "CommStructure");

    -- INJECTOR CONSTANTS ("FXD", "SDP", "PDP") (Serial, Fixed Dependant, Parallel Dependant)
    constant InjectorType: string(1 to 3) := jsonGetString(PEJSONConfig, "InjectorType");

    -- BUFFER CONSTANTS
    constant InBufferSize: integer := jsonGetInteger(PEJSONConfig, "InBufferSize");
    constant OutBufferSize: integer := jsonGetInteger(PEJSONConfig, "OutBufferSize");

    -- COMMON CONSTANTS
    constant DataWidth: integer := TAM_FLIT;
    subtype DataWidth_t is std_logic_vector(DataWidth - 1 downto 0);

end package PE_PKG;
