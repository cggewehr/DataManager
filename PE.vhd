--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Container for apps                                                --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Carlos Gabriel de Araujo Gewehr                                   --
-- CREATED      : Aug 6th, 2019                                                     --
-- VERSION      : v0.1                                                              --
-- HISTORY      : Version 0.1 - Aug 6th, 2019                                       --
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- TODO         : 
    -- Create app handler and scheduler (parametrized by JSON config)
    -- Instantiate app specific injectors and buffers according to JSON config
    -- Finish buffer instantiation
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.HeMPS_defaults.all;
use work.HemPS_PKG.all;
use work.PE_PKG.all;

entity PE is 
    generic(
        -- Path to JSON file containing PE parameters
        ConfigFile:         : string
    );
    port(
	    clock               : in  std_logic;
        reset               : in  std_logic;

	   -- NoC Interface      
        clock_tx            : out std_logic;
        tx                  : out std_logic;
        data_out            : out regflit;
        credit_i            : in  std_logic;
        clock_rx            : in  std_logic;        
        rx                  : in  std_logic;
        data_in             : in  regflit;
        credit_o            : out std_logic; 	-- Debug MC
        write_enable_debug  : out std_logic; 
        data_out_debug      : out std_logic_vector(31 downto 0);
        busy_debug          : in  std_logic;
        
        --Dynamic Insertion of Applications
        ack_app             : out std_logic;
        req_app             : in  std_logic_vector(31 downto 0);

        -- External Memory
        address             : out std_logic_vector(29 downto 0);
        data_read           : in  std_logic_vector(31 downto 0) 
    );
end PE;

architecture behavioral of PE is

    -- JSON config file
    constant JSONConfig: T_JSON := jsonLoadFile(ConfigFile);

    -- BUFFER SIGNALS
    constant InBufferSize: integer := jsonGetInteger(JSONConfig, "InBufferSize");
    constant OutBufferSize: integer := jsonGetInteger(JSONConfig, "OutBufferSize");
    signal InBuffer : InBuffer_t(0 to InBufferSize - 1);
    signal OutBuffer : OutBuffer_t(0 to OutBufferSize - 1);

    -- SCHEDULER SIGNALS
    constant SchedPolicy: string(1 to 4) := jsonGetString(JSONConfig, "SchedPolicy");
    constant RoundRobinClkPeriod: integer := jsonGetInteger(JSONConfig, "RoundRobinClkPeriod");

    -- APP INTERFACE SIGNALS
    constant AppAmount: integer := jsonGetInteger(JSONConfig, "AppAmount");




begin
    


end architecture;
