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
   > MunicipalDeaths.dta 
   > StateDeaths.dta 

    contact: mailto:damian.clarke@economics.ox.ac.uk


Past major versions
   > v0.00: Fetal death regressions and plots

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global MOR  "~/investigacion/2014/MexAbort/Data/Mortality"
global REG  "~/investigacion/2014/MexAbort/Results/Mortality/Regressions"
global LOG  "~/investigacion/2014/MexAbort/Log"
global GRA  "~/investigacion/2014/MexAbort/Results/Mortality/Graphs"

log using "$LOG/mortalityEstimates.txt", text replace

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
local desc    0
local reg     1
local placebo 0
local plot    1

********************************************************************************
*** (2) Basic set up as base for all regressions
********************************************************************************
use "$MOR/StateDeaths"

keep if year<2011&year>2002

gen ageGroup=.
replace ageGroup=1 if Age>=15&Age<20
replace ageGroup=2 if Age>=20&Age<30
replace ageGroup=3 if Age>=30&Age<40
replace ageGroup=4 if Age>=40&Age<50

gen trimester=.
replace trimester=1 if month>=1&month<4
replace trimester=2 if month>=4&month<7
replace trimester=3 if month>=7&month<10
replace trimester=4 if month>=10&month<13
gen yeart = year + (trimester-1)/4

gen semester=.
replace semester=1 if month>=1&month<7
replace semester=2 if month>=7&month<13
gen years = year + (semester-1)/2

label define a 1 "15-19" 2 "20-29" 3 "30-39" 4 "40-49" 
label values ageGroup a
drop MMR
rename materndeath MMR

********************************************************************************
*** (2) Descriptive graphs
********************************************************************************
if `desc'==1 {

	preserve
	collapse Mdeathrate (sum) MMR, by(DF years ageGroup)

	foreach ageG of numlist 1(1)4 {
		if `ageG'==1 local name "15 to 19"
		if `ageG'==2 local name "20 to 29"
		if `ageG'==3 local name "30 to 39"
		if `ageG'==4 local name "40 to 49"
		
		twoway line Mdeathrate year if DF==1&ageGroup==`ageG', xline(2008)    ///
	  	  || line Mdeathrat year if DF==0&ageGroup==`ageG', scheme(s1color)   ///
		  xline(2007.3, lpat(dash)) legend(label(1 "DF") label(2 "Not DF"))   ///
		  title("Maternal Deaths per Live Birth for Age Group `name'")
		graph export "$GRA/GroupDeaths`ageG'.eps", as(eps) replace

		twoway line MMR year if DF==1&ageGroup==`ageG', yaxis(1)          ///
	  	  || line   MMR year if DF==0&ageGroup==`ageG', yaxis(2)          ///
		  scheme(s1color) xline(2008) xline(2007.3, lpat(dash))           ///
		  legend(label(1 "DF") label(2 "Not DF"))                         ///
		  title("Number of Maternal Deaths for Age Group `name'")
		graph export "$GRA/GroupDeathsNum`ageG'.eps", as(eps) replace
	}
	restore
	
	preserve
	collapse Mdeathrate (sum) MMR, by(DF years)
	label var MMR "Number of Maternal Deaths"

	twoway line Mdeathrate year if DF==1 || line Mdeathrate year if DF==0, ///
	  xline(2008) scheme(s1color) xline(2007.3, lpat(dash))                ///
	  legend(label(1 "DF") label(2 "Not DF"))                              ///
     title("Maternal Deaths per Live Birth")
	graph export "$GRA/GroupDeaths.eps", as(eps) replace

	twoway line MMR year if DF==1, yaxis(1) || line MMR year if DF==0,    ///
	  yaxis(2) scheme(s1color) xline(2008) xline(2007.3, lpat(dash))      ///
	  xtitle("Year of Register") legend(label(1 "DF") label(2 "Not DF"))  ///
	  title("Number of Maternal Deaths")
	graph export "$GRA/GroupDeathsNum.eps", as(eps) replace
	restore
}

********************************************************************************
*** (3) Regressions
********************************************************************************
if `reg'==1 {
	preserve
	collapse Mdeathra `cont' (sum) MMR, by(DF yearmo year month ageGroup stateid)
	gen Abortion      = DF==1&year>2008
	gen AbortionClose = stateid=="15"&year>2008
	destring stateid, replace

	local cc cluster(stateid)
	bys stateid (year month): gen linear=_n
	foreach num of numlist 1(1)4 {
		reg Mdeathrate `FE' `tr' `cont' Abortion* if ageG==`num', `cc'
		outreg2 Abortion* using "$REG/rateMatDeath.tex", tex(pretty)

		reg MMR        `FE' `tr' `cont' Abortion* `cont' /*
		*/ if ageG==`num', `cc'
		outreg2 Abortion* using "$REG/NumMatDeath.tex", tex(pretty)
	}
	restore
}

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
