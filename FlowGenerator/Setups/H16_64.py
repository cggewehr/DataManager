import sys
from Sources import PlatformComposer

# Creates base 5x5 NoC
Setup = PlatformComposer.Platform((5, 5), ReferenceClock=ReferenceClock)

# Adds bus containing 6 PEs @ base NoC position (4,4)
BusA = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(4,4))

# Adds bus containing 6 PEs @ base NoC position (4,3)
BusB = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(4,3))

# Adds bus containing 6 PEs @ base NoC position (4,2)
BusC = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusC, WrapperLocationInBaseNoc=(4,2))

# Adds bus containing 6 PEs @ base NoC position (4,1)
BusD = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusD, WrapperLocationInBaseNoc=(4,1))

# Adds bus containing 6 PEs @ base NoC position (4,0)
BusE = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusE, WrapperLocationInBaseNoc=(4,0))

# Adds crossbar containing 8 PEs @ base NoC position (0,4)
CrossbarA = PlatformComposer.Crossbar(8)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(0,4))

# Adds crossbar containing 8 PEs @ base NoC position (0,3)
CrossbarB = PlatformComposer.Crossbar(8)
Setup.addStructure(NewStructure=CrossbarB, WrapperLocationInBaseNoc=(0,3))
