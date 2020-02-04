#!/usr/bin/env python
import sys
from os import getcwd
import statistics
#from sklearn import preprocessing

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
print("JSON files created at " + getcwd() + "/Flows/" + SetupScript + " " + AppScript + "/flow/")

# Generate log containing project information
ProjectInfo = open("Flows/" + SetupScript + " " + AppScript + "/" + SetupScript + " " + AppScript + "Info.txt", 'w')
ProjectInfo.write("Setup: " + SetupScript + "\n")
ProjectInfo.write("\tAmount of PEs: " + str(Setup.AmountOfPEs) + "\n")
ProjectInfo.write("\tAmount of PEs in base NoC: " + str((Setup.BaseNoCDimensions[0]*Setup.BaseNoCDimensions[1]) - Setup.AmountOfWrappers) + "\n")
ProjectInfo.write("\tAmount of Wrappers: " + str(Setup.AmountOfWrappers) + "\n")

ProjectInfo.write("\tAmount of Buses: " + str(Setup.AmountOfBuses) + "\n")
AmountOfPEsInBuses = 0
for Bus in Setup.Buses:
    AmountOfPEsInBuses += len(Bus.PEs)
ProjectInfo.write("\tAmount of PEs in each Bus: " + str(Setup.AmountOfPEsInBuses) + "\n")

ProjectInfo.write("\tAmount of Crossbars: " + str(Setup.AmountOfCrossbars) + "\n")
AmountOfPEsInCrossbars = 0
for Crossbar in Setup.Crossbars:
    AmountOfPEsInCrossbars += len(Crossbar.PEs)
ProjectInfo.write("\tAmount of PEs in each Crossbar: " + str(Setup.AmountOfPEsInCrossbars) + "\n")

ProjectInfo.write("Application: " + "\n")
ProjectInfo.write("\tNumber of Applications: " + str(len(Applications)) + "\n")

Threads = []
for App in Applications:
    for Thread in App.Threads:
        Threads.append(Thread)
ProjectInfo.write("\tNumber of Threads: " + str(len(Threads)) + "\n")

Targets = []
for Thread in Threads:
    for Target in Thread.Targets:
        Targets.append(Target)
ProjectInfo.write("\tAmount of Targets: " + str(len(Targets)) + "\n")

Bandwidth = []
for Thread in Threads:
    Bandwidth.append(Thread.TotalBandwidth)
ProjectInfo.write("\tTotal required bandwidth: " + str(sum(Bandwidth)) + "\n")

ProjectInfo.write("\tAverage required bandwidth (per thread): " + str(statistics.mean(Bandwidth)) + "\n")
ProjectInfo.write("\tStd deviation of required bandwidth (per thread): " + str(statistics.pstdev(Bandwidth)) + "\n")

# TODO: Classify application as concentrated or distributed (function of std dev) and high demand or low demand

# Classify application as concentrated or distributed
# BandwidthNormalized = preprocessing.normalize([Bandwidth])
# if statistics.pstdev(BandwidthNormalized) > 0.35:
#     ProjectInfo.write("\n\tApplication is concentrated")
# else:
#     ProjectInfo.write("\n\tApplication is distributed")
#
# # Classify as high demand or low demand
# if statistics.mean(Bandwidth) > 100:  # Bandwidth is expressed in Mbps
#     ProjectInfo.write("\tApplication is high demand")
# else:
#     ProjectInfo.write("\tApplication is low demand")

# Close info file and exit successfully
ProjectInfo.close()
exit(0)
