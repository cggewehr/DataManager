import sys
from Sources import PlatformComposer

# Creates base 3x3 NoC
Setup = PlatformComposer.Platform(BaseNoCDimensions=(3, 3), ReferenceClock=ReferenceClock)

# Adds crossbar containing 7 PEs @ base NoC position (2, 0)
CrossbarA = PlatformComposer.Crossbar(7)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(2, 0))

# Adds bus containing 6 PEs @ base NoC position (2, 1)
BusA = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(2, 1))

# Adds bus containing 6 PEs @ base NoC position (2, 2)
BusB = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(2, 2))
