import json
import random
import os
import math
import copy
import sys
from . import AppComposer


class Platform:

    # Constructor
    def __init__(self, BaseNoCDimensions, ReferenceClock):

        self.AllocationMap = dict()
        self.Applications = []
        self.BaseNoCDimensions = BaseNoCDimensions
        self.BaseNoC = [[None for x in range(BaseNoCDimensions[0])] for y in range(BaseNoCDimensions[1])]
        self.PEs = dict()
        self.Injectors = dict()
        self.WrapperAddresses = dict()  # Maps a PEPos value to its wrapper's address in base NoC
        self.AmountOfPEs = BaseNoCDimensions[0] * BaseNoCDimensions[1]
        self.AmountOfWrappers = 0
        self.AmountOfBuses = 0
        self.AmountOfPEsInBuses = []
        self.Buses = []
        self.AmountOfCrossbars = 0
        self.AmountOfPEsInCrossbars = []
        self.Crossbars = []
        self.NUMBER_PROCESSORS_X = self.BaseNoCDimensions[0]
        self.NUMBER_PROCESSORS_Y = self.BaseNoCDimensions[1]
        self.ReferenceClock = ReferenceClock  # In MHz

        # Generate initial PE objects at every NoC address (to be replaced by a wrapper when a structure is added)
        i = 0
        for y in range(BaseNoCDimensions[1]):

            for x in range(BaseNoCDimensions[0]):

                self.BaseNoC[x][y] = PE(PEPos=i, AppID=None, ThreadID=None, InjectorClockPeriod=self.ReferenceClock)
                self.PEs[i] = self.BaseNoC[x][y]

                i += 1


    # Adds structure (Bus or Crossbar) to base NoC
    def addStructure(self, NewStructure, WrapperLocationInBaseNoc: tuple):

        # Checks for a present wrapper at given location in base NoC
        if isinstance(self.BaseNoC[WrapperLocationInBaseNoc[0]][WrapperLocationInBaseNoc[1]], Structure):

            # There already is a wrapper at this position in base NoC
            print("Error: There already is a wrapper at given location " + str(WrapperLocationInBaseNoc) + " \n")
            exit(1)

        else:

            # Inserts given structure into base NoC
            self.AmountOfPEs += len(NewStructure.PEs) - 1  # Adds PEs from new structure and remove a PE from base NoC to make room for a wrapper
            self.AmountOfWrappers += 1

            if NewStructure.StructureType == "Bus":

                self.AmountOfBuses += 1
                self.AmountOfPEsInBuses.append(len(NewStructure.PEs))
                self.Buses.append(NewStructure)


            elif NewStructure.StructureType == "Crossbar":

                self.AmountOfCrossbars += 1
                self.AmountOfPEsInCrossbars.append(len(NewStructure.PEs))
                self.Crossbars.append(NewStructure)

            self.BaseNoC[WrapperLocationInBaseNoc[0]][WrapperLocationInBaseNoc[1]] = NewStructure

            NewStructure.AddressInBaseNoC = (WrapperLocationInBaseNoc[1] * self.BaseNoCDimensions[0]) + WrapperLocationInBaseNoc[0]

            # Updates all PEPos values (platform-wide)
            self.updatePEAddresses()


    # Sets PEPos values according to the square NoC algorithm
    def updatePEAddresses(self):

        SquareNoCBound = math.ceil(math.sqrt(self.AmountOfPEs))

        # Set NoC 1st of wrapper PE addresses
        x_base = 0
        y_base = 0
        x_square = 0
        y_square = 0
        for i in range(self.BaseNoCDimensions[0]*self.BaseNoCDimensions[1]):  # Loops through base NoC

            # Unique network ID based on square NoC algorithm
            #PEPos = (y_square * SquareNoCBound) + x_square
            PEPos = (y_base * SquareNoCBound) + x_base  # TODO
            #print(str(PEPos) + " (" + str(x_base) + "," + str(y_base) + ") (" + str(x_square) + "," + str(y_square) + ")")
            self.WrapperAddresses[PEPos] = (y_base * self.BaseNoCDimensions[0]) + x_base

            # If current base NoC position is a PE (not a wrapper), set its address
            if isinstance(self.BaseNoC[x_base][y_base], PE):

                self.BaseNoC[x_base][y_base].PEPos = PEPos
                self.PEs[PEPos] = self.BaseNoC[x_base][y_base]

            # If current base NoC position is a wrapper, sets address for the first element of its corresponding structure
            elif isinstance(self.BaseNoC[x_base][y_base], Structure):

                self.BaseNoC[x_base][y_base].PEs[0].PEPos = PEPos
                self.PEs[PEPos] = self.BaseNoC[x_base][y_base].PEs[0]

            # Increment base NoC x & y indexes
            if x_base == self.BaseNoCDimensions[0] - 1:

                x_base = 0
                y_base += 1

            else:

                x_base += 1

            # Increment square NoC x & y indexes
            if x_square == SquareNoCBound:

                x_square = 0
                y_square += 1

            else:

                x_square += 1

        # Set Remaining PEs on wrapper
        x_base = 0
        y_base = 0
        x_square = 0
        y_square = self.BaseNoCDimensions[1]
        x_square_limit = self.BaseNoCDimensions[0]
        y_square_limit = self.BaseNoCDimensions[1]
        for i in range(self.BaseNoCDimensions[0]*self.BaseNoCDimensions[1]):  # Loops through base NoC

            # If current base NoC position is a wrapper, sets address for all the elements contained in its corresponding structure, except the first
            if isinstance(self.BaseNoC[x_base][y_base], Structure):

                for j in range(len(self.BaseNoC[x_base][y_base].PEs) - 1):

                    # Update PEPos vale at current PE object
                    PEPos = (y_square * SquareNoCBound) + x_square  # TODO
                    #PEPos = (y_base * SquareNoCBound) + x_base  # TODO
                    #print(str(PEPos) + " (" + str(x_base) + "," + str(y_base) + ") (" + str(x_square) + "," + str(y_square) + ")")
                    self.BaseNoC[x_base][y_base].PEs[j + 1].PEPos = PEPos
                    self.WrapperAddresses[PEPos] = (y_base * self.BaseNoCDimensions[0]) + x_base

                    # Updates reference to current PE object at master PE dictionary
                    self.PEs[PEPos] = self.BaseNoC[x_base][y_base].PEs[j + 1]

                    # Increment square NoC x & y indexes
                    if x_square == x_square_limit and y_square == 0:

                        x_square = 0
                        x_square_limit += 1
                        y_square_limit += 1
                        y_square = y_square_limit

                    else:

                        if x_square < x_square_limit:

                            x_square += 1

                        elif y_square > 0:

                            y_square -= 1

            # Increment base NoC x & y indexes
            if x_base == self.BaseNoCDimensions[0] - 1:

                x_base = 0
                y_base += 1

            else:

                x_base += 1


    # Find matching PE address (PEPos) for a given Thread object
    def getPEPos(self, Thread):

        for i in range(self.AmountOfPEs):

            if self.AllocationMap[i].ParentApplication.AppID == Thread.ParentApplication.AppID and self.AllocationMap[i].ThreadID == Thread.ThreadID:

                return i

        print("Warning: No mathcing PE found for given thread")

    # Adds an application (containing various Thread objects) to platform
    def addApplication(self, Application):

        Application.AppID = len(self.Applications)
        Application.ParentPlatform = self
        self.Applications.append(Application)


    # Sets allocation map (Maps AppID and ThreadID to an unique PE)
    def setAllocationMap(self, AllocationMap):

        self.AllocationMap = AllocationMap


    # Updates PE objects with application and thread info
    def mapToPlatform(self):

        for i in range(len(self.PEs)):

            if i in self.AllocationMap:

                # Updates PE objects and creates Injector objects
                Thread = self.AllocationMap[i]
                self.PEs[i].AppID = Thread.ParentApplication.AppID
                self.PEs[i].ThreadID = Thread.ThreadID
                self.Injectors[i] = Injector(PEPos=self.PEs[i].PEPos, Thread=Thread, InjectorClockPeriod=self.ReferenceClock)

            else:  # No thread allocated at current address, create dummy PE and Injector objects

                # Creates dummy PE and Injector objects
                self.PEs[i].AppID = 99
                self.PEs[i].ThreadID = 99
                self.Injectors[i] = Injector(PEPos=self.PEs[i].PEPos, Thread=AppComposer.Thread(), InjectorClockPeriod=99)


    # Generate JSON config files for PEs, Injectors and Platform
    def generateJSON(self, Path):

        for i in range(self.AmountOfPEs):

            # Creates directory if it doesn't exist
            if not os.path.exists(Path):
                os.makedirs(Path)

            # Write Injector JSON config file
            if i in self.Injectors:

                f = open(Path + "INJ" + str(i) + ".json", 'w')
                f.write(self.Injectors[i].toJSON())
                f.close()

            # Write PE JSON config file
            if i in self.PEs:

                f = open(Path + "PE" + str(i) + ".json", 'w')
                f.write(self.PEs[i].toJSON())
                f.close()

        # TODO: Write Platform config file
        f = open(Path + "PlatformConfig.json", 'w')
        f.write(self.toJSON())
        f.close()


    def toJSON(self):

        return json.dumps(self.toDict(), sort_keys=True, indent=4)


    def __str__(self):

        pass


#   Returns dictionary of object with serializeable attributes (for JSON generation)
    def toDict(self):

        SerializableObject = copy.deepcopy(self)

        del SerializableObject.PEs
        del SerializableObject.Applications
        del SerializableObject.Injectors
        del SerializableObject.BaseNoC
        del SerializableObject.AllocationMap
        del SerializableObject.Buses
        del SerializableObject.Crossbars

        SerializableObject.WrapperAddresses = [self.WrapperAddresses[i] for i in range(len(self.WrapperAddresses))]

        return SerializableObject.__dict__

class Structure:

    def __init__(self, StructureType, AmountOfPEs):
        
        self.StructureType = StructureType
        self.PEs = [PE(PEPos=i, AppID=None, ThreadID=None, InjectorClockPeriod=None) for i in range(AmountOfPEs)]
        self.AddressInBaseNoC = None


    def setPE(self, PENumber, PEObject):

        self.PEs[PENumber] = PEObject


    def setPEs(self, PEsArray):

        if len(self.PEs) != len(PEsArray):
            print("Warning: Given array has unexpected length\n")

        self.PEs = PEsArray


    def __str__(self):

        return "\nStructureType"


class Bus(Structure):

    def __init__(self, AmountOfPEs):

        Structure.__init__(self, StructureType="Bus", AmountOfPEs=AmountOfPEs)


class Crossbar(Structure):

    def __init__(self, AmountOfPEs):

        Structure.__init__(self, StructureType="Crossbar", AmountOfPEs=AmountOfPEs)


class PE:

    def __init__(self, PEPos, AppID, ThreadID, InjectorClockPeriod):

        self.CommStructure = "NOC"  # Default
        self.InjectorType = "FXD"  # Default

        if InjectorClockPeriod is None:
            self.InjectorClockPeriod = None
        else:
            self.InjectorClockPeriod = int((1/InjectorClockPeriod) * 100)  # In nanoseconds

        self.InBufferSize = 128  # Default
        self.OutBufferSize = 128  # Default
        self.PEPos = PEPos
        self.AppID = AppID
        self.ThreadID = ThreadID
        self.AverageProcessingTimeInClockPulses = 1  # Default


    def toJSON(self):

        return json.dumps(self.__dict__, sort_keys=True, indent=4)


class Injector:

    def __init__(self, PEPos, Thread, InjectorClockPeriod):

        # Gets position value from AllocationTable dictionary
        self.PEPos = PEPos
        self.AppID = Thread.ParentApplication.AppID if Thread.ParentApplication is not None else 99
        self.ThreadID = Thread.ThreadID if Thread.ThreadID is not None else 99

        # Checks for
        if Thread.TotalBandwidth is not None:

            # LinkBandwidth = DataWidth * ClockFrequency
            # Consumed Bandwidth = LinkBandwidth * InjectionRate
            # InjectionRate = (ConsumedBandwidth)/(DataWidth * ClockFrequency)
            self.InjectionRate = int((Thread.TotalBandwidth * 100) / (32 * InjectorClockPeriod))

            if self.InjectionRate == 0 and Thread.TotalBandwidth != 0:

                print("Warning: Injection rate = 0% at injector " + str(self.PEPos) + ", setting it to 1%")
                self.InjectionRate = 1

            if self.InjectionRate > 100:

                print("Warning: Injection rate > 100% (" + str(self.InjectionRate) + "%) at injector " + str(self.PEPos) + ", setting it to 100%")
                self.InjectionRate = 100

        else:

            self.InjectionRate = 0

        self.TargetPEs = []
        self.AmountOfMessagesInBurst = []

        if Thread.TotalBandwidth != 0:

            # Determines TargetPEs and AmountOfMessagesInBurst arrays based on required bandwidth
            for i in range(len(Thread.Targets)):

                self.TargetPEs.append(Thread.ParentApplication.ParentPlatform.getPEPos(Thread.Targets[i].TargetThread))
                self.AmountOfMessagesInBurst.append(Thread.Targets[i].Bandwidth)

        else:

            # Set dummy values
            self.TargetPEs.append(99)
            self.AmountOfMessagesInBurst.append(99)

        self.TargetPayloadSize = [126] * len(self.TargetPEs)

        self.SourcePEs = [0]  # Default
        self.SourcePayloadSize = 32  # Default
        self.AmountOfSourcePEs = len(self.SourcePEs)
        self.AmountOfTargetPEs = len(self.TargetPEs)
        self.AverageProcessingTimeInClockPulses = 1  # Default
        self.InjectorType = "FXD"  # Default
        self.FlowType = "RND"  # Default
        self.HeaderSize = 2  # Default
        self.timestampFlag = 1984626850  # Default
        self.amountOfMessagesSentFlag = 2101596287  # Default
        self.RNGSeed1 = random.randint(0, 2147483646)  # Random Value
        self.RNGSeed2 = random.randint(0, 2147483646)  # Random Value

        self.Headers = dict()
        self.Payloads = dict()

        for i in range(len(self.TargetPEs)):

            payloads_aux = [  # Default
                "PEPOS",
                "TMSTP",
                "RANDO",
                "RANDO",
                "RANDO",
                "RANDO",
            ]

            for j in range(int(self.TargetPayloadSize[i]) - 6):
                payloads_aux.append("RANDO")  # Preenche com RANDO #Default

            self.Headers["Header" + str(self.TargetPEs[i])] = ["ADDR", "SIZE"]  # Default
            self.Payloads["Payload" + str(self.TargetPEs[i])] = payloads_aux


    def toJSON(self):

        return json.dumps(self.__dict__, sort_keys=True, indent=4)

