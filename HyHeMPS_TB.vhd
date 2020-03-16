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
-- TODO        : 
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

    signal PEInterfaces: PEInterface_vector(0 to AmountOfPEs - 1);

begin


    -- Instantiates HyHeMPS
    HyHeMPSGEN: entity work.HyHeMPS

        generic map(
            PlatformConfigFile => PlatformConfigFile
        )

        port map (
            Clock => Clock,
            Reset => Reset,
            PEInterfaces => PEInterfaces
        );


    -- Instantiates PEs (which then instantiate Injectors) to provide stimulus
    PEsGEN: for i in 0 to AmountOfPEs - 1 generate

        PE: entity work.PE

            generic map(
                PEConfigFile => "flow/PE" + integer'image(i) + ".json",
                InjectorConfigFile => "flow/INJ" + integer'image(i) + ".json",
                PlatformConfigFile => PlatformConfigFile,
                InboundLogFilename => "log/InLog" + integer'image + ".txt",
                OutboundLogFilename => "log/OutLog" + integer'image + ".txt",
            )

            port map (
                Clock => Clock,
                Reset => Reset,
                
                Clock_tx => PEInterfaces(i).Clock_tx,
                Tx => PEInterfaces(i).Tx,
                Data_out => PEInterfaces(i).Data_out,
                Credit_i => PEInterfaces(i).Credit_i,
                Clock_rx => PEInterfaces(i).Clock_rx,
                Rx => PEInterfaces(i).Rx,
                Data_In => PEInterfaces(i).Data_In,
                Credit_o => PEInterfaces(i).Credit_o
            );

    end generate PEsGEN;

    
end architecture RTL;