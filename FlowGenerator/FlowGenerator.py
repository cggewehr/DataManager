import sys
from os import getcwd
import importlib

# Expects arguments:
SetupModule = str(sys.argv[1])      # $1 = Name of setup file, located in Setups folder
AppModule = str(sys.argv[2])        # $2 = Name of application file, located in Applications folder
AllocModule = str(sys.argv[3])      # $3 = Name of allocation map file, located in Maps folder
ReferenceClock = int(sys.argv[4])   # $4 = Platform reference clock, in MHz

# Imports Setup module
try:
    exec(open("Setups/" + SetupModule + ".py").read())
except FileNotFoundError:
    print("Error: Given Setup module \"" + str(SetupModule) + "\" not found at Setups directory")
    exit(1)

# Imports Application module
try:
    exec(open("Applications/" + AppModule + ".py").read())
except FileNotFoundError:
    print("Error: Given Application module \"" + str(AppModule) + "\" not found at Applications directory")
    exit(1)

# Import Allocation Map module
try:
    exec(open("AllocationMaps/" + AllocModule + ".py").read())
except FileNotFoundError:
    print("Error: Given Allocation Map module \"" + str(AllocModule) + "\" not found at AllocationMaps directory")
    exit(1)

# Link applications to Platform
for i in range(len(Applications)):
    Setup.addApplication(Applications[i])

# Link Allocation Map to platform
Setup.setAllocationMap(AllocationMap)

# Makes PE and Injector objects
Setup.mapToPlatform()

# Generate project JSON config files
Setup.generateJSON("Flows/" + SetupModule + " " + AppModule + "/flow/")
print("JSON files created at " + getcwd() + "\\Flows\\" + SetupModule + " " + AppModule + "\\flow\\")
