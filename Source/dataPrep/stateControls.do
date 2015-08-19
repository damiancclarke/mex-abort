/* stateControls.do              damiancclarke             yyyy-mm-dd:2015-07-19
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Controls at the level of state*year for Mexico from 2001 to 2013.  See notes in
stateData.txt for data sources.

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) globals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2014/MexAbort/Data/State"
global LOG "~/investigacion/2014/MexAbort/Log"
global SOR "~/investigacion/2014/MexAbort/Source/dataPrep"

log using "$LOG/stateControls.txt", text replace


*-------------------------------------------------------------------------------
*--- (2a) Format state income sheets
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir income
!ssconvert -S siha_2_1_1.xlsx income/years.csv
foreach num of numlist 6(1)18 {
    insheet using income/years.csv.`num', comma clear
    keep in 4/35
    keep v1 v13
    rename v1 stateName
    rename v13 totalIncome
    gen year = 1995+`num'
    tempfile f`num'
    save `f`num''
}

clear all
append using `f6' `f7' `f8' `f9' `f10' `f11' `f12' `f13' `f14' `f15' `f16' `f17' `f18'
save "$DAT/stateIncome", replace

*-------------------------------------------------------------------------------
*--- (2b) Format state spending sheets
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir spending
!ssconvert -S siha_2_1_2.xlsx spending/years.csv
foreach num of numlist 6(1)18 {
    insheet using spending/years.csv.`num', comma clear
    keep in 4/35
    keep v1 v13
    rename v1 stateName
    rename v13 totalIncome
    gen year = 1995+`num'
    tempfile f`num'
    save `f`num''
}

clear all
append using `f6' `f7' `f8' `f9' `f10' `f11' `f12' `f13' `f14' `f15' `f16' `f17' `f18'
save "$DAT/stateSpending", replace


*-------------------------------------------------------------------------------
*--- (2c) Regional GDP
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir GDP
!ssconvert siha_2_1_5.xlsx GDP/GDP.csv

insheet using GDP/GDP.csv, comma clear
keep in 4/35
rename v1 stateName
destring v12, replace
reshape long v, i(state) j(year)
rename v GDP
replace year=2001+year
expand 4 if year==2003
bys stateName year: gen n=_n
replace GDP = . if n != 1
replace year = year-n+1 if n != 1
drop n
bys stateName (year): ipolate GDP year, gen(GDPfull) epolate
gen GDP03 = GDP if year==2003
bys stateName: egen GDPreplace = min(GDP03)
replace GDP = GDPfull
replace GDP = GDPreplace if GDP<0
drop GDPfull GDP03 GDPreplace


cd "$SOR"
