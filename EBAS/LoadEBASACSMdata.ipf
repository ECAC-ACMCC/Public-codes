#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function LoadEBASACSMfiles()
	
	SetDataFolder root:
	Make/O/T/N=0 NameofStations
	
    String pathName
    NewPath/O/Q pathName   // ouvre une boîte pour choisir le dossier

    String file
    Variable i = 0
    
    do
        file = IndexedFile(pathName, i, ".csv")
        if (strlen(file) == 0)
            break
        endif

        // extraire nom station (avant "_")
        String station = StringFromList(0, file, "_")

        // sécurité : garder seulement 7 caractères
        station = station[0,6]

        // créer dossier root:station
        NewDataFolder/O/S $("root:" + station)

        // charger le fichier dans ce dossier
        //LoadWave/J/D/O/P=pathName file
        LoadWave/A=Organic/Q/O/J/D/K=0/L={0,1,0,1,1}/V={","," $",0,0}/P=pathName file
        LoadWave/A=ACSMtime/Q/J/V={","," $",0,0}/L={0,1,0,0,1}/R={French,2,2,2,1,"Year-Month-DayOfMonth",40}/P=pathName file
        
        wave ACSMtime0, Organic0
        Rename ACSMtime0, ACSMtime
        Rename Organic0, Organic
        wave Organic, ACSMtime
		
		InsertPoints i,1,NameOfStations
		NameOfStations[i]=station
		
			
        i += 1
    while(1)

End
	


End Function


Function PrepareAndPlot()
	SetDataFolder root:
	Wave/T NameofStations=root:NameofStations
	String list = DataFolderList("*",";")
	make/O/N=(ItemsInList(list)) GraphTicks
	GraphTicks=p+1
	Display/N=AvailabilityPlot

	Variable i = 0
	
	for(i=0;i<ItemsInList(list);i+=1)
		String folder = "root:"+StringFromList(i, list, ";")
		SetDataFolder $folder
		wave TimeWave=$(folder+":ACSMtime")
		wave DataWave=$(folder+":Organic")
		Make/O/N=(numpnts(DataWave)) IntWave
		IntWave = i+1
		
		AppendToGraph/W=AvailabilityPlot IntWave vs TimeWave
	
	endfor
	SetDataFolder root:
	
	Label bottom " "
	SetAxis left 0,ItemsInList(list)+1
	ModifyGraph userticks(left)={GraphTicks,NameofStations}
	ModifyGraph lsize=6
	ModifyGraph grid(left)=1,gridRGB(left)=(26214,26214,26214)
	ModifyGraph dateInfo(bottom)={0,0,-1},dateFormat(bottom)={Default,2,1,1,2,"Year",-6}
	ModifyGraph grid=1,gridRGB(bottom)=(43690,43690,43690)

End Function

