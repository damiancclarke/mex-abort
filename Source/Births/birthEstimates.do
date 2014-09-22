* birthEstimates v0.00              DCC/HM                 yyyy-mm-dd:2014-09-15
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

/* Combine birth data with population data to determine 1/0 outcome for each wo-
man living in each State.  Run weighted binary regression for birth against tre-
atment.
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DIR  "~/investigacion/2014/MexAbort"
global DAT  "~/database/MexDemografia/Natalidades"
global DAT2 "~/investigacion/2014/MexAbort/Data/Population"
global DAT2 "~/investigacion/2014/MexAbort/Data/Population"
global BIR "~/investigacion/2014/MexAbort/Data/Births"
global OUT  "~/investigacion/2014/MexAbort/Results/Births"
global LOG  "~/investigacion/2014/MexAbort/Log"

cap mkdir $OUT
cap mkdir $LOG
log using $LOG/birthEstimates.txt, text replace

local sName Aguascalientes BajaCalifornia BajaCaliforniaSur Campeche Chiapas  /*
*/ Chihuahua Coahuila Colima DistritoFederal Durango Guanajuato Guerrero      /*
*/ Hidalgo Jalisco Mexico Michoacan Morelos Nayarit NuevoLeon Oaxaca Puebla   /*
*/ Queretaro QuintanaRoo SanLuisPotsi Sinaloa Sonora Tabasco Tamaulipas       /*
*/ Tlaxcala Veracruz Yucatan Zacatecas

local import 1
local placebo 0

local period Month
*local period Year
********************************************************************************
*** (2) Import births, rename
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
	gen birth=1 if ano_nac==ano_reg

	if `"`period'"'=="Year" {
		collapse (sum) birth (mean) edad_madr edad_padr edociv_mad escol_mad escol_pad/*
		*/ act_mad act_pad hijos_vivo hijos_sobr, by(ent_ocurr ano_nac edad_madn)
	}
	else if `"`period'"'=="Month" {
		collapse (sum) birth (mean) edad_madr edad_padr edociv_mad escol_mad escol_pad/*
		*/ act_mad act_pad hijos_vivo hijos_sobr, by(ent_ocurr ano_nac mes_nac edad_madn)
	}
	
	rename edad_madn Age
	rename ent_ocurr birthStateNum
	rename ano_nac year

	keep if year>=2001&year<2012
	save "$BIR/BirthsState`period'", replace
}

use "$BIR/BirthsStateYear"
gen Abortion=birthStateNum==9&year>2008
gen AbortionClose=birthStateNum==15&year>2008
foreach AA of numlist 15(1)40 {
	dis "Regression for age = `AA' (no trend)"
	reg birth i.birthStateNum i.year Abort* if Age==`AA' `wt', `se'
}
qui tab birthStateNum, gen(StDum)
qui foreach num of numlist 1(1)32 {
	replace StDum`num'= StDum`num'*year
}

foreach AA of numlist 15(1)40 {
	dis "Regression for age = `AA' (trend)"
	reg birth i.year i.birthState StDum* Abort* if Age==`AA' `wt', `se'
}
drop Abort* StDum*


********************************************************************************
*** (3) Merge to population data (must rename states from popln to match)
********************************************************************************
use "$DAT2/popStateYr1549LONG.dta", clear
gen birthStateNum=.
local nn=1

foreach SS of local sName {
	dis "`SS'"
	replace birthStateNum=`nn' if stateName==`"`SS'"'
	local ++nn
}

merge 1:1 birthStateNum year Age using "$BIR/BirthsStateYear" 
keep if _merge==3

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


