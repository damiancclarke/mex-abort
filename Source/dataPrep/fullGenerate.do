/* fullGenerate.do v0.00         damiancclarke             yyyy-mm-dd:2015-02-21
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file takes microdata on births, fetal deaths, maternal deaths, murders, cr-
imes, divorces and marriages, along with covariates and makes one large data set
at the level of the state * month * year level.

Individual data sets are generated from INEGI microdata, and generating files a-
re located in subfolder called xxxxGenerate where xxxx refers to the variable of
interest (birth, marriage, divorce, ...). The following are the raw datafiles u-
sed:

> Data/Mortality/MortalityMonth.dta
> Data/Mortality/FetalMunicip.dta
> Data/Social/CrimeMonth.dta
> Data/Social/CrimeMonth.dta
> Data/Social/DivorceMonth.dta
> Data/Social/MarriageMonth.dta


contact: damian.clarke@economics.ox.ac.uk
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global MOR  "~/investigacion/2014/MexAbort/Data/Mortality"
global SOC  "~/investigacion/2014/MexAbort/Data/Social"
global POP  "~/investigacion/2014/MexAbort/Data/Population"
global LOG  "~/investigacion/2014/MexAbort/Log"

log using "$LOG/fullGenerate.txt", text replace

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc   /*
*/ totalout subsidies unemployment condom* any* adolescentKnows SP

local popName Chihuahua Sonora Coahuila Durango Oaxaca Tamaulipas Jalisco     /*
*/ Zacatecas BajaCaliforniaSur Chiapas Veracruz BajaCalifornia NuevoLeon      /*
*/ Guerrero SanLuisPotosi Michoacan Campeche Sinaloa QuintanaRoo Yucatan      /*
*/ Puebla Guanajuato Nayarit Tabasco Mexico Hidalgo Queretaro Colima          /*
*/ Aguascalientes Morelos Tlaxcala DistritoFederal
local popNum 8 26 5 10 20 28 14 32 3 7 30 2 19 12 24 16 4 25 23 31 21 11 18 27 /*
*/ 15 13 22 6 1 17 29 9

local mAll   1
local stateG 1

********************************************************************************
*** (3) Full merge with birth data (slow)
********************************************************************************
if `mAll'== 1 {
    use "$BIR/MunicipalBirths"
    merge 1:1 id Age year month using "$MOR/FetalMunicip.dta", gen(_mergeFD)
    keep if year>2000&year<2012
    drop if Age<15|Age>49
    drop if month==99
    count if _mergeFD==2
    *1 case (id=23010)
    drop if _mergeFD==2 
    
    replace fetalDeath=0 if _mergeFD==1
    replace earlyTerm =0 if _mergeFD==1
    replace lateTerm  =0 if _mergeFD==1


    merge 1:1 id Age year month using "$MOR/MortalityMonth.dta", gen(_mergeMort)
    keep if year>2000&year<2012
    drop if Age<15|Age>49
    drop if month==.
    drop if munid=="00."
    count if _mergeMort==2
    *10 (missing municip id)
    drop if _mergeMort==2
        
    replace MMR            = 0 if _mergeMort==1
    replace materndeath    = 0 if _mergeMort==1
    replace murder         = 0 if _mergeMort==1
    replace murderWoman    = 0 if _mergeMort==1
    replace familyViolence = 0 if _mergeMort==1

    
    merge 1:1 id Age year month using "$SOC/DivorceMonth.dta", gen(_mergeDivorce)
    keep if year>2000&year<2012
    drop if Age<15|Age>49
    replace divorce = 0 if _mergeDivorce==1


    merge 1:1 id Age year month using "$SOC/MarriageMonth.dta", gen(_mergeMarriage)
    keep if year>2000&year<2012
    drop if Age<15|Age>49
    replace marriage = 0 if _mergeMarriage==1


    merge m:1 id year month using "$SOC/CrimeMonth.dta", gen(_mergeCrime)
    keep if year>2000&year<2012
    drop if Age<15|Age>49
    replace intrafamilyViolence = 0 if _mergeCrime==1&year>2002
    replace intrafamilyViolence = . if year<=2002
    replace abortionCrime       = 0 if _mergeCrime==1&year>2002
    replace abortionCrime       = . if year<=2002

    save "$BIR/BirthsFullMunicipal", replace
}

********************************************************************************
*** (4) Generate State file
********************************************************************************
if `stateG'==1 {
    use "$BIR/BirthsFullMunicipal.dta", clear

    replace medicalstaff=. if MedMissing         ==1
    replace planteles=.    if plantelesMissing   ==1
    replace laboratorios=. if laboratoriosMissing==1
    replace aulas=.        if aulasMissing       ==1
    replace bibliotecas=.  if bibliotecasMissing ==1
    replace talleres=.     if talleresMissing    ==1

    collapse medicalstaff planteles aulas bibliotecas totalinc totalout condom* /*
    */ subsidies unemploym any* adolescentKno (sum) birth fetalDeath early late /*
    */ MMR materndeath murder* familyViolence divorce marriage intrafamilyViole /*
    */ abortionCrime, by(stateid year month Age) fast

    gen MedMissing         = medicalstaff     ==.
    gen plantelesMissing   = planteles        ==.
    gen aulasMissing       = aulas            ==.
    gen bibliotecasMissing = bibliotecas      ==.

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
    merge 1:1 stateName Age month year using "$POP/populationStateYearMonth1549.dta"
    drop if year<2001|year>2010&year!=.
    drop _merge

    gen yearmonth   = year + (month-1)/12
    gen birthrate   = birth/imputePop
    gen Fdeathrate  = fetalDeath/birth
    gen lFdeathrate = earlyTerm/birth
    gen eFdeathrate = lateTerm/birth
    gen DF=stateNum =="32"

    label var DF            "Indicator for Mexico D.F."
    label var stateName     "State name from population data"
    label var stateid       "State number (string) from population data"
    label var medicalstaff  "Number of medical staff in the state (average)"
    label var MedMissing    "Indicator for missing obs on medical staff"
    label var planteles     "Number of educational establishments in municipality"
    label var aulas         "Number of classrooms in municipality"
    label var bibliotecas   "Number of libraries in municipality"
    label var unemployment  "Unemployment rate in the State"
    label var condomFirstTe "% teens reporting using condoms at first intercourse"
    label var condomRecentT "% teens reporting using condoms at recent intercourse"
    label var anyFirstTeen  "% of teens using any contraceptive method"
    label var adolescentKno "Percent of teens reporting knowing any contraceptives"
    label var condomRecent  "% of adults using condoms at recent intercourse"
    label var anyRecent     "% of adults using any contraceptive at recent intercou"
    label var yearmonth     "Year and month added together (numerical)"
    label var MMR           "Deaths of women within 42 days of childbirth"
    label var materndeath   "Deaths of women related to pregnancy"
    label var murder        "All Murders"
    label var murderWoman   "Murders of women"
    label var familyViolence "Murders related to family violence"
    label var divorce       "Divorces (number)"
    label var marriage      "Marriage (number)"
    label var intrafamilyViolence "Prosecution for intra-family violence"
    label var abortionCrime "Number of cases of abortion which are prosecuted" 
    
    label data "Full data and covariates at level of State*Month*Age"
    save "$BIR/BirthsFullState.dta", replace
}


********************************************************************************
*** (X) Close
********************************************************************************
log close
