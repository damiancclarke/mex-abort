/* mortalityGenerate v0.10          DCC/HM                 yyyy-mm-dd:2014-11-03
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

This script generates a number of output files based on mortality data, and cov-
ariates included in birth data.  These covariates include time-varying municipal
and regional controls, along with total population and total births at the same
level. It produces the following files:

   > MunicipalDeaths.dta
   > StateDeaths.dta

where the difference between each file is the level of aggregation (State is hi-
gher than Municipal).

The file can be controlled in section 1 which requires a group of globals and l-
ocals defining locations of key data sets and specification decisions.  Current-
ly the following data is required:
   > DEFUN01.dta-DEFUN12.dta: raw death records from INEGI
   > MunicipalBirths.dta: total population at a state level by time


    contact: mailto:damian.clarke@economics.ox.ac.uk


Past major versions
   > v0.00: Creates maternal mortality at a municipal level

*/

vers 11
clear all
set more off
cap log close
set matsize 10000

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT  "~/database/MexDemografia/DefuncionesGenerales"
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global MOR  "~/investigacion/2014/MexAbort/Data/Mortality"
global POP  "~/investigacion/2014/MexAbort/Data/Population"
global LOG  "~/investigacion/2014/MexAbort/Log"

log using "$LOG/mortalityGenerate.txt", text replace

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc /*
*/ totalout subsidies unemployment condom* any* adolescentKnows SP
local popName Chihuahua Sonora Coahuila Durango Oaxaca Tamaulipas Jalisco     /*
*/ Zacatecas BajaCaliforniaSur Chiapas Veracruz BajaCalifornia NuevoLeon      /*
*/ Guerrero SanLuisPotosi Michoacan Campeche Sinaloa QuintanaRoo Yucatan      /*
*/ Puebla Guanajuato Nayarit Tabasco Mexico Hidalgo Queretaro Colima          /*
*/ Aguascalientes Morelos Tlaxcala DistritoFederal
local popNum 8 26 5 10 20 28 14 32 3 7 30 2 19 12 24 16 4 25 23 31 21 11 18 27 /*
*/ 15 13 22 6 1 17 29 9

local import 1
local mergeB 0
local stateG 0

********************************************************************************
*** (2) Import mortality, rename
********************************************************************************
if `import'==1 {
  foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 {
      dis "Working with `yr'"
      use "$DAT/DEFUN`yr'.dta", clear
      keep ent_regis mun_regis ent_resid mun_resid ent_ocurr mun_ocurr       /*
		  */ causa_def lista_mex sexo edad dia_ocurr mes_ocurr anio_ocur dia_nac /*
		  */ mes_nacim anio_nacim ocupacion escolarida edo_civil presunto        /*
		  */ asist_medi nacionalid embarazo rel_emba edad_agru maternas vio_fami

      replace edad=.       if edad==4998
      replace mun_resid=.  if mun_resid==999
      replace mun_ocurr=.  if mun_ocurr==999
      replace ent_resid=.  if ent_resid==99
      replace dia_ocurr=.  if dia_ocurr==99
      replace mes_ocurr=.  if mes_ocurr==99
      replace anio_ocur=.  if anio_ocur==9999
      replace anio_nacim=. if anio_nacim==9999
	
	
      gen MMR=maternas!=""
      gen materndeath=rel_emba==1
      keep if anio_ocur>=2001&anio_ocur<=2012

      gen murder         = presunto==2
      gen murderWoman    = presunto==2&sexo==2
      gen familyViolence = vio_fami==1

      local Dvars MMR materndea edad_ag murder murderWoman familyViolence
      collapse (sum) `Dvars', by(ent_oc mun_oc anio_oc edad)

      rename edad Age
      rename ent_ocurr StateNum
      rename mun_ocurr MunNum
      rename anio_ocur year
      rename edad_agru ageGroup

      keep if Age>=4001&Age<=4120
      replace Age=Age-4000
	
      tostring StateNum, gen(entN)
      gen length=length(entN)
      gen zero="0" if length==1
      egen stateid=concat(zero entN)
      drop length zero entN

      tostring MunNum, gen(munN)
      gen length=length(munN)
      gen zero="0" if length==2
      replace zero="00" if length==1
      egen munid=concat(zero munN)
      drop length zero munN

      egen id=concat(stateid munid)
      label data "Count of Maternal Deaths by age, municipality and year"
      tempfile M`yr'
      save `M`yr''
  }
  clear
  append using `M01' `M02' `M03' `M04' `M05' `M06' `M07' `M08' `M09' `M10' /*
  */ `M11' `M12'
  save "$MOR/MortalityYear", replace
}

********************************************************************************
*** (X) Close
********************************************************************************
log close
