library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CircularBuffer is
    
    generic (
        BufferSize: Integer;
        DataWidth: Integer
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

    type bufferArray_t is array (natural range <>) of std_logic_vector(DataWidth - 1 downto 0);
    signal bufferArray : bufferArray_t(BufferSize - 1 downto 0);

    signal readPointer : integer range 0 to BufferSize - 1;
    signal writePointer: integer range 0 to BufferSize - 1;
    signal dataCount: integer range 0 to BufferSize;
    
    signal dataCountIncrFlag, dataCountDecrFlag: std_logic;

    -- Simple increment and wrap around
    function incr(value: integer ; maxValue: in integer ; minValue: in integer) return integer is

    begin

        if value = maxValue then
            return minValue;
        else
            return value + 1;
        end if;

    end function incr;

begin


    -- Asynchrounously sets flags
    bufferEmptyFlag <= '1' when DataCount = 0 else '0';
    bufferFullFlag <= '1' when DataCount = BufferSize else '0';
    bufferAvailableFlag <= '1' when DataCount < BufferSize else '0';


    -- Handles write requests
    WriteProcess: process(Clock, Reset) begin

        if Reset = '1' then

            writePointer <= 0;
            writeACK <= '0';
            dataCountIncrFlag <= '0';

        elsif rising_edge(Clock) then

            -- writeACK and dataCountIncrFlag are defaulted to '0'
            writeACK <= '0';
            dataCountIncrFlag <= '0';

            -- Checks for a write request. If there is valid data available and free space on the buffer, write it and send ACK to producer entity
            if writeRequest = '1' and dataInAV = '1' and dataCount < bufferSize then

                bufferArray(writePointer) <= dataIn;
                writeACK <= '1';
                writePointer <= incr(writePointer, bufferSize - 1, 0);
                dataCountIncrFlag <= '1';

            end if;

        end if;

    end process;


    -- Handles read requests
    ReadProcess: process(Clock, Reset) begin

        if Reset = '1' then

            readPointer <= 0;
            dataOutAV <= '0';
            dataCountDecrFlag <= '0';
	    dataOut	<= (others => '0');	

        elsif rising_edge(Clock) then

            -- DataAV and dataCountDecrFlag are defaulted to '0'
            --dataOutAV <= '0'; 
            dataCountDecrFlag <= '0';

            -- Checks for a read request. If there is data on the buffer, pass in on to consumer entity
            if readRequest = '1' and dataCount > 0 then

                dataOut <= bufferArray(readPointer);
                dataOutAV <= '1';
                readPointer <= incr(readPointer, bufferSize - 1, 0);
                dataCountDecrFlag <= '1';
	    -- The RX is only lowered when the buffer has no more content
	    elsif dataCount < 0 then 

		dataOutAV <= '0';

            end if;

        end if;

    end process; 


    -- Updates dataCount (amount of buffer slots filled)
    DataCountProcess: process(Clock, Reset) 
        variable dataCountTemp: integer range 0 to bufferSize;
    begin
    
        if Reset = '1' then
        
            dataCountTemp := 0;
            dataCount <= 0;

        elsif falling_edge(Clock) then
        
            if dataCountIncrFlag = '1' then
            
                dataCountTemp := incr(dataCount, bufferSize, 0);
                
            end if;
            
            if dataCountDecrFlag = '1' then
            
                dataCountTemp := dataCountTemp - 1;
                
            end if;
            
            dataCount <= dataCountTemp;
        
        end if;
       
    end process;


end architecture RTL;
        

        
