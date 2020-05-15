--------------------------------------------------------------------------------
-- Title       : HyHeMPS top level block
-- Project     : HyHeMPS
--------------------------------------------------------------------------------
-- Authors     : Carlos Gewehr (carlos.gewehr@ecomp.ufsm.br)
-- Company     : UFSM, GMICRO
-- Standard    : VHDL-1993
--------------------------------------------------------------------------------
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
--               Add WrapperInterfacingStructure array to JSON config
--               Add "isNoC", "isBus" and "isCrossbar" to JSON config
--               Add "BridgeBufferSize" to JSON config
--------------------------------------------------------------------------------


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.JSON.all;
    use work.HyHeMPS_PKG.all;


entity HyHeMPS is
    generic (
        PlatformConfigFile: string;
        AmountOfPEs: integer;
        AmountOfNoCNodes: integer
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

    -- Base NoC parameters (from JSON config)
    constant NoCXSize: integer := jsonGetInteger(PlatCFG, "BaseNoCDimensions/0");
    constant NoCYSize: integer := jsonGetInteger(PlatCFG, "BaseNoCDimensions/1");
    --constant NoCAmountOfNodes: integer := NoCXSize * NoCYSize;
    constant SquareNoCBound: integer := jsonGetInteger(PlatCFG, "SquareNoCBound");
    --constant RouterAddresses: HalfDataWidth_t := GetRouterAddresses(PlatCFG, NoCXSize, NoCYSize);
    signal LocalPortInterfaces: RouterPort_vector(0 to AmountOfNoCNodes - 1);

    -- Buses Parameters (from JSON config)
    constant AmountOfBuses: integer := jsonGetInteger(PlatCFG, "AmountOfBuses");
    constant AmountOfPEsInBuses: integer_vector(0 to AmountOfBuses - 1) := jsonGetIntegerArray(PlatCFG, "AmountOfPEsInBuses");
    constant SizeOfLargestBus: integer := jsonGetInteger(PlatCFG, "LargestBus");

    subtype BusArrayOfInterfaces is PEInterface_vector(0 to SizeOfLargestBus - 1);
    type BusInterfaces_t is array(natural range <>) of BusArrayOfInterfaces;
    signal BusInterfaces: BusInterfaces_t(0 to AmountOfBuses - 1);

    subtype BusPEAddresses_t is DataWidth_vector(0 to SizeOfLargestBus);  -- PEs + wrapper
    type BusPEAddresses_vector is array(natural range <>) of BusPEAddresses_t;
    signal BusPEAddresses: BusPEAddresses_vector(0 to AmountOfBuses - 1);

    -- Crossbars Parameters (from JSON config)
    constant AmountOfCrossbars: integer := jsonGetInteger(PlatCFG, "AmountOfCrossbars");
    constant AmountOfPEsInCrossbars: integer_vector(0 to AmountOfCrossbars - 1) := jsonGetIntegerArray(PlatCFG, "AmountOfPEsInCrossbars");
    constant SizeOfLargestCrossbar: integer := jsonGetInteger(PlatCFG, "LargestCrossbar");

    subtype CrossbarArrayOfInterfaces is PEInterface_vector(0 to SizeOfLargestBus - 1);
    type CrossbarInterfaces_t is array(natural range <>) of CrossbarArrayOfInterfaces;
    signal CrossbarInterfaces: CrossbarInterfaces_t(0 to AmountOfCrossbars - 1);

    subtype CrossbarPEAddresses_t is DataWidth_vector(0 to SizeOfLargestCrossbar);  -- PEs + wrapper
    type CrossbarPEAddresses_vector is array(natural range <>) of CrossbarPEAddresses_t;
    signal CrossbarPEAddresses: CrossbarPEAddresses_vector(0 to AmountOfCrossbars - 1);

    -- 
    constant BridgeBufferSize: integer := jsonGetInteger(PlatCFG, "BridgeBufferSize");

begin

    -- Instantiates Hermes NoC
    NocGen: entity work.Hermes

        generic map(
            PlatformConfigFile => PlatformConfigFile
        )

        port map (
            Clocks => Clocks,
            Reset => Reset,
            LocalPortInterfaces => LocalPortInterfaces
        );

     
    -- Instantiate buses, if any are to be instantiated
    BusesCond: if AmountOfBuses > 0 generate

        BusesGen: for i in 0 to AmountOfBuses - 1 generate
            signal WrapperID: integer_vector(0 to AmountOfBuses - 1);
        begin

            WrapperID(i) <= jsonGetInteger(PlatCFG, "BusWrapperID/" & integer'image(i));

            -- Adds bridge to crossbar interface
            LocalPortInterfaces(WrapperID(i)).ClockRx <= BusInterfaces(i)(0).ClockRx;
            LocalPortInterfaces(WrapperID(i)).Rx <= BusInterfaces(i)(0).Rx;
            LocalPortInterfaces(WrapperID(i)).DataIn <= BusInterfaces(i)(0).DataIn;
            LocalPortInterfaces(WrapperID(i)).CreditI <= BusInterfaces(i)(0).CreditI;
            BusInterfaces(i)(0).ClockTx <= LocalPortInterfaces(WrapperID(i)).ClockTx;
            BusInterfaces(i)(0).Tx <= LocalPortInterfaces(WrapperID(i)).Tx;
            BusInterfaces(i)(0).DataOut <= LocalPortInterfaces(WrapperID(i)).DataOut;
            BusInterfaces(i)(0).CreditO <= LocalPortInterfaces(WrapperID(i)).CreditO;

            -- Adds this wrapper's address in XY coordinates to PEAddresses array to be passed to its bus
            BusPEAddresses(i)(0)(DataWidth - 1 downto HalfDataWidth) <= (others => '0');
            BusPEAddresses(i)(0)(HalfDataWidth - 1 downto 0) <= RouterAddress(WrapperID(i), SquareNoCBound);

            BusInstance: entity work.HyBus

                generic map(
                    Arbiter          => "RR",
                    AmountOfPEs      => AmountOfPEsInBuses(i) + 1, 
                    PEAddresses      => BusPEAddresses(i),
                    BridgeBufferSize => BridgeBufferSize
                )

                port map(
                    --Clock        => RouterInterfaces(WrapperID(i)).Clock,  -- TODO: Map structure clock to clock of its wrapper
                    --Clock        => Clocks(WrapperID(i)),  -- TODO: Map structure clock to clock of its wrapper
                    Clock        => Clocks(jsonGetInteger(PlatCFG, "BusWrapperID/" & integer'image(i))),  -- TODO: Map structure clock to clock of its wrapper
                    Reset        => Reset,  -- Global reset, from entity interface
                    PEInterfaces => BusInterfaces(i)  -- TODO: Map to bus interface
                );

            report "Instantiated bus " & integer'image(i) & " with " integer'image(AmountOfPEsInBuses(i)) & " elements" severity note;

        end generate BusesGen;

    end generate BusesCond;


    -- Instantiate crossbars, if any are to be instantiated
    CrossbarCond: if AmountOfCrossbars > 0 generate

        CrossbarsGen: for i in 0 to AmountOfCrossbars - 1 generate
            signal WrapperID: integer_vector(0 to AmountOfBuses - 1);
        begin

            WrapperID(i) <= jsonGetInteger(PlatCFG, "CrossbarWrapperID/" & integer'image(i));

            -- Passes PE interface to crossbar interface
            LocalPortInterfaces(WrapperID(i)).ClockRx <= CrossbarInterfaces(i)(0).ClockRx;
            LocalPortInterfaces(WrapperID(i)).Rx <= CrossbarInterfaces(i)(0).Rx;
            LocalPortInterfaces(WrapperID(i)).DataIn <= CrossbarInterfaces(i)(0).DataIn;
            LocalPortInterfaces(WrapperID(i)).CreditI <= CrossbarInterfaces(i)(0).CreditI;
            CrossbarInterfaces(i)(0).ClockTx <= LocalPortInterfaces(WrapperID(i)).ClockTx;
            CrossbarInterfaces(i)(0).Tx <= LocalPortInterfaces(WrapperID(i)).Tx;
            CrossbarInterfaces(i)(0).DataOut <= LocalPortInterfaces(WrapperID(i)).DataOut;
            CrossbarInterfaces(i)(0).CreditO <= LocalPortInterfaces(WrapperID(i)).CreditO;

            -- Adds this wrapper's address in XY coordinates to PEAddresses array to be passed to its crossbar
            CrossbarPEAddresses(i)(0)(DataWidth - 1 downto HalfDataWidth) <= (others => '0');
            CrossbarPEAddresses(i)(0)(HalfDataWidth - 1 downto 0) <= RouterAddress(WrapperID(i), SquareNoCBound);

            CrossbarInstance: entity work.Crossbar

                generic map(
                    ArbiterType      => "RR",
                    AmountOfPEs      => AmountOfPEsInCrossbars(i) + 1,
                    PEAddresses      => CrossbarPEAddresses(i),
                    BridgeBufferSize => BridgeBufferSize
                )

                port map(
                    --Clock        => RouterInterfaces(WrapperID(i)).Clock,
                    Clock        => Clocks(jsonGetInteger(PlatCFG, "CrossbarWrapperID/" & integer'image(i))),
                    Reset        => Reset,  -- Global reset, from entity interface
                    PEInterfaces => CrossbarInterfaces(i)  -- TODO: Map to crossbar interface
                );

            report "Instantiated crossbar " & integer'image(i) & " with " integer'image(AmountOfPEsInCrossbars(i)) & " elements" severity note;

        end generate CrossbarsGen;

    end generate CrossbarCond;


    -- Connects PE interfaces passed from top entity to local port of routers and into dedicated structures
    PEConnectGen: for i in 0 to AmountOfPEs - 1 generate

        -- GAMBIARRA. Temporary values since VHDL doesnt allow variables in a for generate statement
        -- Used as a name replacement for jsonGetInteger() call
        signal busID, busPosition, crossbarID, crossbarPosition, routerPosition: integer_vector(0 to AmountOfPEs - 1);

    begin

        -- Maps Local port a router to this PE interface, provided through HyHeMPS entity interface
        ConnectToNoC: if jsonGetBoolean(PlatCFG, "isNoC/" & integer'image(i)) generate

            routerPosition(i) <= jsonGetInteger(PlatCFG, "WrapperAddresses/" & integer'image(i));  -- Returns addr in base NoC of given PE ID

            LocalPortInterfaces(routerPosition(i)).ClockRx <= PEInterfaces(i).ClockTx;
            LocalPortInterfaces(routerPosition(i)).Rx <= PEInterfaces(i).Tx;
            LocalPortInterfaces(routerPosition(i)).DataIn <= PEInterfaces(i).DataOut;
            LocalPortInterfaces(routerPosition(i)).CreditI <= PEInterfaces(i).CreditO;
            PEInterfaces(i).ClockRx <= LocalPortInterfaces(routerPosition(i)).ClockTx;
            PEInterfaces(i).Rx <= LocalPortInterfaces(routerPosition(i)).Tx;
            PEInterfaces(i).DataIn <= LocalPortInterfaces(routerPosition(i)).DataOut;
            PEInterfaces(i).CreditI <= LocalPortInterfaces(routerPosition(i)).CreditO;

            report "PE ID " & integer'image(i) & " connected to local port of router " & integer'image(routerPosition(i)) severity note;

        end generate ConnectToNoC;


        -- Adds this PE interface to its respective bus interface
        ConnectToBus: if jsonGetBoolean(PlatCFG, "isBus/" & integer'image(i)) generate

            busID(i) <= jsonGetInteger(PlatCFG, "busID/" & integer'image(i));
            busPosition(i) <= getBusPosition(i, busID(i), PlatCFG);

            -- Passes this PE's interface onto its respective place in its Bus interface
            BusInterfaces(busID(i))(busPosition(i)).ClockTx <= PEInterfaces(i).ClockTx;
            BusInterfaces(busID(i))(busPosition(i)).Tx <= PEInterfaces(i).Tx;
            BusInterfaces(busID(i))(busPosition(i)).DataOut <= PEInterfaces(i).DataOut;
            BusInterfaces(busID(i))(busPosition(i)).CreditO <= PEInterfaces(i).CreditO;
            PEInterfaces(i).ClockRx <= BusInterfaces(busID(i))(busPosition(i)).ClockRx;
            PEInterfaces(i).Rx <= BusInterfaces(busID(i))(busPosition(i)).Rx;
            PEInterfaces(i).DataIn <= BusInterfaces(busID(i))(busPosition(i)).DataIn;
            PEInterfaces(i).CreditI <= BusInterfaces(busID(i))(busPosition(i)).CreditI;

            -- Adds this PE's address in XY coordinates to PEAddresses array to be passed to its bus
            BusPEAddresses(busID(i))(busPosition(i))(HalfDataWidth - 1 downto 0) <= RouterAddress(i, SquareNoCBound);
            BusPEAddresses(busID(i))(busPosition(i))(DataWidth - 1 downto HalfDataWidth) <= (others => '0');
            
            report "PE ID " & integer'image(i) & " connected to bus " & integer'image(busID(i)) & " at bus position " & integer'image(busPosition(i)) severity note;

        end generate ConnectToBus;


        -- Adds this PE interface to its respective crossbar interface
        ConnectToCrossbar: if jsonGetBoolean(PlatCFG, "isCrossbar/" & integer'image(i)) generate

            crossbarID(i) <= jsonGetInteger(PlatCFG, "crossbarID/" & integer'image(i));
            crossbarPosition(i) <= getCrossbarPosition(i, crossbarID(i), PlatCFG);

            -- Passes this PE's interface onto its respective place in its Crossbar interface
            CrossbarInterfaces(crossbarID(i))(crossbarPosition(i)).ClockTx <= PEInterfaces(i).ClockTx;
            CrossbarInterfaces(crossbarID(i))(crossbarPosition(i)).Tx <= PEInterfaces(i).Tx;
            CrossbarInterfaces(crossbarID(i))(crossbarPosition(i)).DataOut <= PEInterfaces(i).DataOut;
            CrossbarInterfaces(crossbarID(i))(crossbarPosition(i)).CreditO <= PEInterfaces(i).CreditO;
            PEInterfaces(i).ClockRx <= CrossbarInterfaces(crossbarID(i))(crossbarPosition(i)).ClockRx;
            PEInterfaces(i).Rx <= CrossbarInterfaces(crossbarID(i))(crossbarPosition(i)).Rx;
            PEInterfaces(i).DataIn <= CrossbarInterfaces(crossbarID(i))(crossbarPosition(i)).DataIn;
            PEInterfaces(i).CreditI <= CrossbarInterfaces(crossbarID(i))(crossbarPosition(i)).CreditI;

            -- Adds this PE's address in XY coordinates to PEAddresses array to be passed to its crossbar
            CrossbarPEAddresses(crossbarID(i))(crossbarPosition(i))(HalfDataWidth - 1 downto 0) <= RouterAddress(i, SquareNoCBound);
            CrossbarPEAddresses(crossbarID(i))(crossbarPosition(i))(DataWidth - 1 downto HalfDataWidth) <= (others => '0');

            report "PE ID " & integer'image(i) & " connected to crossbar " & integer'image(crossbarID(i)) & " at crossbar position " & integer'image(crossbarPosition(i)) severity note;

        end generate ConnectToCrossbar;

    end generate PEConnectGen;

end architecture RTL;
