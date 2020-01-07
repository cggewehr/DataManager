

# Expects as arguments: $1 = amount of PEs in network

import sys

AmountOfPEs = int(sys.argv[1])

# Makes list of file objects
InLogs = [open("InLog" + str(x), 'r') for x in range(AmountOfPEs)]
OutLogs = [open("OutLog" + str(x), 'r') for x in range(AmountOfPEs)]

# Initialize 2D arrays for average latency ccomputation
AverageLatencies = [[0 for i in range(AmountOfPEs)] for j in range(AmountOfPEs)]
#AverageLatenciesCounters = [[0 for i in range(AmountOfPEs)] for j in range(AmountOfPEs)]
AverageLatenciesCounters = AverageLatencies

# Loops through every Output log and tries to find matching message in an Input log
for i in range(AmountOfPEs):

    # Makes list of every line in a single Output log
    OutLogLines = OutLogs[i].read().splitlines()
    print("\nLog " + OutLogs[i].name + " contains " + str(len(OutLogs)) + " entries")

    # Loops through every line in Output log and get a message
    for j in range(len(OutLogLines)):

        # Splits current Output log line field into corresponding variables
        # An Output log line should look like: ( | target ID | source ID | msg size | timestamp | ), each field separated by a single whitespace
        OutLogEntry = OutLogLines[j].split()
        TargetID = int(OutLogEntry[0])
        SourceID = int(OutLogEntry[1])
        MessageSize = int(OutLogEntry[2])
        OutputTimestamp = int(OutLogEntry[3])

        # Loops through every Input log and tries to find a match for current message
        for k in range(AmountOfPEs):

            # Makes list of every line in a single Input log
            InLogLines = InLogs[k].read().splitlines()

            # Loops through every Input log line and compares Source, Target and Timestamp fields
            for l in range(len(InLogLines)):

                # Splits current Output log line field into corresponding variables
                # An Input log line should look like: ( | target ID | source ID | msg size | output timestamp | input timestamp | )
                InLogEntry = InLogLines[l].split()
                compTargetID = int(InLogEntry[0])
                compSourceID = int(InLogEntry[1])
                compMessageSize = int(InLogEntry[2])
                compOutputTimestamp = int(InLogEntry[3])
                InputTimestamp = int(InLogEntry[4])

                if (TargetID == compTargetID and SourceID == compSourceID and OutputTimestamp == compOutputTimestamp):

                    # Found match for current message
                    CurrentLatency = OutputTimestamp - InputTimestamp
                    print("\n\tFound match for message " + str(j) + " sent by ID = " + str(SourceID) + " with latency = " + str(CurrentLatency))

                    # Update average latency value (https://blog.demofox.org/2016/08/23/incremental-averaging/)
                    AverageLatenciesCounters[TargetID][SourceID] += 1
                    AverageLatencies[TargetID][SourceID] += (CurrentLatency - AverageLatencies[TargetID][SourceID]) / AverageLatenciesCounters[TargetID][SourceID]
                    break





