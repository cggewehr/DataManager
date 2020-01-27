import json
import random
import AppComposer


class Platform:

    # Constructor
    def __init__(self, BaseNoCDimensions: tuple):

        self.AllocationMap = dict()
        self.Applications = []
        self.BaseNoC = [[None for x in range(BaseNoCDimensions[0])] for y in range(BaseNoCDimensions[1])]
        self.PEs = dict()
        self.Injectors = dict()
        self.WrapperAddresses = dict()
        self.AmountOfPEs = BaseNoCDimensions[0] * BaseNoCDimensions[1]

    # Adds structure (Bus or Crossbar) to base NoC
    def addStructure(self, Structure, WrapperLocationInBaseNoc: tuple):

        # Checks for a present wrapper at given location in base NoC
        if self.BaseNoC[WrapperLocationInBaseNoc[0]][WrapperLocationInBaseNoc[1]] == None:

            # Inserts given structure into base NoC
            self.AmountOfPEs += Structure.AmountOfPEs - 1  # Adds PEs from new structure and remove a PE from base NoC to make room for a wrapper
            self.BaseNoC[WrapperLocationInBaseNoc[0]][WrapperLocationInBaseNoc[1]] = Structure

        else:

            print("Error: There already is a wrapper at given location " + str(WrapperLocationInBaseNoc) + " \n")
            exit(1)

    # TODO: Set addresses in PEAddresses arrays inside every Structure object
    def setPEAddresses(self):

        pass

    # Adds an application (containing various Thread objects) to platform
    def addApplication(self, Application):

        self.Applications.append(Application)
        Application.ParentPlatform = self

    # Sets allocation map (Maps AppID and ThreadID to an unique PE)
    def setAllocationMap(self, AllocationMap):

        self.AllocationMap = AllocationMap

    # Sets PEPos values according to Allocation Map
    def mapToPlatform(self):

        for i in range(len(self.Applications)):

            for j in range(len(self.Applications[i].Threads)):

                # Generates PE and Injector objects and and populates
                PEPos = self.AllocationMap[(self.Applications[i].AppID, self.Applications[i].Threads[j].ThreadID)]

                if PEPos >= self.AmountOfPEs:
                    print("Warning: Found PEPos value higher than total amount of PEs\n")

                self.PEs[PEPos] = PE(PEPos=PEPos, AppID=self.Applications[i].AppID,
                                     ThreadID=self.Applications[i].Threads[j].ThreadID)
                self.Injectors[PEPos] = Injector(Thread=self.Applications[i].Threads[j])

    # Generate JSON config files for PEs, Injectors and Platform
    def generateJSON(self):

        for i in range(self.AmountOfPEs - 1):

            # Write Injector JSON config file
            f = open("InjectorConfig" + str(i) + ".json", 'w')
            f.write(self.Injectors[i].toJSON())
            f.close()

            # Write PE JSON config file
            f = open("PEConfig" + str(i) + ".json", 'w')
            f.write(self.PEs[i].toJSON())
            f.close()

    # TODO: Write Platform config file


class Structure:

    def __init__(self, StructureType, AmountOfPEs):
        self.StructureType = StructureType
        self.AmountOfPEs = AmountOfPEs
        self.PEAddresses = [None for i in range(AmountOfPEs)]

        def setPE(self, PENumber, PEObject):
            self.PEAddresses[PENumber] = PEObject

        def setPEs(self, PEsArray):
            self.PEAddresses = PEsArray

            if len(self.PEAddresses) != len(PEsArray):
                print("Warning: Given array has unexpected length\n")


class Bus(Structure):

    def __init__(self, AmountOfPEs):
        Structure.__init__(self, StructureType="Bus", AmountOfPEs=AmountOfPEs)


class Crossbar(Structure):

    def __init__(self, AmountOfPEs):
        Structure.__init__(self, StructureType="Crossbar", AmountOfPEs=AmountOfPEs)


class PE:

    def __init__(self, PEPos, AppID, ThreadID):
        self.CommStructure: "NOC"  # Default
        self.InjectorType: "FXD"  # Default
        self.InjectorClockPeriod = 2  # In ns, corresponds to 500 MHz frequency
        self.InBufferSize = 128  # Default
        self.OutBufferSize = 128  # Default
        self.PEPos = PEPos
        self.AppID = AppID
        self.ThreadID = ThreadID
        self.AverageProcessingTimeInClockPulses = 1  # Default

    def toJSON(self):
        return json.dumps(self.__dict__, sort_keys=True, indent=4)


class Injector:

    def __init__(self, Thread):

        # Gets position value from AllocationTable dictionary
        self.PEPos = Thread.ParentApplication.ParentPlatform.AllocationMap[(Thread.ParentApplication.AppID, Thread.ThreadID)]

        self.AppID = Thread.ParentApplication.AppID
        self.ThreadID = Thread.ThreadID

        # LinkBandwidth = DataWidth * ClockFrequency (Assuming 500 MHz -> 2 ns period)
        # Consumed Bandwidth = LinkBandwidth * InjectionRate
        # InjectionRate = (ConsumedBandwidth)/(DataWidth * ClockFrequency)
        self.InjectionRate = (Thread.TotalBandwidth * 1_000_000) / (32 * 500_000_000)

        self.TargetPEs = []
        self.AmountOfMessagesInBurst = []

        # Determines TargetPEs and AmountOfMessagesInBurst arrays based on required bandwidth
        for i in range(len(Thread.Targets)):
            self.TargetPEs.append(Thread.ParentApplication.ParentPlatform.AllocationMap[(Thread.ParentApplication.AppID, Thread.Targets[i].TargetThreadID)])
            self.AmountOfMessagesInBurst.append(Thread.Targets[i].Bandwidth)

        self.TargetPayloadSize = [126] * len(self.TargetPEs)

        #self.__init__(PEPos, AppID, ThreadID, InjectionRate, TargetPEs, TargetPayloadSize, AmountOfMessagesInBurst)

    #def __init__(self, PEPos, AppID, ThreadID, InjectionRate, TargetPEs, TargetPayloadSize, AmountOfMessagesInBurst):

        #self.PEPos = PEPos
        #self.AppID = AppID
        #self.ThreadID = ThreadID
        #self.InjectionRate = InjectionRate
        self.SourcePEs = [0]  # Default
        self.SourcePayloadSize = 32  # Default
        #self.TargetPEs = TargetPEs
        #self.TargetPayloadSize = TargetPayloadSize
        #self.AmountOfMessagesInBurst = AmountOfMessagesInBurst
        self.AmountOfSourcePEs = len(self.SourcePEs)
        self.AmountOfTargetPEs = len(self.TargetPEs)
        self.AverageProcessingTimeInClockPulses = 1  # Default
        self.InjectorType = "FXD"  # Default
        self.FlowType = "RND"  # Default
        self.HeaderSize = "2"  # Default
        self.AmountOfMessagesInBurst = 1  # Default
        self.timestampFlag = 1984626850  # Default
        self.amountOfMessagesSentFlag = 2101596287  # Default
        self.RNGSeed1 = random.randint(0, 2147483646)  # Random Value
        self.RNGSeed2 = random.randint(0, 2147483646)  # Random Value

        self.Headers = dict()
        self.Payload = dict()

        for i in range(len(self.TargetPEs)):

            payload_aux = [  # Default
                "PEPOS",
                "TMSTP",
                "RANDO",
                "RANDO",
                "RANDO",
                "RANDO",
            ]

            for j in range(int(self.TargetPayloadSize[i]) - 6):
                payload_aux.append("RANDO")  # Preenche com RANDO #Default

            self.Headers["Header" + str(self.TargetPEs[i])] = ["ADDR", "SIZE"]  # Default
            self.Payload["Payload" + str(self.TargetPEs[i])] = payload_aux

    def toJSON(self):

        return json.dumps(self.__dict__, sort_keys=True, indent=4)

    def __str__(self):

        pass
