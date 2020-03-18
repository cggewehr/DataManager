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
--               Implement NoCPosIsWrapper() (Returns true for wrapper, false for router) in software
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
        PlatformConfigFile: string;
        AmountOfPEs: integer;
        AmountOfNoCNodes: integer;
        AmountOfBusNodes: integer;
        AmountOfCrossbarNodes: integer
    );

    port (
        Clocks: in std_logic_vector(0 to AmountOfNoCNodes - 1);
        Reset: in std_logic;
        PEInterfaces: inout PEInterface_vector(0 to AmountOfPEs - 1)
    );

end entity HyHeMPS;


architecture RTL of HyHeMPS is

    -- Reads platform JSON config file
    constant PlatformJSONConfig: T_JSON := jsonLoad(PlatformConfigFile);

    -- Base NoC parameters
    constant NoCXSize: integer := jsonGetInteger(PlatformJSONConfig, "BaseNoCDimensions/0");
    constant NoCYSize: integer := jsonGetInteger(PlatformJSONConfig, "BaseNoCDimensions/1");
    --constant NoCAmountOfNodes: integer := NoCXSize * NoCYSize;
    constant RouterAddresses: HalfDataWidth_t := GetRouterAddresses(PlatformJSONConfig, NoCXSize, NoCYSize);
    signal RouterInterfaces: RouterInterface_t(0 to AmountOfNoCNodes - 1);

    -- Buses Parameters
    constant AmountOfBuses: integer := jsonGetInteger(PlatformJSONConfig, "AmountOfBuses");
    constant AmountOfPEsInBuses: integer_vector(0 to AmountOfBuses - 1) := jsonGetIntegerArray(PlatformJSONConfig, "AmountOfPEsInBuses");
    constant SizeOfLargestBus: integer := jsonGetInteger(PlatformJSONConfig, "LargestBus");
    --type BusInterfaceArray_t is array(0 to SizeOfLargestBus - 1) of BusInterface;   -- Array of multiple BusInterface, contains all the PE interfaces for a single bus
    signal BusInterfaces: BusInterfaces_t(0 to AmountOfBuses - 1);              -- Array of BusInterfaceArray, contains all 

    -- Crossbars Parameters
    constant AmountOfCrossbars: integer := jsonGetInteger(PlatformJSONConfig, "AmountOfCrossbars");
    constant AmountOfPEsInCrossbars: integer_vector(0 to AmountOfCrossbars - 1) := jsonGetIntegerArray(PlatformJSONConfig, "AmountOfPEsInCrossbars");
    constant SizeOfLargestCrossbar: integer := jsonGetInteger(PlatformJSONConfig, "LargestCrossbar");
    signal CrossbarInterfaces: CrossbarInterfaces_t(0 to AmountOfCrossbars - 1);

begin

    
    -- Instantiates and connects NoC routers and wrappers, if any
    NoCGen: for x in 0 to AmountOfNoCNodes - 1 generate

        -- Instantiates a router
        RouterInstance: if jsonGetBoolean(PlatformJSONConfig, "NoCPosIsWrapper/" + integer'image(i)) generate

            Router: entity work.RouterCC

                generic map (
                    Address => RouterAddresses(i)
                )

                port map (
                    Clock    => RouterInterfaces(i).Clock,
                    Reset    => RouterInterfaces(i).Reset,
                    Rx       => RouterInterfaces(i).Rx,
                    Data_in  => RouterInterfaces(i).Data_in,
                    Credit_o => RouterInterfaces(i).Credit_o,
                    Tx       => RouterInterfaces(i).Tx,
                    Data_out => RouterInterfaces(i).Data_out,
                    Credit_i => RouterInterfaces(i).Credit_i
                );

        end generate RouterGen;


        -- Instantiates a wrapper
        WrapperInstance: if not jsonGetBoolean(PlatformJSONConfig, "NoCPosIsWrapper/" + integer'image(i)) generate

            Wrapper: entity work.Wrapper

                generic map (
                    Address => RouterAddresses(i)
                )

                port map (
                    Clock    => RouterInterfaces(i).Clock,
                    Reset    => RouterInterfaces(i).Reset,
                    Rx       => RouterInterfaces(i).Rx,
                    Data_in  => RouterInterfaces(i).Data_in,
                    Credit_o => RouterInterfaces(i).Credit_o,
                    Tx       => RouterInterfaces(i).Tx,
                    Data_out => RouterInterfaces(i).Data_out,
                    Credit_i => RouterInterfaces(i).Credit_i
                );

        end generate WrapperGen;


        -- Defines Clock and Reset
        RouterInterfaces(i).Clock <= Clocks(i);
        RouterInterfaces(i).Reset <= Reset;


        -- Maps this router's south port to the north port of the router below it 
        SouthMap: if y > 0 generate

            RouterInterfaces(i).Rx(South) <= RouterInterfaces(x - NoCXSize).Tx(North);
            RouterInterfaces(i).Data_in(South) <= RouterInterfaces(x - NoCXSize).Data_Out(North);
            RouterInterfaces(i).Credit_i(South) <= RouterInterfaces(x - NoCXSize).Credit_o(North);

        end generate SouthMap;


        -- Grounds this router's south port, since this router has no router below it
        SouthGround: if y = 0 generate

            RouterInterfaces(i).Rx(South) <= '0';
            RouterInterfaces(i).Data_in(South) <= (others => '0');
            RouterInterfaces(i).Credit_i(South) <= '0';

        end generate SouthGround;


        -- Maps this router's north port to the south port of the router above it
        NorthMap: if y < NoCYSize - 1 generate

            RouterInterfaces(i).Rx(North) <= RouterInterfaces(x + NoCXSize).Rx(South);
            RouterInterfaces(i).Data_in(North) <= RouterInterfaces(x + NoCXSize).Rx(South);
            RouterInterfaces(i).Credit_i(North) <= RouterInterfaces(x + NoCXSize).Credit_o(South);

        end generate NorthMap;


        -- Grounds this router's north port, since this router has no router above it 
        NorthGround: if y = NoCYSize - 1 generate

            RouterInterfaces(i).Rx(North) <= '0';
            RouterInterfaces(i).Data_in(North) <= (others => '0');
            RouterInterfaces(i).Credit_i(North) <= '0';

        end generate NorthGround;


        -- Maps this router's west port to the east port of the router to its right
        WestMap: if x < NoCXSize - 1 generate

            RouterInterfaces(i).Rx(West) <= RouterInterfaces(i + 1).Rx(East);
            RouterInterfaces(i).Data_in(West) <= RouterInterfaces(i + 1).Data_in(East);
            RouterInterfaces(i).Credit_i(West) <= RouterInterfaces(i + 1).Credit_i(East);

        end generate WestMap;


        -- Grounds this router's west port, since this router has no router to its right
        WestGround: if x = NoCXSize - 1 generate

            RouterInterfaces(i).Rx(West) <= '0';
            RouterInterfaces(i).Data_in(West) <= (others => '0');
            RouterInterfaces(i).Credit_i(West) <= '0';

        end generate WestGround;


        -- Maps this router's east port to the east port of the router to its left
        EastMap: if x > 0 generate

            RouterInterfaces(i).Rx(East) <= RouterInterfaces(i - 1).Rx(West);
            RouterInterfaces(i).Data_in(East) <= RouterInterfaces(i - 1).Data_out(West)
            RouterInterfaces(i).Credit_i(East) <= RouterInterfaces(i - 1).Credit_o(West);

        end generate EastMap;


        -- Grounds this router's east port, since this router has no router to its left
        EastGround: if x = 0 generate

            RouterInterfaces(i).Rx(West) <= '0';
            RouterInterfaces(i).Data_in(West) <= (others => '0');
            RouterInterfaces(i).Credit_i(West) <= '0';

        end generate EastMap;

    end generate NoCGen;


    -- Connects PE interfaces passed from top entity to local port of routers and into dedicated structures
    PEConnectGen: for i in 0 to AmountOfPEs - 1 generate

        -- GAMBIARRA. Temporary values 
        signal busID, busPosition, crossbarID, crossbarPosition, routerPosition: integer_vector(0 to AmountOfPEs - 1);

    begin

        -- Maps Local port a router to this PE interface, provided through HyHeMPS entity interface
        ConnectNoC: if jsonGetBoolean(PlatformJSONConfig, "isNoC/" + integer'image(i)) generate

            routerPosition(i) <= jsonGetInteger(PlatformJSONConfig, "WrapperAddresses/" + integer'image(i));

            RouterInterfaces(routerPosition(i)).Rx(Local) <= PEInterfaces(i).Tx;
            RouterInterfaces(routerPosition(i)).Data_in(Local) <= PEInterfaces(i).Data_out;
            RouterInterfaces(routerPosition(i)).Credit_i(Local) <= PEInterfaces(i).Credit_i;
            PEInterfaces(i).Credit_i <= RouterInterfaces(routerPosition(i)).Credit_o(Local);
            PEInterfaces(i).Rx <= RouterInterfaces(routerPosition(i)).Tx(Local);
            PEInterfaces(i).Data_in <= RouterInterfaces(routerPosition(i)).Data_out(Local);

        end generate ConnectNoC;


        ConnectBus: if jsonGetBoolean(PlatformJSONConfig, "isBus/" + integer'image(i)) generate

            busID(i) <= jsonGetInteger(PlatformJSONConfig, "busID/" + integer'image(i));
            busPosition(i) <= getBusPosition(i, busID(i), PlatformJSONConfig);

            -- TODO: Add PEInterface to BusInterfaces(i)
            
            --PEInterfaces(i).Credit_i <= 
            --PEInterfaces(i).Rx <= 
            --PEInterfaces(i).Data_in <= 

        end generate ConnectBus;


        ConnectCrossbar: if jsonGetBoolean(PlatformJSONConfig, "isCrossbar/" + integer'image(i)) generate

            crossbarID(i) <= jsonGetInteger(PlatformJSONConfig, "crossbarID/" + integer'image(i));
            crossbarPosition(i) <= getCrossbarPosition(i, crossbarID(i), PlatformJSONConfig);

            -- TODO: Add PEInterface to CrossbarInterfaces(i)


        end generate ConnectCrossbar;

    end generate PEConnectGen;


    -- Instantiate buses, if any are to be instantiated
    BusesCond: if AmountOfBuses > 0 generate

        BusesGen: for i in 0 to AmountOfBuses - 1 generate

            BusInstance: entity work.Bus

                generic map(
                    Arbiter => "RR",
                    AmountOfPEs => AmountOfPEsInBuses(i)
                )

                port map (
                    Clock => -- Clock of its wrapper
                    PEInterfaces => BusInterfaces(i) -- TODO: Map to bus interface
                );

        end generate BusesGen;

    end generate BusesCond;


    -- Instantiate crossbars, if any are to be instantiated
    CrossbarCond: if AmountOfCrossbars > 0 generate

        CrossbarsGen: for i in 0 to AmountOfCrossbars - 1 generate

            CrossbarInstance: entity work.Crossbar

                generic map(
                    AmountOfPEs => AmountOfPEsInCrossbars(i)
                )

                port map (
                    Clock => -- Clock of its wrapper
                    PEInterfaces => CrossbarInterfaces(i) -- TODO: Map to crossbar interface
                );

        end generate CrossbarsGen;

    end generate CrossbarCond;

    
end architecture RTL;