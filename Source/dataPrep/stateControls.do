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
*--- (2) Format state income sheets
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

cd "$SOR"
