import sys
from Sources import PlatformComposer

# Creates base 4x4 NoC
Setup = PlatformComposer.Platform((4, 4), ReferenceClock=ReferenceClock)

# Adds bus containing 6 PEs @ base NoC position (0, 3)
BusA = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(0,3))

# Adds bus containing 6 PEs @ base NoC position (1,3)
BusB = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(1,3))

# Adds bus containing 6 PEs @ base NoC position (2,3)
BusC = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusC, WrapperLocationInBaseNoc=(2,3))

# Adds crossbar containing 6 PEs @ base NoC position (3,3)
CrossbarA = PlatformComposer.Crossbar(6)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(3,3))
