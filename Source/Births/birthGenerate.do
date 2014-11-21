/* birthGenerate v0.00              DCC/HM                 yyyy-mm-dd:2014-10-17
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

This script genrates a number of output files based on birth data and covariates 
produced from the script municipPrep.py as well as population data produced from
poplnPrep.do and contraceptive data from contracepPrep.do.  It produces the fol-
lowing four files:

	> MunicipalBirths.dta
	> StateBirths.dta
	> MunicipalBirths_deseason.dta
	> StateBirths_deseason.dta

where the difference between each file is the level of aggregation (State is hi-
gher than Municipal), and whether or not births are deseasoned to remove regular 
monthly variation.

There is also another version which can be run if the local `sameyear' is set to
1. The sameyear version produces the same output, but only includes births regi-
stered in the same year, and the year following the year of birth. The reason to
do this is that we are concerned that for later year births, some may be unregi-
stered given that we only have files up until 2012. By restricting to only incl-
ude births registered in the same year and the year following the birth, this r-
esolves the issue, presuming that parental birth registering patterns do not ch-
ange over time.  If this local is set, the files will be produced as above, how-
ever will have "Sameyear" at the end of each name.

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


    contact: mailto:damian.clarke@economics.ox.ac.uk


Past major versions
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
global DAT2 "~/investigacion/2014/MexAbort/Data/Population"
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global OUT  "~/investigacion/2014/MexAbort/Results/Births"
global LOG  "~/investigacion/2014/MexAbort/Log"
global COV1 "~/investigacion/2014/MexAbort/Data/Municip"
global COV2 "~/investigacion/2014/MexAbort/Data/Labour/Desocupacion2000_2014"
global COV3 "~/investigacion/2014/MexAbort/Data/Contracep"

log using "$LOG/birthGenerate.txt", text replace

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc /*
*/ totalout subsidies unemployment condom* any* adolescentKnows 

foreach uswado in mergemany {
	cap which `uswado'
	if _rc!=0 ssc install `uswado'
}

local lName aguascalientes baja_california baja_california_sur campeche       /*
*/ coahuila_de_zaragoza colima chiapas chihuahua distrito_federal durango     /*
*/ guanajuato guerrero hidalgo jalisco mexico michoacan_de_ocampo morelos     /*
*/ nayarit nuevo_leon oaxaca puebla queretaro quintana_roo san_luis_potosi    /*
*/ sinaloa sonora tabasco tamaulipas tlaxcala veracruz_de_ignacio_de_la_llave /*
*/ yucatan zacatecas
local popName Chihuahua Sonora Coahuila Durango Oaxaca Tamaulipas Jalisco     /*
*/ Zacatecas BajaCaliforniaSur Chiapas Veracruz BajaCalifornia NuevoLeon      /*
*/ Guerrero SanLuisPotosi Michoacan Campeche Sinaloa QuintanaRoo Yucatan      /*
*/ Puebla Guanajuato Nayarit Tabasco Mexico Hidalgo Queretaro Colima          /*
*/ Aguascalientes Morelos Tlaxcala DistritoFederal
local popNum 8 26 5 10 20 28 14 32 3 7 30 2 19 12 24 16 4 25 23 31 21 11 18 27 /*
*/ 15 13 22 6 1 17 29 9

local covPrep  0
local rural    1
local import   0
local mergeCV  0
local mergeB   1
local Mdetrend 0
local stateG   1
local Sdetrend 0

local sameyear 0
if `sameyear'==1 local app Sameyear

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

   *expand so one cell for each age 15-49 (expensive)
	expand 35
	bys id year month: gen Age=_n+14
	save "$BIR/BirthCovariates", replace
}

********************************************************************************
*** (2c) Import births, rename
********************************************************************************
if `import'==1 {
	foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 {
		dis "Appending `yr'"
		append using "$DAT/NACIM`yr'.dta"
	}

	foreach v of varlist mun_resid mun_ocurr {
		replace `v'=. if `v'==999
	}
	foreach v of varlist tloc_resid ent_ocurr edad_reg edad_madn edad_padn dia_nac/*
	*/ mes_nac dia_reg mes_reg edad_madr edad_padr orden_part hijos_vivo hijos_sobr {
		replace `v'=. if `v'==99
	}
	foreach v of varlist sexo tipo_nac lugar_part q_atendio edociv_mad escol_mad /*
	*/ escol_pad act_mad act_pad fue_prese {
		replace `v'=. if `v'==99
	}
	replace ano_nac=. if ano_nac==9999

	gen birth=1 /*if ano_nac==ano_reg*/
	keep if ano_nac>=2001&ano_nac<2012


	drop if mun_ocurr==.
	drop if mes_nac==.

	if `sameyear'==1 keep if ano_nac==ano_reg|ano_nac==ano_reg-1
	
	if `"`period'"'=="Year" {
		collapse (sum) birth, by(ent_ocurr mun_ocurr ano_nac edad_madn)
	}
	else if `"`period'"'=="Month" {
		collapse (sum) birth, by(ent_ocurr mun_ocurr ano_nac mes_nac edad_madn)
		rename mes_nac month
	}

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
	save "$BIR/BirthsMonth`app'", replace
}

********************************************************************************
*** (2d) Generate rurality data from populations in birth data
********************************************************************************
if `rural'==1 {
    use "$DAT/NACIM12.dta"
    gen rural=tloc_regis <= 3
    collapse rural, by(ent_resid mun_resid)

    rename ent_resid birthStateNum
    rename mun_resid birthMunNum
    lab dat "Percent of localities which are rural by municipio (from births)"
    save "$DAT2/Rurality", replace
}

********************************************************************************
*** (2e) Merge with covariates, generate treatments
********************************************************************************
if `mergeB'==1 {
	use "$BIR/BirthsMonth`app'", clear
	drop if Age<15|(Age>49&Age!=.)
  merge m:1 birthStateNum birthMunNum using "$DAT2/Rurality"
  drop if _merge!=3
  drop _merge
  
  merge 1:1 id year month Age using "$BIR/BirthCovariates"
	replace birth=0 if _merge==2

	dis "note that in 39094 cases, the mother's age of birth isn't recorded"
	dis "These are lest in the dataset with age recorded as missing."
	drop _merge

	gen Abortion      = stateid=="09"&year>2008
	gen AbortionClose = stateid=="15"&year>2008
	gen yearmonth     = year+(month-1)/12

	label var birthStateNum "State identifier (numerical)"
	label var birthMunNum   "Municipal identifier (numerical)"
	label var Age           "Mother's age at birth"
	label var month         "Month of birth (1-12)"
	label var year          "Year of birth (2001-2011)"
	label var stateid       "State identifier (string)"
	label var munid         "Municipal identifier (string)"
	label var id            "Concatenation of state and municipal id (string)"
	label var state         "State name (in words)"
	label var municip       "Municipality name (in words)"
	label var medicalstaff  "Number of medical staff in the municipality"
	label var MedMissing    "Indicator for missing obs on medical staff"
	label var planteles     "Number of educational establishments in municipality"
	label var aulas         "Number of classrooms in municipality"
	label var bibliotecas   "Number of libraries in municipality"
	label var laboratorios  "Number of laboratories (study) in the municipality"
	label var talleres      "Number of workshops in the municipality"
	label var trimester     "Trimester of the year (I-IV)"
	label var unemployment  "Unemployment rate in the State"
	label var condomFirstTe "% teens reporting using condoms at first intercourse"
	label var condomRecentT "% teens reporting using condoms at recent intercourse"
	label var anyFirstTeen  "% of teens using any contraceptive method"
	label var adolescentKno "Percent of teens reporting knowing any contraceptives"
	label var condomRecent  "% of adults using condoms at recent intercourse"
	label var anyRecent     "% of adults using any contraceptive at recent intercou"
	label var Abortion      "Availability of abortion (1 in DF post reform)"
	label var yearmonth     "Year and month added together (numerical)"

	label data "Birth data and covariates at level of Municipality*Month*Age"
	drop if year>2010

  *******THIS SUBSETS TO ONLY REGIONAL*********
  keep if rural<=0.5
  *******THIS SUBSETS TO ONLY REGIONAL*********

  save "$BIR/MunicipalBirths`app'.dta", replace
}

********************************************************************************
*** (3) Deseason (de-month) municipal file
********************************************************************************
if `Mdetrend'==1 {
	use "$BIR/MunicipalBirths`app'.dta"
	drop if year>=2010
	tab month, gen(_Month)
	bys id Age: gen trend=_n

	gen birthdetrend=.
	drop _Month12

	levelsof id, local(SSid)
	foreach S of local SSid {
		foreach A of numlist 15(1)49 {
			dis "Detrending Age==`A' in Municipality `S'"

			reg birth _Month* trend if Age==`A'&id=="`S'"
			predict resid if Age==`A'&id=="`S'", r 
			sum birth if Age==`A'&id=="`S'"
			replace birthdetrend=`r(mean)'+resid if Age==`A'&id=="`S'"

			drop resid
		}
	}
	save "$BIR/MunicipalBirths_deseason`app'.dta", replace
}

********************************************************************************
*** (4) Generate State file
********************************************************************************
if `stateG' {
	use "$BIR/MunicipalBirths`app'.dta", clear

	replace medicalstaff=. if MedMissing==1
	replace planteles=. if plantelesMissing==1
	replace laboratorios=. if laboratoriosMissing==1
	replace aulas=. if aulasMissing==1
	replace bibliotecas=. if bibliotecasMissing==1
	replace talleres=. if talleresMissing==1

	collapse medicalstaff planteles aulas bibliotecas totalinc totalout condom* /*
	*/ subsidies unemployment any* adolescentKnows rural (sum) birth,           /*
	*/ by(stateid state year month Age) fast

	gen MedMissing         = medicalstaff ==.
	gen plantelesMissing   = planteles    ==.
	gen aulasMissing       = aulas        ==.
	gen bibliotecasMissing = bibliotecas  ==.
	
	replace medicalstaff  =0 if medicalstaff ==.
	replace planteles     =0 if planteles    ==.
	replace aulas         =0 if planteles    ==.
	replace bibliotecas   =0 if bibliotecas  ==.	
	
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
	merge 1:1 stateName Age month year using "$DAT2/populationStateYearMonth1549.dta"
	drop if year<2001|year>2010&year!=.
	drop _merge
	
	gen yearmonth= year + (month-1)/12
	gen birthrate  = birth/imputePop
	gen DF=stateNum=="32"

	label var DF            "Indicator for Mexico D.F."
	label var stateName     "State name from population data"
	label var stateNum      "State number (string) from population data"	
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


	label data "Birth data and covariates at level of State*Month*Age"
	save "$BIR/StateBirths`app'.dta", replace
}

********************************************************************************
*** (5) Deseason (de-month) State file
********************************************************************************
if `Sdetrend'==1 {
	use "$BIR/StateBirths`app'.dta"
	drop if year>=2010
	tab month, gen(_Month)
	bys stateid Age: gen trend=_n

	gen birthdetrend=.
	drop _Month12

	levelsof stateid, local(SSid)
	foreach A of numlist 15(1)49 {
		foreach S of local SSid {
			dis "Detrending Age==`A' in State `S'"

			reg birth _Month* trend if Age==`A'&stateid=="`S'"
			predict resid if Age==`A'&stateid=="`S'", r 
			sum birth if Age==`A'&stateid=="`S'"
			replace birthdetrend=`r(mean)'+resid if Age==`A'&stateid=="`S'"

			drop resid
		}
	}
	save "$BIR/StateBirths_deseason`app'.dta", replace
}


********************************************************************************
*** (X) Close
********************************************************************************
log close
