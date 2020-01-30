import AppComposer
import PlatformComposer
import sys

# Entry point (Expects clock frequency as $1)
def main():

    # Creates base 2x2 NoC 
    Setup = PlatformComposer.Platform((2,2), int(sys.argv[1]))

    # Adds bus containing 5 PEs @ base NoC position (1,0)
    BusA = PlatformComposer.Bus(3)
    Setup.addStructure(NewStructure = BusA, WrapperLocationInBaseNoc = (1,0))

    # Adds bus containing 5 PEs @ base NoC position (1, 1)
    BusB = PlatformComposer.Bus(4)
    Setup.addStructure(NewStructure = BusB, WrapperLocationInBaseNoc = (1,1))

    # Make Application
    PIP = AppComposer.Application(AppName = "PIP")

    # Make Threads
    InpMemA = AppComposer.Thread()
    HS = AppComposer.Thread()
    VS = AppComposer.Thread()
    JUG1 = AppComposer.Thread()
    InpMemB = AppComposer.Thread()
    JUG2 = AppComposer.Thread()
    MEM = AppComposer.Thread()
    OpDisp = AppComposer.Thread()

    # Add Threads to applications
    PIP.addThread(InpMemA)
    PIP.addThread(HS)
    PIP.addThread(VS)
    PIP.addThread(JUG1)
    PIP.addThread(InpMemB)
    PIP.addThread(JUG2)
    PIP.addThread(MEM)
    PIP.addThread(OpDisp)

    # Add targets to Threads (Bandwidth must be in Megabits/second)
    InpMemA.addTarget(AppComposer.Target(TargetThread = HS, Bandwidth = 128))       # InpMemA -- 128 -> HS
    InpMemA.addTarget(AppComposer.Target(TargetThread = InpMemB, Bandwidth = 64))   # InpMemA -- 64 -> InpMemB
    HS.addTarget(AppComposer.Target(TargetThread = VS, Bandwidth = 64))             # HS -- 64 -> VS
    VS.addTarget(AppComposer.Target(TargetThread = JUG1, Bandwidth = 64))           # VS -- 64 -> JUG1
    JUG1.addTarget(AppComposer.Target(TargetThread = MEM, Bandwidth = 64))          # JUG1 -- 64 -> MEM
    InpMemB.addTarget(AppComposer.Target(TargetThread = JUG2, Bandwidth = 64))      # InpMemB -- 64 -> JUG2
    JUG2.addTarget(AppComposer.Target(TargetThread = MEM, Bandwidth = 64))          # JUG2 -- 64 -> MEM
    MEM.addTarget(AppComposer.Target(TargetThread = OpDisp, Bandwidth = 64))        # MEM -- 64 -> OpDisp

    # Link App to Platform
    Setup.addApplication(PIP)

    # Make Allocation Map (Maps AppID and ThreadID to an unique PE)
    AllocationMap = dict()
    AllocationMap[0] = InpMemA
    AllocationMap[1] = HS
    AllocationMap[2] = VS
    AllocationMap[3] = JUG1
    AllocationMap[4] = InpMemB
    AllocationMap[5] = JUG2
    AllocationMap[6] = MEM
    AllocationMap[7] = OpDisp

    # Link Allocation Map to platform 
    Setup.setAllocationMap(AllocationMap)

    # Makes PE and Injector objects
    Setup.mapToPlatform()

    # Generate project JSON config files
    Setup.generateJSON("PIP/flow/")


# Forces entry point
if __name__ == "__main__":
    main()

