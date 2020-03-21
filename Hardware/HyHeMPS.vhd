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
-- TODO        : Make HyHeMPS_PKG combining HeMPS_defaults and PE_PKG PKGs
--               Define record equivalent to RouterCC entity interface
--               Define record of PE interface 
--               Define array of record of PE interface
--               Implement NoCPosIsWrapper() (Returns true for wrapper, false for router) in software
--               Implement getBusPosition(i, busID(i), PlatCFG)
--               Implement add wrapper bridge to bus/crossbar interface
--               Map structure clock to clock of its wrapper
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
    constant PlatCFG: T_JSON := jsonLoad(PlatformConfigFile);

    -- Base NoC parameters
    constant NoCXSize: integer := jsonGetInteger(PlatCFG, "BaseNoCDimensions/0");
    constant NoCYSize: integer := jsonGetInteger(PlatCFG, "BaseNoCDimensions/1");
    --constant NoCAmountOfNodes: integer := NoCXSize * NoCYSize;
    constant RouterAddresses: HalfDataWidth_t := GetRouterAddresses(PlatCFG, NoCXSize, NoCYSize);
    signal RouterInterfaces: RouterInterface_t(0 to AmountOfNoCNodes - 1);

    -- Buses Parameters
    constant AmountOfBuses: integer := jsonGetInteger(PlatCFG, "AmountOfBuses");
    constant AmountOfPEsInBuses: integer_vector(0 to AmountOfBuses - 1) := jsonGetIntegerArray(PlatCFG, "AmountOfPEsInBuses");
    constant SizeOfLargestBus: integer := jsonGetInteger(PlatCFG, "LargestBus");
    signal BusInterfaces: BusInterfaces_t(0 to AmountOfBuses - 1);

    -- Crossbars Parameters
    constant AmountOfCrossbars: integer := jsonGetInteger(PlatCFG, "AmountOfCrossbars");
    constant AmountOfPEsInCrossbars: integer_vector(0 to AmountOfCrossbars - 1) := jsonGetIntegerArray(PlatCFG, "AmountOfPEsInCrossbars");
    constant SizeOfLargestCrossbar: integer := jsonGetInteger(PlatCFG, "LargestCrossbar");
    signal CrossbarInterfaces: CrossbarInterfaces_t(0 to AmountOfCrossbars - 1);

begin

    
    -- Instantiates and connects NoC routers and wrappers, if any
    NoCGen: for i in 0 to AmountOfNoCNodes - 1 generate


        -- Instantiates a router
        RouterInstance: if jsonGetBoolean(PlatCFG, "NoCPosIsWrapper/" + integer'image(i)) generate

            report "Instantiated a router at base NoC position " + integer'image(i) severity note;

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

        end generate RouterInstance;


        -- Instantiates a wrapper
        WrapperInstance: if not jsonGetBoolean(PlatCFG, "NoCPosIsWrapper/" + integer'image(i)) generate

            report "Instantiated a wrapper at base NoC position " + integer'image(i) severity note;

            Wrapper: entity work.Wrapper

                generic map (
                    Address => RouterAddresses(i),
                    InterfacingStructure =>  -- TODO: Set interfacing structure ("BUS" or "XBR")
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

            -- TODO: Add bridge to bus/crossbar interface

        end generate WrapperInstance;


        -- Defines Clock and Reset
        RouterInterfaces(i).Clock <= Clocks(i);
        RouterInterfaces(i).Reset <= Reset;


        -- Maps this router's south port to the north port of the router below it 
        SouthMap: if i >= NoCXSize generate

            RouterInterfaces(i).Rx(South) <= RouterInterfaces(i - NoCXSize).Tx(North);
            RouterInterfaces(i).Data_in(South) <= RouterInterfaces(i - NoCXSize).Data_Out(North);
            RouterInterfaces(i).Credit_i(South) <= RouterInterfaces(i - NoCXSize).Credit_o(North);

            report "Mapped south port of router/wrapper " + integer'image(i) + " to north port of router " + integer'image(i - NoCXSize) severity note;

        end generate SouthMap;


        -- Grounds this router's south port, since this router has no router below it
        SouthGround: if i < NoCXSize generate

            RouterInterfaces(i).Rx(South) <= '0';
            RouterInterfaces(i).Data_in(South) <= (others=>'0');
            RouterInterfaces(i).Credit_i(South) <= '0';

            report "Grounded south port of router/wrapper " + integer'image(i) severity note;

        end generate SouthGround;


        -- Maps this router's north port to the south port of the router above it
        NorthMap: if i < NoCXSize * (NoCYSize - 1) generate

            RouterInterfaces(i).Rx(North) <= RouterInterfaces(i + NoCXSize).Tx(South);
            RouterInterfaces(i).Data_in(North) <= RouterInterfaces(i + NoCXSize).Data_out(South);
            RouterInterfaces(i).Credit_i(North) <= RouterInterfaces(i + NoCXSize).Credit_o(South);

            report "Mapped north port of router/wrapper " + integer'image(i) + " to south port of router " + integer'image(i + NoCXSize) severity note;

        end generate NorthMap;


        -- Grounds this router's north port, since this router has no router above it 
        NorthGround: if i >= NoCXSize * (NoCYSize - 1) generate

            RouterInterfaces(i).Rx(North) <= '0';
            RouterInterfaces(i).Data_in(North) <= (others=>'0');
            RouterInterfaces(i).Credit_i(North) <= '0';

            report "Grounded north port of router/wrapper " + integer'image(i) severity note;

        end generate NorthGround;


        -- Maps this router's west port to the east port of the router to its right
        WestMap: if i mod NoCXSize /= 0 generate

            RouterInterfaces(i).Rx(West) <= RouterInterfaces(i + 1).Tx(East);
            RouterInterfaces(i).Data_in(West) <= RouterInterfaces(i + 1).Data_out(East);
            RouterInterfaces(i).Credit_i(West) <= RouterInterfaces(i + 1).Credit_o(East);

            report "Mapped west port of router/wrapper " + integer'image(i) + " to east port of router " + integer'image(i + 1) severity note;

        end generate WestMap;


        -- Grounds this router's west port, since this router has no router to its right
        WestGround: if i mod NoCXSize = 0 generate

            RouterInterfaces(i).Rx(West) <= '0';
            RouterInterfaces(i).Data_in(West) <= (others=>'0');
            RouterInterfaces(i).Credit_i(West) <= '0';

            report "Grounded west port of router/wrapper " + integer'image(i) severity note;

        end generate WestGround;


        -- Maps this router's east port to the east port of the router to its left
        EastMap: if i mod NoCXSize /= NoCXSize - 1 generate

            RouterInterfaces(i).Rx(East) <= RouterInterfaces(i - 1).Tx(West);
            RouterInterfaces(i).Data_in(East) <= RouterInterfaces(i - 1).Data_out(West)
            RouterInterfaces(i).Credit_i(East) <= RouterInterfaces(i - 1).Credit_o(West);

            report "Mapped east port of router/wrapper " + integer'image(i) + " to west port of router " + integer'image(i - 1) severity note;

        end generate EastMap;


        -- Grounds this router's east port, since this router has no router to its left
        EastGround: if i mod NoCXSize = NoCXSize - 1 generate

            RouterInterfaces(i).Rx(West) <= '0';
            RouterInterfaces(i).Data_in(West) <= (others=>'0');
            RouterInterfaces(i).Credit_i(West) <= '0';

            report "Grounded east port of router/wrapper " + integer'image(i) + "\n\n" severity note;

        end generate EastMap;

    end generate NoCGen;


    -- Instantiate buses, if any are to be instantiated
    BusesCond: if AmountOfBuses > 0 generate

        BusesGen: for i in 0 to AmountOfBuses - 1 generate

            report "Instantiated bus " + integer'image(i) + " with " integer'image(AmountOfPEsInBuses(i)) + " elements" severity note;

            BusInstance: entity work.Bus

                generic map(
                    Arbiter => "RR",
                    AmountOfPEs => AmountOfPEsInBuses(i)
                )

                port map (
                    Clock =>  -- TODO: Map structure clock to clock of its wrapper
                    Reset => Reset,  -- Global reset, from entity interface
                    PEInterfaces => BusInterfaces(i)  -- TODO: Map to bus interface
                );

        end generate BusesGen;

    end generate BusesCond;


    -- Instantiate crossbars, if any are to be instantiated
    CrossbarCond: if AmountOfCrossbars > 0 generate

        CrossbarsGen: for i in 0 to AmountOfCrossbars - 1 generate

            report "Instantiated crossbar " + integer'image(i) + " with " integer'image(AmountOfPEsInCrossbars(i)) + " elements" severity note;

            CrossbarInstance: entity work.Crossbar

                generic map(
                    AmountOfPEs => AmountOfPEsInCrossbars(i)
                )

                port map (
                    Clock =>  -- TODO: Map structure clock to clock of its wrapper
                    Reset => Reset,  -- Global reset, from entity interface
                    PEInterfaces => CrossbarInterfaces(i)  -- TODO: Map to crossbar interface
                );

        end generate CrossbarsGen;

    end generate CrossbarCond;


    -- Connects PE interfaces passed from top entity to local port of routers and into dedicated structures
    PEConnectGen: for i in 0 to AmountOfPEs - 1 generate

        -- GAMBIARRA. Temporary values since VHDL doesnt allow variables in a for generate statement
        -- Used as a name replacement for jsongetInteger() returing 
        signal busID, busPosition, crossbarID, crossbarPosition, routerPosition: integer_vector(0 to AmountOfPEs - 1);

    begin

        -- Maps Local port a router to this PE interface, provided through HyHeMPS entity interface
        ConnectToNoC: if jsonGetBoolean(PlatCFG, "isNoC/" + integer'image(i)) generate

            routerPosition(i) <= jsonGetInteger(PlatCFG, "WrapperAddresses/" + integer'image(i));  -- Returns addr in base NoC of given PE ID

            RouterInterfaces(routerPosition(i)).Rx(Local) <= PEInterfaces(i).Tx;
            RouterInterfaces(routerPosition(i)).Data_in(Local) <= PEInterfaces(i).Data_out;
            RouterInterfaces(routerPosition(i)).Credit_i(Local) <= PEInterfaces(i).Credit_o;
            PEInterfaces(i).Credit_i <= RouterInterfaces(routerPosition(i)).Credit_o(Local);
            PEInterfaces(i).Rx <= RouterInterfaces(routerPosition(i)).Tx(Local);
            PEInterfaces(i).Data_in <= RouterInterfaces(routerPosition(i)).Data_out(Local);

            report "PE ID " + integer'image(i) + " connected to local port of router " + integer'image(routerPosition(i)) severity note;

        end generate ConnectToNoC;


        -- Adds this PE interface to its respective bus interface
        ConnectToBus: if jsonGetBoolean(PlatCFG, "isBus/" + integer'image(i)) generate

            busID(i) <= jsonGetInteger(PlatCFG, "busID/" + integer'image(i));
            busPosition(i) <= getBusPosition(i, busID(i), PlatCFG);

            -- TODO: Add PEInterface to BusInterfaces(i)
            BusInterfaces(busID(i)).AmountOfPEs <= jsonGetInteger(PlatCFG, "AmountOfPEsInBus/" + integer'image(busID));
            BusInterfaces(busID(i)).Rx(busPosition) <= PEInterfaces(i).Tx;
            BusInterfaces(busID(i)).Data_in(busPosition) <= PEInterfaces(i).Data_out;
            BusInterfaces(busID(i)).Credit_i(busPosition) <= PEInterfaces(i).Credit_o;
            PEInterfaces(i).Credit_i <= BusInterfaces(busID(i)).Credit_o(busPosition);
            PEInterfaces(i).Rx <= BusInterfaces(busID(i)).Tx(busPosition);
            PEInterfaces(i).Data_in <= BusInterfaces(busID(i)).Data_out(busPosition);

            report "PE ID " + integer'image(i) + " connected to bus " + integer'image(busID(i)) + " at bus position " + integer'image(busPosition(i)) severity note;

        end generate ConnectToBus;


        -- Adds this PE interface to its respective crossbar interface
        ConnectToCrossbar: if jsonGetBoolean(PlatCFG, "isCrossbar/" + integer'image(i)) generate

            crossbarID(i) <= jsonGetInteger(PlatCFG, "crossbarID/" + integer'image(i));
            crossbarPosition(i) <= getCrossbarPosition(i, crossbarID(i), PlatCFG);

            -- TODO: Add PEInterface to CrossbarInterfaces(i)
            CrossbarInterfaces(crossbarID(i)).AmountOfPEs <= jsonGetInteger(PlatCFG, "AmountOfPEsInBus/" + integer'image(busID));
            CrossbarInterfaces(crossbarID(i)).Rx(busPosition) <= PEInterfaces(i).Tx;
            CrossbarInterfaces(crossbarID(i)).Data_in(busPosition) <= PEInterfaces(i).Data_out;
            CrossbarInterfaces(crossbarID(i)).Credit_i(busPosition) <= PEInterfaces(i).Credit_o;
            PEInterfaces(i).Credit_i <= CrossbarInterfaces(crossbarID(i)).Credit_o(busPosition);
            PEInterfaces(i).Rx <= CrossbarInterfaces(crossbarID(i)).Tx(busPosition);
            PEInterfaces(i).Data_in <= CrossbarInterfaces(crossbarID(i)).Data_out(busPosition);

            report "PE ID " + integer'image(i) + " connected to crossbar " + integer'image(crossbarID(i)) + " at crossbar position " + integer'image(crossbarPosition(i)) severity note;

        end generate ConnectToCrossbar;

    end generate PEConnectGen;

    
end architecture RTL;
