import sys
from Sources import PlatformComposer

# Creates base 6x6 NoC
Setup = PlatformComposer.Platform((6,6), ReferenceClock=ReferenceClock)

# Adds crossbar containing 11 PEs @ base NoC position (0,5)
CrossbarA = PlatformComposer.Crossbar(9)
Setup.addStructure(NewStructure=CrossbarA, WrapperLocationInBaseNoc=(0,5))

# Adds crossbar containing 11 PEs @ base NoC position (1,5)
CrossbarB = PlatformComposer.Crossbar(11)
Setup.addStructure(NewStructure=CrossbarB, WrapperLocationInBaseNoc=(1,5))

# Adds crossbar containing 11 PEs @ base NoC position (2,5)
CrossbarC = PlatformComposer.Crossbar(11)
Setup.addStructure(NewStructure=CrossbarC, WrapperLocationInBaseNoc=(2,5))

# Adds crossbar containing 11 PEs @ base NoC position (3,5)
CrossbarD = PlatformComposer.Crossbar(11)
Setup.addStructure(NewStructure=CrossbarD, WrapperLocationInBaseNoc=(3,5))

# Adds bus containing 4 PEs @ base NoC position (4,5)
BusA = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusA, WrapperLocationInBaseNoc=(4,5))

# Adds bus containing 4 PEs @ base NoC position (4,4)
BusB = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusB, WrapperLocationInBaseNoc=(4,4))

# Adds bus containing 4 PEs @ base NoC position (5,5)
BusC = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusC, WrapperLocationInBaseNoc=(5,5))

# Adds bus containing 4 PEs @ base NoC position (5,4)
BusD = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusD, WrapperLocationInBaseNoc=(5,4))

# Adds bus containing 4 PEs @ base NoC position (5,3)
BusE = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusE, WrapperLocationInBaseNoc=(5,3))

# Adds bus containing 4 PEs @ base NoC position (5,2)
BusF = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusF, WrapperLocationInBaseNoc=(5,2))

# Adds bus containing 4 PEs @ base NoC position (5,1)
BusG = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusG, WrapperLocationInBaseNoc=(5,1))

# Adds bus containing 4 PEs @ base NoC position (5,0)
BusH = PlatformComposer.Bus(4)
Setup.addStructure(NewStructure=BusH, WrapperLocationInBaseNoc=(5,0))
