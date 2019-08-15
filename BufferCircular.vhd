library ieee;
use ieee.std_logic_1164.all;

entity CircularBuffer is
    
    generic (
        bufferSize: Integer;
        dataWidth: Integer
    );
    port (

        -- Basic
        clock : in std_logic;
        reset : in std_logic;

        -- Input Interface
        dataIn : in std_logic_vector(dataWidth - 1 downto 0);
        dataInAV: in std_logic;
        writeRequest : in std_logic;
        writeACK : out std_logic;

        -- Output interface
        dataOut : out std_logic_vector(dataWidth - 1 downto 0);
        dataOutAV : out std_logic;
        readRequest: in std_logic;

        -- Flags
        bufferEmptyFlag : out std_logic;
        bufferFullFlag : out std_logic;
        bufferAvailableFlag : out std_logic;

    );

end entity CircularBuffer;

architecture RTL of CircularBuffer is

    signal buffer : array(bufferSize - 1 downto 0) of std_logic_vector(dataWidth - 1 downto 0);

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

    bufferEmptyFlag <= '1' when dataCount = 0 else '0';
    bufferFullFlag <= '1' when dataCount = BufferSize else '0';
    bufferAvailableFlag <= '1' when dataCount < bufferSize else '0';

    WriteProcess: process(clock, reset)

    begin

        if reset = '1' then

            writePointer <= 0;
            writeACK <= '0';
            dataCount <= 0;

        elsif rising_edge(clock) then

            writeACK <= '0';

            if writeRequest = '1' and dataInAV = '1' then

                buffer(writePointer) <= dataIn;
                writeACK <= '1';
                incr(writePointer);
                incr(dataCount);

            end if;

        end if;

    end process;

    ReadProcess: process(clock, reset)

    begin

        if reset = '1' then

            readPointer <= 0;
            dataOutAV <= '0';

        elsif rising_edge(clock) then

            dataOutAV <= '0';

            if readRequest = '1' then

                dataOut <= buffer(readPointer);
                dataOutAV <= '1';
                incr(readPointer);
                decr(dataCount);

            end if;

        end if;

    end process;

end architecture RTL;
        

        