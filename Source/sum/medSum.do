/* medSum.do v0.00               damiancclarke             yyyy-mm-dd:2015-10-02
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Counts numbers of births and deaths for summary tables.

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) globals and locals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2014/MexAbort/Data/State"
global OUT "~/investigacion/2014/MexAbort/Results/Summary/"



*-------------------------------------------------------------------------------
*--- (2) Setup as per analysis file
*-------------------------------------------------------------------------------
use "$DAT/stateData.dta", clear
drop birthsReg* birthsOc*
reshape long birthsResidents population, i(year stateNum) j(age)

merge 1:1 stateNum age year using "$DAT/MMRState_resid", force
drop if stateNum>32|age<15|age>44
keep if year>2001&year<2012

replace MMR       = 0 if _merge==1
gen   birth       = birthsResidents
gen   mmr         = MMR/birth*100000
gen   Mdeaths     = MMR
gen   birthRate   = birth/population*1000
gen   DF          = stateNum==9
gen   MexState    = stateNum==15
gen   DFMex       = stateNum==9|stateNum==15

gen   Reform      = stateNum==9&year>2007
gen   ReformClose = stateNum==15&year>2007
gen   after       = year>=2008


gen ageGroup = .
replace ageGroup = 1 if age>=15&age<20
replace ageGroup = 2 if age>=20&age<35
replace ageGroup = 3 if age>=35&age<40
replace ageGroup = 4 if age>=40&age<45
replace birth    = birth/1000
exit
*-------------------------------------------------------------------------------
*--- (3) Sum stats by: All, Age, Pre/Post, for each of All, DF, Other
*-------------------------------------------------------------------------------
rename birthRate birth1
rename birth     birth2
rename mmr       MMR1
rename Mdeaths   MMR2
gen    all = 1

*-------------------------------------------------------------------------------
*--- (3a) All 
*-------------------------------------------------------------------------------

foreach sum in birth MMR {
    if `"`sum'"'=="birth" local wt [fw = population]
    if `"`sum'"'=="MMR"   local wt [fw = birthsResidents]

    preserve
    collapse `sum'1 (rawsum) `sum'2 `wt', by(all)
    reshape long `sum', i(all) j(type)
    drop all
    rename `sum' All
    tempfile All`sum'
    save `All`sum''
    restore

    preserve
    collapse `sum'1 (rawsum) `sum'2 `wt', by(DFMex)
    reshape long `sum', i(DFMex) j(type)
    reshape wide `sum', i(type) j(DFMex)
    rename `sum'0 Other
    rename `sum'1 DFMex
    merge 1:1 type using `All`sum''
    drop _merge
    list
    save `All`sum'', replace
    restore

    *---------------------------------------------------------------------------
    *--- (3b) By Age
    *---------------------------------------------------------------------------
    preserve
    collapse `sum'1 (rawsum) `sum'2 `wt', by(all ageGroup)
    reshape long `sum', i(all ageGroup) j(type)
    drop all
    rename `sum' All
    tempfile Age`sum'
    save `Age`sum''
    restore

    preserve
    collapse `sum'1 (rawsum) `sum'2 `wt', by(DFMex ageGroup)
    reshape long `sum', i(DFMex ageGroup) j(type)
    reshape wide `sum', i(type ageGroup) j(DFMex)
    rename `sum'0 Other
    rename `sum'1 DFMex
    merge 1:1 type ageGroup using `Age`sum''
    drop _merge
    list
    keep if type==1
    save `Age`sum'', replace
    restore

    *---------------------------------------------------------------------------
    *--- (3c) By Pre/Post
    *-------------------------------------------------------------------------------
    preserve
    collapse `sum'1 (rawsum) `sum'2 `wt', by(all after)
    reshape long `sum', i(all after) j(type)
    drop all
    rename `sum' All
    tempfile Post`sum'
    save `Post`sum''
    restore

    preserve
    collapse `sum'1 (rawsum) `sum'2 `wt', by(DFMex after)
    reshape long `sum', i(DFMex after) j(type)
    reshape wide `sum', i(type after) j(DFMex)
    rename `sum'0 Other
    rename `sum'1 DFMex
    merge 1:1 type after using `Post`sum''
    drop _merge
    list
    keep if type==1
    save `Post`sum'', replace
    restore

    *---------------------------------------------------------------------------
    *--- (3d) Output files
    *-------------------------------------------------------------------------------
    preserve
    clear

    if `"`sum'"'=="birth" local n1 "Number of Births"
    if `"`sum'"'=="birth" local n2 "Birth Rate"
    if `"`sum'"'=="MMR"   local n1 "Number of Maternal Deaths"
    if `"`sum'"'=="MMR"   local n2 "Maternal Mortality Ratio"

    append using `All`sum'' `Age`sum'' `Post`sum''
    gen variable = "`n1'" if type==2
    replace variable = "`n2'"   if type==1
    gen group = "15-19" if ageGroup == 1
    replace group = "20-34" if ageGroup == 2
    replace group = "35-39" if ageGroup == 3
    replace group = "40+"   if ageGroup == 4
    replace group = "Pre"   if after    == 0
    replace group = "Post"  if after    == 1
    

    drop type ageGroup after
    order variable group DFMex Other All

    outsheet using "$OUT/`sum'Sum.txt", delimiter("&") replace noquote
    restore
}

!python formatMedSum.py
