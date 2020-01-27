class Application:

    def __init__(self, AppID, AppName):
        self.Threads = []
        self.AppID = AppID
        self.AppName = AppName
        self.ParentPlatform = None

    def addThread(self, Thread):
        # Generates
        self.Threads.append(Thread)
        Thread.ParentApplication = self

    def __str__(self):
        pass


class Thread:

    def __init__(self, ThreadID):
        self.Targets = []
        self.ThreadID = ThreadID
        self.TotalBandwidth = 0

    def addTarget(self, Target):
        self.Targets.append(Target)
        self.TotalBandwidth += Target.Bandwidth

    def __str__(self):
        pass


class Target:

    def __init__(self, TargetThreadID, TargetName, Bandwidth):
        self.TargetThreadID = TargetThreadID
        self.TargetName = TargetName
        self.Bandwidth = Bandwidth

    def __str__(self):
        pass
