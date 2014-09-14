* poplnPrep.do v 0.10               DCC/HM                 yyyy-mm-dd:2014-06-29
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

/* Script to extract all data from DBF files and convert to .dta for each year
of births.

DBFDUPM IS INCOMPLETE!!!
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DIR "~/investigacion/2014/MexAbort"
global DAT "~/database/MexDemografia/Natalidades"


********************************************************************************
*** (2) Unzip raw birth data
********************************************************************************
foreach y in 01 02 03 04 05 06 07 08 09 10 11 12 {
	cd "$DAT/20`y'"
	unzipfile "natalidad_base_datos_20`y'", replace

	foreach f in NACIM`y' ENTMUN {
		!dbfdump `f'.dbf --info | grep '^[0-9]*[\.]' | grep [A-Z_] | awk {'printf "%s;", $2'} > `f'.csv
		!echo "" >> `f'.csv
		!dbfdump -fs=';' `f' >> `f'.csv 
		*!dbfdump NACIM`year'.dbf -fs=';' > NACIM`year'.csv
		*!dbfdump ENTMUN.dbf -fs=';' > ENTMUN.csv
	}
}
