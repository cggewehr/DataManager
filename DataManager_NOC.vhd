--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Data Manager                                                      --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Jul 9th, 2015                                                     --
-- VERSION      : v1.0                                                             --
-- HISTORY      : Version 0.1 - Jul 9th, 2015                                       --
--              : Version 0.2.1 - Set 18th, 2015                                    --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.HeMPS_defaults.all;
use work.HemPS_PKG.all;
use work.Text_Package.all;


entity DataManager_NOC is 
    generic(
            fileNameIn  : string;  --	.fileNameIn("./flow/fileIn100.txt"),
            fileNameOut : string
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
        
        --Dynamic Insertion of Applications
        ack_app             : out std_logic;
        req_app             : in  std_logic_vector(31 downto 0);

        -- External Memory
        address             : out std_logic_vector(29 downto 0);
        data_read           : in  std_logic_vector(31 downto 0) 
    );
end DataManager_NOC;

architecture behavioral of DataManager_NOC is
begin
    clock_tx <= clock;
    SEND: block
    
    -- Injector Signals
    type state is (S0, S1);
    signal currentState : state;
    signal words: regflit; --  eop + word 
    file flitFile : text open read_mode is fileNameIn;

    begin

        process(clock, reset)

            variable flitLine   : line;
            variable str        : string(1 to 8);

        begin 

            if reset = '1' then
                currentState <= S1;
                words <= (OTHERS=>'0');

            elsif rising_edge(clock) then

                case currentState is

                    when S0 =>
                        if not(endfile(flitFile)) or (credit_i = '0') then
                            if(credit_i = '1') then
                                readline(flitFile, flitLine);
                                read(flitLine, str);
                                words <= StringToStdLogicVector(str);
                                currentState <= S0;
                            else -- Local port haven't space on buffer
                                currentState <= S0;
                            end if;
                        else -- End of File
                            currentState <= S1;
                        end if;

                    when S1 =>

                        if not(endfile(flitFile)) then
                            readline(flitFile, flitLine);
                            read(flitLine, str);
                            words <= StringToStdLogicVector(str);
                            currentState <= S0;
                        else
                            words <= (OTHERS=>'0');
                            currentState <= S1;
                        end if;

                end case;

            end if;

        end process;

        data_out <= words;
        tx <= '1' when currentState = S0 else '0';

    end block SEND;
    
    RECIEVE: block
        type state is (S0);
        signal currentState : state;
        signal completeLine : regflit;
        file flitFile : text open write_mode is fileNameOut;
    begin
        completeLine <= data_in;
        process(clock, reset)
            variable flitLine   : line;
            variable str        : string (1 to 9);
        begin
            if reset = '1' then
                currentState <= S0;
                credit_o <= '1';
            elsif rising_edge(clock) then
                case currentState is
                    when S0 =>
                        if rx = '1' then
                            write(flitLine, StdLogicVectorToString(completeLine));
                            writeline(flitFile, flitLine);
                        end if;
                        currentState <= S0;
                end case;
                credit_o <= '1';
            end if;
        end process;
	assert (falling_edge(rx)= FALSE) severity note;
    end block RECIEVE;
    
end architecture;
