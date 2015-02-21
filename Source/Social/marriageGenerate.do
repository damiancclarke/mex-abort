/* marriageGenerate.do v0.00     damiancclarke             yyyy-mm-dd:2014-02-21
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Converts raw marriage data into a file with one line per age, month*year, and s-
tate.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT "~/database/MexDemografia/Nupcialidad"
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global MAR  "~/investigacion/2014/MexAbort/Data/Mortality"
global POP  "~/investigacion/2014/MexAbort/Data/Population"
global LOG  "~/investigacion/2014/MexAbort/Log"

log using "$LOG/marriageGenerate.txt", text replace

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc   /*
*/ totalout subsidies unemployment condom* any* adolescentKnows SP

local import 1

********************************************************************************
*** (2) Import microdata
********************************************************************************
if `import'==1 {
    foreach yr in 10 11 12 {
        dis "Appending `yr'"
        append using "$DAT/MATRI`yr'"
        keep genero ent_regis mun_regis mes_regis anio_regis edad_con1 edad_con2 /*
        */ entrh_con1 munrh_con1 entrh_con2 munrh_con2
    }

    keep if genero==1
    rename entrh_con2 ent_resla
    rename munrh_con2 mun_resla
    rename entrh_con1 ent_resel
    rename munrh_con1 mun_resel
    rename edad_con2 edad_la
    rename edad_con1 edad_el

    foreach yr in 01 02 03 04 05 06 07 08 09 {
        dis "Appending `yr'"
        append using "$DAT/MATRI`yr'"
                                        #delimit ;
        keep ent_regis mun_regis ent_resla mun_resla ent_resel mun_resel edad_la
        edad_el mes_regis anio_regis;
                                        #delimit cr
    }

    gen marriage = 1
    replace edad_el=. if edad_el==99
    replace edad_la=. if edad_la==99

    collapse edad_el (sum) marriage, by(edad_la mun_regis ent_regis mes_regis anio)


    rename edad_la    Age
    rename edad_el    husbAge
    rename mun_regis  MunNum
    rename ent_regis  StateNum
    rename mes_regis  month
    rename anio_regis year

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
    label data "Count of marriages by age, municipality and month"
    save "$MAR/MarriageMonth", replace
}
