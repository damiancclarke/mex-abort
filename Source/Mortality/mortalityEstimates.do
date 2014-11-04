/* mortalityEstimates v1.00          DCC/HM                yyyy-mm-dd:2014-11-03
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

This file uses data generated in the file mortalityGenerate.do and runs diff-in-
diff regressions examining the effect of the Mexico April 2007 abortion reform
on maternal mortality.  The regression takes the following format:

MM_jst = a + b*f(t) + c*loc_js + d*reform + e*X_js + f*X_s + u

  where:
    MM_jst are the quantity of maternal deaths in municip j, state s and month t
    f(t) is a flexible measure of time (FE and trends)
    loc_js are municipality FEs
    reform takes the value of 1 in locations and time where the reform ocurred
    X_js are municipality-level time varying controls, and
    X_s are state-level time varying controls

Descriptive statistics are presented including plots of maternal deaths and rat-
es (marternal deaths divided by total number of births) over time between DF and
other municipalities/states.

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
   >
   >

    contact: mailto:damian.clarke@economics.ox.ac.uk


Past major versions
   > v0.00: Mortality per woman giving birth

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


local desc    1
local smooth  0
local reg     0

local newgen  0
local numreg  0
local placebo 0
local AgeGrp  0
local placGrp 0

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc /*
*/ totalout subsidies unemployment
local FE i.year#i.month
local trend StDum*
local se cluster(idNum)


********************************************************************************
*** (2) Descriptive graphs
********************************************************************************
if `desc'==1 {
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

	use "$MOR/StateDeaths", clear
	keep if year<2011&year>2002
	drop MMR
	rename materndeath MMR	

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
}

exit
********************************************************************************
*** (3) Regressions
********************************************************************************
if `reg'==1 {
	use "$BIR/StateBirths", clear
	keep if yearmonth<2010.5
	gen ageGroup=.
	foreach num of numlist 1(1)7 {
		local lb=10+`num'*5
		local ub=`lb'+5
		dis "Age Group `num' is between `lb' and `ub'"
		replace ageGroup=`num' if Age>=`lb'&Age<`ub'
	}
	label define a 1 "15-19" 2 "20-24" 3 "25-29" 4 "30-34" 5 "35-39" 6 "40-44" 7 "45+"
	label values ageGroup a

	collapse birthrate (sum) birth `cont', by(DF yearmonth year month ageGroup stateid)
	gen Abortion      = DF==1&year>2008
	gen AbortionClose = stateid=="15"&year>2008
	destring stateid, replace

	local cc cluster(stateid)
	bys stateid (year month): gen linear=_n
	foreach num of numlist 1(1)7 {
		reg birthrate i.stateid i.year#i.month Abortion* if ageG==`num', `cc'
		reg birthrate i.stateid i.year#i.month i.stateid#c.linear Abortion* /*
		*/ if ageG==`num', `cc'
		outreg2 Abortion* using "$REG/rateNoControls.tex", tex(pretty)
		reg birthrate i.stateid i.year#i.month i.stateid#c.linear Abortion* `cont' /*
		*/ if ageG==`num', `cc'
		outreg2 Abortion* using "$REG/rateControls.tex", tex(pretty)
		reg birth i.stateid i.year#i.month Abortion* if ageG==`num', `cc'
		reg birth i.stateid i.year#i.month i.stateid#c.linear Abortion* /*
		*/ if ageG==`num', `cc'
		outreg2 Abortion* using "$REG/NumNoControls.tex", tex(pretty)
		reg birth i.stateid i.year#i.month i.stateid#c.linear Abortion* `cont' /*
		*/ if ageG==`num', `cc'
		outreg2 Abortion* using "$REG/NumControls.tex", tex(pretty)
	}
}

exit


********************************************************************************
*** (6) Generate treatment and trends
********************************************************************************
if `newgen'==1 {

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
	
	parmby "areg birth `FE' `cont' Abort*, absorb(idNum) `se'", by(Age) /*
	*/ saving("$OUT/MFE.dta", replace)
	parmby "areg birth `FE' `trend' `cont' Abort*, absorb(idNum) `se'", by(Age) /*
	*/ saving("$OUT/MFET.dta", replace)
}

if `AgeGrp'==1 {
	use "$BIR/BirthsMonthCovariates"
	keep if Age<=40&Age>14
	
	destring id, gen(idNum)
	gen AgeGroup=1 if Age>=15&Age<20
	replace AgeGroup=2 if Age>=20&Age<25
	replace AgeGroup=3 if Age>=25&Age<30
	replace AgeGroup=4 if Age>=30

	collapse (sum) birth (mean) Abort* `cont' idNum `trend', /*
	*/ by(AgeGroup stateid munid id year month)
	
	parmby "areg birth `FE' `cont' Abort*, absorb(idNum) `se'", by(AgeGroup) /*
	*/ saving("$OUT/MFEAgeG.dta", replace) 
	parmby "areg birth `FE' `trend' `cont' Abort*, absorb(idNum) `se'",  /*
	*/ by(AgeGroup) saving("$OUT/MFETAgeG.dta", replace)
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
		replace Placebo`n'       = . if year>=2008
		replace PlaceboClose`n'  = . if year>=2008

		parmby "areg birth `FE' `cont' Place*, absorb(idNum) `se'", by(Age) /*
		*/ saving("$P/MFE`n'.dta", replace) 
		parmby "areg birth `FE' `trend' `cont' Place*, absorb(idNum) `se'", /*
		*/ by(Age) saving("$P/MmFET`n'.dta", replace) 
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

	collapse (sum) birth (mean) `cont' idNum `trend', /*
	*/ by(AgeGroup stateid munid id year month yearmonth)

	foreach n of numlist 4 5 6 7 {
		foreach m of numlist 1(2)11 {
			cap rm "$P/MPlacFET_`n'_`m'.dta"
			
			local time = 200`n'+(`m'-1)/12
			dis "Time is `time'"

			gen Placebo`n'_`m'      = stateid=="09"&yearmonth>200`n'+(`m'-1)/12
			gen PlaceboClose`n'_`m' = stateid=="15"&year>200`n'
			replace Placebo`n'_`m'       = . if year>=2008
			replace PlaceboClose`n'_`m'  = . if year>=2008

			parmby "areg birth `FE' `trend' `cont' Place*, absorb(idNum) `se'", /*
			*/ by(Age) saving("$P/MPlacFET_`n'_`m'.dta", replace)
			local files `files' "$P/MPlacFET_`n'_`m'.dta"
			drop Place*
		}
	}
	clear
	append using `files'
	save "$P/AgeGroupPlacebos", replace
}


********************************************************************************
*** (9) Plot main results by age group and age
********************************************************************************
clear 
append using "$P/AgeGroupPlacebos" "$OUT/MFETAgeG.dta"
gen keep=regexm(parm, "Plac|Abor")
keep if keep==1
eclplot est min max AgeGroup if parm=="Abortion", scheme(s1color)
graph export "$OUT/AgeGroupResults.eps", as(eps) replace
!epstopdf "$OUT/AgeGroupResults.eps"

gen time=.
foreach n1 of numlist 4(1)7{
	foreach n2 of numlist 1(2)11 {
		replace time=2000+`n1'+(`n2'-1)/12 if parm=="Placebo`n1'_`n2'"
	}
}
replace time=2008 if parm=="Abortion"
foreach g in 1 2 3 4 {
	eclplot est min max time if AgeGroup==`g', scheme(s1color) yline(0) /*
	*/ title("Age Group `g'")
	graph export "$OUT/PlaceboResult_Age`g'.eps", as(eps) replace
	!epstopdf "$OUT/PlaceboResult_Age`g'.eps"
}

use "$OUT/MFET.dta", clear
keep if parm=="Abortion"|parm=="AbortionClose"
eclplot est min max Age if parm=="Abortion", scheme(s1color)
graph export "$OUT/DF_EstimatesAge.eps", as(eps) replace
eclplot est min max Age if parm=="AbortionClose", scheme(s1color)
graph export "$OUT/Mex_EstimatesAge.eps", as(eps) replace

********************************************************************************
*** (10) Import regression results and plot
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

********************************************************************************
*** (X) Clean
********************************************************************************
log close
