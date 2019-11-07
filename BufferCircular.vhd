library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CircularBuffer is
    
    generic (
        bufferSize: Integer;
        dataWidth: Integer
    );
    port (

        -- Basic
        Clock : in std_logic;
        Reset : in std_logic;

        -- Input Interface
        DataIn : in std_logic_vector(dataWidth - 1 downto 0);
        DataInAV: in std_logic;
        WriteRequest : in std_logic;
        WriteACK : out std_logic;

        -- Output interface
        DataOut : out std_logic_vector(dataWidth - 1 downto 0);
        DataOutAV : out std_logic;
        ReadRequest: in std_logic;

        -- Flags
        BufferEmptyFlag : out std_logic;
        BufferFullFlag : out std_logic;
        BufferAvailableFlag : out std_logic

    );

end entity CircularBuffer;

architecture RTL of CircularBuffer is

    type bufferArray_t is array (natural range <>) of std_logic_vector(dataWidth - 1 downto 0);
    signal bufferArray : bufferArray_t(bufferSize - 1 downto 0);

    signal readPointer : integer range 0 to BufferSize - 1;
    signal writePointer: integer range 0 to BufferSize - 1;
    signal dataCount: integer range 0 to BufferSize - 1;

    -- Increments and wraps around
    procedure incr(signal value : inout integer) is

    begin

        if value = (bufferSize - 1) then
            value <= 0;
        else
            value <= value + 1;
        end if;

    end procedure;

    -- Decrements and wraps around
    procedure decr(signal value : inout integer) is

    begin

        if value = 0 then
            value <= (bufferSize - 1);
        else
            value <= value - 1;
        end if;

    end procedure;

begin

    -- Asynchrounously sets flags
    bufferEmptyFlag <= '1' when dataCount = 0 else '0';
    bufferFullFlag <= '1' when dataCount = BufferSize else '0';
    bufferAvailableFlag <= '1' when dataCount < bufferSize else '0';


    -- Handles write requests
    WriteProcess: process(Clock, Reset)

    begin

        if Reset = '1' then

            writePointer <= 0;
            writeACK <= '0';
            dataCount <= 0;

        elsif rising_edge(Clock) then

            -- writeACK is defaulted to '0'
            writeACK <= '0';

            -- Checks for a write request. If there is valid data available and free space on the buffer, write it and send ACK to producer entity
            if writeRequest = '1' and dataInAV = '1' and dataCount < bufferSize then

                bufferArray(writePointer) <= dataIn;
                writeACK <= '1';
                incr(writePointer);
                incr(dataCount);

            end if;

        end if;

    end process;


    -- Handles read requests
    ReadProcess: process(Clock, Reset)

    begin

        if Reset = '1' then

            readPointer <= 0;
            dataOutAV <= '0';

        elsif rising_edge(Clock) then

            -- DataAV is defaulted do '0'
            dataOutAV <= '0';

            -- Checks for a read request. If there is data on the buffer, pass in on to consumer entity
            if readRequest = '1' and dataCount > 0 then

                dataOut <= bufferArray(readPointer);
                dataOutAV <= '1';
                incr(readPointer);
                decr(dataCount);

            end if;

        end if;

    end process;


end architecture RTL;
        

        