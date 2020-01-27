import AppComposer
import PlatformComposer
#import SetupA

# Entry point
def main():

    # Creates base 2x2 NoC 
    Setup = PlatformComposer.Platform((2,2))

    # Adds bus containing 5 PEs @ base NoC position (1,0)
    BusA = PlatformComposer.Bus(5)
    Setup.addStructure(Structure = BusA, WrapperLocationInBaseNoc = (1,0) )

    # Adds bus containing 5 PEs @ base NoC position (1, 1)
    BusB = PlatformComposer.Bus(5)
    Setup.addStructure(Structure = BusB, WrapperLocationInBaseNoc = (1,1) )

    # Make Application
    PIP = AppComposer.Application(AppID = 0, AppName = "PIP")

    # Make Threads
    InpMemA = AppComposer.Thread(ThreadID = 0)
    HS = AppComposer.Thread(ThreadID = 1)
    VS = AppComposer.Thread(ThreadID = 2)
    JUG1 = AppComposer.Thread(ThreadID = 3)
    InpMemB = AppComposer.Thread(ThreadID = 4)
    JUG2 = AppComposer.Thread(ThreadID = 5)
    MEM = AppComposer.Thread(ThreadID = 6)
    OpDisp = AppComposer.Thread(ThreadID = 7)

    # Add targets to Threads (Bandwidth must be in Megabits/second)
    InpMemA.addTarget(AppComposer.Target(TargetThreadID = HS.ThreadID, TargetName = "HS", Bandwidth = 128))            # InpMemA -- 128 -> HS
    InpMemA.addTarget(AppComposer.Target(TargetThreadID = InpMemB.ThreadID, TargetName = "InpMemB", Bandwidth = 64))   # InpMemA -- 64 -> InpMemB
    HS.addTarget(AppComposer.Target(TargetThreadID = VS.ThreadID, TargetName = "VS", Bandwidth = 64))                  # HS -- 64 -> VS
    VS.addTarget(AppComposer.Target(TargetThreadID = JUG1.ThreadID, TargetName = "JUG1", Bandwidth = 64))              # VS -- 64 -> JUG1
    JUG1.addTarget(AppComposer.Target(TargetThreadID = MEM.ThreadID, TargetName = "MEM", Bandwidth = 64))              # JUG1 -- 64 -> MEM
    InpMemB.addTarget(AppComposer.Target(TargetThreadID = JUG2.ThreadID, TargetName = "JUG2", Bandwidth = 64))         # InpMemB -- 64 -> JUG2
    JUG2.addTarget(AppComposer.Target(TargetThreadID = MEM.ThreadID, TargetName = "MEM", Bandwidth = 64))              # JUG2 -- 64 -> MEM
    MEM.addTarget(AppComposer.Target(TargetThreadID = OpDisp.ThreadID, TargetName = "OpDisp", Bandwidth = 64))         # MEM -- 64 -> OpDisp

    # Add Threads to applications
    PIP.addThread(InpMemA)
    PIP.addThread(HS)
    PIP.addThread(VS)
    PIP.addThread(JUG1)
    PIP.addThread(InpMemB)
    PIP.addThread(JUG2)
    PIP.addThread(MEM)
    PIP.addThread(OpDisp)

    # Link App to Platform
    Setup.addApplication(PIP)

    # Make Allocation Map (Maps AppID and ThreadID to an unique PE)
    AllocationMap = dict()
    AllocationMap[(PIP.AppID, InpMemA.ThreadID)] = 0
    AllocationMap[(PIP.AppID, HS.ThreadID)] = 1
    AllocationMap[(PIP.AppID, VS.ThreadID)] = 2
    AllocationMap[(PIP.AppID, JUG1.ThreadID)] = 3
    AllocationMap[(PIP.AppID, InpMemB.ThreadID)] = 4
    AllocationMap[(PIP.AppID, JUG2.ThreadID)] = 5
    AllocationMap[(PIP.AppID, MEM.ThreadID)] = 6
    AllocationMap[(PIP.AppID, OpDisp.ThreadID)] = 7

    # Link Allocation Map to platform 
    Setup.setAllocationMap(AllocationMap)

    # Makes PE and Injector objects
    Setup.mapToPlatform()

    # Generate project JSON config files
    Setup.generateJSON("PIP/Flow/")

# Forces entry point
if __name__ == "__main__":
    main()

