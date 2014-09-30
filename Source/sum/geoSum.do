/* geoSum.do v0.00               damiancclarke             yyyy-mm-dd:2014-09-29
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8


This file takes INEGI shape data and superimposes birth data to make maps of bi-
rths over time.

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
global MAP "~/database/MexMunicipios/ife2010/secciones-inegi/"
global BIR "~/database/MexDemografia/Natalidades/"
global OUT "~/investigacion/2014/MexAbort/Results/Descriptives/Geo/"

