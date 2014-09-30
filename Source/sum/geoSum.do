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

local mapgen 0

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
