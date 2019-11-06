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
use work.JSON.all;

entity PE is 

    generic(
        -- Path to JSON file containing PE and APP parameters
        PEConfigFile          : string;
        InjectorConfigFile    : string
    );
    port(

        -- Basic
	    Clock               : in  std_logic;
        Reset               : in  std_logic;

	   -- NoC Interface      
        Clock_tx            : out std_logic;
        Tx                  : out std_logic;
        Data_out            : out DataWidth_t;
        Credit_i            : in  std_logic;
        Clock_rx            : in  std_logic;        
        Rx                  : in  std_logic;
        Data_in             : in  DataWidth_t;
        Credit_o            : out std_logic;    -- Debug MC
        Write_enable_debug  : out std_logic; 
        Data_out_debug      : out std_logic_vector(31 downto 0);
        Busy_debug          : in  std_logic;
        
        --Dynamic Insertion of Applications
        Ack_app             : out std_logic;
        Req_app             : in  std_logic_vector(31 downto 0);

        -- External Memory
        Address             : out std_logic_vector(29 downto 0);
        Data_read           : in  std_logic_vector(31 downto 0) 
    );

end entity PE;

architecture Injector of PE is

    -- JSON config files
    constant PEJSONConfig: T_JSON := jsonLoadFile(PEConfigFile);
    constant InjectorJSONConfig: T_JSON := jsonLoadFile(InjectorConfigFile);

    -- COMM STRUCTURE INTERFACE CONSTANTS ("NOC", "XBR" or "P2P", "BUS")
    constant CommStructure: string(1 to 3) := jsonGetString(PEJSONConfig, "CommStructure");

    -- INJECTOR CONSTANTS ("FXD", "DPD")
    constant InjectorType: string(1 to 3) := jsonGetString(PEJSONConfig, "InjectorType");
    constant InjectorClockPeriod: integer := integer'value(jsonGetString(PEJSONConfig, "InjectorClockPeriod"));
    signal InjectorClock: std_logic := '0';

    -- INPUT BUFFER (DATA FROM STRUCTURE)
    constant InBufferSize: integer := integer'value(jsonGetString(PEJSONConfig, "InBufferSize"));
    signal InDataIn: DataWidth_t; -- Type defined in PE_PKG.vhd
    signal InDataInAV: std_logic;
    signal InWriteRequest: std_logic;
    signal InWriteACK: std_logic;
    signal InDataOut: DataWidth_t; -- Type defined in PE_PKG.vhd
    signal InDataOutAV: std_logic;
    signal InReadRequest: std_logic;
    signal InBufferEmpty: std_logic;
    signal InBufferFull: std_logic;
    signal InBufferAvailable: std_logic;

    -- OUTPUT BUFFER (DATA TO STRUCTURE)
    constant OutBufferSize: integer := integer'value(jsonGetString(PEJSONConfig, "OutBufferSize"));
    signal OutDataIn: DataWidth_t; -- Type defined in PE_PKG.vhd
    signal OutDataInAV: std_logic;
    signal OutWriteRequest: std_logic;
    signal OutWriteACK: std_logic;
    signal OutDataOut: DataWidth_t; -- Type defined in PE_PKG.vhd
    signal OutDataOutAV: std_logic;
    signal OutReadRequest: std_logic;
    signal OutBufferEmpty: std_logic;
    signal OutBufferFull: std_logic;
    signal OutBufferAvailable: std_logic;

begin 

    InBuffer: entity work.BufferCircular
        generic map(
            bufferSize => InBufferSize,
            dataWidth  => DataWidth -- Constant defined in PE_PKG.vhd
        )
        port map (

            -- Basic
            clock => InClock,
            reset => reset,

            -- Input Interface
            dataIn => InDataIn,
            dataInAV => InDataInAV,
            writeRequest => InWriteRequest,
            writeACK => InWriteACK,

            -- Output Interface
            dataOut => InDataOut,
            dataOutAV => InDataOutAV,
            readRequest => InReadRequest,

            -- Flags
            bufferEmptyFlag => InBufferEmptyFlag,
            bufferFullFlag => InBufferFullFlag,
            bufferAvailableFlag => InBufferAvailableFlag
            
        );

    OutBuffer: entity work.BufferCircular
        generic map(
            bufferSize => OutBufferSize,
            dataWidth  => DataWidth -- Constant defined in PE_PKG.vhd
        )
        port map (

            -- Basic
            clock => InjectorClock,
            reset => reset,

            -- Input Interface
            dataIn => OutDataIn,
            dataInAV => OutDataInAV,
            writeRequest => OutWriteRequest,
            writeACK => OutWriteACK,

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


    BufferCrossbarInterface : block (CommStructure = "XBR" or CommStructure = "P2P") is
        
    begin

        -- TODO: implement crossbar interface
    
    end block BufferCrossbarInterface;


    BufferBusInterface : block (CommStructure = "BUS") is
        
    begin

        -- TODO: implement bus interface
    
    end block BufferBusInterface;


    InjectorClockGenerator: process

    begin

        wait for InjectorClockPeriod/2;
        InjectorClock <= not InjectorClock;

    end process;


    Injector: entity work.Injector
        generic map(
            PEConfigFile => PEConfigFile,
            InjectorConfigFile => InjectorConfigFile
        )
        port map(
            
            -- Basic
            Clock => InjectorClock,
            Reset => Reset,

            -- Input Interface
            DataIn => InDataOut,
            DataInAV => InDataOutAV,
            InputBufferReadRequest => InReadRequest,

            -- Output Interface
            DataOut => OutDataIn,
            DataOutAV => OutDataInAV,
            OutputBufferWriteRequest => OutWriteRequest,
            OutputBufferWriteACK => OutWriteACK

        );

end architecture Injector;

--architecture Plasma of PE is

--begin
    
--end architecture Plasma;