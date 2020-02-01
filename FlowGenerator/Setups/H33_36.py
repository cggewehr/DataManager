import sys
from Sources import PlatformComposer

# Creates base 4x3 NoC
Setup = PlatformComposer.Platform((4, 3), ReferenceClock=ReferenceClock)

# Adds crossbar containing 9 PEs @ base NoC position (0,2)
CrossbarA = PlatformComposer.Crossbar(9)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(0,2))

# Adds bus containing 3 PEs @ base NoC position (1,2)
BusA = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(1,2))

# Adds bus containing 3 PEs @ base NoC position (2,2)
BusB = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(2,2))

# Adds bus containing 3 PEs @ base NoC position (3,2)
BusC = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusC, WrapperLocationInBaseNoc=(3,2))

# Adds bus containing 3 PEs @ base NoC position (3,1)
BusD = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusD, WrapperLocationInBaseNoc=(3,1))

# Adds crossbar containing 9 PEs @ base NoC position (3,0)
CrossbarB = PlatformComposer.Crossbar(9)
Setup.addStructure(NewStructure=CrossbarB, WrapperLocationInBaseNoc=(3,0))
