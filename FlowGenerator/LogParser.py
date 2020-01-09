

class Message:

    # Constructor
    def __init__(self, InputString):

        logEntry = InputString.split()
        self.TargetID = int(LogEntry[0])
        self.SourceID = int(LogEntry[1])
        self.MessageSize = int(LogEntry[2])
        self.OutputTimestamp = int(LogEntry[3])

        try:
            self.InputTimestamp = int(LogEntry[4])
            self.isInputEntry = True
        except:
            self.isInputEntry = False

    # Overloads operator " = " ( Compares 2 messages )
    def __eq__(self, OtherMessage):
        if (self. TargetID == OtherMessage.TargetID and SourceID == OtherMessage.SourceID and OutputTimestamp == OtherMessage.OutputTimestamp):
            return True
        else:
            return False

class Log:

    def __init__(self, LogType):
        self.Entries = []
        self.LogType = LogType

    def addEntry(self, Message):
        self.Entries.append(Message)

# Expects as arguments: $1 = amount of PEs in network
def main():

    import sys

    AmountOfPEs = int(sys.argv[1])

    # Builds Log objects from text files
    for i in range(AmountOfPEs):

        # Open log text files
        InLogFile = open("InLog" + str(i), 'r')
        OutLogFile = open("OutLog" + str(i), 'r')

        # Add log object to container
        InLogs[i] = Log()
        OutLogs[i] = Log()

        # Add entries to Input log
        while():
            try:
                InLogs[i].addEntry(Message(readline(InLogFile)))
            except:
                pass
                break

        # Add entries to Output log
        while():
            try:
                OutLogs[i].addEntry(Message(readline(OutLogFile)))
            except:
                pass
                break


    # Compare entries

if __name__ == "__main__":
    main()