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
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_std.all;

library work;
    use work.PE_PKG.all;
    use work.JSON.all;

entity PE is 

    generic(
        -- Path to JSON file containing PE and APP parameters
        PEConfigFile        : string := "PESample.json";
        InjectorConfigFile  : string := "InjectorSample.json";
        PlatformConfigFile  : string := "PlatformSample.json"
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
        Credit_o            : out std_logic
    );

end entity PE;

architecture Injector of PE is

    -- JSON config files
    constant PEJSONConfig: T_JSON := jsonLoad(PEConfigFile);

    -- COMM STRUCTURE INTERFACE CONSTANTS ("NOC", "XBR" or "P2P", "BUS")
    constant CommStructure: string(1 to 3) := jsonGetString(PEJSONConfig, "CommStructure");

    -- INJECTOR CONSTANTS ("FXD", "DPD")
    constant InjectorType: string(1 to 3) := jsonGetString(PEJSONConfig, "InjectorType");
    constant InjectorClockPeriod: integer := jsonGetInteger(PEJSONConfig, "InjectorClockPeriod"); -- in ns
    signal InjectorClock: std_logic := '0';

    -- INPUT BUFFER (DATA FROM STRUCTURE)
    constant InBufferSize: integer := jsonGetInteger(PEJSONConfig, "InBufferSize");
    signal InDataIn: DataWidth_t; -- Type defined in PE_PKG.vhd
    signal InDataInAV: std_logic;
    signal InWriteRequest: std_logic;
    signal InWriteACK: std_logic;
    signal InDataOut: DataWidth_t; -- Type defined in PE_PKG.vhd
    signal InDataOutAV: std_logic;
    signal InReadRequest: std_logic;
    signal InBufferEmptyFlag: std_logic;
    signal InBufferFullFlag: std_logic;
    signal InBufferAvailableFlag: std_logic;

    -- OUTPUT BUFFER (DATA TO STRUCTURE)
    constant OutBufferSize: integer := jsonGetInteger(PEJSONConfig, "OutBufferSize");
    signal OutDataIn: DataWidth_t; -- Type defined in PE_PKG.vhd
    signal OutDataInAV: std_logic;
    signal OutWriteRequest: std_logic;
    signal OutWriteACK: std_logic;
    signal OutDataOut: DataWidth_t; -- Type defined in PE_PKG.vhd
    signal OutDataOutAV: std_logic;
    signal OutReadRequest: std_logic;
    signal OutBufferEmptyFlag: std_logic;
    signal OutBufferFullFlag: std_logic;
    signal OutBufferAvailableFlag: std_logic;

begin 

    InBuffer: entity work.CircularBuffer
        generic map(
            bufferSize => InBufferSize,
            dataWidth  => DataWidth -- Constant defined in PE_PKG.vhd
        )
        port map (

            -- Basic
            clock => Clock_rx, -- Clock_rx is defined by interfacing entity
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

    OutBuffer: entity work.CircularBuffer
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


    BufferNOCInterface: if (CommStructure = "NOC") generate

        -- NoC Interface
        clock_tx <= InjectorClock; -- injectorClock = Output buffer clock
        data_out <= OutDataOut;
        OutReadRequest <= credit_i;
        tx <= OutDataOutAV;

        InDataInAV <= rx;
        InWriteRequest <= rx;
        InDataIn <= data_in;
        credit_o <= InBufferAvailableFlag;             

    end generate BufferNOCInterface;


    BufferCrossbarInterface: if (CommStructure = "XBR" or CommStructure = "P2P") generate

        -- TODO: implement crossbar interface
    
    end generate BufferCrossbarInterface;


    BufferBusInterface : if (CommStructure = "BUS") generate

        -- TODO: implement bus interface
    
    end generate BufferBusInterface;


    InjectorClockGenerator: process

    begin

        wait for (InjectorClockPeriod / 2) * 1 ns;
        InjectorClock <= not InjectorClock;

    end process;


    Injector: entity work.Injector
        generic map(
            PEConfigFile => PEConfigFile,
            InjectorConfigFile => InjectorConfigFile,
            PlatformConfigFile => PlatformConfigFile
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
            OutputBufferWriteACK => OutWriteACK,
            OutputBufferSlotAvailable => OutBufferAvailableFlag

        );


end architecture Injector;

--architecture Plasma of PE is

--begin
    
--end architecture Plasma;