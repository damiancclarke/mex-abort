/* birthGenerate v1.10              DCC/HM                 yyyy-mm-dd:2014-10-17
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

This script genrates a number of output files based on birth data and covariates 
produced from the script municipPrep.py as well as population data produced from
poplnPrep.do and contraceptive data from contracepPrep.do. It produces the foll-
owing two files:

	> MunicipalBirths.dta
	> StateBirths.dta

where the difference between each file is the level of aggregation (State is hi-
gher than Municipal). Each file contains one line per year*age (15-49), w-
ith the number of births that women of the age group had in that time period and
area (either municipality or State).  This includes cases where zero births occ-
urred in the in the particular area.

The file can be controlled in section 1 which requires a group of globals and l-
ocals defining locations of key data sets and specification decisions.  Current-
ly the following data is required:
   > Doctors.csv: number of medical staff per municipality over time
   > EducInf.csv: investment in infrastructure over time
   > Income.csv: income for each municipality over time
   > Spending.csv: spending for each municipality over time
   > Employment figure from each state from INEGI (1 sheet per state)
   > NACIM01.dta-NACIM12.dta: raw birth records from INEGI
   > populationStateYearMonth1549.dta: total population at a state level by time
   > metropolitan.dta: A list of which municipalities are metropolitan 

    contact: mailto:damian.clarke@economics.ox.ac.uk
             mailto:hanna.muhlrad@economics.ox.ac.uk


Past major versions
   > v1.10: Makes file at a year level rather than month
   > v1.00: Recreates data so it is now in quinquennial age groups 
   > v0.10: Adds in data for degree of rurality, and for municipal area or not
   > v0.00: Creates four files: municipal, state, and deseasoned or not

*/

vers 11
clear all
set more off
cap log close
set matsize 10000

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT  "~/database/MexDemografia/Natalidades"
global POP  "~/investigacion/2014/MexAbort/Data/Population/Municip"
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global OUT  "~/investigacion/2014/MexAbort/Results/Births"
global LOG  "~/investigacion/2014/MexAbort/Log"
global COV1 "~/investigacion/2014/MexAbort/Data/Municip"
global COV2 "~/investigacion/2014/MexAbort/Data/Labour/Desocupacion2000_2014"
global COV3 "~/investigacion/2014/MexAbort/Data/Contracep"
global MET  "~/investigacion/2014/MexAbort/Data/Geo"

log using "$LOG/birthGenerate.txt", text replace

foreach uswado in mergemany {
	cap which `uswado'
	if _rc!=0 ssc install `uswado'
}

local covPrep  0
local mergeCV  0
local import   0
local mergeB   0
local stateG   1
local yr3      0

if `yr3'==1 local fileend _window3
if `yr3'==0 local fileend

#delimit ;
local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc
           totalout subsidies unemployment condom* any* adolescentKnows;
local lName aguascalientes   baja_california   baja_california_sur   campeche       
   coahuila_de_zaragoza  colima  chiapas  chihuahua  distrito_federal durango     
   guanajuato guerrero  hidalgo  jalisco  mexico  michoacan_de_ocampo morelos     
   nayarit  nuevo_leon  oaxaca  puebla queretaro quintana_roo san_luis_potosi    
   sinaloa sonora tabasco tamaulipas tlaxcala veracruz_de_ignacio_de_la_llave 
   yucatan zacatecas;
local popName Chihuahua Sonora Coahuila Durango Oaxaca Tamaulipas Jalisco     
   Zacatecas  BajaCaliforniaSur Chiapas Veracruz BajaCalifornia NuevoLeon      
   Guerrero  SanLuisPotosi Michoacan Campeche Sinaloa QuintanaRoo Yucatan      
   Puebla  Guanajuato  Nayarit  Tabasco  Mexico  Hidalgo Queretaro Colima          
   Aguascalientes Morelos Tlaxcala DistritoFederal;
local popNum 8 26 5 10 20 28 14 32 3 7 30 2 19 12 24 16 4 25 23 31 21 11 18 27 
   15 13 22 6 1 17 29 9;
#delimit cr

********************************************************************************
*** (2) Generate Municipal file
********************************************************************************
if `covPrep'==1 {
    insheet using "$COV1/Doctors/Doctors.csv", tab names
    gen MedMissing=medicalstaff=="ND"|medicalstaff=="n. a"
    replace medicalstaff="0" if medicalstaff=="ND"|medicalstaff=="n. a"
    destring medicalstaff, replace

    expand 2 if year==2010
    expand 5 if year==2005
    bys year clave: gen n=_n
    replace year=2011 if year==2010&n==2
    foreach num of numlist 1(1)5 {
        replace year=year-`num'+1 if year==2005&n==`num'
    }
    drop n
    rename clave id
    rename estado state
    rename municipio municip
    tostring id, gen(nid)
    drop id

    gen length=length(nid)
    gen zero="0" if length==4
    egen id=concat(zero nid)
    drop nid zero length
    save "$COV1/Doctors", replace

    insheet using "$COV1/EducInf/EducInf.csv", names delim(";") clear
    foreach var of varlist planteles aulas bibliotecas labor talle {
        gen `var'Missing=`var'=="ND"
        replace `var'=subinstr(`var',".","",1)
        replace `var'="0" if `var'=="ND"
        destring `var', replace
    }
    expand 2 if year==2010
    expand 5 if year==2005
    bys year id: gen n=_n
    replace year=2011 if year==2010&n==2
    foreach num of numlist 1(1)5 {
        replace year=year-`num'+1 if year==2005&n==`num'
    }
    drop n
    tostring id, gen(nid)
    drop id
    
    gen length=length(nid)
    gen zero="0" if length==4
    egen id=concat(zero nid)
    drop nid zero length
    save "$COV1/EducInf", replace
    
    foreach cv in Income Spending {
        insheet using "$COV1/`cv'/`cv'.csv", comma names clear
        drop if year<2001
        expand 2 if year==2010
        bys year id: gen n=_n
        replace year=2011 if year==2010&n==2
        drop n
        cap tostring id, gen(nid)
        cap gen nid=id
        drop id
        
        gen length=length(nid)
        gen zero="0" if length==4
        egen id=concat(zero nid)
        drop nid zero length
        save "$COV1/`cv'", replace
    }
    
    *EXPAND TO MONTHS
    foreach set in Doctors EducInf Income Spending {
        use "$COV1/`set'"
        drop if id==""
        expand 12
        bys id year: gen month=_n
        drop if month>12
        save, replace
    }
    
    foreach ENT of local lName {
        insheet using "$COV2/`ENT'.csv", comma names clear
        keep state number year trimeter desocup dsea
        drop if year<2001|year>2011
        rename trimeter trimester
        rename desocup unemployment
        rename dsea deseasonUnemployment
        destring unemp, replace
        destring desea, replace
        expand 3
        bys state year trimester: gen month=_n
        replace month=month+3 if trimester=="II"
        replace month=month+6 if trimester=="III"
        replace month=month+9 if trimester=="IV"
        save "$COV2/`ENT'", replace
    }
    clear
    
    foreach ENT of local lName {
        append using "$COV2/`ENT'"
    }
    tostring number, gen(id)
    
    gen length=length(id)
    gen zero="0" if length==1
    egen stateid=concat(zero id)
    drop id zero length number
    
    save "$COV2/Labour", replace
}

********************************************************************************
*** (2b) Merge covariate datasets
********************************************************************************
if `mergeCV'==1 {
    mergemany 1:1 "$COV1/Doctors" "$COV1/EducInf" "$COV1/Income" /*
    */ "$COV1/Spending", match(year month id) verbose
    keep if _merge_S==3&_merge_I==3&_merge_E==3
    drop _merge*
    gen stateid=substr(id,1,2)
    
    merge m:1 stateid year month using "$COV2/Labour"
    drop _merge
    save "$BIR/BirthCovariates", replace
    
    merge m:1 stateid year using "$COV3/Contraception"
    drop if _merge==2
    drop _merge

    merge 1:1 id year month using "$COV1/seguroPopularMonth"
    replace SP=0 if year<2003&_merge==1
    replace SP=1 if year>2009&_merge==1
    drop if _merge==2
    drop _merge

    merge m:1 id using "$MET/metropolitan", gen(_metMerge)
    gen metropolitan=_metMerge==3
    drop _metMerge

    ds id year stateid MunName month metropolitanName state municip anexos /*
    */ trimester, not
    collapse `r(varlist)', by(id year stateid MunName state municip)
    
    expand 7
    bys id year: gen ageGroup=_n

    merge m:1 ageGro id year using "$POP/populationMunicipalYear1549", gen(_mPop)
    *losing year 2000 and id==14125, 23009.  This is fine.
    keep if _mPop==3
    
    
    save "$BIR/BirthCovariates", replace
}

********************************************************************************
*** (3) Import births, rename
********************************************************************************
if `import'==1 {
    foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 13 {
        dis "Working with `yr'"
        use "$DAT/NACIM`yr'.dta"

       #delimit ;
        local v999 mun_resid mun_ocurr;
        local v99  tloc_resid ent_ocurr edad_reg edad_madn edad_padn dia_nac 
        mes_nac dia_reg mes_reg edad_madr edad_padr orden_part hijos_vivo  
        hijos_sobr sexo tipo_nac lugar_part q_atendio edociv_mad act_pad
        escol_pad escol_mad fue_prese act_mad;
        #delimit cr
    
        foreach v of local v999 {
            replace `v'=. if `v'==999
        }
        foreach v of local v99  {
            replace `v'=. if `v'==99
        }
        replace ano_nac=. if ano_nac==9999
        
        gen birth=1

        keep if ano_nac>=2001&ano_nac<2012
        
        if `yr3'==1 {
            gen difyr=ano_reg-ano_nac
            keep if difyr>=0&difyr<=3
        }
        drop if mun_ocurr==.
        drop if mes_nac==.

        collapse (sum) birth, by(ent_ocurr mun_ocurr ano_nac edad_madn)

        rename edad_madn Age
        rename ent_ocurr birthStateNum
        rename mun_ocurr birthMunNum
        rename ano_nac year

        tostring birthStateNum, gen(entN)
        gen length=length(entN)
        gen zero="0" if length==1
        egen stateid=concat(zero entN)
        drop length zero entN
        
        tostring birthMunNum, gen(munN)
        gen length=length(munN)
        gen zero="0" if length==2
        replace zero="00" if length==1
        egen munid=concat(zero munN)
        drop length zero munN

        egen id=concat(stateid munid)
        tempfile f`yr'
        save `f`yr''
    }

    clear
    append using `f01' `f02' `f03' `f04' `f05' `f06' `f07' `f08' `f09' `f10' /*
    */ `f11' `f12' `f13' 
    save "$BIR/BirthsYear`fileend'", replace
}


    
********************************************************************************
*** (4) Merge with covariates, generate treatments
********************************************************************************
if `mergeB'==1 {
    use "$BIR/BirthsYear`fileend'", clear
    drop if Age<15|Age>49
    gen ageGroup = .
    local a1 = 10
    foreach num of numlist 1(1)7 {
        local a1=`a1'+5
        local a2=`a1'+4
        dis "Ages: `a1', `a2'"
        replace ageGroup=`num' if Age>=`a1'&Age<=`a2'
    }
    local cvar ageGroup birthStateNum birthMunNum year stateid munid id
    collapse (sum) birth, by(`cvar')
    
    merge 1:1 id year ageGroup using "$BIR/BirthCovariates"
    drop if _merge==1
    *578 obs from 14125, 20009, 23010.

    tab ageGroup if _merge==2
    sum birth
    replace birth=0 if _merge==2
    sum birth
    drop _merge birthStateNum birthMunNum _mPop

    gen Abortion      = stateid=="09"&year>=2008
    gen AbortionClose = stateid=="15"&year>=2008

    gen birthRate     = birth/municipalPopln
    
    label var ageGroup      "Mother's age group at birth"
    label var year          "Year of birth (2001-2011)"
    label var stateid       "State identifier (string)"
    label var munid         "Municipal identifier (string)"
    label var id            "Concatenation of state and municipal id (string)"
    label var state         "State name in words"
    label var municip       "Municipality name in words"
    label var medicalstaff  "Number of medical staff in the municipality"
    label var MedMissing    "Indicator for missing obs on medical staff"
    label var planteles     "Number of educational establishments in municip"
    label var aulas         "Number of classrooms in municipality"
    label var bibliotecas   "Number of libraries in municipality"
    label var laboratorios  "Number of laboratories (study) in the municip"
    label var talleres      "Number of workshops in the municipality"
    label var unemployment  "Unemployment rate in the State"
    label var condomFirstTe "% teens reporting using condoms at first sex"
    label var condomRecentT "% teens reporting using condoms in recent sex"
    label var anyFirstTeen  "% of teens using any contraceptive method"
    label var adolescentKno "Percent of teens knowing any contraceptives"
    label var condomRecent  "% of adults using condoms at recent sex"
    label var anyRecent     "% of adults using any contraceptive at recent sex"
    label var Abortion      "Availability of abortion (1 in DF post reform)"
    label var metropolitan  "Indicator for if the municip is metropolitan"
    label var metroPop      "Population of metropolitan area in 2010"
    label var SP            "Seguro Popular in Municipality"
    label var birth         "Count of the number of births"
    label var birthRate     "Number of births per women of this age group"
    
    
    label data "Birth data and covariates at level of Municipality*Year*Age"
    save "$BIR/MunicipalBirths`fileend'.dta", replace
}


********************************************************************************
*** (5) Generate State file
********************************************************************************
if `stateG' {
    use "$POP/../popStateYr1549LONG.dta"
    keep if year>=2001&year<=2011

    gen ageGroup = .
    local a1 = 10
    foreach num of numlist 1(1)7 {
        local a1=`a1'+5
        local a2=`a1'+4
        dis "Ages: `a1', `a2'"
        replace ageGroup=`num' if Age>=`a1'&Age<=`a2'
    }
    collapse (sum) population, by(ageGroup year stateNum stateName)
    tempfile statepop
    save `statepop'
    
    use "$BIR/MunicipalBirths`fileend'.dta", clear
  
    replace medicalstaff=. if MedMissing==1
    replace planteles=.    if plantelesMissing==1
    replace laboratorios=. if laboratoriosMissing==1
    replace aulas=.        if aulasMissing==1
    replace bibliotecas=.  if bibliotecasMissing==1
    replace talleres=.     if talleresMissing==1

    #delimit ;
    local col medicalstaff planteles aulas bibliotecas totalinc totalout condom*
              subsidies unemployment any* adolescentKnows SP;
    #delimit cr
    
    collapse `col' (sum) birth, by(stateid state year ageGroup)
    
    gen MedMissing         = medicalstaff ==.
    gen plantelesMissing   = planteles    ==.
    gen aulasMissing       = aulas        ==.
    gen bibliotecasMissing = bibliotecas  ==.
	
    replace medicalstaff  = 0 if medicalstaff ==.
    replace planteles     = 0 if planteles    ==.
    replace aulas         = 0 if planteles    ==.
    replace bibliotecas   = 0 if bibliotecas  ==.	
	
    gen stateName=""
    tokenize `popName'
    local i=1
    foreach num of numlist `popNum' {
        if `num'<10 {
            replace stateName="``i''" if stateid=="0`num'"
        }
        if `num' >=10 {
            replace stateName="``i''" if stateid=="`num'"
        }
        local ++i
    }

    local popfile "populationStateYearMonth1549.dta"
    merge 1:1 stateName ageGroup year using `statepop'
    drop if year<2001|year>2011&year!=.
    drop _merge
	
    gen birthrate  = birth/population
    gen DF=stateNum=="32"

    label var DF            "Indicator for Mexico D.F."
    label var stateName     "State name from population data"
    label var stateNum      "State number (string) from population data"	
    label var medicalstaff  "Number of medical staff in the state (average)"
    label var MedMissing    "Indicator for missing obs on medical staff"
    label var planteles     "Number of educational establishments in municip"
    label var aulas         "Number of classrooms in municipality"
    label var bibliotecas   "Number of libraries in municipality"
    label var unemployment  "Unemployment rate in the State"
    label var condomFirstTe "% teens reporting using condoms at first sex"
    label var condomRecentT "% teens reporting using condoms at recent sex"
    label var anyFirstTeen  "% of teens using any contraceptive method"
    label var adolescentKno "Percent of teens knowing any contraceptives"
    label var condomRecent  "% of adults using condoms at recent sex"
    label var anyRecent     "% of adults using any contraceptive at recent sex"


    label data "Birth data and covariates at level of State*Month*Age"
    save "$BIR/StateBirths`fileend'.dta", replace
}

********************************************************************************
*** (X) Close
********************************************************************************
log close
