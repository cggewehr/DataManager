--------------------------------------------------------------------------
-- Package com tipos basicos
--------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use work.HeMPS_defaults.all;

package PE_PKG is

	type InBuffer_t is array(natural range<>) of regflit;
	type OutBuffer_t is array(natural range<>) of regflit;

end package PE_PKG;
