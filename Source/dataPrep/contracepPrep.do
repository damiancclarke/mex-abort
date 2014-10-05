/* contracepPrep.do v0.00        damiancclarke              yyyy-mm-dd:2014-10-05
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file takes data from ENSANUT surveys (2000, 2006, 2012) and calculates con-
traceptive use by state and time.

This file requires data in the following structure:
> ./2000/Datos
> ./2000/Documentos
> ./2006/Datos
> ./2006/Documentos
> ./2012/Datos
> ./2012/Documentos

where in each folder there are four surveys (and their pdfs).  These are called:
> Adolescentes
> Adultos
> Menores
> Utilizadores

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and Locals
********************************************************************************
global DAT ~/database/ENSANUT_Mex/
global OUT ~/investigacion/2014/MexAbort/Data/Contracep

cap mkdir $OUT

local yrs 2000 2006 2012

********************************************************************************
*** (2a) Open files, keep questions 2012
********************************************************************************
tempfile inter

use $DAT/2012/Datos/Adultos
egen anyFirst = rowtotal(a802a-a802i)
egen anyRecent = rowtotal(a803a-a803h)
rename a802a condomFirst
rename a803a condomRecent
replace anyFirst=1 if anyFirst>1
replace anyRecent=1 if anyRecent>1
gen year=2012

collapse condom* anyFirst anyRecent, by(entidad)
save `inter'

use $DAT/2012/Datos/Adolescentes, clear
gen adolescentKnows=d201==1
egen anyFirstTeen = rowtotal(d208a-d208i)
egen anyRecentTeen = rowtotal(d210a-d210h)
rename d208a condomFirstTeen
rename d210a condomRecentTeen
replace anyFirstT=1 if anyFirstT>1
replace anyRecentT=1 if anyRecentT>1
gen year=2012

collapse condom* anyFirstT anyRecentT adolescent, by(entidad)
merge 1:1 entidad using `inter'
drop _merge
label data "State level contraceptive controls (from ENSANUT 2012)"
save "$OUT/Contracep2012", replace

********************************************************************************
*** (2b) Open files, keep questions 2006
********************************************************************************
use $DAT/2006/Datos/Adultos
rename ent entidad
egen anyRecent = rowtotal(a920a-a920h)
gen condomRecent=(a920a-2)*-1
replace anyRecent=1 if anyRecent>1
gen year=2006

collapse condom* anyRecent, by(entidad)
save `inter', replace

use $DAT/2006/Datos/Adolescentes, clear
tostring ent, gen(entidad)
foreach num of numlist 1(1)9{
	replace entidad="0`num'" if entidad=="`num'"
}
gen adolescentKnows=d201==1
gen anyFirstTeen = 1 if d204a<=6|d204b<=6|d204c<=6
replace anyFirstTeen = 0 if d204a>6&d204a!=.
gen condomFirstTeen=1 if d204a==6|d204b==6|d204c==6
replace condomFirstTeen=0 if d204a==13
gen condomRecentTeen=1 if d205==1
replace condomRecentTeen=0 if d205==2
gen year=2006

collapse condom* anyFirstT adolescent, by(entidad)
merge 1:1 entidad using `inter'
drop _merge
label data "State level contraceptive controls (from ENSANUT 2006)"
save "$OUT/Contracep2006", replace
