import sys
from Sources import PlatformComposer

# Creates base 3x5 NoC
Setup = PlatformComposer.Platform((3, 5), ReferenceClock=ReferenceClock)

# Adds bus containing 4 PEs @ base NoC position (0,4)
BusA = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(0,4))

# Adds bus containing 4 PEs @ base NoC position (1,4)
BusB = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(1,4))

# Adds crossbar containing 5 PEs @ base NoC position (2,4)
CrossbarA = PlatformComposer.Crossbar(5)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(2,4))

