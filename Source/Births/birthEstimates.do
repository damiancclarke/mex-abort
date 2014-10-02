* birthEstimates v1.00              DCC/HM                 yyyy-mm-dd:2014-09-15
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

/* Combine birth data with population data to determine 1/0 outcome for each wo-
man living in each State.  Run weighted binary regression for birth against tre-
atment.

Note that period won't work for year.



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

cap mkdir $OUT
cap mkdir $LOG
log using $LOG/birthEstimates.txt, text replace

local sName Aguascalientes BajaCalifornia BajaCaliforniaSur Campeche Chiapas  /*
*/ Chihuahua Coahuila Colima DistritoFederal Durango Guanajuato Guerrero      /*
*/ Hidalgo Jalisco Mexico Michoacan Morelos Nayarit NuevoLeon Oaxaca Puebla   /*
*/ Queretaro QuintanaRoo SanLuisPotosi Sinaloa Sonora Tabasco Tamaulipas      /*
*/ Tlaxcala Veracruz Yucatan Zacatecas
local lName aguascalientes baja_california baja_california_sur campeche       /*
*/ coahuila_de_zaragoza colima chiapas chihuahua distrito_federal durango     /*
*/ guanajuato guerrero hidalgo jalisco mexico michoacan_de_ocampo morelos     /*
*/ nayarit nuevo_leon oaxaca puebla queretaro quintana_roo san_luis_potosi    /*
*/ sinaloa sonora tabasco tamaulipas tlaxcala veracruz_de_ignacio_de_la_llave /*
*/	yucatan zacatecas


local covars  0
local covmer  0
local import  0
local mercov  0
local newgen  0
local numreg  0
local placebo 0
local AgeGrp  1
local placGrp 0

local period Month
*local period Year

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc /*
*/ totalout subsidies unemployment
local FE i.idNum i.year#i.month
local trend StDum*
local se cluster(idNum)


********************************************************************************
*** (2a) Import covariate data (previous running of Python script)
********************************************************************************
if `covars'==1 {
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
if `covmer'==1 {
	mergemany 1:1 "$COV1/Doctors" "$COV1/EducInf" "$COV1/Income" /*
	*/ "$COV1/Spending", match(year month id) verbose
	keep if _merge_S==3&_merge_I==3&_merge_E==3
	drop _merge*
	gen stateid=substr(id,1,2)
	
	merge m:1 stateid year month using "$COV2/Labour"
	drop _merge
	save "$BIR/BirthCovariates", replace
}

********************************************************************************
*** (3) Import births, rename
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
	save "$BIR/Births`period'", replace
}

********************************************************************************
*** (4) Merge to population data (must rename states from popln to match)
********************************************************************************
*use "$DAT2/populationStateYearMonth1549.dta", clear
*gen birthStateNum=.
*local nn=1

*foreach SS of local sName {
*	dis "`SS'"
*	replace birthStateNum=`nn' if stateName==`"`SS'"'
*	local ++nn
*}

**tostring birthStateNum, gen(nid)
**gen length=length(nid)
**gen zero="0" if length==1
**egen stateid=concat(zero nid)
**drop nid length zero

**drop if year<2001|year>2011
**merge m:1 stateid year month using "$BIR/BirthCovariates"

**kill here


*merge 1:m birthStateNum Age year month using "$BIR/BirthsMonth" 
*drop if Age<15|Age>49


*keep if _merge==3
*drop _merge

********************************************************************************
*** (5) Merge to covariates
********************************************************************************
if `mercov'==1 {
	use "$BIR/BirthsMonth", clear
	merge m:1 id year month using "$BIR/BirthCovariates"
	replace birth=0 if _merge==2
	drop _merge
}

********************************************************************************
*** (6) Generate treatment and trends
********************************************************************************
if `newgen'==1 {
	gen Abortion      = stateid=="09"&year>2008
	gen AbortionClose = stateid=="15"&year>2008

	gen yearmonth     = year+(month-1)/12
	
	qui tab stateid, gen(StDum)
	qui foreach num of numlist 1(1)32 {
		replace StDum`num'= StDum`num'*year
	}

	label data "Full birth data collapsed by Municipality and Age, with covariates"
	save "$BIR/BirthsMonthCovariates", replace
}

********************************************************************************
*** (7) Run total number regressions
********************************************************************************
if `numreg'==1 {
	use "$BIR/BirthsMonthCovariates"
	keep if Age<=40&Age>14
	
	destring id, gen(idNum)
	
	parmby "reg birth `FE' `cont' Abort*, `se'", by(Age) saving("$OUT/MFE.dta") 
	parmby "reg birth `FE' `trend' `cont' Abort*, `se'", by(Age) saving("$OUT/MFET.dta") 
}

if `AgeGrp'==1 {
	use "$BIR/BirthsMonthCovariates"
	keep if Age<=40&Age>14
	
	destring id, gen(idNum)
	gen AgeGroup=1 if Age>=15&Age<20
	replace AgeGroup=2 if Age>=20&Age<25
	replace AgeGroup=3 if Age>=25&Age<30
	replace AgeGroup=4 if Age>=30

	collapse (sum) birth (mean) `controls' idNum year month `trend', /*
	*/ by(AgeGroup stateid munid id)
	
	parmby "reg birth `FE' `cont' Abort*, `se'", by(AgeGroup) /*
	*/ saving("$OUT/MFEAgeG.dta") 
	parmby "reg birth `FE' `trend' `cont' Abort*, `se'", by(AgeGroup) /*
	*/ saving("$OUT/MFETAgeG.dta") 
}



********************************************************************************
*** (8) Placebo regressions
********************************************************************************
if `placebo'==1 {
	use "$BIR/BirthsMonthCovariates", clear
	keep if Age<=40&Age>14
	cap mkdir "$OUT/Placebo"
	global P "$OUT/Placebo"
	
	destring id, gen(idNum)

	foreach n of numlist 4 5 6 {
		gen Placebo`n'      = stateid=="09"&year>200`n'
		gen PlaceboClose`n' = stateid=="15"&year>200`n'
		replace Placebo`n'       = . if year>2008
		replace PlaceboClose`n'  = . if year>2008

*		parmby "reg birth `FE' `cont' Place*, `se'", by(Age) /*
*		*/ saving("$P/MFE`n'.dta") 
		parmby "reg birth `FE' `trend' `cont' Place*, `se'", by(Age) /*
		*/ saving("$P/MmFET`n'.dta") 
		drop Place*
	}
}

if `placGrp'==1 {
	use "$BIR/BirthsMonthCovariates", clear
	keep if Age<=40&Age>14
	global P "$OUT/Placebo"
	local files
	
	destring id, gen(idNum)
	gen AgeGroup=1 if Age>=15&Age<20
	replace AgeGroup=2 if Age>=20&Age<25
	replace AgeGroup=3 if Age>=25&Age<30
	replace AgeGroup=4 if Age>=30

	collapse (sum) birth (mean) `controls' idNum year month `trend', /*
	*/ by(AgeGroup stateid munid id)

	foreach n of numlist 4 5 6 7 {
		foreach m of numlist 1(2)11 {
			local time = 200`n'+(`m'-1)/12
			dis "Time is `time'"
			gen Placebo`n'_`m'=stateid=="09"&yearmonth>200`n'+(`m'-1)/12
			gen PlaceboClose`n' = stateid=="15"&year>200`n'
			replace Placebo`n'       = . if year>2008
			replace PlaceboClose`n'  = . if year>2008

			parmby "reg birth `FE' `trend' `cont' Place*, `se'", by(Age) /*
			*/ saving("$P/MPlacFET_`n'_`m'.dta")
			local files `files' "$P/MPlacFET_`n'_`m'.dta"
		}
	}
	clear
	append using `files'
	save "$P/AgeGroupPlacebos", replace
}


********************************************************************************
*** (9) Plot main results by age
********************************************************************************
use "$OUT/MFET.dta"
keep if parm=="Abortion"|parm=="AbortionClose"
eclplot est min max Age if parm=="Abortion", scheme(s1color)
graph export "$OUT/DF_EstimatesAge.eps", as(eps) replace
eclplot est min max Age if parm=="AbortionClose", scheme(s1color)
graph export "$OUT/Mex_EstimatesAge.eps", as(eps) replace

********************************************************************************
*** (9) Import regression results and plot
********************************************************************************
clear
append using "$OUT/MFET.dta" "$P/MFET3.dta" "$P/MFET4.dta" "$P/MFET5.dta" "$P/MFET6.dta"
keep if parm=="Abortion"|parm=="AbortionClose"|parm=="Placebo3"| /*
*/ parm=="PlaceboClose3"|parm=="Placebo4"|parm=="PlaceboClose4"| /*
*/ parm=="PlaceboClose4"|parm=="Placebo5"|parm=="PlaceboClose5"| /*
*/ parm=="PlaceboClose5"|parm=="Placebo6"|parm=="PlaceboClose6"

gen year=2003 if parm=="PlaceboClose3"|parm=="Placebo3"
replace year=2004 if parm=="PlaceboClose4"|parm=="Placebo4"
replace year=2005 if parm=="PlaceboClose5"|parm=="Placebo5"
replace year=2006 if parm=="PlaceboClose6"|parm=="Placebo6"
replace year=2008 if parm=="AbortionClose"|parm=="Abortion"

keep if Age==25
eclplot est min max year if parm=="Placebo3"|parm=="Placebo4"|/*
*/ parm=="Placebo5"|parm=="Placebo6"|parm=="Abortion", scheme(s1color)
graph export "$OUT/DF_EstimatesPlacebo.eps", as(eps) replace

eclplot est min max year if parm=="PlaceboClose3"|parm=="PlaceboClose4"|/*
*/ parm=="PlaceboClose5"|parm=="PlaceboClose6"|parm=="AbortionClose", scheme(s1color)
graph export "$OUT/Mex_EstimatesPlacebo.eps", as(eps) replace 




/*
********************************************************************************
*** (4) Gen birth no birth
********************************************************************************
rename birth quantity1
gen quantity0=population-quantity1

reshape long quantity, i(stateNum stateName year Age) j(birth)
keep stateNum stateName year Age birth birthStateNum quantity

if `placebo'==1 {
	drop if year>2008
	gen Abortion=stateName=="DistritoFederal"&year>2004
	gen AbortionClose=stateName=="Mexico"&year>2004
}
else {
	gen Abortion=stateName=="DistritoFederal"&year>2008
	gen AbortionClose=stateName=="Mexico"&year>2008
}

********************************************************************************
*** (5) Regress
********************************************************************************
local se cluster(birthStateNum)
local wt [fw=quantity]

foreach AA of numlist 15(1)40 {
	dis "Logit for age = `AA' (no trend)"
	logit birth i.birthStateNum i.year Abort* if Age==`AA' `wt', `se'
}

qui tab birthStateNum, gen(StDum)
qui foreach num of numlist 1(1)31 {
	replace StDum`num'= StDum`num'*year
}

foreach AA of numlist 15(1)40 {
	dis "Logit for age = `AA' (trend)"
	logit birth i.year i.birthState StDum* Abort* if Age==`AA' `wt', `se'
}

gen AgeGroup=1 if Age>=15&Age<=19
replace AgeGroup=2 if Age>=20&Age<=24
replace AgeGroup=3 if Age>=25&Age<=29
replace AgeGroup=4 if Age>=30&Age<=34
replace AgeGroup=5 if Age>=35&Age<=39

drop StDum*
collapse (sum) quantity, by(stateName year AgeGroup birth* Abortion AbortionClose)

foreach AA of numlist 1(1)5 {
	dis "Logit for age group = `AA' (no trend)"
	logit birth i.birthStateNum i.year Abort* if AgeGroup==`AA' `wt', `se'
}

qui tab birthStateNum, gen(StDum)
qui foreach num of numlist 1(1)31 {
	replace StDum`num'= StDum`num'*year
}

foreach AA of numlist 1(1)5 {
	dis "Logit for age = `AA' (trend)"
	logit birth i.year i.birthState StDum* Abort* if AgeGroup==`AA' `wt', `se'
}
*/
