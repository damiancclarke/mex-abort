* socialPrep.do v 0.10              DCC/HM                 yyyy-mm-dd:2015-02-20
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

/* Script to extract all data from DBF files and convert to .dta for each year
of social indicators (marriage, divorce, crimes).
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DIR "~/investigacion/2014/MexAbort"
global DAT "~/database/MexDemografia/"


********************************************************************************
*** (2a) Unpack marriage data
********************************************************************************
foreach y in 01 02 03 04 05 06 07 08 09 10 11 12 {
  cd "$DAT/Nupcialidad/20`y'"

	foreach f in MATRI`y' ENTMUN {
		!dbfdump `f'.dbf --info | grep '^[0-9]*[\.]' | grep [A-Z_] | awk {'printf "%s;", $2'} > `f'.csv
		!echo "" >> `f'.csv
		!dbfdump -fs=';' `f' >> `f'.csv 
		insheet using `f'.csv, names delimit(";") clear
		save ../`f'.dta, replace
	}
}
exit
********************************************************************************
*** (2b) Unpack divorce data
********************************************************************************
foreach y in 01 02 03 04 05 06 07 08 09 10 11 {
  cd "$DAT/Divorcios/20`y'"

	foreach f in DIVOR`y' ENTMUN {
		!dbfdump `f'.dbf --info | grep '^[0-9]*[\.]' | grep [A-Z_] | awk {'printf "%s;", $2'} > `f'.csv
		!echo "" >> `f'.csv
		!dbfdump -fs=';' `f' >> `f'.csv 
		insheet using `f'.csv, names delimit(";") clear
		save ../`f'.dta, replace
	}
}
