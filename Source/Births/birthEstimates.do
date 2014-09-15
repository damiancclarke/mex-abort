* birthEstimates v0.00              DCC/HM                 yyyy-mm-dd:2014-09-15
*---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*

/* Combine birth data with population data to determine 1/0 outcome for each wo-
man living in each State.  Run weighted binary regression for birth against tre-
atment.
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DIR  "~/investigacion/2014/MexAbort"
global DAT  "~/database/MexDemografia/Natalidades"
global DAT2 "~/investigacion/2014/MexAbort/Data/Population"
global OUT  "~/investigacion/2014/MexAbort/Results/Births"

cap mkdir $OUT

********************************************************************************
*** (2) Import births, rename
********************************************************************************
foreach yr in 01 02 03 04 05 06 07 08 09 10 11 12 {
	append using "$DAT/NACIM`yr'.dta"
}

sort ENT_OCURR MES_NAC

replace MUN_RESID=. if MUN_RESID==999
replace TLOC_RESID=. if TLOC_RESID==99
replace ENT_OCURR=. if ENT_OCURR==99
replace MUN_OCURR=. if MUN_OCURR==999
replace SEXO=. if SEXO==9
replace EDAD_REG=. if EDAD_REG==99
replace EDAD_REG=0 if EDAD_REG==98
replace EDAD_MADN=. if EDAD_MADN==99
replace EDAD_PADN=. if EDAD_PADN==99
replace DIA_NAC=. if DIA_NAC==99
replace MES_NAC=. if MES_NAC==99
replace ANO_NAC=. if ANO_NAC==9999
replace DIA_REG=. if DIA_REG==99
replace MES_REG=. if MES_REG==99
replace EDAD_MADR=. if EDAD_MADR==99
replace EDAD_PADR=. if EDAD_PADR==99
replace TIPO_NAC=. if TIPO_NAC==9
replace ORDEN_PART=. if ORDEN_PART==99
replace LUGAR_PART=. if LUGAR_PART==9
replace Q_ATENDIO=. if Q_ATENDIO==9
replace HIJOS_VIVO=. if HIJOS_VIVO==99
replace HIJOS_SOBR=. if HIJOS_SOBR==99
replace EDOCIV_MAD=. if EDOCIV_MAD==9
replace ESCOL_MAD=. if ESCOL_MAD==9
replace ESCOL_PAD=. if ESCOL_PAD==9
replace ACT_MAD=. if ACT_MAD==9
replace ACT_PAD=. if ACT_PAD==9
replace FUE_PRESE=. if FUE_PRESE==9

gen birth=1 if ANO_NAC==ANO_REG

collapse (sum) birth (mean) EDAD_MADR EDAD_PADR Q_ATENDIO EDOCIV_MAD /*
*/ ESCOL_MAD ESCOL_PAD  ACT_MAD ACT_PAD HIJOS_VIVO HIJOS_SOBR, /*
*/ by(ENT_OCURR ANO_NAC EDAD_MADN)

rename ENT_OCURR state_ocur
rename EDAD_MADN age_mom
*rename EDAD_PADN age_dad
rename ANO_NAC year_birth
rename EDAD_MADR age_mom_reg
rename EDAD_PADR age_dad_reg
rename Q_ATENDIO who_attend
rename HIJOS_VIVO live_birth
rename HIJOS_SOBR surviv_child
rename ESCOL_MAD mom_ed
rename ESCOL_PAD dad_ed
rename ACT_MAD work_mom
rename ACT_PAD work_dad

********************************************************************************
*** (3) Merge to population data
********************************************************************************
rename age_mom Age
rename stata_ocur stateNum
merge 1:m stateNum year_birth age_mom using "$DAT2/populationStateYear1549.dta" 


