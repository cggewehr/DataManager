import AppComposer
import PlatformComposer
import sys

# Entry point
def main():

    # Creates base 4x4 NoC 
    Setup = PlatformComposer.Platform((4,4), int(sys.argv[1]))

    # Make Application
    MPEG4 = AppComposer.Application(AppID = 0, AppName = "MPEG4")

    # Make Threads
    VU = AppComposer.Thread(ThreadID = 0)
    AU = AppComposer.Thread(ThreadID = 1)
    MedCPU = AppComposer.Thread(ThreadID = 2)
    RAST = AppComposer.Thread(ThreadID = 3)
    SDRAM = AppComposer.Thread(ThreadID = 4)
    SRAM1 = AppComposer.Thread(ThreadID = 5)
    SRAM2 = AppComposer.Thread(ThreadID = 6)
    IDCT = AppComposer.Thread(ThreadID = 7)
    ADSP = AppComposer.Thread(ThreadID = 8)
    UpSamp = AppComposer.Thread(ThreadID = 9)
    BAB = AppComposer.Thread(ThreadID = 10)
    RISC = AppComposer.Thread(ThreadID = 11)
    
    # Add targets to Threads (Bandwidth must be in Megabits/second)
    VU.addTarget(AppComposer.Target(TargetThreadID = SDRAM.ThreadID, TargetName = "SDRAM", Bandwidth = 190))
    AU.addTarget(AppComposer.Target(TargetThreadID = SDRAM.ThreadID, TargetName = "SDRAM", Bandwidth = 0.5))
    MedCPU.addTarget(AppComposer.Target(TargetThreadID = SDRAM.ThreadID, TargetName = "SDRAM", Bandwidth = 60))
    MedCPU.addTarget(AppComposer.Target(TargetThreadID = SRAM1.ThreadID, TargetName = "SRAM1", Bandwidth = 40))
    RAST.addTarget(AppComposer.Target(TargetThreadID = SDRAM.ThreadID, TargetName = "SDRAM", Bandwidth = 600))
    RAST.addTarget(AppComposer.Target(TargetThreadID = SRAM1.ThreadID, TargetName = "SRAM1", Bandwidth = 40))
    SDRAM.addTarget(AppComposer.Target(TargetThreadID = VU.ThreadID, TargetName = "VU", Bandwidth = 190))
    SDRAM.addTarget(AppComposer.Target(TargetThreadID = AU.ThreadID, TargetName = "AU", Bandwidth = 0.5))
    SDRAM.addTarget(AppComposer.Target(TargetThreadID = MedCPU.ThreadID, TargetName = "MedCPU", Bandwidth = 60))
    SDRAM.addTarget(AppComposer.Target(TargetThreadID = RAST.ThreadID, TargetName = "RAST", Bandwidth = 600))
    SDRAM.addTarget(AppComposer.Target(TargetThreadID = ADSP.ThreadID, TargetName = "ADSP", Bandwidth = 0.5))
    SDRAM.addTarget(AppComposer.Target(TargetThreadID = UpSamp.ThreadID, TargetName = "UpSamp", Bandwidth = 910))
    SDRAM.addTarget(AppComposer.Target(TargetThreadID = BAB.ThreadID, TargetName = "BAB", Bandwidth = 32))
    SRAM1.addTarget(AppComposer.Target(TargetThreadID = MedCPU.ThreadID, TargetName = "MedCPU", Bandwidth = 40))
    SRAM1.addTarget(AppComposer.Target(TargetThreadID = RAST.ThreadID, TargetName = "RAST", Bandwidth = 40))
    SRAM2.addTarget(AppComposer.Target(TargetThreadID = IDCT.ThreadID, TargetName = "IDCT", Bandwidth = 250))
    SRAM2.addTarget(AppComposer.Target(TargetThreadID = UpSamp.ThreadID, TargetName = "UpSamp", Bandwidth = 670))
    SRAM2.addTarget(AppComposer.Target(TargetThreadID = BAB.ThreadID, TargetName = "BAB", Bandwidth = 173))
    SRAM2.addTarget(AppComposer.Target(TargetThreadID = RISC.ThreadID, TargetName = "RISC", Bandwidth = 500))
    IDCT.addTarget(AppComposer.Target(TargetThreadID = SRAM2.ThreadID, TargetName = "SRAM2", Bandwidth = 250))
    ADSP.addTarget(AppComposer.Target(TargetThreadID = SDRAM.ThreadID, TargetName = "SDRAM", Bandwidth = 0.5))
    UpSamp.addTarget(AppComposer.Target(TargetThreadID = SDRAM.ThreadID, TargetName = "SDRAM", Bandwidth = 910))
    UpSamp.addTarget(AppComposer.Target(TargetThreadID = SRAM2.ThreadID, TargetName = "SRAM2", Bandwidth = 670))
    BAB.addTarget(AppComposer.Target(TargetThreadID = SDRAM.ThreadID, TargetName = "SDRAM", Bandwidth = 32))
    BAB.addTarget(AppComposer.Target(TargetThreadID = SRAM2.ThreadID, TargetName = "SRAM2", Bandwidth = 173))
    RISC.addTarget(AppComposer.Target(TargetThreadID = SRAM2.ThreadID, TargetName = "SRAM2", Bandwidth = 500))

    # Add Threads to applications
    MPEG4.addThread(VU)
    MPEG4.addThread(AU)
    MPEG4.addThread(MedCPU)
    MPEG4.addThread(RAST)
    MPEG4.addThread(SDRAM)
    MPEG4.addThread(SRAM1)
    MPEG4.addThread(SRAM2)
    MPEG4.addThread(IDCT)
    MPEG4.addThread(ADSP)
    MPEG4.addThread(UpSamp)
    MPEG4.addThread(BAB)
    MPEG4.addThread(RISC)

    # Link App to Platform
    Setup.addApplication(MPEG4)

    # Make Allocation Map (Maps AppID and ThreadID to an unique PE)
    AllocationMap = dict()
    AllocationMap[(MPEG4.AppID, VU.ThreadID)] = 0
    AllocationMap[(MPEG4.AppID, AU.ThreadID)] = 1
    AllocationMap[(MPEG4.AppID, MedCPU.ThreadID)] = 2
    AllocationMap[(MPEG4.AppID, RAST.ThreadID)] = 3
    AllocationMap[(MPEG4.AppID, SDRAM.ThreadID)] = 4
    AllocationMap[(MPEG4.AppID, SRAM1.ThreadID)] = 5
    AllocationMap[(MPEG4.AppID, SRAM2.ThreadID)] = 6
    AllocationMap[(MPEG4.AppID, IDCT.ThreadID)] = 7
    AllocationMap[(MPEG4.AppID, ADSP.ThreadID)] = 8
    AllocationMap[(MPEG4.AppID, UpSamp.ThreadID)] = 9
    AllocationMap[(MPEG4.AppID, BAB.ThreadID)] = 10
    AllocationMap[(MPEG4.AppID, RISC.ThreadID)] = 11

    # Link Allocation Map to platform 
    Setup.setAllocationMap(AllocationMap)

    # Makes PE and Injector objects
    Setup.mapToPlatform()

    # Generate project JSON config files
    Setup.generateJSON("MPEG4/flow/")

# Forces entry point
if __name__ == "__main__":
    main()

