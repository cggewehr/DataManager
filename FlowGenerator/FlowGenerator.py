#!/usr/bin/env python
import sys
from os import getcwd
import statistics
from sklearn import preprocessing

# Expects arguments:
SetupScript = str(sys.argv[1])      # $1 = Name of setup script, located in Setups folder
AppScript = str(sys.argv[2])        # $2 = Name of application script, located in Applications folder
AllocScript = str(sys.argv[3])      # $3 = Name of allocation map script, located in Maps folder
ReferenceClock = int(sys.argv[4])   # $4 = Platform reference clock, in MHz

# Executes Setup script
try:
    exec(open("Setups/" + SetupScript + ".py").read())
except FileNotFoundError:
    print("Error: Given Setup script \"" + str(SetupScript) + "\" not found at Setups directory")
    exit(1)

# Executes Application script
try:
    exec(open("Applications/" + AppScript + ".py").read())
except FileNotFoundError:
    print("Error: Given Application script \"" + str(AppScript) + "\" not found at Applications directory")
    exit(1)

# Executes Allocation Map script
try:
    exec(open("AllocationMaps/" + AllocScript + ".py").read())
except FileNotFoundError:
    print("Error: Given Allocation Map script \"" + str(AllocScript) + "\" not found at AllocationMaps directory")
    exit(1)

# Link applications to Platform (Applications array must be set on given app script)
for i in range(len(Applications)):
    Setup.addApplication(Applications[i])

# Link Allocation Map to platform
Setup.setAllocationMap(AllocationMap)

# Makes PE and Injector objects
Setup.mapToPlatform()

# Generate project JSON config files
Setup.generateJSON("Flows/" + SetupScript + " " + AppScript + "/flow/")
print("JSON files created at " + getcwd() + "\\Flows\\" + SetupScript + " " + AppScript + "\\flow\\")

# Generate log containing project information
ProjectInfo = open("Flows/" + SetupScript + " " + AppScript + "/" + SetupScript + " " + AppScript + "Info.txt", 'w')
ProjectInfo.write("Setup: " + SetupScript)
ProjectInfo.write("\tAmount of PEs: " + Setup.AmountOfPEs)
ProjectInfo.write("\tAmount of PEs in base NoC: " + str((Setup.BaseNoCDimensions[0]*Setup.BaseNoCDimensions[1]) - Setup.AmountOfWrappers))
ProjectInfo.write("\tAmount of Wrappers: " + Setup.AmountOfWrappers)

ProjectInfo.write("\tAmount of Buses: " + Setup.AmountOfBuses)
AmountOfPEsInBuses = 0
for i in Setup.Buses:
    AmountOfPEsInBuses += len(Setup.Buses[i].PEs)
ProjectInfo.write("\tAmount of PEs in each Bus: " + str(Setup.AmountOfPEsInBuses))

ProjectInfo.write("\tAmount of Crossbars: " + Setup.AmountOfCrossbars)
AmountOfPEsInCrossbars = 0
for i in Setup.Crossbars:
    AmountOfPEsInCrossbars += len(Setup.Crossbars[i].PEs)
ProjectInfo.write("\tAmount of PEs in each Crossbar: " + str(Setup.Crossbars))

ProjectInfo.write("Application: ")
ProjectInfo.write("\tNumber of Applications: " + str(len(Applications)))

Threads = []
for i in Applications:
    for j in Applications[i].Threads:
        Threads.append(Applications[i].Threads[j])
ProjectInfo.write("\tNumber of Threads: " + str(len(Threads)))

Targets = []
for i in Threads:
    for j in Threads[i].Targets:
        Targets.append(Threads[i].Targets[j])
ProjectInfo.write("\tAmount of Targets" + str(len(Targets)))

Bandwidth = []
for i in Threads:
    Bandwidth.append(Threads[i].TotalBandwidth)
ProjectInfo.write("\tTotal required bandwidth: " + str(sum(Bandwidth)))

ProjectInfo.write("\tAverage required bandwidth (per thread): " + str(statistics.mean(Bandwidth)))
ProjectInfo.write("\tStd deviation of required bandwidth (per thread): " + str(statistics.pstdev(Bandwidth)))

# TODO: Classify application as concentrated or distributed (function of std dev) and high demand or low demand

# Classify application as concentrated or distributed
BandwidthNormalized = preprocessing.normalize([Bandwidth])
if statistics.pstdev(BandwidthNormalized) > 0.35:
    ProjectInfo.write("\n\tApplication is concentrated")
else:
    ProjectInfo.write("\n\tApplication is distributed")

# Classify as high demand or low demand
if statistics.mean(Bandwidth) > 100:  # Bandwidth is expressed in Mbps
    ProjectInfo.write("\tApplication is high demand")
else:
    ProjectInfo.write("\tApplication is low demand")

# Close info file and exit successfully
ProjectInfo.close()
exit(0)
