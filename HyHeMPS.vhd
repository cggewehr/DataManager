--------------------------------------------------------------------------------
-- Title       : HyHeMPS top level block
-- Project     : HyHeMPS - Hybrid Hermes Multiprocessor System-on-Chip
--------------------------------------------------------------------------------
-- Authors     : Carlos Gewehr (carlos.gewehr@ecomp.ufsm.br)
-- Company     : UFSM, GMICRO
-- Standard    : VHDL-1993
-------------------------------------------------------------------------------
-- Description : Top level instantiation of NoC, Buses and Crossbar, as defined
--              in given JSON config file
--------------------------------------------------------------------------------
-- Changelog   : v0.01 - Initial implementation
--------------------------------------------------------------------------------
-- TODO        : Make HyHeMPS_PKG combining HeMPS_defaults and PE_PKG 
--               Define record equivalent to RouterCC entity interface
--               Define record of PE interface 
--               Define array of record of PE interface
--               Implement BusesGen and CrossbarsGen
--               Implement FillRouterAddresses()
--               Implement NoCPosIsWrapper() (Returns true for wrapper, false for router)
--------------------------------------------------------------------------------


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.PE_PKG.all;
    use work.JSON.all;
    use work.HeMPS_defaults.all;


entity HyHeMPS is
    generic (
        PlatformConfigFile: string
    );

    port (
        Clock: in std_logic;
        Reset: in std_logic;
        
        PEInterfaces: PEInterface_vector
    );

end entity HyHeMPS;


architecture RTL of HyHeMPS is

    -- Reads platform JSON config file
    constant PlatformJSONConfig: T_JSON := jsonLoad(PlatformConfigFile);

    -- Base NoC parameters
    constant NoCXSize: integer := jsonGetInteger(PlatformJSONConfig, "BaseNocDimensions/0");
    constant NoCYSize: integer := jsonGetInteger(PlatformJSONConfig, "BaseNocDimensions/1");
    constant NoCAmountOfNodes: integer := NoCXSize * NoCYSize;
    constant RouterAddresses: HalfDataWidth_t := GetRouterAddresses(PlatformJSONConfig, RouterAddresses);

    -- Buses Parameters
    constant AmountOfBuses: integer := jsonGetInteger(PlatformJSONConfig, "AmountOfBuses");
    constant AmountOfPEsInBuses: integer_vector(0 to AmountOfBuses - 1) := jsonGetIntegerArray(PlatformJSONConfig, "AmountOfPEsInBuses");

    -- Crossbars Parameters
    constant AmountOfCrossbars: integer := jsonGetInteger(PlatformJSONConfig, "AmountOfCrossbars");
    constant AmountOfPEsInCrossbars: integer_vector(0 to AmountOfCrossbars - 1) := jsonGetIntegerArray(PlatformJSONConfig, "AmountOfPEsInCrossbars");

begin

    
    -- Instantiates NoC routers and wrappers, if any
    NoCGen: for i in 0 to NoCAmountOfNodes - 1 generate

        -- Instantiate a router
        RouterGen: if jsonGetBoolean(PlatformJSONConfig, "NoCPosIsWrapper/" + integer'image(i)) generate

            Router: entity work.RouterCC

                generic map (
                    Address => RouterAddresses(i)
                )

                port map (
                    -- Map to router interface record

                );

        end generate RouterGen;

        -- Instantiate a wrapper
        WrapperGen: if not jsonGetBoolean(PlatformJSONConfig, "NoCPosIsWrapper/" + integer'image(i)) generate

            Wrapper: entity work.Wrapper

                generic map (
                    Address => RouterAddresses(i)
                )

                port map (
                    -- Map to router interface record

                );

        end generate WrapperGen;

    end generate;


    -- Sets conections between NoC routers and wrappers
    RouterInterconnectGen: for i in NoCAmountOfNodes - 1 generate

        if not jsonGetBoolean(PlatformJSONConfig, "NoCPosIsWrapper/" + integer'image(i)) generate

            -- TODO

        end generate;

    end generate RouterInterconnectGen;


    -- Connects PE interfaces passed from top entity to local port of routers and dedicated structures
    PEConnectGen: for i in AmountOfPEs - 1 generate

        if 

    end generate PEConnectGen;


    -- Instantiate buses, if any are to be instantiated
    BusesCond: if AmountOfBuses > 0 generate

        BusesGen: for i in 0 to AmountOfBuses - 1 generate

            Bus: entity work.Bus

                generic map(
                    Arbiter => "RR",
                    AmountOfPEs => AmountOfPEsInBuses(i)
                )

                port map (
                    
                );

        end generate BusesGen;

    end generate BusesCond;


    -- Instantiate crossbars, if any are to be instantiated
    CrossbarCond: if AmountOfCrossbars > 0 generate

        CrossbarsGen: for i in 0 to AmountOfCrossbars generate

            Crossbar: entity work.Crossbar

                generic map(
                    AmountOfPEs => AmountOfPEsInCrossbars(i)
                )

                port map (
                    
                );

        end generate CrossbarsGen;

    end generate CrossbarCond;

    
end architecture RTL;