--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Data Manager                                                      --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Jul 9th, 2015                                                     --
-- VERSION      : v1.0                                                              --
-- HISTORY      : Version 0.1 - Jul 9th, 2015                                       --
--              : Version 0.2.1 - Set 18th, 2015                                    --
--					 : Version 0.3 - Jan 30th, 2019 (Carlos Gewehr, GMICRO)              --
--              : Version 0.4 - Feb 27th, 2019 (Carlos Gewehr, GMICRO)              --
--------------------------------------------------------------------------------------

-- 0.3 Changelog: 
-- Version adds injection rate (other then 100%) to injector as a generic parameter
-- injection rate is fixed throughout the whole simulation execution
-- injection rate is the percentage of clock cycles in which result in a successful transmission of a new flit 
-- (flits held at injector for lack of space on buffer, meaning, when credit_i = 0, dont count) 
-- Documentation improvements

-- 0.4 Changelog:
-- Adds support for continuously variable injection rate
-- "injectionMode" generic should be defined as "1" for fixed percentage or "0" for enable (ON/OFF) control

-- For fixed percentagem mode, "injectionMode" generic should be set to 0, and the desired injection rate percentage
-- entered as an integer ranging from 0 up to 100 on the "injectionRate" generic

-- For enable controlled mode, "injectionMode" generic should be set to 1, and the enable signal "injectionEnable" externally manipulated
-- in a test bench or otherwise

-- Further documentation improvements

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use work.HeMPS_defaults.all;
use work.HemPS_PKG.all;
use work.Text_Package.all;


entity DataManager_NOC is 
    generic(
        taskID      : integer;      -- Allocated task ID
        threadId    : integer;      -- Allocated thread ID
        PEPos       : integer;      -- PE position in network (PE ID)
        targetPos   : integer       -- Target PE position in network
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

architecture MPEG of DataManager_NOC is

    signal semaphore    : integer range -100 to 99;  -- Controls message flow 
    signal sendCount    : integer range 0 to 128;    -- Counter for total messages received
    signal receiveCount : integer range 0 to 128;    -- Counter for total messages sent
    signal receiveSize  : integer range 0 to 128;    -- Number of flits to be received in a message
    signal transmitSize : integer range 0 to 128;    -- Number of flits to be sent in a message

begin

    RX: block
        type state is (S0, S1, S2, S3, S4, S5);
        signal currentState: state;
    begin
        process(reset, clock)
            variable flitCount: integer;
        begin
            if (reset = '1') then
                data_out <= (OTHERS=>'0');
                tx <= '0';
                currentState <= S0;
                flitCount := 0;
                sendCount <= 0;
                receiveCount <= 0;

                -- TODO: Read file to determine network position, allocated task and thread Id's 
                if threadID = 0 then
                    -- Target thread is 3
                    receiveSize <= 64;
                    transmitSize <= 64;
                elsif threadID = 1 then
                    -- Target thread is 0
                    receiveSize <= 64;
                    transmitSize <= 64;
                elsif threadID = 2 then
                    -- Target thread is 1
                    receiveSize <= 128; 
                    transmitSize <= 64;
                elsif threadID = 3 then
                    -- No target thread
                    -- Only receives messages from thread 0
                    receiveSize <= 64;
                    transmitSize <= 0;
                elsif threadID = 4 then
                    -- Target thread is 2
                    -- Only transmits to thread 2
                    receiveSize <= 0;
                    transmitSize <= 128;
                end if;

            elsif rising_edge(clock) then
                case state is
                    when S0 =>
                        if data_in = netPos and rx = '1' then
                            -- New message incoming
                            -- Target flit
                            currentState <= S1;
                            flitCount := flitCount + 1;
                        end if;
                    when S1 =>
                        -- 
                        if rx = '1' then
                            flitCount := flitCount + 1;
                        end if;

                        if flitCount = receiveSize then
                            currentState <= S2;
                        else
                            currentState <= S3;
                            flitCount := 0;
                        end if;
                    when S2 => 
                        receiveCount <= receiveCount + 1;
                        semaphore <= semaphore + 1;
                        currentState <= S0;
                end case;
            end if;
        end process;
    end block RX;

    TX : block is
        type State is (S0, S1, S2, S3, S4, S5);
        signal currentState : State;
    begin

        process(semaphore, reset, clock)
            variable flitCount : integer range 0 to 128;
        begin
            if(reset = '1') then
                flitCount <= 0;
            elsif rising_edge(clock) then
                if (semaphore > 1) then
                    case currentState is
                        when S0 => -- flit <= message target
                            if threadID /= 3 then
                                data_out <= std_logic_vector(targetPos, data_out'length);
                                tx <= '1';
                                currentState <= S1;
                                flitCount := flitCount + 1;
                            else -- if threadID = 3 transmits nothing, holds on S0
                                currentState <= S0;
                            end if;

                        when S1 => -- flit <= message size
                            data_out <= std_logic_vector(messageSize, data_out'length);
                            tx <= '1';
                            currentState <= S2;
                        when S2 => -- flit <= payload (Source Processor)
                            data_out <= std_logic_vector(PEPos, data_out'length);
                            tx <= '1';
                            currentState <= S3;
                            flitCount := flitCount + 1;
                        when S3 => -- flit <= payload (Message target thread) (Doesnt actually match HERMES behavior, cant know ID of thread (page ID, between 1 and 3), transmits ID of app target thread instead)
                            data_out <= std_logic_vector(targetThread, data_out'length);
                            tx <= '1';
                            currentState <= S4;
                            flitCount := flitCount + 1;
                        when S4 => -- flit <= payload (Message source thread) (Cant know thread id (Page ID between 1 and 3), transmits ID of app source thread)
                            data_out <= std_logic_vector(threadID, data_out'length);
                            tx <= '1';
                            currentState <= S5;
                            flitCount := flitCount + 1;
                        when S5 => -- flit <= payload (Payload size)
                            data_out <= std_logic_vector(messageSize - 2, data_out'length); 
                            tx <= '1';
                            currentState <= S6;
                            flitCount := flitCount + 1;
                        when S6 => -- flit <= message (amount of messages sent by this PE)
                            data_out <= std_logic_vector(sendCount, data_out'length);
                            tx <= '1';
                            currentState <= S7;
                            flitCount := flitCount + 1;
                        when S7 => 
                            data_out <= (others => '0');
                            tx <= '1';
                            flitCount := flitCount + 1;

                            if (flitCount < transmitSize) then
                                currentState <= S7;
                            else
                                currentState <= S8;
                            end if;
                        when S8 => 
                            semaphore <= semaphore - 1;
                            currentState <= S0;
                    end case;
                end if;
            end if;
        end process;
    end block TX;
    
end architecture MPEG;
