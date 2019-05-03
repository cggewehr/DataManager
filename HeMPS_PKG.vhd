
--------------------------------------------------------------------------
-- package com tipos basicos
--------------------------------------------------------------------------
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

package HeMPS_PKG is

--------------------------------------------------------
-- HEMPS CONSTANTS
--------------------------------------------------------
	-- paging definitions
	constant PAGE_SIZE_H_INDEX	: integer := 13;
	constant PAGE_NUMBER_H_INDEX	: integer := 15;

	-- Hemps top definitions
	constant NUMBER_PROCESSORS_X	: integer := 3; 
	constant NUMBER_PROCESSORS_Y	: integer := 3; 

	--constant TAM_BUFFER		: integer := 8;

	constant MASTER_ADDRESS		: integer := 0;
	constant NUMBER_PROCESSORS	: integer := NUMBER_PROCESSORS_Y*NUMBER_PROCESSORS_X;

	subtype core_str is string(1 to 6);
	subtype kernel_str is string(1 to 3);
	type core_type_type is array(0 to NUMBER_PROCESSORS-1) of core_str;
	constant core_type : core_type_type := ("plasma","plasma","plasma","plasma","plasma","plasma","plasma","plasma","plasma");
	type kernel_type_type is array(0 to NUMBER_PROCESSORS-1) of kernel_str;
	constant kernel_type : kernel_type_type := ("mas","sla","sla","sla","sla","sla","sla","sla","sla");

--------------------------------------------------------
-- Hybrid HEMPS CONSTANTS
--------------------------------------------------------
	constant NUMBER_BUSES     : integer := 1;
	constant NUMBER_CROSSBARS : integer := 0;
	constant LARGESTBUS       : integer := 8;
	constant LARGESTCROSSBAR  : integer := 0;

	type Proc_Addresses is array(natural range <>) of std_logic_vector(31 downto 0);

	-- Bus definitions
	constant NUMBER_PROCESSORS_BUS : integer := 8;
	constant BUS_POSITION          : integer := 4;
	constant BUS_PROC_ADDR : Proc_Addresses(0 to LARGESTBUS-1) := (x"00000101",x"00000003",x"00000103",x"00000203",x"00000303",x"00000302",x"00000301",x"00000300");

	-- If NUMBER_BUSES = 1 this constant will not be used
	type array_Proc_Bus_Addresses is array(0 to 1) of Proc_Addresses(0 to LARGESTBUS-1);
	constant BUS_PROC_ADDRS : array_Proc_Bus_Addresses := (others=>(others=>(others=>'U')));

	-- Crossbar definitions
	-- No Crossbars

end HeMPS_PKG;