/*fullGraphs v0.00               damiancclarke             yyyy-mm-dd:2014-02-26
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file takes State data of various indicators, and graphs trends over time by
year.  It works with the BirthsFullState.dta.

*/

vers 11
clear all
set more off
cap log close


********************************************************************************
*** (1) Globals, locals
********************************************************************************
global DAT "~/investigacion/2014/MexAbort/Data/Births"
global OUT "~/investigacion/2014/MexAbort/Results/Graphs/Trends/Full"
global LOG "~/investigacion/2014/MexAbort/Log"

log using "$LOG/fullGraphs.txt", text replace
cap mkdir "$OUT"

local svars materndeath murder murderWoman familyViolence divorce marriage
local cvars intrafamilyViolence abortionCrime
local avars Fdeathrate lFdeathrate eFdeathrate birthrate

********************************************************************************
*** (2) Open, format
********************************************************************************
use "$DAT/BirthsFullState"

gen group=1 if Age>=15&Age<=19
replace group=2 if Age>=20&Age<=24
replace group=3 if Age>=25&Age<=29
replace group=4 if Age>=30&Age<=34
replace group=5 if Age>=35&Age<=39
replace group=5 if Age>=40&Age<=44

preserve
collapse `avars' (sum) `svars' `cvars', by(DF group year)
********************************************************************************
*** (3) graphs
********************************************************************************
foreach num of numlist 1(1)5 {
    foreach bv of varlist `svars' `avars' {
    
        twoway line `bv' year if DF==0&group==`num', yaxis(1) || /*
        */ line `bv' year if DF==1&group==`num', yaxis(2)        /*
        */ scheme(s1color) xline(2007.33) /*
        */ legend(label(1 "All Other States") label(2 "Mexico DF")) /*
        */ note("Left hand axis is for all States. Right axis hand is for Mexico D.F.")
        graph export "$OUT/`bv'_AgeGroup`num'.eps", replace as(eps)
    }
}


restore
keep if Age==15
collapse (sum) `cvars', by(DF year)
foreach bv of varlist `cvars' {
    twoway line `bv' year if DF==0, yaxis(1) || /*
    */ line `bv' year if DF==1, yaxis(2)        /*
    */ scheme(s1color) xline(2007.33) /*
    */ legend(label(1 "All Other States") label(2 "Mexico DF")) /*
    */ note("Left hand axis is for all States. Right axis hand is for Mexico D.F.")
    graph export "$OUT/`bv'.eps", replace as(eps)
}
