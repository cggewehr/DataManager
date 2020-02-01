import sys
from Sources import PlatformComposer

# Creates base 5x6 NoC
Setup = PlatformComposer.Platform((5, 6), ReferenceClock=ReferenceClock)

# Adds crossbar containing 8 PEs @ base NoC position (0,5)
CrossbarA = PlatformComposer.Crossbar(8)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(0,5))

# Adds crossbar containing 8 PEs @ base NoC position (1,5)
CrossbarB = PlatformComposer.Crossbar(8)
Setup.addStructure(NewStructure=CrossbarB, WrapperLocationInBaseNoc=(1,5))

# Adds crossbar containing 7 PEs @ base NoC position (2,5)
CrossbarC = PlatformComposer.Crossbar(7)
Setup.addStructure(NewStructure=CrossbarC, WrapperLocationInBaseNoc=(2,5))

# Adds bus containing 3 PEs @ base NoC position (3,5)
BusA = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(3,5))

# Adds bus containing 3 PEs @ base NoC position (4,5)
BusB = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(4,5))

# Adds bus containing 3 PEs @ base NoC position (4,4)
BusC = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusC, WrapperLocationInBaseNoc=(4,4))

# Adds bus containing 3 PEs @ base NoC position (4,3)
BusD = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusD, WrapperLocationInBaseNoc=(4,3))

# Adds bus containing 3 PEs @ base NoC position (4,2)
BusE = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusE, WrapperLocationInBaseNoc=(4,2))

# Adds bus containing 3 PEs @ base NoC position (4,1)
BusF = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusF, WrapperLocationInBaseNoc=(4,1))

# Adds bus containing 3 PEs @ base NoC position (4,0)
BusG = PlatformComposer.Bus(3)
Setup.addStructure(NewStructure=BusG, WrapperLocationInBaseNoc=(4,0))
