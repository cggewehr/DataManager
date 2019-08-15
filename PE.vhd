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
    -- Instantiate Injector
    -- Determine CROSSBAR and BUS interfaces
---------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.BufferCircular.all;
use work.PE_PKG.all;

entity PE is 
    generic(
        -- Path to JSON file containing PE and APP parameters
        PEConfigFile          : string;
        InjectorConfigFile    : string
    );
    port(
	    clock               : in  std_logic;
        reset               : in  std_logic;

	   -- NoC Interface      
        clock_tx            : out std_logic;
        tx                  : out std_logic;
        data_out            : out DataWidth;
        credit_i            : in  std_logic;
        clock_rx            : in  std_logic;        
        rx                  : in  std_logic;
        data_in             : in  DataWidth;
        credit_o            : out std_logic;    -- Debug MC
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
    constant InjectorJSONConfig: T_JSON := jsonLoadFile(InjectorConfigFile);

    -- COMM STRUCTURE INTERFACE CONSTANTS ("NOC", "XBR", "BUS")
    constant CommStructure: string(1 to 3) := jsonGetString(PEJSONConfig, "CommStructure");

    -- INJECTOR CONSTANTS ("FXD", "SDP", "PDP") (Serial, Fixed Dependant, Parallel Dependant)
    constant InjectorType: string(1 to 3) := jsonGetString(PEJSONConfig, "InjectorType");

    -- INPUT BUFFER (DATA FROM STRUCTURE)
    constant InBufferSize: integer := jsonGetInteger(PEJSONConfig, "InBufferSize");
    signal InClock: std_logic;
    signal InDataIn: DataWidth_t; -- Tipo definido em HeMPS_defaults.vhd
    signal InDataInAV: std_logic;
    signal InWriteRequest: std_logic;
    signal InDataOut: DataWidth_t; -- Tipo definido em HeMPS_defaults.vhd
    signal InDataOutAV: std_logic;
    signal InReadRequest: std_logic;
    signal InBufferEmpty: std_logic;
    signal InBufferFull: std_logic;
    signal InBufferAvailable: std_logic;

    -- OUTPUT BUFFER (DATA TO STRUCTURE)
    constant OutBufferSize: integer := jsonGetInteger(PEJSONConfig, "OutBufferSize");
    signal OutClock: std_logic;
    signal OutDataIn: DataWidth_t; -- Tipo definido em HeMPS_defaults.vhd
    signal OutDataInAV: std_logic;
    signal OutWriteRequest: std_logic;
    signal OutDataOut: DataWidth_t; -- Tipo definido em HeMPS_defaults.vhd
    signal OutDataOutAV: std_logic;
    signal OutReadRequest: std_logic;
    signal OutBufferEmpty: std_logic;
    signal OutBufferFull: std_logic;
    signal OutBufferAvailable: std_logic;

begin

    InBuffer: entity work.BufferCircular
        generic map(
            bufferSize => InBufferSize,
            dataWidth  => DataWidth -- Constante definida em HeMPS_defaults.vhd
        )
        port map (

            -- Basic
            clock => InClock,
            reset => reset,

            -- Input Interface
            dataIn => InDataIn,
            dataInAV => InDataInAV,
            writeRequest => InWriteRequest,

            -- Output Interface
            dataOut => InDataOut,
            dataOutAV => InDataOutAV,
            readRequest => InReadRequest,

            -- Flags
            bufferEmptyFlag => InBufferEmptyFlag,
            bufferFullFlag => InBufferFullFlag,
            bufferAvailableFlag => InBufferAvailableFlag
            
        );

    OutClock <= InClock;

    OutBuffer: entity work.BufferCircular
        generic map(
            bufferSize => OutBufferSize,
            dataWidth  => DataWidth -- Constante definida em HeMPS_defaults.vhd
        )
        port map (

            -- Basic
            clock => OutClock,
            reset => reset,

            -- Input Interface
            dataIn => OutDataIn,
            dataInAV => OutDataInAV,
            writeRequest => OutWriteRequest,

            -- Output Interface
            dataOut => OutDataOut,
            dataOutAV => OutDataOutAV,
            readRequest => OutReadRequest,

            -- Flags
            bufferEmptyFlag => OutBufferEmptyFlag,
            bufferFullFlag => OutBufferFullFlag,
            bufferAvailableFlag => OutBufferAvailableFlag
            
        );


    BufferNOCInterface : block (CommStructure = "NOC") is
        
    begin
    
        -- NoC Interface
        clock_tx <= OutClock;
        data_out <= OutDataOut;
        OutReadRequest <= credit_i;
        tx <= OutDataOutAV;

        InClock <= clock_rx;
        InDataInAV <= rx;
        InWriteRequest <= rx;
        InDataIn <= data_in;
        credit_o <= InBufferAvailable;             

    end block BufferNOCInterface;


    BufferCrossbarInterface : block (CommStructure = "XBR") is
        
    begin
    
    end block BufferCrossbarInterface;


    BufferBusInterface : block (CommStructure = "BUS") is
        
    begin
    
    end block BufferBusInterface;


    Injector: entity work.Injector
        generic map(
            PEConfigFile => PEConfigFile,
            InjectorConfigFile => InjectorConfigFile
        )
        port map(
            
            -- Basic
            clock => clock_rx,
            reset => reset,

            -- Input Interface
            dataIn => InDataOut,
            dataInAV => InDataOutAV,
            inputBufferReadRequest => InReadRequest,

            -- Output Interface
            dataOut => OutDataIn,
            dataOutAV => OutDataInAV,
            outputBufferWriteRequest => OutWriteRequest

        );

end architecture Injector;

--architecture Plasma of PE is

--begin
    
--end architecture Plasma;