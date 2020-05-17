--------------------------------------------------------------------------------
-- Title       : Bus
-- Project     : HyHeMPS
--------------------------------------------------------------------------------
-- File        : Bus.vhd
-- Author      : Carlos Gewehr (carlos.gewehr@ecomp.ufsm.br)
-- Company     : UFSM, GMICRO (Grupo de Microeletronica)
-- Standard    : VHDL-1993
--------------------------------------------------------------------------------
-- Description : Implements a Bus interconnect, in which PEs compete for access
--               to a shared communication medium.
--------------------------------------------------------------------------------
-- Revisions   : v0.01 - Initial implementation
--------------------------------------------------------------------------------
-- TODO        : 
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library work;
	use work.HyHeMPS_PKG.all;


entity HyBus is

	generic(
		Arbiter: string;
		AmountOfPEs: integer;
		PEAddresses: DataWidth_vector;  -- As XY coordinates
		BridgeBufferSize: integer;
		IsStandalone: boolean
	);
	port(
		Clock: in std_logic;
		Reset: in std_logic;
		PEInterfaces: inout PEInterface_vector
	);

end entity HyBus;


architecture RTL of HyBus is

	-- Arbiter signals
	signal arbiterACK: std_logic;
	signal arbiterGrant: std_logic_vector(0 to AmountOfPEs - 1);
	signal arbiterRequest: std_logic_vector(0 to AmountOfPEs - 1);

	-- Bus signals
	signal busData: DataWidth_t;
	signal busTx: std_logic;
	signal busCredit: std_logic;

	-- Bus control signals
	signal controlRx: std_logic_vector(0 to AmountOfPEs - 1);
	signal controlCredit: std_logic_vector(0 to AmountOfPEs - 1);
	signal controlChangeFlit: std_logic;
	
	-- Inverts ADDR flit of every new message going through the wrapper if bus is integrated in HyHeMPS
	signal busDataInv: DataWidth_t;
	signal dataToWrapper: DataWidth_t;

begin

	-- Instantiates bridges
	BusBridgeGen: for i in 0 to AmountOfPEs - 1 generate

		BusBridge: entity work.BusBridge

			generic map(
				BufferSize => BridgeBufferSize
			)
			port map(

				-- Basic
				Clock   => Clock,
				Reset   => Reset,

				-- PE interface (Bridge input)
				ClockRx => PEInterfaces(i).ClockRx,
				Rx      => PEInterfaces(i).Tx,
				DataIn  => PEInterfaces(i).DataOut,
				CreditO => PEInterfaces(i).CreditI,

				-- Bus interface (Bridge output)
				ClockTx => open,
				Tx      => BusTx,
				DataOut => BusData,
				CreditI => BusCredit,

				-- Arbiter interface
				Ack     => arbiterACK,
				Request => arbiterRequest(i),
				Grant   => arbiterGrant(i)

			);

	end generate BusBridgeGen;
	

	-- Controls Rx of PEs based on what PE is currently using the bus
	BusControl: entity work.BusControl

		generic map(
			AmountOfPEs => AmountOfPEs,
			PEAddresses => PEAddresses
		)
		port map(

			-- Basic
			Clock => Clock,
			Reset => Reset,

			-- Bus interface
			BusData => busData,
			BusTx => busTx,
			BusCredit => busCredit,
			ChangeFlit => controlChangeFlit,

			-- PE interface
			PERx => controlRx,
			PECredit => controlCredit

		);


	-- Instantiates Round Robin arbiter
	RoundRobinArbiterGen: if Arbiter = "RR" generate

		RoundRobinArbiter: entity work.BusRRArbiter

			generic map(
				AmountOfPEs => AmountOfPEs
			)
			port map (
				Clock => Clock,
				Reset => Reset,
				Ack   => arbiterACK,
				Grant => arbiterGrant,
				Req   => arbiterRequest
			);

	end generate RoundRobinArbiterGen;

 
	-- Instantiates Daisy Chain arbiter
	--DaisyChainArbiterGen: if Arbiter = "DC" generate

	--	DaisyChainArbiter: entity work.DaisyChainArbiter

	--		generic map(
	--			AmountOfPEs => AmountOfPEs
	--		)
	--		port map (
	--			Clock   => Clock,
	--			Reset   => Reset,
	--			Ack     => arbiterACK,
	--			Grant   => arbiterGrant,
	--			Request => arbiterRequest
	--		);

	--end generate DaisyChainArbiterGen;


	-- Connects PE interfaces to bus 
	PEConnectGen: for i in 0 to AmountOfPEs - 1 generate
	
		-- PE input interface (DataIn to be set at the end of this generate statement)
		PEInterfaces(i).ClockRx <= Clock;
		PEInterfaces(i).Rx <= controlRx(i);
		controlCredit(i) <= PEInterfaces(i).CreditO;

		-- PE output interface
		busData <= PEInterfaces(i).DataOut;
		busTx <= PEInterfaces(i).Tx;
		PEInterfaces(i).CreditI <= busCredit;
		
		-- This "i" corresponds to a wrapper, map its DataIn to dataToWrapper in order to be able to invert ADDR flit (busDataInv)
		WrapperConnect: if i = 0 generate
	        PEInterfaces(i).DataIn <= dataToWrapper;
	    end generate WrapperConnect;
	    
	    -- This "i" corresponds to a PE, map its DataIn to BusData, because inverting ADDR flit is not necessary 
	    BusConnect: if i /= 0 generate
	        PEInterfaces(i).DataIn <= BusData;
	    end generate BusConnect;

	end generate PEConnectGen;
	
	-- High order bits <= 0, low order bits <= Target Wrapper ADDR (NoC router decides next hop based on low order bits of ADDR flit)
	busDataInv(DataWidth - 1 downto HalfDataWidth) <= (others => '0');
	busDataInv(HalfDataWidth downto 0) <= busData(HalfDataWidth - 1 downto 0);
	
	-- Inverts ADDR flit (<= busDataInv), does nothing to SIZE and payload flits
	dataToWrapper <= busData when IsStandalone or controlChangeFlit = '0' else
	                 busDataInv;
	
end architecture RTL;
