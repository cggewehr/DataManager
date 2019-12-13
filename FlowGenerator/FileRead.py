from Injector import Injector,verifyFile

import json
import sys

#prompt the user for a file to import

with open('platInput.json') as json_file:
    data = json.load(json_file)

verifyFile(data)

appID = 0
SourcePEs = []
TargetPEs = []
TargetPayloadSize_aux = []
TargetPayloadSize = []

for app in data['system']['apps']:
	numtask = app['numTask']
	trafficPattern = app['trafficPattern']
	mapping = app['mapping']
	PEpos = app['PEpos']
	InjRate = app['InjRate']
	SourcePayloadSize = [20] * (int(numtask) -1)

	if len(app['TargetPayload']) == 1:
		TargetPayloadSize = [int(app['TargetPayload'][0])] * (int(numtask))
	else:	
		TargetPayloadSize = app['TargetPayload']

	if len(app['InjRate']) == 1:
		InjRate = [int(app['InjRate'][0])] * (int(numtask))
	else:	
		InjRate = app['InjRate']


	for task in range(int(numtask)):
		#Se o trafego for randomico, guardar apenas os vizinhos da tarefa
		SourcePEs = PEpos[:] #Copia a lista de todos
		SourcePEs.pop(task)  #Se retira da lista, sobrando apenas os vizinhos
		TargetPEs = PEpos[:] #Copia a lista de todos
		TargetPEs.pop(task)  #Se retira da lista, sobrando apenas os vizinhos
		TargetPayloadSize_aux = TargetPayloadSize[:]
		TargetPayloadSize_aux.pop(task)

		inj = Injector(PEPos = PEpos[task], APPID = appID, ThreadID = task, InjectionRate = InjRate[task], SourcePEs = SourcePEs, SourcePayloadSize = SourcePayloadSize, TargetPEs = TargetPEs, TargetPayloadSize = TargetPayloadSize)
		f = open('output' + str(appID) + str(task)+ '.json','w')
		f.write(inj.toJSON());
		f.close()



		#print(PEpos[task])

	
	#appID += 1
