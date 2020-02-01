import sys
from Sources import PlatformComposer

# Creates base 4x3 NoC
Setup = PlatformComposer.Platform((4, 3), ReferenceClock=ReferenceClock)

# Adds bus containing 3 PEs @ base NoC position (3,2)
BusA = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(3,2))

# Adds bus containing 3 PEs @ base NoC position (3,1)
BusB = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(3,1))

# Adds crossbar containing 10 PEs @ base NoC position (3,0)
CrossbarA = PlatformComposer.Crossbar(10)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(3,0))
