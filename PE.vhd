---------------------------------------------------------------------------------------------------------
-- DESIGN UNIT  : Container for a single MSG Injector and In/Out Buffers parametrizable by a JSON file --
-- DESCRIPTION  :                                                                                      --
-- AUTHOR       : Carlos Gabriel de Araujo Gewehr                                                      --
-- CREATED      : Aug 6th, 2019                                                                        --
-- VERSION      : v0.1                                                                                 --
-- HISTORY      : Version 0.1 - Aug 6th, 2019                                                          --
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- TODO         : 
    -- Instantiate Buffer
    -- Instantiate Injector
    -- Determine CROSSBAR and BUS interfaces
---------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.HeMPS_defaults.all;
use work.HemPS_PKG.all;
use work.PE_PKG.all;
use work.BUfferCircular.all;

entity PE is 
    generic(
        -- Path to JSON file containing PE and APP parameters
        PEConfigFile          : string;
        APPConfigFile         : string       
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

architecture Injector of PE is

    -- JSON config files
    constant PEJSONConfig: T_JSON := jsonLoadFile(PEConfigFile);
    constant APPJSONConfig: T_JSON := jsonLoadFile(APPConfigFile);

    -- COMM STRUCTURE INTERFACE SIGNALS ("NOC", "XBR", "BUS")
    constant CommStructure: string(1 to 3) := jsonGetString(PEJSONConfig, "CommStructure");

    -- BUFFER SIGNALS
    constant InBufferSize: integer := jsonGetInteger(PEJSONConfig, "InBufferSize");
    signal InBuffer: InBuffer_t(0 to InBufferSize - 1);
    signal InDataAV: std_logic;
    signal InBufferReady: std_logic;

    constant OutBufferSize: integer := jsonGetInteger(PEJSONConfig, "OutBufferSize");
    signal OutBuffer: OutBuffer_t(0 to OutBufferSize - 1);
    signal OutDataAV: std_logic;
    signal OutBufferReady: std_logic;

begin

    -- instanciate buffers
    InBuffer: entity work.BufferCircular
        generic map(
            bufferSize => InBufferSize,
            dataWidth  => regflit
        )
        port map (
            clock => clock_rx,
            reset => reset,

            
            
        );    

end architecture Injector;

--architecture Plasma of PE is

--begin
    
--end architecture Plasma;