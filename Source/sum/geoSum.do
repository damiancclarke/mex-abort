/* geoSum.do v0.00               damiancclarke             yyyy-mm-dd:2014-09-29
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8


This file takes INEGI shape data and superimposes birth data to make maps of bi-
rths over time.  The INEGI map data (state or municipal) comes from the followi-
ng address:
     http://www.inegi.org.mx/geo/contenidos/geoestadistica/m_geoestadistico.aspx



The following global' variables must be set:
  > MAP: folder where secciones.shp from INEGI is located
  > BIR: folder where birth data is stored
  > OUT: folder to export completed maps

contact: mailto:damian.clarke@economics.ox.ac.uk
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global MAP "~/database/MexMunicipios/INEGI"
global BIR "~/database/MexDemografia/Natalidades/"
global OUT "~/investigacion/2014/MexAbort/Results/Descriptives/Geo/"
global DAT "~/investigacion/2014/MexAbort/Data/Births"

local mapgen 0
local import 0

********************************************************************************
*** (2) convert shape to dta files
********************************************************************************
if `mapgen'==1 {
	cap which shp2dta
	if _rc!=0 ssc install shp2dta

	foreach l in Entidades Municipios {
		shp2dta using $MAP/`l'/`l'_2013.shp, database($MAP/`l') coordinates($MAP/`l'Coords)
		use $MAP/`l', clear
		d
	}
}

********************************************************************************
*** (3) Collapse yearly birth count by desired level
********************************************************************************
if `import'==1 {
	foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 {
		dis "Appending `yr'"
		append using "$BIR/NACIM`yr'.dta"
	}

	keep if ent_ocurr<=32
	keep if mun_ocurr!=999
	drop if mes_nac==.
	drop if ano_nac==9999|mes_nac==99|dia_nac==99
	keep if ano_nac>=2001&ano_nac<2012

	gen birth=1
	collapse (sum) birth, by(ent_ocurr mun_ocurr ano_nac)

	tostring ent_ocurr, gen(CVE_ENT)
	tostring mun_ocurr, gen(CVE_MUN)

	foreach num of numlist 1(1)9{
		replace CVE_ENT="0`num'" if CVE_ENT=="`num'"
		replace CVE_MUN="00`num'" if CVE_MUN=="`num'"
	}
	foreach num of numlist 10(1)99{
		replace CVE_MUN="0`num'" if CVE_MUN=="`num'"
	}

	tab ano_nac
	reshape wide birth, i(CVE_ENT CVE_MUN) j(ano_nac)
	save "$DAT/BirthsStateWide.dta", replace
}

********************************************************************************
*** (4a) Make State maps
********************************************************************************
use "$DAT/BirthsStateWide.dta", clear
collapse (sum) birth*, by(CVE_ENT)

merge 1:1 CVE_ENT using "$MAP/Entidades"

foreach y of numlist 2005(1)2010 {
	spmap birth`y' using $MAP/EntidadesCoords, id(_ID) fcolor(Heat) osize(vthin)
	graph export $OUT/Ebirths`y'.eps, as(eps) replace
}

gen Reform=1 if CVE_ENT=="15"
replace Reform=2 if CVE_ENT=="09"
spmap Reform using $MAP/EntidadesCoords, id(_ID) fcolor(Heat) osize(vthin)
graph export $OUT/EReform.eps, as(eps) replace

********************************************************************************
*** (4b) Make Municipal maps
********************************************************************************
use "$DAT/BirthsStateWide.dta", clear
merge 1:1 CVE_ENT CVE_MUN using "$MAP/Municipios"

foreach y of numlist 2005(1)2010 {
	spmap birth`y' using $MAP/MunicipiosCoords, id(_ID) fcolor(Heat) osive(vthin)
	graph export $OUT/Mbirths`y'.eps, as(eps) replace
}

gen Reform=1 if CVE_ENT=="15"
replace Reform=2 if CVE_ENT=="09"
spmap Reform using $MAP/MunicipiosCoords, id(_ID) fcolor(Heat) osive(vthin)
graph export $OUT/MReform.eps, as(eps) replace
