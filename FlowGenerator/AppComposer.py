class Application:

    def __init__(self, AppName):
        self.Threads = []
        self.AppID = None
        self.AppName = AppName
        self.ParentPlatform = None


    def addThread(self, Thread):
        # Generates
        Thread.ThreadID = len(self.Threads)
        Thread.ParentApplication = self
        self.Threads.append(Thread)


    def __str__(self):
        pass


class Thread:

    def __init__(self):

        self.Targets = []
        self.ThreadID = None
        self.ParentApplication = None
        self.TotalBandwidth = 0


    def addTarget(self, Target):

        self.Targets.append(Target)
        self.TotalBandwidth += Target.Bandwidth
        Target.SourceThread = self


    def __str__(self):

        pass


class Target:

    def __init__(self, TargetThread, Bandwidth):

        self.TargetThread = TargetThread
        self.SourceThread = None
        self.Bandwidth = Bandwidth


    def __str__(self):
        pass
