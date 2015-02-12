/* birthCount.do v0.00           damiancclarke             yyyy-mm-dd:2015-02-11
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file counts births registered each year, producing a final count of births
recorded in 2005-2013 admin records.


*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals
********************************************************************************
global DAT "~/database/MexDemografia/Natalidades"
global OUT "~/investigacion/2014/MexAbort/Results/Births/count"


********************************************************************************
*** (2) read in, check
********************************************************************************
foreach yr in 05 06 07 08 09 10 11 12 13 {
    dis "Year is 20`yr'"
    count
    use "$DAT/NACIM`yr'.dta", clear
    keep if ano_nac>=2005&ano_nac<=2012

    gen birth=1
    collapse (sum) birth, by(ano_nac)
    gen syear=2000+`yr'
    list

    tempfile b`yr'
    save `b`yr''
}

clear
append using `b05' `b06' `b07' `b08' `b09' `b10' `b11' `b12' `b13'

********************************************************************************
*** (3) Graph
********************************************************************************
replace birth=birth/100000
reshape wide birth, i(ano_nac) j(syear)
graph bar birth2005 birth2006 birth2007 birth2008 birth2009 birth2010 birth2011 /*
*/ birth2012 birth2013, over(ano_nac) stack scheme(s1color) /*
*/ legend(lab(1 "2005 record")  lab(2 "2006 record") lab(3 "2007 record") /*
*/ lab(4 "2008 record") lab(5 "2009 record") lab(6 "2010 record") /*
*/ lab(7 "2011 record")  lab(8 "2012 record") lab(9 "2013 record")) /*
*/ xtitle("100,000 births") ytitle("Birth Year")
graph export "$OUT/BirthsPerYear.eps", as(eps) replace
