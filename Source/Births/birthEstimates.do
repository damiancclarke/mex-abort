/* birthEstimates v2.00              DCC/HM                yyyy-mm-dd:2014-09-15
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file uses data generated in the file birthGenerate.do, and runs difference-
in-differences regressions examining the effect of the Mexico April 2007 aborti-
on reform on births.  The regression takes the following format:

births_jst = a + b*f(t) + c*loc_js + d*reform + e*X_js + f*X_s + u

  where:
    births_jst are the quantity of births in municipality j, state s and month t
    f(t) is a flexible measure of time (FE and trends)
    loc_js are municipality FEs
    reform takes the value of 1 in locations and time where the reform ocurred
    X_js are municipality-level time varying controls, and
    X_s are state-level time varying controls

Descriptive statistics are presented including plots of births and birth rates
over time between DF and other municipalities/states.

We also examine spillover effects by looking at regions close to the reform. Th-
is consists (for now) of controlling for all of Mexico as the close region, how-
ever going forward will be determined much more precisely based on distance and
costs and opportunities to access the reform.

Along with the main regressions for each age group, a series of placebo tests a-
re run.  This consists of using the entire pre-reform period, and comparing the
reform regions with the non-reform regions to test the parallel trends assumpti-
ons required for consistent identification.

The file can be controlled in section 1 which requires a group of globals and l-
ocals defining locations of key data sets and specification decisions.  Current-
ly the following data is used:
   > MunicipalBirths.dta 
   > StateBirths.dta 

    contact: mailto:damian.clarke@economics.ox.ac.uk


Past major versions
   > v0.00: Ran logit of birth versus no birth.  This only works at state level
   > v1.00: Ran number of births at municipal level (OLS)
   > v2.00: Remove generating code and just run regressions and descriptives

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global REG  "~/investigacion/2014/MexAbort/Results/Births/Regressions"
global LOG  "~/investigacion/2014/MexAbort/Log"
global GRA  "~/investigacion/2014/MexAbort/Results/Births/Graphs"

cap mkdir "$REG"
cap mkdir "$GRA"
cap mkdir "$GRA/months"
cap mkdir "$GRA/years"

log using $LOG/birthEstimates.txt, text replace

local FE i.stateid i.year#i.month 
local tr i.stateid#c.linear
local se cluster(stateid)
local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc /*
*/ totalout subsidies unemployment


local desc    0
local reg     0
local event   0
local trend   0

local Mtrend  1

********************************************************************************
*** (1b) Data and Specific Decisions
********************************************************************************
use "$BIR/StateBirths.dta"
keep if yearmonth>=2001&yearmonth<=2010

gen ageGroup=.
replace ageGroup=1 if Age>=15&Age<20
replace ageGroup=2 if Age>=20&Age<30
replace ageGroup=3 if Age>=30&Age<40
replace ageGroup=4 if Age>=40&Age<49

label define a 1 "15-19" 2 "20-29" 3 "30-39" 4 "40+"
label values ageGroup a

********************************************************************************
*** (2) Descriptive graphs
********************************************************************************
if `desc'==1 {
	preserve
	collapse birthrate (sum) birth, by(DF yearmonth year Age)
	foreach age of numlist 15(1)49 {
		dis "Graphing for Age `age'"
		twoway line birthrate yearmonth if DF==1&Age==`age', scheme(s1color)   ///
	  	  ||   line birthrate yearmonth if DF==0&Age==`age', xline(2008)     ///
		  xline(2007.3, lpat(dash)) legend(label(1 "DF") label(2 "Not DF"))    ///
		  title("Birthrate for Age `age'") xlabel(2001[1]2011)
		graph export "$GRA/months/births`age'.eps", as(eps) replace
		twoway line birth yearmonth if DF==1&Age==`age', yaxis(1)               ///
	  	  || line birth yearmonth if DF==0&Age==`age', yaxis(2)               ///
		  scheme(s1color) xline(2008) xline(2007.3, lpat(dash))                 ///
		  legend(label(1 "DF") label(2 "Not DF"))                               ///
		  title("Number of Births for Age `age'") xlabel(2001[1]2011)
		graph export "$GRA/months/birthsNum`age'.eps", as(eps) replace
	}

	collapse birthrate (sum) birth, by(DF year Age)
	foreach age of numlist 15(1)49 {
		dis "Graphing for Age `age'"
		twoway line birthrate year if DF==1&Age==`age', scheme(s1color)      ///
	  	  ||   line birthrate year if DF==0&Age==`age', xline(2008)        ///
		    legend(label(1 "DF") label(2 "Not DF"))                          ///
		  title("Birthrate for Age `age'") xlabel(2001[1]2011)
		graph export "$GRA/years/births`age'.eps", as(eps) replace
		twoway line birth year if DF==1&Age==`age', yaxis(1)                  ///
	  	  || line birth year if DF==0&Age==`age', yaxis(2)                  ///
		  scheme(s1color) xline(2008) legend(label(1 "DF") label(2 "Not DF")) ///
		  title("Number of Births for Age `age'") xlabel(2001[1]2011)
		graph export "$GRA/years/birthsNum`age'.eps", as(eps) replace
	}
  restore

	preserve
	collapse birthrate (sum) birth, by(DF yearmonth year ageGroup)
  local upage 19 29 39 45
  tokenize `upage'

	foreach ageG of numlist 1(1)4 {
      if `ageG'==1 local lb=15
      if `ageG'==2 local lb=20
      if `ageG'==3 local lb=30
      if `ageG'==4 local lb=40

		dis "Graphing for AgeGroup `lb' to ``ageG''"
		twoway line birthrate yearmonth if DF==1&ageGroup==`ageG', xline(2008)   ///
	  	|| line birthrate yearmonth if DF==0&ageGroup==`ageG', scheme(s1color) ///
		  xline(2007.3, lpat(dash)) legend(label(1 "DF") label(2 "Not DF"))      ///
		  title("Birthrate for Age Group `lb' to ``ageG''") xlabel(2001[1]2010)
		graph export "$GRA/months/Groupbirths`lb'-``ageG''.eps", as(eps) replace

    twoway line birth yearmonth if DF==1&ageGroup==`ageG', yaxis(1)   ///
	 	  || line birth yearmonth if DF==0&ageGroup==`ageG',   yaxis(2)   ///
		  scheme(s1color) xline(2008) xline(2007.3, lpat(dash))           ///
		  legend(label(1 "DF") label(2 "Not DF")) xlabel(2001[1]2010)     ///
		  title("Number of Births for Age Group `lb' to ``ageG''")
		graph export "$GRA/months/GroupbirtshNum`lb'-``ageG''.eps", as(eps) replace
	}

 	collapse birthrate (sum) birth, by(DF year ageGroup)
  tokenize `upage'
	foreach ageG of numlist 1(1)4 {
      if `ageG'==1 local lb=15
      if `ageG'==2 local lb=20
      if `ageG'==3 local lb=30
      if `ageG'==4 local lb=40

		dis "Graphing for AgeGroup `lb' to ``ageG''"
		twoway line birthrate year if DF==1&ageGroup==`ageG', xline(2008)    ///
	  	|| line birthrate year  if DF==0&ageGroup==`ageG', scheme(s1color) ///
		  legend(label(1 "DF") label(2 "Not DF"))                            ///
		  title("Birthrate for Age Group `lb' to ``ageG''") xlabel(2001[1]2010)
		graph export "$GRA/years/Groupbirths`lb'-``ageG''.eps", as(eps) replace

    twoway line birth year if DF==1&ageGroup==`ageG', yaxis(1)                 ///
	 	  ||   line birth year if DF==0&ageGroup==`ageG',   yaxis(2)               ///
		  scheme(s1color) xline(2008) legend(label(1 "DF") label(2 "Not DF"))      ///
		  title("Number of Births for Age Group `lb' to ``ageG''") xlabel(2001[1]2010)
		graph export "$GRA/years/GroupbirtshNum`lb'-``ageG''.eps", as(eps) replace
	}
  restore
}

if `trend'==1 {
    cap mkdir "$GRA/States"
    local sta $GRA/States
    preserve
    collapse birthrate (sum) birth, by(state DF yearmonth ageGroup)
    local upage 19 29 39 45
    tokenize `upage'

    foreach ageG of numlist 1(1)4 {
        if `ageG'==1 local lb=15
        if `ageG'==2 local lb=20
        if `ageG'==3 local lb=30
        if `ageG'==4 local lb=40

        levelsof state, local(sname)
        foreach s of local sname {
            twoway line birthrate yearmonth if DF==1&ageGroup==`ageG',        ///
            || line birthrate yearmonth if state==`"`s'"'&ageGroup==`ageG',   ///
            xline(2007.3, lpat(dash)) legend(label(1 "DF") label(2 "`s'"))    ///
            title("Birthrate for Age Group `lb' to ``ageG''")                 ///
            xlabel(2001[1]2010) xline(2008) scheme(s1color)
            graph export "`sta'/Births_`s'_`lb'-``ageG''.eps", as(eps) replace
        }
    }
    restore
}

********************************************************************************
*** (3a) Regressions (month)
********************************************************************************
if `reg'==1 {
  cap rm "$REG/NumBirths.tex"
  cap rm "$REG/NumBirths.txt"  

  preserve
	collapse birthra (sum) birth `cont', by(DF yearmo year month ageGro stateid)
	gen Abortion      = DF==1&yearm>=2008
	gen AbortionClose = stateid=="15"&yearm>=2008
	destring stateid, replace

	bys stateid (year month): gen linear=_n
	foreach num of numlist 1(1)4 {

		reg birth `FE' Abortion* `cont' if ageG==`num', `se'
		outreg2 Abortion* using "$REG/NumBirths.tex", tex(pretty)
		reg birth `FE' `tr' Abortion* `cont' if ageG==`num', `se'
		outreg2 Abortion* using "$REG/NumBirths.tex", tex(pretty)
	}
	restore
}


********************************************************************************
*** (3b) Regressions (year)
********************************************************************************
if `reg'==1 {
    preserve
    collapse birthra (sum) birth `cont', by(DF year ageGro stateid)
    gen Abortion      = DF==1&year>=2008
    gen AbortionClose = stateid=="15"&year>=2008
    destring stateid, replace

    bys stateid (year): gen linear=_n
    local FE i.stateid i.year
    local tr i.stateid#c.linear
    local se cluster(stateid)

    foreach num of numlist 1(1)4 {
        
        reg birth `FE' Abortion* `cont' if ageG==`num', `se'
        outreg2 Abortion* using "$REG/NumBirths.tex", tex(pretty)
        reg birth `FE' `tr' Abortion* `cont' if ageG==`num', `se'
        outreg2 Abortion* using "$REG/NumBirths.tex", tex(pretty)
    }
    restore
}

    
if `event'==1 {
  cap rm "$REG/Event.tex"
  cap rm "$REG/Event.txt"  
    
  preserve
	collapse birthra (sum) birth `cont', by(DF yearmo year month ageGro stateid)
  foreach m of numlist 1(1)20 {
      gen Abortion_m`m' = DF==1&yearm>=(2007.75-(`m'/12))
  }
  foreach m of numlist 0(1)10 {
      gen Abortion_p`m' = DF==1&yearm>=(2007.75+(`m'/12))
  }
	destring stateid, replace

	bys stateid (year month): gen linear=_n
	foreach num of numlist 1(1)4 {

		reg birth `FE' Abortion* `cont' if ageG==`num', `se'
		outreg2 Abortion* using "$REG/Event.tex", tex(pretty)
		reg birth `FE' `tr' Abortion* `cont' if ageG==`num', `se'
		outreg2 Abortion* using "$REG/Event.tex", tex(pretty)
	}
	restore
}

********************************************************************************
*** (4) Municipal Analysis
********************************************************************************
use "$BIR/MunicipalBirths.dta", clear
keep if yearmonth>=2001&yearmonth<=2011

gen all=1
gen ageGroup=.
replace ageGroup=1 if Age>=15&Age<20
replace ageGroup=2 if Age>=20&Age<30
replace ageGroup=3 if Age>=30&Age<40
replace ageGroup=4 if Age>=40&Age<49

label define a 1 "15-19" 2 "20-29" 3 "30-39" 4 "40+"
label values ageGroup a

********************************************************************************
*** (4) Municipal Analysis
********************************************************************************
if `Mtrend'==1 {
    local cond all==1 metropolitan==1 metropolitan==1&metroPop>1000000 /*
    */ metropolitan==1&metroPop>500000
    local Cname All Metropolitan VeryLargeMetrop LargeMetrop
    tokenize `Cname'

    gen MexMetrop     = "Zona metropolitana del Valle de México"
    replace MexMetrop = 2 if state == "DISTRITO FEDERAL"

    foreach c of local cond {
        preserve
        keep if `c'
        collapse (sum) birth, by(year MexMetrop) 
        
         #delimit ;
        twoway line year birth if MexMetrop==2 || line year birth if MexMetrop==1
        || line year birth if MexMetrop==0, title("Births Per Year, `1'")
        ytitle("Number of Births") xtitle("Year") xline(2008, lpat(dash))
        scheme(s1mono) legend(label(1 "Mexico DF") label(2 "Mexico Metropolitan")
                              label(3 "Not Mexico City"));
        save "$GRA/MunicipalTrend_`c'.eps", as(eps) replace;
        #delimit cr
        restore
        macro shift
    }
}
********************************************************************************
*** (X) Clean
********************************************************************************
log close
