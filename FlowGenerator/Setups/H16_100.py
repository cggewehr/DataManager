import sys
from Sources import PlatformComposer

# Creates base 6x6 NoC
Setup = PlatformComposer.Platform((6, 6), ReferenceClock=ReferenceClock)

# Adds bus containing 6 PEs @ base NoC position (0,5)
BusA = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(0,5))

# Adds bus containing 6 PEs @ base NoC position (1,5)
BusB = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(1,5))

# Adds bus containing 6 PEs @ base NoC position (2,5)
BusC = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusC, WrapperLocationInBaseNoc=(2,5))

# Adds bus containing 6 PEs @ base NoC position (3,5)
BusD = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusD, WrapperLocationInBaseNoc=(3,5))

# Adds bus containing 6 PEs @ base NoC position (4,5)
BusE = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusE, WrapperLocationInBaseNoc=(4,5))

# Adds bus containing 6 PEs @ base NoC position (5,5)
BusF = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusF, WrapperLocationInBaseNoc=(5,5))

# Adds bus containing 6 PEs @ base NoC position (5,4)
BusG = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusG, WrapperLocationInBaseNoc=(5,4))

# Adds bus containing 6 PEs @ base NoC position (5,3)
BusH = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusH, WrapperLocationInBaseNoc=(5,3))

# Adds bus containing 6 PEs @ base NoC position (5,2)
BusI = PlatformComposer.Bus(6)
Setup.addStructure(NewStructure=BusI, WrapperLocationInBaseNoc=(5,2))

# Adds crossbar containing 8 PEs @ base NoC position (5,1)
CrossbarA = PlatformComposer.Crossbar(10)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(5,1))

# Adds crossbar containing 8 PEs @ base NoC position (5,0)
CrossbarB = PlatformComposer.Crossbar(11)
Setup.addStructure(NewStructure=CrossbarB, WrapperLocationInBaseNoc=(5,0))
