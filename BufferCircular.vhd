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

    signal readPointer : integer range 0 to BufferSize - 1;
    signal writePointer: integer range 0 to BufferSize - 1;
    signal dataCount: integer range 0 to BufferSize - 1;

begin

    bufferEmptyFlag <= '1' when dataCount = 0 else '0';
    bufferFullFlag <= '1' when dataCount = BufferSize else '0';
    bufferAvailableFlag <= '1' when dataCount < bufferSize else '0';

    process(clock, reset)

        begin

            if (reset = '1') then

                for i in 0 to BufferSize - 1 loop
                    Buffer(i) <= (others => '0');
                end loop;

                readPointer <= 0;
                writePointer <= 0;
                dataCount <= 0;

            elsif rising_edge(clk) then

                if (dataInAV = '1') and (dataCount < BufferSize) then
                    
                    InBuffer(writePointer) <= dataIn;
                    dataCount <= dataCount + 1;

                    writePointer <= (writePointer + 1) % (BufferSize - 1);

                end if;

                if () then

                end if;

            end if;

        end process;

end architecture RTL;
        

        