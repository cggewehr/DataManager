import AppComposer
import PlatformComposer
import sys

# Entry point
def main():

    # Creates base 4x4 NoC 
    Setup = PlatformComposer.Platform((4,4), int(sys.argv[1]))

    # Make Application
    VOPD = AppComposer.Application(AppID = 0, AppName = "VOPD")

    # Make Threads
    VLD = AppComposer.Thread(ThreadID = 0)
    RunLeDec = AppComposer.Thread(ThreadID = 1)
    InvScan = AppComposer.Thread(ThreadID = 2)
    AcdcPred = AppComposer.Thread(ThreadID = 3)
    Iquan = AppComposer.Thread(ThreadID = 4)
    IDCT = AppComposer.Thread(ThreadID = 5)
    ARM = AppComposer.Thread(ThreadID = 6)
    UpSamp = AppComposer.Thread(ThreadID = 7)
    VopRec = AppComposer.Thread(ThreadID = 8)
    Pad = AppComposer.Thread(ThreadID = 9)
    VopMem = AppComposer.Thread(ThreadID = 10)
    StripeMem = AppComposer.Thread(ThreadID = 11)

    # Add targets to Threads (Bandwidth must be in Megabits/second)
    VLD.addTarget(AppComposer.Target(TargetThreadID = RunLeDec.ThreadID, TargetName = "RunLeDec", Bandwidth = 70))
    RunLeDec.addTarget(AppComposer.Target(TargetThreadID = InvScan.ThreadID, TargetName = "InvScan", Bandwidth = 362))
    InvScan.addTarget(AppComposer.Target(TargetThreadID = AcdcPred.ThreadID, TargetName = "AcdcPred", Bandwidth = 362))
    AcdcPred.addTarget(AppComposer.Target(TargetThreadID = Iquan.ThreadID, TargetName = "Iquan", Bandwidth = 362))
    AcdcPred.addTarget(AppComposer.Target(TargetThreadID = StripeMem.ThreadID, TargetName = "StripeMem", Bandwidth = 49))
    StripeMem.addTarget(AppComposer.Target(TargetThreadID = Iquan.ThreadID, TargetName = "Iquan", Bandwidth = 27))
    Iquan.addTarget(AppComposer.Target(TargetThreadID = IDCT.ThreadID, TargetName = "IDCT", Bandwidth = 357))
    IDCT.addTarget(AppComposer.Target(TargetThreadID = UpSamp.ThreadID, TargetName = "UpSamp", Bandwidth = 353))
    ARM.addTarget(AppComposer.Target(TargetThreadID = IDCT.ThreadID, TargetName = "IDCT", Bandwidth = 16))
    ARM.addTarget(AppComposer.Target(TargetThreadID = Pad.ThreadID, TargetName = "Pad", Bandwidth = 16))
    UpSamp.addTarget(AppComposer.Target(TargetThreadID = VopRec.ThreadID, TargetName = "VopRec", Bandwidth = 300))
    VopRec.addTarget(AppComposer.Target(TargetThreadID = Pad.ThreadID, TargetName = "Pad", Bandwidth = 313))
    Pad.addTarget(AppComposer.Target(TargetThreadID = VopMem.ThreadID, TargetName = "VopMem", Bandwidth = 313))
    VopMem.addTarget(AppComposer.Target(TargetThreadID = Pad.ThreadID, TargetName = "Pad", Bandwidth = 94))

    # Add Threads to applications
    VOPD.addThread(VLD)
    VOPD.addThread(RunLeDec)
    VOPD.addThread(InvScan)
    VOPD.addThread(AcdcPred)
    VOPD.addThread(Iquan)
    VOPD.addThread(IDCT)
    VOPD.addThread(ARM)
    VOPD.addThread(UpSamp)
    VOPD.addThread(VopRec)
    VOPD.addThread(Pad)
    VOPD.addThread(VopMem)
    VOPD.addThread(StripeMem)

    # Link App to Platform
    Setup.addApplication(VOPD)

    # Make Allocation Map (Maps AppID and ThreadID to an unique PE)
    AllocationMap = dict()
    AllocationMap[(VOPD.AppID, VLD.ThreadID)] = 0
    AllocationMap[(VOPD.AppID, RunLeDec.ThreadID)] = 1
    AllocationMap[(VOPD.AppID, InvScan.ThreadID)] = 2
    AllocationMap[(VOPD.AppID, AcdcPred.ThreadID)] = 3
    AllocationMap[(VOPD.AppID, Iquan.ThreadID)] = 4
    AllocationMap[(VOPD.AppID, IDCT.ThreadID)] = 5
    AllocationMap[(VOPD.AppID, ARM.ThreadID)] = 6
    AllocationMap[(VOPD.AppID, UpSamp.ThreadID)] = 7
    AllocationMap[(VOPD.AppID, VopRec.ThreadID)] = 8
    AllocationMap[(VOPD.AppID, Pad.ThreadID)] = 9
    AllocationMap[(VOPD.AppID, VopMem.ThreadID)] = 10
    AllocationMap[(VOPD.AppID, StripeMem.ThreadID)] = 11

    # Link Allocation Map to platform 
    Setup.setAllocationMap(AllocationMap)

    # Makes PE and Injector objects
    Setup.mapToPlatform()

    # Generate project JSON config files
    Setup.generateJSON("VOPD/flow/")

# Forces entry point
if __name__ == "__main__":
    main()

