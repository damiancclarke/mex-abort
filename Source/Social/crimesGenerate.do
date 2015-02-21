/* crimesGenerate.do v0.00       damiancclarke             yyyy-mm-dd:2014-02-21
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Converts raw crime data into a file with one line per age, month*year, and state

Prior to 2009 the code for intrafamily violence is 171200
2009 and onwards it is 181100 to 181199

2008 and earlier abortion == 170105
2009 onwards abortion     == 111300
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT  "~/database/MexDemografia/Judiciales"
global BIR  "~/investigacion/2014/MexAbort/Data/Births"
global SOC  "~/investigacion/2014/MexAbort/Data/Social"
global POP  "~/investigacion/2014/MexAbort/Data/Population"
global LOG  "~/investigacion/2014/MexAbort/Log"

log using "$LOG/crimesGenerate.txt", text replace

local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc   /*
*/ totalout subsidies unemployment condom* any* adolescentKnows SP

local import 1

********************************************************************************
*** (2) Import microdata
********************************************************************************
if `import'==1 {
    foreach yr in 03 04 05 06 07 08 {
        use "$DAT/20`yr'/pdel20`yr'"
        merge 1:1 id_ps "$DAT/20`yr'/preg20`yr'"

        keep b_munoc b_entoc b_delito b_mesreg b_anoreg b_entreg b_munreg /*
        */ b_edad b_sexo
        gen intrafamilyViolence = b_delito==171200
        gen abortionCrime       = b_delito==170105

        tempfile c`yr'
        save `c`yr''
    }
    foreach yr in 09 10 11 {
        use "$DAT/20`yr'/pdel20`yr'"
        merge 1:1 id_ps "$DAT/20`yr'/preg20`yr'"

        keep b_munoc b_entoc b_delito b_mesreg b_anoreg b_entreg b_munreg /*
        */ b_edad b_sexo
        gen intrafamilyViolence = b_delito==181100
        gen abortionCrime       = b_delito==111300

        tempfile c`yr'
        save `c`yr''
    }
    clear
    append `c03' `c04' `c05' `c06' `c07' `c08' `c09' `c10' `c11'
    collapse (sum) intraf abortionCrime, by(b_mesreg b_anoreg b_entreg b_munreg)


    rename b_munreg  MunNum
    rename b_entreg  StateNum
    rename b_mesreg  month
    rename b_anoreg  year
    
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
    label data "Count of crimes by age, municipality and month"
    save "$SOC/CrimeMonth", replace
}
