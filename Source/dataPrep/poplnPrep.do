* poplnPrep.do v 0.00               DCC/HM                 yyyy-mm-dd:2014-06-29
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

/*Script to take population data by State and year and format into one file with
one line per State*year*age group of women.  Each line then has the total number
of women living in that State in that year.  In regressions based on age groups
we should then collapse taking totals over various ages (ie 15-19, 20-24 and so
forth).

The raw data used in this script can be downloaded in one zip file from the fol-
lowing address:
http://www.conapo.gob.mx/work/models/CONAPO/Proyecciones/Datos/descargas/Estimaciones_y_Proyecciones.zip

This Stata script then uses a Python module to export the unzipped data above
(two sheets per State), into individual sheets.  For now, we only use data bas-
ed on beginning of the year populations.  Later when we run estimates based on
month we should use both beginning and middle of year numbers, and interpolate
between months.  The python module can be downloaded from github here:
https://github.com/dilshod/xlsx2csv

To control this file only the glolbals and locals in section (1) need to be cha-
nged to reflect directory structure on the local machine.

For optimal viewing of this file, set tab width to 2.
*/

vers 11
set more off
clear all
cap log close

*********************************************************************************
*** (1) Globals and locals
*********************************************************************************
global DAT "~/investigacion/2014/MexAbort/Data/Population"
global OUT "~/investigacion/2014/MexAbort/Results/Descriptives/Popln"

#delimit ;
local States Aguascalientes BajaCalifornia BajaCaliforniaSur Campeche Chiapas
  Chihuahua Coahuila Colima DistritoFederal Durango Guanajuato Guerrero Hidalgo
  Jalisco Mexico Michoacan Morelos Nayarit NuevoLeon Oaxaca Puebla Queretaro
  QuintanaRoo SanLuisPotosi Sinaloa Sonora Tabasco Tamaulipas Tlaxcala Veracruz
  Yucatan Zacatecas;
local Numbers 29 12 09 17 10 01 03 28 32 04 22 14 26 07 25 16 30 23 13 05 21 27
  19 15 18 02 24 06 31 11 20 08;
#delimit cr

cd "$DAT"

local graphs 0
*********************************************************************************
*** (2) Convert xlsx from zip file to csv data using Python + system call
*********************************************************************************
foreach S of local States {
	dis "Converting state `S'"
	!xlsx2csv Estimaciones\ y\ Proyecciones\\1990-2010\\\`S'_est.xlsx `S'1990.csv	
	!xlsx2csv Estimaciones\ y\ Proyecciones\\2010-2030\\\`S'_pry.xlsx `S'2010.csv

	!xlsx2csv -s 2 Estimaciones\ y\ Proyecciones\\1990-2010\\\`S'_est.xlsx /*
	*/ `S'mid1990.csv	
	!xlsx2csv -s 2 Estimaciones\ y\ Proyecciones\\2010-2030\\\`S'_pry.xlsx /*
	*/ `S'mid2010.csv
}


*********************************************************************************
*** (3a) Read in each csv (beginning of year), keep only women data
*********************************************************************************
foreach yy of numlist 1990 2010 {
	tokenize `Numbers'
	foreach S of local States {
		insheet using `S'`yy'.csv, clear
		gen startwomen=1 if v1=="Mujeres"
		gen n=_n
		sum n if startwomen==1
		local begin=`r(mean)'+1
		count
		local end=`r(N)'
		keep in `begin'/`end'

		rename v1 Age
		foreach num of numlist 2(1)22 {
			local year=`num'+`yy'-2
			rename v`num' year_`year'
			replace year_`year'=round(year_`year')
		}
		drop startwomen n
		cap drop v* 
		if `yy'==1990 drop year_2010
		gen stateName="`S'"
		gen stateNum="`1'"
		gen month=1
		macro shift
		save "`S'`yy'.dta", replace
	}
}

*********************************************************************************
*** (3b) Read in each csv (middle of year), keep only women data
*********************************************************************************
foreach yy of numlist 1990 2010 {
	tokenize `Numbers'
	foreach S of local States {
		insheet using `S'mid`yy'.csv, clear
		gen startwomen=1 if v1=="Mujeres"
		gen n=_n
		sum n if startwomen==1
		local begin=`r(mean)'+1
		count
		local end=`r(N)'
		keep in `begin'/`end'

		rename v1 Age
		foreach num of numlist 2(1)22 {
			local year=`num'+`yy'-2
			rename v`num' year_`year'
			replace year_`year'=round(year_`year')
		}
		drop startwomen n
		cap drop v* 
		if `yy'==1990 drop year_2010
		gen stateName="`S'"
		gen stateNum="`1'"
		gen month=7
		drop if Age==""
		macro shift
		save "`S'mid`yy'.dta", replace
	}
}


*********************************************************************************
*** (4) Append 1990-2010 (estimates) with 2010-2030 (projections)
*********************************************************************************
foreach S of local States {
	use `S'1990
	merge 1:1 Age using `S'2010
	order Age state*
	save `S', replace

	use `S'mid1990
	merge 1:1 Age using `S'mid2010
	order Age state*
	save `S'mid, replace
}

*********************************************************************************
*** (5) Append into one dataset and clean up folder
*********************************************************************************
clear
foreach S of local States {
	dis "Appending `S' to aggregate file..."
	append using `S' `S'mid

	rm `S'1990.dta
	rm `S'2010.dta
	rm `S'1990.csv
	rm `S'2010.csv
	rm `S'.dta
	rm `S'mid1990.dta
	rm `S'mid2010.dta
	rm `S'mid1990.csv
	rm `S'mid2010.csv
	rm `S'mid.dta
}

drop _merge
destring Age, replace


*********************************************************************************
*** (6) Expand, impute and save month and yearly data
*********************************************************************************
order Age stateName stateNum month
preserve
keep if month==1
lab dat "Mexican population data for women by age, State and year"
save $DAT/populationStateYear.dta, replace

keep if Age>=15&Age<=49
save $DAT/populationStateYear1549.dta, replace
restore


reshape long year_, i(stateName stateNum Age month) j(year)
expand 6
bys stateNum Age year month: gen n=_n-1
replace month=month+n
drop n
rename year_ pop
replace pop=. if month!=1&month!=7
bys stateNum Age (year month): gen counter=_n

bys stateNum Age: ipolate pop counter, gen(imputePop)
drop if imputePop==.
replace imputePop=round(imputePop)
drop pop counter

lab dat "Mexican population data for women by age, State and year*month"
save $DAT/populationStateYearMonth.dta, replace
keep if Age>=15&Age<=49
save $DAT/populationStateYearMonth1549.dta, replace


*********************************************************************************
*** (7) Make basic descriptive graphs
*********************************************************************************
if `graphs'==1 {
	use $DAT/populationStateYear.dta, clear
	collapse (sum) year*, by(state*)
	reshape long year_, i(stateName stateNum) j(year)
	rename year_ pop
	replace pop=pop/1000000
	lab var pop "Population in Millions"

	twoway line pop year, scheme(s1color) ///
	  title("All State Rough Population Trends") subtitle("Women Aged 15-49") ///
	  ytitle("Population in Millions")
	graph export "$OUT/populationRoughTrends.eps", as(eps) replace

	twoway line pop year if stateNum=="32", scheme(s1color) ///
	  title("Mexico D.F. Rough Population Trend") subtitle("Women Aged 15-49") ///
	  ytitle("Population in Millions")
	graph export "$OUT/populationTrendDF.eps", as(eps) replace

	gen DF=stateNum=="32"
	collapse (sum) pop, by(DF year)
	twoway line pop year if DF==1 || line pop year if DF==0, scheme(s1color) ///
	  title("Treat and Control Rough Population Trend") ///
	  ytitle("Population in Millions") subtitle("Women Aged 15-49") ///
	  legend(label(1 "D.F.") label(2 "Rest of Mexico"))
	graph export "$OUT/populationTrendTreatControl.eps", as(eps) replace
}
