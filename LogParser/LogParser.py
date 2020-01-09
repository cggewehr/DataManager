
#                                                  Class Definitions
########################################################################################################################


class Message:

    # Constructor
    def __init__(self, InputString):

        # An Input log line should look like: ( | target ID | source ID | msg size | output timestamp | input timestamp | )
        # An Output log line should look like: ( | target ID | source ID | msg size | output timestamp | )
        logEntry = InputString.split()  # split() method takes a string of whitespace separated values and outputs a list of those same values
        self.TargetID = int(logEntry[0])
        self.SourceID = int(logEntry[1])
        self.MessageSize = int(logEntry[2])
        self.OutputTimestamp = int(logEntry[3])

        # If log has a 5th entry (Inout Timestamp field), its an input log entry
        try:
            self.InputTimestamp = int(logEntry[4])
            self.isInputEntry = True
        except IndexError:
            self.isInputEntry = False

    # Overloads operator " = " ( Compares 2 messages )
    def __eq__(self, comp):
        if (self.TargetID == comp.TargetID and self.SourceID == comp.SourceID
                and self.MessageSize == comp.MessageSize and self.OutputTimestamp == comp.OutputTimestamp):
            return True
        else:
            return False

    # Overloads print()
    def __str__(self):
        if self.isInputEntry:
            return ("\nTargetID = " + str(self.TargetID) +
                    "\nSourceID = " + str(self.SourceID) +
                    "\nMessageSize = " + str(self.MessageSize) +
                    "\nOutputTimestamp = " + str(self.OutputTimestamp) +
                    "\nInputTimestamp = " + str(self.InputTimestamp) +
                    "\nisInputEntry = " + str(self.isInputEntry))
        else:
            return ("\nTargetID = " + str(self.TargetID) +
                    "\nSourceID = " + str(self.SourceID) +
                    "\nMessageSize = " + str(self.MessageSize) +
                    "\nOutputTimestamp = " + str(self.OutputTimestamp) +
                    "\nisInputEntry = " + str(self.isInputEntry))


class Log:

    # Constructor
    def __init__(self, logType):
        self.Entries = []
        self.logType = logType

    # Adds a Message object to Entries array
    def addEntry(self, Message):
        self.Entries.append(Message)

    def __str__(self):
        tempString = ""

        tempString += ("\tLogtype = " + str(self.logType) + "\n")

        for i in range(len(self.Entries)):
            tempString += ("\n\tEntry " + str(i))
            tempString += (str(self.Entries[i]))
            tempString += "\n"

        return tempString


#                                                     Entry Point
########################################################################################################################


# Expects as arguments: $1 = amount of PEs in network ; $2 = Debug flag
def main():

    # Sets argument values
    import sys
    amountOfPEs = int(sys.argv[1])
    debugFlag = int(sys.argv[2])

    # Inits variables
    InLogs = [None for i in range(amountOfPEs)]
    OutLogs = [None for i in range(amountOfPEs)]
    avgLatencies = [[0 for i in range(amountOfPEs)] for j in range(amountOfPEs)]
    avgLatenciesCounters = [[0 for i in range(amountOfPEs)] for j in range(amountOfPEs)]
    missCount = [[0 for i in range(amountOfPEs)] for j in range(amountOfPEs)]
    hitCount = [[0 for i in range(amountOfPEs)] for j in range(amountOfPEs)]

    # Builds Log objects from text files
    for i in range(amountOfPEs):

        # Open log text files
        InLogFile = open("InLog" + str(i) + ".txt", 'r')
        OutLogFile = open("OutLog" + str(i) + ".txt", 'r')

        # Add log object to container
        InLogs[i] = Log("Input")
        OutLogs[i] = Log("Output")

        # Add entries (as Message objects) to Input log
        for inLine in InLogFile.readlines():
            InLogs[i].addEntry(Message(inLine))

        # Add entries (as Message objects) to Output log
        for outLine in OutLogFile.readlines():
            OutLogs[i].addEntry(Message(outLine))

        # Close files
        InLogFile.close()
        OutLogFile.close()

    # Prints out Log objects if debug flag is active
    if debugFlag == 1:
        for i in range(amountOfPEs):
            print("\t\tIn log " + str(i) + "\n")
            print(InLogs[i])
        for i in range(amountOfPEs):
            print("\t\tOut log " + str(i) + "\n")
            print(OutLogs[i])

    # Tries to find an In log entry match for every Out log entry
    for i in range(amountOfPEs):

        currentOutLog = OutLogs[i]

        # Loop through all entries in current Out log
        for j in range(len(currentOutLog.Entries)):

            currentOutEntry = currentOutLog.Entries[j]
            currentTarget = currentOutEntry.TargetID
            currentInLog = InLogs[currentTarget]
            foundFlag = False

            # Loop through all entries of current In log, compares each of them to current message in current Out log
            for k in range(len(currentInLog.Entries)):

                currentInEntry = currentInLog.Entries[k]

                if currentOutEntry == currentInEntry:

                    # Found match for current message
                    currentLatency = currentInEntry.InputTimestamp - currentOutEntry.OutputTimestamp

                    if debugFlag == 1:
                        print("Found match for message " + str(j) + " sent by ID = " +
                            str(currentOutEntry.SourceID) + " to target " + str(currentOutEntry.TargetID) +
                            " with size " + str(currentOutEntry.MessageSize) + " with latency = " + str(currentLatency))
                    foundFlag = True

                    # Update average latency value (https://blog.demofox.org/2016/08/23/incremental-averaging/)
                    src = currentOutEntry.SourceID
                    tgt = currentOutEntry.TargetID
                    avgLatenciesCounters[src][tgt] += 1
                    avgLatencies[src][tgt] += (currentLatency - avgLatencies[src][tgt]) / avgLatenciesCounters[src][tgt]
                    hitCount[src][tgt] += 1

                    break

            if not foundFlag:
                missCount[currentOutEntry.SourceID][currentOutEntry.TargetID] += 1

                if debugFlag == 1:
                    print("No match found for message" + str(j) + " sent by ID = " + str(currentOutEntry.SourceID) +
                          " to target " + str(currentOutEntry.TargetID) + " with size " + str(currentOutEntry.MessageSize))

    # Prints out amount of successfully delivered messages
    print("\n\tSuccessfully Delivered Messages")
    for target in range(amountOfPEs):
        for source in range(amountOfPEs):
            if hitCount[source][target] + missCount[source][target] > 0:
                print("Messages successfully delivered from " + str(source) + " to " + str(target) + ": " +
                      str(hitCount[source][target]) + "/" + str(hitCount[source][target] + missCount[source][target]))

    # Prints out average latency values
    print("\n\tAverage Latency Values:")
    for target in range(amountOfPEs):
        for source in range(amountOfPEs):
            if avgLatencies[source][target] != 0:
                print("Average latency from PE ID " + str(source) + " to PE ID " + str(target) + " = " + str(
                      avgLatencies[source][target]))


    print("")

# Forces entry point
if __name__ == "__main__":
    main()

