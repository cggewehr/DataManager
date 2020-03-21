--------------------------------------------------------------------------------
-- Title       : HyHeMPS test bench
-- Project     : HyHeMPS - Hybrid Hermes Multiprocessor System-on-Chip
--------------------------------------------------------------------------------
-- Authors     : Carlos Gewehr (carlos.gewehr@ecomp.ufsm.br)
-- Company     : UFSM, GMICRO
-- Standard    : VHDL-1993
--------------------------------------------------------------------------------
-- Description : Instantiates HyHeMPS and configurable PEs
--------------------------------------------------------------------------------
-- Changelog   : v0.01 - Initial implementation
--------------------------------------------------------------------------------
-- TODO        : Make 
--------------------------------------------------------------------------------


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.PE_PKG.all;
    use work.JSON.all;
    use work.HeMPS_defaults.all;


entity HyHeMPS_TB is
    
end entity HyHeMPS_TB;


architecture RTL of HyHeMPS_TB is

    constant PlatformConfigFile: string := "flow/PlatformConfig.json";
    constant PlatformJSONConfig: T_JSON := jsonLoad(PlatformConfigFile);

    constant AmountOfPEs: integer := jsonGetInteger(PlatformJSONConfig, "AmountOfPEs");
    constant NoCXSize: integer := jsonGetInteger(PlatformJSONConfig, "BaseNoCDimensions/0");
    constant NoCYSize: integer := jsonGetInteger(PlatformJSONConfig, "BaseNoCDimensions/1");
    constant AmountOfNoCNodes: integer := NoCXSize * NoCYSize;

    signal PEInterfaces: PEInterface_vector(0 to AmountOfPEs - 1);

    signal Reset: std_logic := '1';
    signal Clocks: std_logic_vector(0 to AmountOfNoCNodes - 1);

    procedure GenerateClock(constant ClockPeriod: in time ; signal Clock: out std_logic) is begin

        ClockLoop: loop

            Clock <= '0';
            wait for ClockPeriod/2;
            Clock <= '1';
            wait for ClockPeriod/2;
            
        end loop;
        
    end procedure GenerateClock;

begin

    -- Holds reset for 100 ns
    Reset <= '1', '0' after 100 ns;


    -- Generates clocks for every router/wrapper
    ClockGen: for i in 0 to AmountOfNoCNodes - 1 generate

        Clocks(i) <= GenerateClock(Clocks(i), jsonGetReal(PlatformJSONConfig, "RouterClockPeriods/" + integer'image(i)) / 1 ns);

    end generate ClockGen;


    -- Instantiates HyHeMPS
    HyHeMPSGen: entity work.HyHeMPS

        generic map(
            PlatformConfigFile => PlatformConfigFile,
            AmountOfPEs => AmountOfPEs
        )

        port map (
            Clocks => Clocks,
            Reset => Reset,
            PEInterfaces => PEInterfaces
        );


    -- Instantiates PEs (which then instantiate Injectors) to provide stimulus
    PEsGen: for i in 0 to AmountOfPEs - 1 generate

        PE: entity work.PE

            generic map(
                PlatformConfigFile  => PlatformConfigFile,
                PEConfigFile        => "flow/PE" + integer'image(i) + ".json",
                InjectorConfigFile  => "flow/INJ" + integer'image(i) + ".json",
                InboundLogFilename  => "log/InLog" + integer'image + ".txt",
                OutboundLogFilename => "log/OutLog" + integer'image + ".txt"
            )

            port map (
                Reset    => Reset,
                Clock_tx => PEInterfaces(i).Clock_tx,
                Tx       => PEInterfaces(i).Tx,
                Data_out => PEInterfaces(i).Data_out,
                Credit_i => PEInterfaces(i).Credit_i,
                Clock_rx => PEInterfaces(i).Clock_rx,
                Rx       => PEInterfaces(i).Rx,
                Data_In  => PEInterfaces(i).Data_In,
                Credit_o => PEInterfaces(i).Credit_o,
                -- TODO: Add arbiter/bridge signals to PE interface
            );

    end generate PEsGEN;

    
end architecture RTL;