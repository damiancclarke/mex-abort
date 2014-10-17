/* birthGenerate v0.00              DCC/HM                 yyyy-mm-dd:2014-10-17
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

This script genrates a number of output files based on birth data and covariates 
produced from the script municipPrep.py as well as population data produced from
poplnPrep.do and contraceptive data from contracepPrep.do.  It produces the fol-
lowing four files:

	> MunicipalBirths.dta
	> StateBirths.dta
	> MunicipalBirths_smoothed.dta
	> StateBirths_smoothed.dta

where the difference between each file is the level of aggregation (State is hi-
gher than Municipal), and whether or not births are deseasoned to remove regular 
monthly variation.

The file can be controlled in section 1 which requires a group of globals and l-
ocals defining locations of key data sets and specification decisions.  Current-
ly the following data is required:
   > Doctors.csv: number of medical staff per municipality over time
   > EducInf.csv: investment in infrastructure over time
   > Income.csv: income for each municipality over time
   > Spending.csv: spending for each municipality over time
   > Employment figure from each state from INEGI (1 sheet per state)
   > NACIM01.dta-NACIM12.dta: raw birth records from INEGI
	 > populationStateYearMonth1549.dta: total population at a state level by time


    contact: mailto:damian.clarke@economics.ox.ac.uk


Past major versions
   > v0.00: Creates four files: municipal, state, and deseasoned or not

*/

vers 11
clear all
set more off
cap log close
set matsize 10000

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT  "~/database/MexDemografia/Natalidades"
global DAT2 "~/investigacion/2014/MexAbort/Data/Population"
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global OUT  "~/investigacion/2014/MexAbort/Results/Births"
global LOG  "~/investigacion/2014/MexAbort/Log"
global COV1 "~/investigacion/2014/MexAbort/Data/Municip"
global COV2 "~/investigacion/2014/MexAbort/Data/Labour/Desocupacion2000_2014"
global COV3 "~/investigacion/2014/MexAbort/Data/Contracep"

