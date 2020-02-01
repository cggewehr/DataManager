import sys
from Sources import PlatformComposer

# Creates base 6x6 NoC
Setup = PlatformComposer.Platform((6,6), ReferenceClock=ReferenceClock)

# Adds crossbar containing 9 PEs @ base NoC position (5,5)
CrossbarA = PlatformComposer.Crossbar(9)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(5,5))

# Adds bus containing 4 PEs @ base NoC position (5,4)
BusA = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(5,4))

# Adds bus containing 4 PEs @ base NoC position (5,3)
BusB = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(5,3))

# Adds bus containing 4 PEs @ base NoC position (5,2)
BusC = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusC, WrapperLocationInBaseNoc=(5,2))

# Adds bus containing 4 PEs @ base NoC position (5,1)
BusD = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusD, WrapperLocationInBaseNoc=(5,1))

# Adds crossbar containing 9 PEs @ base NoC position (5,0)
CrossbarB = PlatformComposer.Crossbar(9)
Setup.addStructure(NewStructure=CrossbarB, WrapperLocationInBaseNoc=(5,0))
