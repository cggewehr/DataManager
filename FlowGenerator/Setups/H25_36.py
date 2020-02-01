import sys
from Sources import PlatformComposer

# Creates base 4x6 NoC
Setup = PlatformComposer.Platform((4,6), ReferenceClock=ReferenceClock)

# Adds bus containing 4 PEs @ base NoC position (0,5)
BusA = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(0,5))

# Adds bus containing 4 PEs @ base NoC position (1,5)
BusB = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(1,5))

# Adds crossbar containing 4 PEs @ base NoC position (2,5)
CrossbarA = PlatformComposer.Crossbar(4)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(2,5))

# Adds crossbar containing 4 PEs @ base NoC position (3,5)
CrossbarB = PlatformComposer.Crossbar(4)
Setup.addStructure(NewStructure=CrossbarB, WrapperLocationInBaseNoc=(3,5))
