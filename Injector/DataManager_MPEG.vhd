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

entity DataManager_NOC is 
    generic(
        taskID      : integer;      -- Allocated task ID
        threadId    : integer;      -- Allocated thread ID
        PEPos       : integer;      -- PE position in network (PE ID)
        targetPos   : integer;      -- Target PE position in network
        targetID    : integer       -- Target thread ID
    );
	 
    port(
    -- Basic
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
        credit_o            : out std_logic
    );
end DataManager_NOC;

architecture MPEG of DataManager_NOC is

    -- Mimics the communication flow of the MPEG app: (Thread 4 sends 100 messages 128 flits wide each to thread 2, ...)

    --  100x128      100x64       100x64       100x64       100x64    (Amount of messages x Amount of flits)
    --    (4)    ->    (2)    ->    (1)    ->    (0)    ->    (3)     (ThreadID)

    signal sendCount    : integer range 0 to 128;    -- Counter for total messages received
    signal receiveCount : integer range 0 to 128;    -- Counter for total messages sent
    signal receiveSize  : integer range 0 to 128;    -- Number of flits to be received in a message
    signal transmitSize : integer range 0 to 128;    -- Number of flits to be sent in a message
 
    signal semaphore    : integer range -128 to 127; -- Controls message flow
    signal semaphoreAdd : std_logic;                 -- Incremets Semaphore
    signal semaphoreSub : std_logic;                 -- Decrements Semaphore

begin
    
    -- Control message flow (only allows a new transmission after a whole message is received)
    FLOWCTRL: block is begin
        process(reset, clock) begin
        
            -- Whole message was received
            if semaphoreAdd = '1' then
                semaphore <= semaphore + 1;
            end if;
            
            -- Whole message was transmited
            if semaphoreSub = '1' then
                semaphore <= semaphore - 1;
            end if;
        
        end process;
    end block FLOWCTRL;

    -- Receives and processes messages from NOC
    PE_RX: block is
        type state is (S0, S1, S2);
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
                credit_o <= '1'; -- Always available
                semaphoreAdd <= '0';

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
                    receiveSize <= 64;
                    transmitSize <= 0;
                elsif threadID = 4 then

                    -- Target thread is 2
                    receiveSize <= 0;
                    transmitSize <= 128;
                end if;

            elsif rising_edge(clock) then
                case currentState is
                    when S0 =>
                        --if data_in = PEPos and rx = '1' then
                        if to_integer(unsigned(data_in)) = PEPos and rx = '1' then

                            -- New message incoming
                            currentState <= S1;
                            flitCount := flitCount + 1;
                            
                        end if;
                        
                        semaphoreAdd <= '0';
                        
                    when S1 =>

                        -- Holds on this state until whole message is received
                        if rx = '1' then
                            flitCount := flitCount + 1;
                        end if;

                        if flitCount = receiveSize then
                            currentState <= S2;
                            flitCount := 0;
                        else
                            currentState <= S1;
                        end if;
                        
                    when S2 => 

                        -- End of message
                        receiveCount <= receiveCount + 1;
                        semaphoreAdd <= '1';
                        currentState <= S0;
                        
                end case;
            end if;
        end process;
    end block PE_RX;

    -- Elaborates new messages and transmits to NOC
    PE_TX : block is
        type State is (S0, S1, S2, S3, S4, S5, S6, S7, S8);
        signal currentState : State;
    begin

        process(reset, clock)
            variable flitCount : integer range 0 to 128;
        begin
            if(reset = '1') then
                flitCount := 0;
                semaphoreSub <= '0';
            elsif falling_edge(clock) then
                if (semaphore > 1) then
                    case currentState is
                        when S0 => -- flit <= message target
                            if threadID /= 3 then

                                if credit_i = '1' then
                                    data_out <= std_logic_vector(to_unsigned(targetPos, data_out'length));
                                    tx <= '1';
                                    currentState <= S1;
                                    flitCount := flitCount + 1;
                                else 
                                    currentState <= S0;
                                end if;

                            else -- if threadID = 3 transmits nothing, holds on S0
                                currentState <= S0;
                            end if;
                            
                            semaphoreSub <= '0';

                        when S1 => -- flit <= message size
                            if credit_i = '1' then
                                data_out <= std_logic_vector(to_unsigned(transmitSize, data_out'length));
                                tx <= '1';
                                currentState <= S2;
                                flitCount := flitCount + 1;
                            else 
                                currentState <= S1;
                            end if;
                        when S2 => -- flit <= payload (Source Processor)
                            if credit_i = '1' then
                                data_out <= std_logic_vector(to_unsigned(PEPos, data_out'length));
                                tx <= '1';
                                currentState <= S3;
                                flitCount := flitCount + 1;
                            else
                                currentState <= S2;
                            end if;
                        when S3 => -- flit <= payload (Message target thread) (Doesnt actually match HERMES behavior, cant know ID of thread (page ID, between 1 and 3), transmits ID of app target thread instead)
                            if credit_i = '1' then
                                data_out <= std_logic_vector(to_unsigned(targetID, data_out'length));
                                tx <= '1';
                                currentState <= S4;
                                flitCount := flitCount + 1;
                            else
                                currentState <= S3;
                            end if;
                        when S4 => -- flit <= payload (Message source thread) (Cant know thread id (Page ID between 1 and 3), transmits ID of app source thread)
                            if credit_i = '1' then
                                data_out <= std_logic_vector(to_unsigned(threadID, data_out'length));
                                tx <= '1';
                                currentState <= S5;
                                flitCount := flitCount + 1;
                            else 
                                currentState <= S4;
                            end if;
                        when S5 => -- flit <= payload (Payload size)
                            if credit_i = '1' then
                                data_out <= std_logic_vector(to_unsigned(transmitSize - 2, data_out'length)); 
                                tx <= '1';
                                currentState <= S6;
                                flitCount := flitCount + 1;
                            else
                                currentState <= S5;
                            end if;
                        when S6 => -- flit <= message (amount of messages sent by this PE)
                            if credit_i = '1' then
                                data_out <= std_logic_vector(to_unsigned(sendCount, data_out'length));
                                tx <= '1';
                                currentState <= S7;
                                flitCount := flitCount + 1;
                            else
                                currentState <= S6;
                            end if;
                        when S7 => 
                            if credit_i = '1' then
                                data_out <= (others=>'0');
                                tx <= '1';
                                flitCount := flitCount + 1;

                                if (flitCount < transmitSize) then
                                    currentState <= S7;
                                else
                                    currentState <= S8;
                                end if;
                            else 
                                currentState <= S7;
                            end if;
                        when S8 => 
                            semaphoreSub <= '1';
                            sendCount <= sendCount + 1;
                            currentState <= S0;
                    end case;
                end if;
            end if;
        end process;
    end block PE_TX;
    
end architecture MPEG;
