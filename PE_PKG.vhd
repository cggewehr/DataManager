--------------------------------------------------------------------------
-- Package com tipos basicos
--------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;

package PE_PKG is

	type app_t is ("MPEG", "SERIAL", "PARALLEL", "CUSTOM");
	type apps_t is array(natural range <>) of app_t;

	type InBuffer_t is array(natural range<>) of std_logic_vector(31 downto 0);
	type OutBuffer_t is array(natural range<>) of std_logic_vector(31 downto 0);

end package PE_PKG;
