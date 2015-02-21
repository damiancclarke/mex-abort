/* fetalGenerate v0.00              DCC/HM                 yyyy-mm-dd:2014-11-21
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

This script generates the output files FDeathMunicip.dta and FDeathState.dta fr-
om fetal mortality data, and covariates included in birth data. These covariates
include time-varying municipal and regional controls along with total population
and total births at the same level.

The file can be controlled in section 1 which requires a group of globals and l-
ocals defining locations of key data sets and specification decisions.  Current-
ly the following data is required:
   > FETAL01.dta-FETAL12.dta: raw fetal death records from INEGI
   > MunicipalBirths.dta: total population at a state level by time

 contact: mailto:damian.clarke@economics.ox.ac.uk

Major versions
   > v0.00: Creates fetal mortality at a municipal level
*/

vers 11
clear all
set more off
cap log close
set matsize 10000

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT  "~/database/MexDemografia/DefuncionesFetales"
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global MOR  "~/investigacion/2014/MexAbort/Data/Mortality"
global POP  "~/investigacion/2014/MexAbort/Data/Population"
global LOG  "~/investigacion/2014/MexAbort/Log"

log using "$LOG/fetalGenerate.txt", text replace

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc   /*
*/ totalout subsidies unemployment condom* any* adolescentKnows 

local popName Chihuahua Sonora Coahuila Durango Oaxaca Tamaulipas Jalisco     /*
*/ Zacatecas BajaCaliforniaSur Chiapas Veracruz BajaCalifornia NuevoLeon      /*
*/ Guerrero SanLuisPotosi Michoacan Campeche Sinaloa QuintanaRoo Yucatan      /*
*/ Puebla Guanajuato Nayarit Tabasco Mexico Hidalgo Queretaro Colima          /*
*/ Aguascalientes Morelos Tlaxcala DistritoFederal
local popNum 8 26 5 10 20 28 14 32 3 7 30 2 19 12 24 16 4 25 23 31 21 11 18 27 /*
*/ 15 13 22 6 1 17 29 9

local import 1
local mergeB 1
local stateG 1

********************************************************************************
*** (2) Import mortality, rename
********************************************************************************
if `import'==1 {
	foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 {
		dis "Appending `yr'"
		append using "$DAT/FETAL`yr'.dta"
		keep ent_regis mun_regis ent_ocurr mun_ocurr sex_prod eda_prod dia_ocur   /*
    */ mes_ocurr anio_ocur eda_madr
	}

  replace ent_ocurr=ent_regis if mun_ocurr==999
  replace mun_ocurr=mun_regis if mun_ocurr==999
  drop ent_regis mun_regis

  gen fetalDeath=1
  gen earlyTerm=eda_prod<=20
  gen lateTerm=eda_prod>20
	collapse (sum) fetalDeath early late, by(ent_oc mun_oc mes_oc anio_oc eda_ma)

	rename eda_ma Age
	rename ent_ocurr StateNum
	rename mun_ocurr MunNum
	rename anio_ocur year
	rename mes_ocurr month

	tostring StateNum, gen(entN)
	gen length=length(entN)
	gen zero="0" if length==1
	egen stateid=concat(zero entN)
	drop length zero entN

	tostring MunNum, gen(munN)
	gen length=length(munN)
	gen zero="0" if length==2
	replace zero="00" if length==1
	egen munid=concat(zero munN)
	drop length zero munN

	egen id=concat(stateid munid)
	label data "Count of Fetal Deaths by age, municipality and month"
	save "$MOR/FetalMunicip.dta", replace
}

********************************************************************************
*** (3) Merge with birth data
********************************************************************************
if `mergeB'==1 {
	use "$MOR/FetalMunicip.dta"
	drop if year>2011
	drop if Age<15|Age>49
	merge 1:1 id Age year month using "$BIR/MunicipalBirths"

  drop if _merge==1

	replace fetalDeath=0 if _merge==2
  replace earlyTerm =0 if _merge==2
  replace lateTerm  =0 if _merge==2
 	drop _merge
	
	label data "Data on fetal deaths linked with births and population"
	save "$MOR/FDeathMunicip.dta", replace
}

********************************************************************************
*** (4) Generate State file
********************************************************************************
if `stateG' {
	use "$MOR/FDeathMunicip.dta", clear

	replace medicalstaff=. if MedMissing==1
	replace planteles=. if plantelesMissing==1
	replace laboratorios=. if laboratoriosMissing==1
	replace aulas=. if aulasMissing==1
	replace bibliotecas=. if bibliotecasMissing==1
	replace talleres=. if talleresMissing==1

	collapse medicalstaff planteles aulas bibliotecas totalinc totalout condom*  /*
	*/ subsidies unemploym any* adolescentKno (sum) birth fetalDeath early late, /*
	*/ by(stateid year month Age) fast

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
	merge 1:1 stateName Age month year using "$POP/populationStateYearMonth1549.dta"
	drop if year<2001|year>2010&year!=.
	drop _merge
	
	gen yearmonth= year + (month-1)/12
	gen birthrate  = birth/imputePop
	gen Fdeathrate = fetalDeath/birth
	gen lFdeathrate = earlyTerm/birth
	gen eFdeathrate = lateTerm/birth
	gen DF=stateNum=="32"

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


	label data "Birth, fetal death data and covariates at level of State*Month*Age"
	save "$MOR/FDeathState.dta", replace
}


********************************************************************************
*** (X) Close
********************************************************************************
log close
