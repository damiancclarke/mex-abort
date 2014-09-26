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

local day    0
local monAll 1
local monAge 1

********************************************************************************
*** (2) Open data, graph trends by day
********************************************************************************
foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 {
	dis "Appending `yr'" 
	append using "$DAT/NACIM`yr'.dta"
}
rename ent_ocurr birthStateNum
keep if birthStateNum<=32

gen Reform=1 if birthStateNum==9
replace Reform=2 if birthStateNum==15
replace Reform=0 if Reform==.&birthStateNum!=.
gen birth=1

drop if mes_nac==.
drop if ano_nac==9999|mes_nac==99|dia_nac==99

if `day'==1 {
	preserve

	collapse (sum) birth, by(dia_nac mes_nac ano_nac Reform)
	keep if ano_nac>=2001&ano_nac<2012
	generate birthday=mdy(mes_nac,dia_nac,ano_nac)

	twoway scatter birth birthday if Reform==0, yaxis(1) || /*
	*/ scatter birth birthday if Reform==1, yaxis(2) || /*
	*/ scatter birth birthday if Reform==2, yaxis(2) scheme(s1color) /*
	*/ legend(label(1 "No Reform") label(2 "Mexico DF") label(3 "Mexico State"))
	graph export "$GRA/AllbirthsReform.eps", as(eps) replace
	
	collapse (sum) birth, by(dia_nac mes_nac ano_nac)
	generate birthday=mdy(mes_nac,dia_nac,ano_nac)
	twoway scatter birth birthday, scheme(s1color)
	graph export "$GRA/Allbirths.eps", as(eps) replace

	restore
}
********************************************************************************
*** (3a) Graph trends by month (all)
********************************************************************************
if `monAll'==1 {
	preserve

	collapse (sum) birth, by(mes_nac ano_nac Reform)
	bys mes_nac Reform: egen monthMean=mean(birth) 
	gen birthDeMean=birth-monthMean
	keep if ano_nac>=2001&ano_nac<2010
	gen birthdate=ano_nac+(mes_nac-1)/12

	sort birthdate
	foreach bv in birth birthDeMean { 
	cap mkdir $GRA/Age/`bv'
	twoway line `bv' birthdate if Ref==0, yaxis(1) ylabel(120000[20000]180000) /*
	*/ ||  line `bv' birthdate if Ref==1, yaxis(2) || /*
	*/ line `bv' birthdate if Ref==2, yaxis(2) scheme(s1color) xline(2007.33) /*
	*/ legend(label(1 "No Reform") label(2 "Mexico DF") label(3 "Mexico State")) /*
	*/ note("Left hand y-axis is for all States. Right hand axis is for DF/Mexico")
	graph export "$GRA/`bv'/AllbirthsReformMonth.eps", as(eps) replace

	twoway line `bv' birthdate if Ref==0, yaxis(1) ylabel(120000[20000]180000) /*
	*/ || line `bv' birthdate if Ref==1, yaxis(2) scheme(s1color) xline(2007.33) /*
	*/ legend(label(1 "No Reform") label(2 "Mexico DF")) /*
	*/ note("Left hand y-axis is for all States. Right hand axis is for DF")
	graph export "$GRA/`bv'/AllbirthsReformMonthDF.eps", as(eps) replace

	collapse (sum) birth, by(mes_nac ano_nac)
	gen birthdate=ano_nac+(mes_nac-1)/12
	twoway scatter birth birthdate, scheme(s1color)
	graph export "$GRA/AllbirthsMonth.eps", as(eps) replace
	restore
}

********************************************************************************
*** (3b) Graph trends by month (by age)
********************************************************************************
if `monAge'==1 {
	cap mkdir $GRA/Age
	preserve

	collapse (sum) birth, by(mes_nac ano_nac Reform edad_madn)
	bys mes_nac Reform edad_madn: egen monthMean=mean(birth) 
	gen birthDeMean=birth-monthMean

	keep if ano_nac>=2001&ano_nac<2010
	gen birthdate=ano_nac+(mes_nac-1)/12

	sort birthdate
	foreach bv in birth birthDeMean { 
	cap mkdir $GRA/Age/`bv'

	foreach a of numlist 15(1)40 {
		twoway line `bv' birthdate if Ref==0&edad_madn==`a', yaxis(1) /*
		*/ ||  line `bv' birthdate if Ref==1&edad_madn==`a', yaxis(2) || /*
		*/ line `bv' birthdate if Ref==2&edad_madn==`a', yaxis(2) scheme(s1color) /*
		*/ xline(2007.33) /*
		*/ legend(label(1 "No Reform") label(2 "Mexico DF") label(3 "Mexico State")) /*
		*/ note("Left hand axis is for all States. Right hand is for DF/Mexico")
		graph export "$GRA/Age/`bv'/Month`a'.eps", as(eps) replace
	}

	foreach  a of numlist 15(1)40 {
		twoway line `bv' birthdate if Ref==0&edad_madn==`a', yaxis(1) /*
		*/ || line `bv' birthdate if Ref==1&edad_madn==`a', yaxis(2)  /*
		*/ scheme(s1color) xline(2007.33) /*
		*/ legend(label(1 "No Reform") label(2 "Mexico DF")) /*
		*/ note("Left hand y-axis is for all States. Right hand axis is for DF")
		graph export "$GRA/Age/`bv'/MonthDF`a'.eps", as(eps) replace
	}
	}	
	restore
}
