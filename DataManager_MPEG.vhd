library ieee;
use ieee.std_logic_1164.all;
library std;
use std.textio.all;
use work.HeMPS_defaults.all;
use work.HemPS_PKG.all;
use work.Text_Package.all;


entity DataManager_NOC is 
    generic(
            fileNameIn  : string;   --	  .fileNameIn("./flow/fileIn100.txt"),
            fileNameOut : string;
				injectionRate: integer; --   (Must be integer value between 0 and 100)    added 0.3
				injectionMode: integer  --   (Must be either 0 or 1), 0 for fixed-percentage rate or 1 for enable controlled rate    added 0.4
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
        credit_o            : out std_logic;
		  
 	-- Debug MC
        write_enable_debug  : out std_logic; 
        data_out_debug      : out std_logic_vector(31 downto 0);
        busy_debug          : in  std_logic;
        
    -- Dynamic Insertion of Applications
        ack_app             : out std_logic;
        req_app             : in  std_logic_vector(31 downto 0);

    -- External Memory
        address             : out std_logic_vector(29 downto 0);
        data_read           : in  std_logic_vector(31 downto 0);
		  
	 -- Enable Control
		injectionEnable     : in std_logic
    );
end DataManager_NOC;

architecture MPEG of DataManager_MPEG is 

    signal semaphore    : integer range -128 to 127; -- Controls message flow 
    signal netPos       : integer range 0 to 15;     -- PE position in network
    signal sendCount    : integer range 0 to 128;    -- Counter for total messages received
    signal receiveCount : integer range 0 to 128;    -- Counter for total messages sent
    signal taskID       : integer range 0 to 2;      -- Allocated task ID
    signal threadId     : integer range 0 to 4;      -- Allocated thread ID
    signal flitMax      : integer range 0 to 128;    -- Number of flits to be received in a message
    signal messageSize  : integer range 0 to 128;    -- Number of flits to be sent in a message

    file allocTable : text open write_mode is fileNameIn; -- TXT containing where all threads are allocated
	 
begin

    

end MPEG;

