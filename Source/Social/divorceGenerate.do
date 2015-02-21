/* divorceGenerate.do v0.00      damiancclarke             yyyy-mm-dd:2014-02-21
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Converts raw divorce data into a file with one line per age, month*year, and st-
ate.

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT  "~/database/MexDemografia/Divorcios"
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global SOC  "~/investigacion/2014/MexAbort/Data/Social"
global POP  "~/investigacion/2014/MexAbort/Data/Population"
global LOG  "~/investigacion/2014/MexAbort/Log"

log using "$LOG/divorceGenerate.txt", text replace

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc   /*
*/ totalout subsidies unemployment condom* any* adolescentKnows SP

local import 1

********************************************************************************
*** (2) Import microdata
********************************************************************************
if `import'==1 {
    foreach yr in 01 02 03 04 05 06 07 08 09 10 11 {
        dis "Appending `yr'"
        append using "$DAT/DIVOR`yr'"
        keep ent_reg mun_reg dura_soc dura_leg edad_la edad_el anio_sen mes_sen
    }

    gen divorce = 1
    replace edad_el=. if edad_el==999
    replace edad_la=. if edad_la==999

    collapse edad_el dura_soc dura_leg (sum) divorce, /*
    */ by(edad_la mun_regis ent_regis mes_sen anio_sen)


    rename edad_la    wifeAgeDivorce
    rename edad_el    husbAgeDivorce
    rename mun_regis  MunNum
    rename ent_regis  StateNum
    rename mes_sen    month
    rename anio_sen   year
    rename dura_soc   durationMarriageSocial
    rename dura_leg   durationMarriageLegal
    
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
    label data "Count of divorces by age, municipality and month"
    save "$SOC/DivorceMonth", replace
}
