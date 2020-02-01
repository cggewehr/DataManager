from Sources import AppComposer

# Make Application
PIP = AppComposer.Application(AppName = "PIP")
Applications = [PIP]

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

# Add targets to Threads (Bandwidth parameter must be in Megabits/second)
InpMemA.addTarget(AppComposer.Target(TargetThread = HS, Bandwidth = 128))       # InpMemA -- 128 -> HS
InpMemA.addTarget(AppComposer.Target(TargetThread = InpMemB, Bandwidth = 64))   # InpMemA -- 64 -> InpMemB
HS.addTarget(AppComposer.Target(TargetThread = VS, Bandwidth = 64))             # HS -- 64 -> VS
VS.addTarget(AppComposer.Target(TargetThread = JUG1, Bandwidth = 64))           # VS -- 64 -> JUG1
JUG1.addTarget(AppComposer.Target(TargetThread = MEM, Bandwidth = 64))          # JUG1 -- 64 -> MEM
InpMemB.addTarget(AppComposer.Target(TargetThread = JUG2, Bandwidth = 64))      # InpMemB -- 64 -> JUG2
JUG2.addTarget(AppComposer.Target(TargetThread = MEM, Bandwidth = 64))          # JUG2 -- 64 -> MEM
MEM.addTarget(AppComposer.Target(TargetThread = OpDisp, Bandwidth = 64))        # MEM -- 64 -> OpDisp
