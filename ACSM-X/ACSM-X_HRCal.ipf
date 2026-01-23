#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function HRCal_Initialize()
	
	
	String/G NameofCalFolder=GetDataFolder(1)
	String/G SpecieList="NO3;SO4;NH4"
	String/G Specie=""
	variable/G TotalSignalBool=0
	variable/G CPCInputBool=0
	string/G CPCCountsWname=""
	string/G CPCTimeWName=""
	variable/G AnalogInputNb=3
	variable/G AnalogConvFactor=1000

	HRCal_Panel()

End Function


Menu "GraphMarquee"
	"HRCal.: Average Cal Point" , AverageCalPoint()
End

Menu "ACSM-X HRCal."
	"Initialize Panel",/q,HRCal_Initialize()
End

Function AverageCalPoint()
	
	wave t_base
	SVAR/Z Specie,CPCCountsWname,CPCTimeWName,NameofCalFolder
	NVAR/Z TotalSignalBool,CPCInputBool,AnalogInputNb,AnalogConvFactor
	
	string OutputWName=Specie+"_ions"
	wave Specie_ion=$OutputWName
	wave cpc_counts,cpc_time,ions_avg,ions_std,cpc_counts_avg,cpc_counts_std, flowrate_avg
	
	wave Flowrate=root:Packages:tw_ACSM2:ABCalib:FlowRate_ccs
	wave ABtime=root:Packages:tw_ACSM2:ABCalib:ABtimewave
	
	GetMarquee bottom
	variable MinIndex,MaxIndex
	MinIndex=BinarySearch(t_base,V_left)
	MaxIndex=BinarySearch(t_base,V_right)
	
	InsertPoints numpnts(cpc_counts_avg),1, ions_avg
	InsertPoints numpnts(cpc_counts_avg),1, ions_std
	InsertPoints numpnts(cpc_counts_avg),1, cpc_counts_avg
	InsertPoints numpnts(cpc_counts_avg),1, cpc_counts_std
	InsertPoints numpnts(cpc_counts_avg),1, flowrate_avg
	
	duplicate/O/R=(MinIndex,MaxIndex) Specie_ion, temp
	WaveStats/Q temp
	ions_avg[numpnts(cpc_counts_avg)-1]=V_avg
	ions_std[numpnts(cpc_counts_avg)-1]=V_sdev
	
	if(CPCInputBool==0)
		MinIndex=BinarySearch(cpc_time,V_left)
		MaxIndex=BinarySearch(cpc_time,V_right)
	endif
	duplicate/O/R=(MinIndex,MaxIndex) cpc_counts, temp
	WaveStats/Q temp
	cpc_counts_avg[numpnts(cpc_counts_avg)-1]=V_avg
	cpc_counts_std[numpnts(cpc_counts_avg)-1]=V_sdev
	
	
	MinIndex=BinarySearch(ABtime,V_left)
	MaxIndex=BinarySearch(ABtime,V_right)
	duplicate/O/R=(MinIndex,MaxIndex) Flowrate, temp
	WaveStats/Q temp
	flowrate_avg[numpnts(cpc_counts_avg)-1]=V_avg
	
	Killwaves/Z temp

End Function


Function HRCal_Panel()
	dowindow HRCalPanel
	if(V_flag==1)
		killwindow HRCalPanel
	endif
	
	newpanel/N=HRCal/W=(200,10,605,370)/K=1
	modifypanel fixedSize = 1
	
	SetDrawEnv fsize= 30,fstyle= 0,textrgb= (8704,8704,8704)
	DrawText 100,45,"ACSM-X HRCal."
	
	SVAR/Z NameofCalFolder
	SetVariable SetV_CalFolder, fSize=14, pos={5,55}, size={350,20}, value = NameOfCalFolder, title="\f01Name of Cal. Folder", disable = 0,fstyle=0,font="Arial"
	PopupMenu PM_Specie, fSize=14, pos={6,100}, size={100,20}, value = "select;"+SpecieInputList(""), title="\f01Specie", proc = SpecieInput_proc, disable = 0,fstyle=1,font="Arial"
	NVAR/Z TotalSignalBool
	CheckBox CB_UseTotalSignal, title="Use Total Signal ?", pos={175,100}, fsize=14,variable=TotalSignalBool,disable=2
	NVAR/Z CPCInputBool
	CheckBox CB_UseCPCInput, title="CPC Analog Input ?", pos={5,150}, fsize=14,variable=CPCInputBool,proc=CPCInput
	if (CPCInputBool==0)
		SVAR/Z CPCCountsWname,CPCTimeWName
		SetVariable SetV_CPCWName, fSize=14, pos={170,150}, size={230,20}, value = CPCCountsWname, title="CPC Counts Wave", disable = 0,fstyle=0,font="Arial"
		SetVariable SetV_CPCTWName, fSize=14, pos={170,175}, size={230,20}, value = CPCTimeWName, title="CPC Time Wave", disable = 0,fstyle=0,font="Arial"
	else
		NVAR/Z AnalogInputNb,AnalogConvFactor
		SetVariable SetV_AnalogInputNb, fSize=14, pos={170,150}, size={170,20}, value = AnalogInputNb, title="Analog Input Nb", disable = 0,fstyle=0,font="Arial"
		SetVariable SetV_AnalogConvFactor, fSize=14, pos={170,175}, size={190,20}, value = AnalogConvFactor, title="Analog Conv. factor", disable = 0,fstyle=0,font="Arial"
	
	endif
	
	
	Button But_PlotTS, title="\\f01 Plot TimeSerie", pos={120,250},fSize=14,size={150,25},font="Arial", fcolor=(52224,34816,0), proc=plotTS

	Button But_CalPlot, title="\\f01 Cal. Plot & Fit", pos={120,300},fSize=14,size={150,25},font="Arial", fcolor=(52224,34816,0), proc=plotCal




End Function


Function/S SpecieInputList(option)
	string option
	
	SVAR/Z SpecieList
	return SpecieList
	
End Function


Function SpecieInput_proc(name,num,str) : PopupMenuControl
	string name
	variable num
	string str

	SVAR/Z Specie
	Specie=str

End Function


FUnction PlotTS(CtrlName) : ButtonControl
	string CtrlName
	
	SVAR/Z Specie,CPCCountsWname,CPCTimeWName,NameofCalFolder
	NVAR/Z TotalSignalBool,CPCInputBool,AnalogInputNb,AnalogConvFactor

	string WaveToSum

	if (stringmatch(Specie,"NO3"))
	
		if(TotalSignalBool==0)
			WaveToSum="NO+_00000;NO2+_00000"
		else
			WaveToSum=""
		endif
	
	elseif(stringmatch(Specie,"SO4"))
		if(TotalSignalBool==0)
			WaveToSum=""
		else
			WaveToSum=""
		endif
	
	elseif(stringmatch(Specie,"NH4"))
	if(TotalSignalBool==0)
			WaveToSum=""
		else
			WaveToSum=""
		endif
	endif
	
	SumWaves(WaveToSum,Specie)
	string OutputWName=Specie+"_ions"
	wave Specie_ion=$OutputWName
	wave t_base

	
	
	if(CPCInputBool==1)
		string AIWaveName="PRESSA"+num2str(AnalogInputNb)+"_V monitor [V]"
		SetDataFolder $("::TPS2")
		wave cpcW=$AIWaveName
		SetDataFolder $NameofCalFolder
		duplicate /O cpcW cpc_raw
		duplicate/O cpc_raw cpc_counts
		cpc_counts*=AnalogConvFactor
		
		Display cpc_counts,Specie_ion vs t_base
		
	else
		wave CPCCountsW=$CPCCountsWname
		wave CPCtimeW=$CPCTimeWName
		duplicate/O CPCCountsW cpc_counts
		duplicate/O CPCTimeW cpc_time
		
		Display Specie_ion vs t_base
		Appendtograph cpc_counts vs cpc_time
		
	endif
	
	ModifyGraph mode=3,marker=59
	ModifyGraph rgb($OutputWName)=(65535,21845,0)
	ModifyGraph rgb(cpc_counts)=(0,0,0)
	
	Make/O/N=0 ions_avg, ions_std, cpc_counts_avg, cpc_counts_std,flowrate_avg
	edit ions_avg, ions_std, cpc_counts_avg, cpc_counts_std,flowrate_avg
	
End Function


FUnction SumWaves(listofwaves,Specie)
	string listofwaves,Specie
	variable nbelemlist=ItemsInList(ListofWaves)
	variable i
	string WaveNameToUse,OutputWName
	
	OutputWName=Specie+"_ions"
	
	for(i=0;i<nbelemlist;i+=1)
		WaveNameToUse=StringFromList(i,ListofWaves)
		wave temp=$WaveNameToUse
		if (i==0)
			duplicate/O temp SumW
			continue
		endif
		SumW+=temp
	endfor
	
	duplicate/O SumW $OutputWName
	KillWaves SumW

End Function


FUnction PlotCal(CtrlName) : ButtonControl
	string CtrlName
	SVAR/Z Specie
	
	wave cpc_counts_avg,ions_avg,flowrate_avg,cpc_counts_std,ions_std
	duplicate/O cpc_counts_avg cpc_no3_pg_avg
	duplicate/O cpc_counts_std cpc_no3_pg_std

	
	variable dp, density, sf, M_specie, M_compound
	dp=300e-7
	sf=0.8
	if(stringmatch(Specie,"NO3"))
		density=1.72
		M_specie=62
		M_compound=80
	elseif(stringmatch(Specie,"SO4"))
		density=1.77
		M_specie=96
		M_compound=132
	elseif(stringmatch(Specie,"NH4"))
		//density=1.72
		//M_specie=18
		//M_compound=80
	endif
	cpc_no3_pg_avg = cpc_counts_avg*(pi/6)*((dp)^3)*(density*sf)*flowrate_avg*(M_specie/M_compound)*1e12
	cpc_no3_pg_std = cpc_counts_std*(pi/6)*((dp)^3)*(density*sf)*flowrate_avg*(M_specie/M_compound)*1e12
	
	Display ions_avg vs cpc_no3_pg_avg
	ModifyGraph mode=3
	ModifyGraph marker(ions_avg)=19
	CurveFit/M=2/W=0/TBOX = 256 line, ions_avg/X=cpc_no3_pg_avg/D
	ModifyGraph rgb(fit_ions_avg)=(8738,8738,8738)
	ErrorBars ions_avg XY,wave=(cpc_no3_pg_std,cpc_no3_pg_std),wave=(ions_std,ions_std)
	Label bottom Specie+" mass (pg/s)"
	Label left "Signal (ions/s)"
	

End Function


Function CPCInput(ctrlName,checked) : CheckBoxControl
	string ctrlName
	Variable checked
	
	SVAR/Z CPCCountsWname
	SVAR/Z CPCTimeWName
	NVAR/Z AnalogInputNb
	NVAR/Z AnalogConvFactor
	
	
	if (checked==1)
		SetVariable SetV_CPCWName, disable=1
		SetVariable SetV_CPCTWName, disable=1
		
		SetVariable SetV_AnalogInputNb, fSize=14, pos={170,150}, size={170,20}, value = AnalogInputNb, title="Analog Input Nb", disable = 0,fstyle=0,font="Arial"
		SetVariable SetV_AnalogConvFactor, fSize=14, pos={170,175}, size={190,20}, value = AnalogConvFactor, title="Analog Conv. factor", disable = 0,fstyle=0,font="Arial"

	else
		
		SetVariable SetV_AnalogInputNb, disable=1
		SetVariable SetV_AnalogConvFactor,disable=1
		
		SetVariable SetV_CPCWName, fSize=14, pos={170,150}, size={230,20}, value = CPCCountsWname, title="CPC Counts Wave", disable = 0,fstyle=0,font="Arial"
		SetVariable SetV_CPCTWName, fSize=14, pos={170,175}, size={230,20}, value = CPCTimeWName, title="CPC Time Wave", disable = 0,fstyle=0,font="Arial"
		
	endif

End Function


