--------------------------------------------------------------------------
-- Package com tipos basicos
--------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use work.HeMPS_defaults.all;

package PE_PKG is

    -- COMMON CONSTANTS
    constant DataWidth: integer := TAM_FLIT;
    subtype DataWidth_t is std_logic_vector(DataWidth - 1 downto 0);

end package PE_PKG;
