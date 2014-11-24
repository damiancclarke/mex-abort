/* fetalEstimates v1.00              DCC/HM                yyyy-mm-dd:2014-11-24
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

This file uses data generated in the file fetalGenerate.do and runs diff-in-diff
regressions examining the effect of the Mexico April 2007 abortion reform on fe-
tal deaths.  The regression takes the following format:

FD_jst = a + b*f(t) + c*loc_js + d*reform_jst + e*X_js + f*X_s + u_jst

  where:
    FD_jst are the quantity of fetal deaths in municip j, state s and month t
    f(t) is a flexible measure of time (FE and trends)
    loc_js are municipality FEs
    reform takes the value of 1 in locations and time where the reform ocurred
    X_js are municipality-level time varying controls, and
    X_s are state-level time varying controls

where FD is measured as all fetal deaths, late term fetal deaths, and early term
fetal deaths.  Descriptive statistics are presented including plots of fetal de-
aths and rates (fetal deaths divided by total number of births) over time between
DF and other municipalities/states.

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
   > FDeathMunicip.dta 
   > FDeathState.dta 

    contact: mailto:damian.clarke@economics.ox.ac.uk


Past major versions
   > v0.00: Fetal death regressions and plots

NOTES:
For now only use sections 1-3.  Sections 4 and 5 need to be revised.
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global MOR  "~/investigacion/2014/MexAbort/Data/Mortality"
global REG  "~/investigacion/2014/MexAbort/Results/Mortality/Regressions/Fetal"
global LOG  "~/investigacion/2014/MexAbort/Log"
global GRA  "~/investigacion/2014/MexAbort/Results/Mortality/Graphs/Fetal"

cap mkdir "$GRA"
cap mkdir "$REG"

log using "$LOG/fetalEstimates.txt", text replace

local cc cluster(stateid)
local FE i.stateid i.year#i.month
local tr i.stateid#c.linear
local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc /*
*/ totalout subsidies unemployment

foreach usado in eclplot parmby {
	cap which `usado'
	if _rc!=0 ssc install `usado'
}

**SWITCHES
local desc    1
local reg     1
local placebo 0
local plot    0

********************************************************************************
*** (2) Basic set up as base for all regressions
********************************************************************************
use "$MOR/FDeathState.dta"

keep if year<2011&year>2002

gen ageGroup=.
replace ageGroup=1 if Age>=15&Age<20
replace ageGroup=2 if Age>=20&Age<30
replace ageGroup=3 if Age>=30&Age<40
replace ageGroup=4 if Age>=40&Age<50

label define a 1 "15-19" 2 "20-29" 3 "30-39" 4 "40-49" 
label values ageGroup a

********************************************************************************
*** (2) Descriptive graphs
********************************************************************************
if `desc'==1 {
  foreach y of varlist fetalDeath earlyTerm lateTerm {
     if `"`y'"'=="fetalDeath" local name "All"
     if `"`y'"'=="earlyTerm" local name "Early Term"
     if `"`y'"'=="lateTerm"  local name "Late Term"

     preserve
     collapse (sum) `y', by(DF year ageGroup)

     foreach ageG of numlist 1(1)4 {
       if `ageG'==1 local name "15 to 19"
       if `ageG'==2 local name "20 to 29"
       if `ageG'==3 local name "30 to 39"
       if `ageG'==4 local name "40 to 49"
		
       twoway line `y' year if DF==1&ageGroup==`ageG', yaxis(1)          ///
	  	  || line `y' year if DF==0&ageGroup==`ageG', yaxis(2)             ///
		    scheme(s1color) xline(2008) xline(2007.3, lpat(dash))            ///
		    legend(label(1 "DF") label(2 "Not DF"))                          ///
		    title("Number of Fetal Deaths (`name') for Age Group `name'")
       graph export "$GRA/FDeaths`ageG'_`y'.eps", as(eps) replace
    }
    restore
	
    preserve
    collapse (sum) `y', by(DF year)
    label var `y' "Number of Fetal Deaths"

     twoway line `y' year if DF==1, yaxis(1) || line `y' year if DF==0,  ///
	    yaxis(2) scheme(s1color) xline(2008) xline(2007.3, lpat(dash))     ///
	    xtitle("Year of Register") legend(label(1 "DF") label(2 "Not DF")) ///
	    title("Number of Fetal Deaths (`name')")
	  graph export "$GRA/FDeaths_`y'.eps", as(eps) replace
	  restore
  }
}

********************************************************************************
*** (3) Regressions
********************************************************************************
if `reg'==1 {
    cap rm "$REG/numFetDeath.tex"
    cap rm "$REG/numFetDeath.txt"

    foreach y of varlist fetalDeath earlyTerm lateTerm {
      preserve
      collapse `cont' (sum) `y', by(DF yearmo year month ageGroup stateid)
      gen Abortion      = DF==1&year>2007
      gen AbortionClose = stateid=="15"&year>2007
      destring stateid, replace

      local cc cluster(stateid)
      bys stateid (year month): gen linear=_n
      foreach num of numlist 1(1)4 {
          reg `y' `FE' `tr' `cont' Abortion `cont' if ageG==`num', `cc'
          outreg2 Abortion* using "$REG/numFetDeath.tex", tex(pretty)
      }
      restore
  }
}

exit
********************************************************************************
*** (4) Placebo regressions
********************************************************************************
if `placebo'==1 {
	global P "$REG/Placebo"
	local files
	preserve

	collapse Mdeathra `cont' (sum) MMR, by(DF yearmo year month ageGroup stateid)
	bys stateid (year month): gen linear=_n
	gen Abortion      = DF==1&year>2008
	gen AbortionClose = stateid=="15"&year>2008
	destring stateid, replace
	drop if ageGroup==.
	
	foreach n of numlist 4 5 6 7 {
		foreach m of numlist 1(2)11 {
			cap rm "$P/Placebo200`n'_`m'.dta"
			
			local time = 200`n'+(`m'-1)/12
			dis "Time is `time'"

			gen Placebo`n'_`m'      = stateid==9&yearmonth>200`n'+(`m'-1)/12
			gen PlaceboClose`n'_`m' = stateid==15&yearmonth>200`n'+(`m'-1)/12
			replace Placebo`n'_`m'       = . if year>=2008
			replace PlaceboClose`n'_`m'  = . if year>=2008
	
			parmby "reg Mdeathrate `FE' `tr' `cont' Placebo* , `cc'", by(ageGroup) /*
			*/ saving("$P/Placebo200`n'_`m'.dta", replace)
			local files `files' "$P/Placebo200`n'_`m'.dta"
			drop Place*
		}
	}
	parmby "reg Mdeathrate `FE' `tr' `cont' Abort* , `cc'", by(ageGroup) /*
	*/ saving("$P/Treat.dta", replace)

	clear
	append using `files' "$P/Treat.dta"
	save "$P/AgeGroupPlacebos", replace
	restore
}

********************************************************************************
*** (5) Plot main results by age group and age
********************************************************************************
if `plot'==1 {
	preserve
	use "$REG/Placebo/AgeGroupPlacebos", clear
	gen keep=regexm(parm, "Plac|Abor")
	keep if keep==1
	eclplot est min max ageGroup if parm=="Abortion", scheme(s1color)
	graph export "$GRA/AgeGroupResults.eps", as(eps) replace

	gen time=.
	foreach n1 of numlist 4(1)7{
		foreach n2 of numlist 1(2)11 {
			replace time=2000+`n1'+(`n2'-1)/12 if parm=="Placebo`n1'_`n2'"
		}
	}
	replace time=2008 if parm=="Abortion"
	foreach g in 1 2 3 4 {
		eclplot est min max time if ageGroup==`g', scheme(s1color) yline(0) /*
		*/ title("Age Group `g'")
		graph export "$GRA/PlaceboResult_Age`g'.eps", as(eps) replace		
	}
	restore
}

********************************************************************************
*** (X) Clean
********************************************************************************
log close
