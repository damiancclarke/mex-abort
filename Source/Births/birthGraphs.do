* birthGraphs.do v0.00           damiancclarke             yyyy-mm-dd:2014-09-21
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global BIR "~/investigacion/2014/MexAbort/Data/Births"
global GRA "~/investigacion/2014/MexAbort/Results/Graphs/Trends"
global DAT  "~/database/MexDemografia/Natalidades"

cap mkdir $GRA


********************************************************************************
*** (2) Open data, graph trends
********************************************************************************
foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 {
	dis "Appending `yr'" 
	append using "$DAT/NACIM`yr'.dta"
}

gen birth=1
drop if ano_nac==9999|mes_nac==99|dia_nac==99
collapse (sum) birth, by(dia_nac mes_nac ano_nac)

keep if ano_nac>=2001&ano_nac<2012
generate birthday=mdy(mes_nac dia_nac ano_nac)

twoway scatter birth birthday, scheme(s1color)
graph export "$GRA/Allbirths.eps", as(eps) replace
