library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CircularBuffer is

	generic (
		BufferSize : Integer;
		DataWidth  : Integer
	);
	port (

		-- Basic
		Reset : in std_logic;

		-- Input Interface
		ClockIn : in std_logic;
		DataIn : in std_logic_vector(DataWidth - 1 downto 0);
		DataInAV : in std_logic;
		WriteACK : out std_logic;

		-- Output interface
		ClockOut : in std_logic;
		DataOut : out std_logic_vector(DataWidth - 1 downto 0);
		DataOutAV : out std_logic;
		ReadReq : in std_logic;

		-- Status flags
		BufferEmptyFlag : out std_logic;
		BufferFullFlag : out std_logic;
		BufferReadyFlag : out std_logic;
		BufferAvailableFlag : out std_logic

	);

end entity CircularBuffer;

architecture RTL of CircularBuffer is

	type bufferArray_t is array (natural range <>) of std_logic_vector(DataWidth - 1 downto 0);
	signal bufferArray : bufferArray_t(BufferSize - 1 downto 0);

	signal readPointer : integer range 0 to BufferSize - 1;
	signal writePointer : integer range 0 to BufferSize - 1;
	signal dataCount : integer range 0 to BufferSize;

	-- Simple increment and wrap around
	function incr(value : integer ; maxValue : in integer ; minValue : in integer) return integer is

	begin

		if value = maxValue then
			return minValue;
		else
			return value + 1;
		end if;

	end function incr;

begin

    -- Update flags asynchrounously
	BufferEmptyFlag <= '1' when dataCount = 0 else '0';
	BufferFullFlag <= '1' when dataCount = BufferSize else '0';
	BufferReadyFlag <= '1' when dataCount < BufferSize else '0';
	BufferAvailableFlag <= '1' when dataCount > 0 else '0';


	-- Updates Data Count whenever a write or read occurs (Asynchrounous)
	UpdateFlags : process(DataInAV, ReadReq, Reset) 

		variable dataCountTemp: integer range 0 to BufferSize;

	begin

		-- Update Data Count from readPointer and writePointer values
		if Reset = '1' then
			dataCountTemp := 0;
		else
			if writePointer > readPointer then
				dataCountTemp := writePointer - readPointer;
			else
				dataCountTemp := (writePointer + BufferSize) - readPointer;
			end if;
		end if;

		dataCount <= dataCountTemp;

	end process UpdateFlags;


	-- Handles write requests
	WriteProcess : process(ClockIn, Reset) begin

		if Reset = '1' then

			writePointer <= 0;
			WriteACK <= '0';

		elsif rising_edge(ClockIn) then

			-- WriteACK is defaulted to '0'
			WriteACK <= '0';

			-- Checks for a write request. If there is valid data available and free space on the buffer, write it and send ACK signal to producer entity
			if DataInAV = '1' and dataCount < bufferSize then

				bufferArray(writePointer) <= dataIn;
				writeACK <= '1';
				writePointer <= incr(writePointer, bufferSize - 1, 0);

			end if;

		end if;

	end process;


	-- Handles read requests
	ReadProcess : process(ClockOut, Reset) begin

		if Reset = '1' then

			readPointer <= 0;
			DataOutAV <= '0';
			DataOut <= (others => '0');

		elsif rising_edge(ClockOut) then

			-- DataAV is defaulted to '0'
			DataOutAV <= '0'; 

			-- Checks for a read request. If there is data on the buffer, pass in on to consumer entity
			if ReadReq = '1' and dataCount > 0 then

				DataOut <= bufferArray(readPointer);
				DataOutAV <= '1';
				readPointer <= incr(readPointer, BufferSize - 1, 0);

			end if;

		end if;

	end process;


end architecture RTL;
