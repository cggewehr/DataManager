import sys
from Sources import PlatformComposer

# Creates base 6x5 NoC
Setup = PlatformComposer.Platform((6,5), ReferenceClock=ReferenceClock)

# Adds crossbar containing 15 PEs @ base NoC position (0,4)
CrossbarA = PlatformComposer.Crossbar(15)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(0,4))

# Adds crossbar containing 15 PEs @ base NoC position (1,4)
CrossbarB = PlatformComposer.Crossbar(15)
Setup.addStructure(NewStructure=CrossbarB, WrapperLocationInBaseNoc=(1,4))

# Adds crossbar containing 15 PEs @ base NoC position (2,4)
CrossbarC = PlatformComposer.Crossbar(15)
Setup.addStructure(NewStructure=CrossbarC, WrapperLocationInBaseNoc=(2,4))

# Adds crossbar containing 15 PEs @ base NoC position (3,4)
CrossbarD = PlatformComposer.Crossbar(15)
Setup.addStructure(NewStructure=CrossbarD, WrapperLocationInBaseNoc=(3,4))

# Adds bus containing 3 PEs @ base NoC position (4,4)
BusA = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(4,4))

# Adds bus containing 3 PEs @ base NoC position (4,3)
BusB = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(4,3))

# Adds bus containing 3 PEs @ base NoC position (5,4)
BusC = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusC, WrapperLocationInBaseNoc=(5,4))

# Adds bus containing 3 PEs @ base NoC position (5,3)
BusD = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusD, WrapperLocationInBaseNoc=(5,3))

# Adds bus containing 3 PEs @ base NoC position (5,2)
BusE = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusE, WrapperLocationInBaseNoc=(5,2))

# Adds bus containing 3 PEs @ base NoC position (5,1)
BusF = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusF, WrapperLocationInBaseNoc=(5,1))

# Adds bus containing 3 PEs @ base NoC position (5,0)
BusG = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusG, WrapperLocationInBaseNoc=(5,0))
