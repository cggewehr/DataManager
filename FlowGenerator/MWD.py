import AppComposer
import PlatformComposer
import sys

# Entry point
def main():

    # Creates base 4x4 NoC 
    Setup = PlatformComposer.Platform((4,4), int(sys.argv[1]))

    # Make Application
    MWD = AppComposer.Application(AppID = 0, AppName = "MWD")

    # Make Threads
    IN = AppComposer.Thread(ThreadID = 0)
    NR = AppComposer.Thread(ThreadID = 1)
    MEM1 = AppComposer.Thread(ThreadID = 2)
    VS = AppComposer.Thread(ThreadID = 3)
    HS = AppComposer.Thread(ThreadID = 4)
    MEM2 = AppComposer.Thread(ThreadID = 5)
    HVS = AppComposer.Thread(ThreadID = 6)
    JUG1 = AppComposer.Thread(ThreadID = 7)
    MEM3 = AppComposer.Thread(ThreadID = 8)
    JUG2 = AppComposer.Thread(ThreadID = 9)
    SE = AppComposer.Thread(ThreadID = 10)
    Blend = AppComposer.Thread(ThreadID = 11)

    # Add targets to Threads (Bandwidth must be in Megabits/second)
    IN.addTarget(AppComposer.Target(TargetThreadID = NR.ThreadID, TargetName = "NR", Bandwidth = 64))
    IN.addTarget(AppComposer.Target(TargetThreadID = HS.ThreadID, TargetName = "HS", Bandwidth = 128))
    NR.addTarget(AppComposer.Target(TargetThreadID = MEM1.ThreadID, TargetName = "MEM1", Bandwidth = 64))
    NR.addTarget(AppComposer.Target(TargetThreadID = MEM2.ThreadID, TargetName = "MEM2", Bandwidth = 96))
    MEM1.addTarget(AppComposer.Target(TargetThreadID = NR.ThreadID, TargetName = "NR", Bandwidth = 64))
    HS.addTarget(AppComposer.Target(TargetThreadID = VS.ThreadID, TargetName = "VS", Bandwidth = 96))
    VS.addTarget(AppComposer.Target(TargetThreadID = JUG1.ThreadID, TargetName = "JUG1", Bandwidth = 96))
    MEM2.addTarget(AppComposer.Target(TargetThreadID = HVS.ThreadID, TargetName = "HVS", Bandwidth = 96))
    HVS.addTarget(AppComposer.Target(TargetThreadID = JUG2.ThreadID, TargetName = "JUG2", Bandwidth = 96))
    JUG1.addTarget(AppComposer.Target(TargetThreadID = MEM3.ThreadID, TargetName = "MEM3", Bandwidth = 96))
    MEM3.addTarget(AppComposer.Target(TargetThreadID = SE.ThreadID, TargetName = "SE", Bandwidth = 64))
    JUG2.addTarget(AppComposer.Target(TargetThreadID = MEM3.ThreadID, TargetName = "MEM3", Bandwidth = 96))
    SE.addTarget(AppComposer.Target(TargetThreadID = Blend.ThreadID, TargetName = "Blend", Bandwidth = 16))

    # Add Threads to applications
    MWD.addThread(IN)
    MWD.addThread(NR)
    MWD.addThread(MEM1)
    MWD.addThread(VS)
    MWD.addThread(HS)
    MWD.addThread(MEM2)
    MWD.addThread(HVS)
    MWD.addThread(JUG1)
    MWD.addThread(MEM3)
    MWD.addThread(JUG2)
    MWD.addThread(SE)
    MWD.addThread(Blend)

    # Link App to Platform
    Setup.addApplication(MWD)

    # Make Allocation Map (Maps AppID and ThreadID to an unique PE)
    AllocationMap = dict()
    AllocationMap[(MWD.AppID, IN.ThreadID)] = 0
    AllocationMap[(MWD.AppID, NR.ThreadID)] = 1
    AllocationMap[(MWD.AppID, MEM1.ThreadID)] = 2
    AllocationMap[(MWD.AppID, VS.ThreadID)] = 3
    AllocationMap[(MWD.AppID, HS.ThreadID)] = 4
    AllocationMap[(MWD.AppID, MEM2.ThreadID)] = 5
    AllocationMap[(MWD.AppID, HVS.ThreadID)] = 6
    AllocationMap[(MWD.AppID, JUG1.ThreadID)] = 7
    AllocationMap[(MWD.AppID, MEM3.ThreadID)] = 8
    AllocationMap[(MWD.AppID, JUG2.ThreadID)] = 9
    AllocationMap[(MWD.AppID, SE.ThreadID)] = 10
    AllocationMap[(MWD.AppID, Blend.ThreadID)] = 11

    # Link Allocation Map to platform 
    Setup.setAllocationMap(AllocationMap)

    # Makes PE and Injector objects
    Setup.mapToPlatform()

    # Generate project JSON config files
    Setup.generateJSON("MWD/flow/")

# Forces entry point
if __name__ == "__main__":
    main()

