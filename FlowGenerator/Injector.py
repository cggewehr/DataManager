import json
import sys

class Injector:
	Headers = dict()
	Payload = dict()
	
	def __init__(self, PEPos, APPID, ThreadID,InjectionRate, SourcePEs, SourcePayloadSize, TargetPEs, TargetPayloadSize):
		self.Headers = dict()
		self.Payload = dict()
		self.PEPos = PEPos
		self.APPID = APPID
		self.ThreadID = ThreadID
		self.InjectionRate = InjectionRate
		self.SourcePEs = SourcePEs
		self.SourcePayloadSize = SourcePayloadSize
		self.TargetPEs = TargetPEs
		self.TargetPayloadSize = TargetPayloadSize
		self.AmountOfSourcePEs = len(SourcePEs)	#Default
		self.AmountOfTargetPEs = len(TargetPEs) #Default
		self.AverageProcessingTimeInClockPulses = "1" 	#Default
		self.InjectorType = "FXD" 	#Default
		self.FlowType = "RND"		#Default
		self.HeaderSize = "2"		#Default
		self.AmountOfMessagesInBurst = "1"	#Default
		self.timestampFlag = "256"	#Default
		self.amountOfMessagesSentFlag = "512"	#Default		

		for i in range(len(self.TargetPEs)):
			payload_aux = [			#Default
      			"PEPOS",
      			"TMSTP",
     			"PEPOS",
      			"PEPOS",
      			"PEPOS",
      			"PEPOS",
      			]
			for j in range(int(self.TargetPayloadSize[i])-6):
				payload_aux.append("PEPOS"); #Preenche com PEPOS #Default
			self.Headers["Header" + self.TargetPEs[i]] = ["ADDR", "SIZE"] 	#Default
			self.Payload["Payload" + self.TargetPEs[i]]= payload_aux
		pass
	
	def toJSON(self):
		print(self.SourcePEs)
        	return json.dumps(self.__dict__, sort_keys=True, indent=4)
	pass


def verifyFile(jsonFile):
	appID = 0
	for app in jsonFile['system']['apps']:
		numtask = int(app['numTask'])

		if len(app['PEpos']) != numtask and app['mapping'] == "CUSTOM":
			print("ERRO: Argumentos em PEpos faltando na App "+ str(appID))
			sys.exit()

		elif (len(app['InjRate']) != numtask) and (len(app['InjRate']) != 1):
			print("ERRO: Argumentos em InjRate faltando na App "+ str(appID))
			sys.exit()

		elif (len(app['TargetPayload']) != numtask) and (len(app['TargetPayload']) != 1):
			print("ERRO: Argumentos em TargetPayload faltando na App "+ str(appID))
			sys.exit()
		appID += 1



# some JSON:
#x = Injector(PEPos = "0", APPID = "1", ThreadID = "0", InjectionRate = "50", AmountOfSourcePEs= "1", SourcePEs = ["1"], SourcePayloadSize = [10], AmountOFTargetPEs = "3", TargetPEs = ["2","3","4"],TargetPayloadSize = [7,8,9])

#f = open('output.json','w')
#f.write(x.toJSON());
#f.close()


