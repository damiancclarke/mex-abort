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
global OUT  "~/investigacion/2014/MexAbort/Results/Births"

cap mkdir $OUT

local sNname AguasCalientes BajaCalifornia BajaCaliforniaSur Campeche Chiapas /*
*/ Chihuahua Coahuila Colima DistritoFederal Durango Guanajuato Guerrero      /*
*/ Hidalgo Jalisco Mexico Michoacan Morelos Nayarit NuevoLeon Oaxaca Puebla   /*
*/ Queretaro QuintanaRoo SanLuisPotsi Sinaloa Sonora Tabasco Tamaulipas       /*
*/ Tlaxcala Veracruz Yucatan Zacatecas

********************************************************************************
*** (2) Import births, rename
********************************************************************************
foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 {
	dis "Appending `yr'"
	append using "$DAT/NACIM`yr'.dta"
}

foreach v of varlist mun_resid mun_ocurr {
	replace `v'=. if `v'==999
}
foreach v of varlist tloc_resid ent_ocurr edad_reg edad_madn edad_padn dia_nac  /*
*/ mes_nac dia_reg mes_reg edad_madr edad_padr orden_part hijos_vivo hijos_sobr {
	replace `v'=. if `v'==99
}
foreach v of varlist sexo tipo_nac lugar_part q_atendio edociv_mad escol_mad /*
*/ escol_pad act_mad act_pad fue_prese {
	replace `v'=. if `v'==99
}
replace ano_nac=. if ano_nac==9999
gen birth=1 if ano_nac==ano_reg

collapse (sum) birth (mean) edad_madr edad_pard edociv_mad escol_mad escol_pad /*
*/ act_mad act_pad hijos_vivo hijos_sobr, by(ent_ocurr ano_nac edad_madn)

rename edad_madn Age
rename ent_occur birthStateNum
rename ano_nac year

********************************************************************************
*** (3) Merge to population data (must rename states from popln to match)
********************************************************************************
tempfile births
save `births'

use "$DAT2/popStateYr1549LONG.dta"
gen birthStateNum=.
local nn=1

foreach SS of local sName {
	replace birthStateNum==`nn' if stateName==`SS'
	local ++nn
}

merge 1:1 birthStateNum year Age using "$DAT2/popStateYr1549LONG.dta" 




