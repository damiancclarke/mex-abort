/* stateControls.do              damiancclarke             yyyy-mm-dd:2015-07-19
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Controls at the level of state*year for Mexico from 2001 to 2013.  See notes in
stateData.txt for data sources.


El Índice Nacional de Corrupción y Buen Gobierno (INCBG) mide experiencias de
corrupción en 35 tipos de servicios prestados por entidades federativas. Utiliza
una escala de 0 a 100: a menor valor obtenido, menor corrupción.
Fórmula para calcular el índice en un servicio: número de veces en los que un
servicio se obtuvo con una mordida / número total de veces en los que se utilizó
el mismo servicio X 100.
Fórmula para calcular el índice general. INCBG = (número de veces en los que se
dio mordida en los 35 servicios / número total de veces que se utilizaron los 35 s
ervicios) X 100. El resultado de esta fórmula es el que se muestra en la tabla.

Contraceptive variables are generated in contracepPrep.do
*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) globals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2014/MexAbort/Data/State"
global BIR "~/database/MexDemografia/Natalidades"
global POP "~/investigacion/2014/MexAbort/Data/Population"
global MUN "~/investigacion/2014/MexAbort/Data/Municip"
global LAB "~/investigacion/2014/MexAbort/Data/Labour/Desocupacion2000_2014"
global CON "~/investigacion/2014/MexAbort/Data/Contracep"
global LOG "~/investigacion/2014/MexAbort/Log"
global SOR "~/investigacion/2014/MexAbort/Source/dataPrep"


log using "$LOG/stateControls.txt", text replace

#delimit ;
local lName aguascalientes   baja_california   baja_california_sur   campeche
   coahuila_de_zaragoza  colima  chiapas  chihuahua  distrito_federal durango
   guanajuato guerrero  hidalgo  jalisco  mexico  michoacan_de_ocampo morelos
   nayarit  nuevo_leon  oaxaca  puebla queretaro quintana_roo san_luis_potosi
   sinaloa sonora tabasco tamaulipas tlaxcala veracruz_de_ignacio_de_la_llave
   yucatan zacatecas;
local fName `" "Aguascalientes" "Baja California" "Baja California Sur"
   "Campeche" "Chiapas" "Chihuahua" "Coahuila" "Colima" "Distrito Federal"
   "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Michoacán" "Morelos"
   "México" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo"
   "San Luis Potosí" "Sinaloa"  "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala"
   "Veracruz" "Yucatán" "Zacatecas" "';
local popName Chihuahua Sonora Coahuila Durango Oaxaca Tamaulipas Jalisco
   Zacatecas  BajaCaliforniaSur Chiapas Veracruz BajaCalifornia NuevoLeon
   Guerrero  SanLuisPotosi Michoacan Campeche Sinaloa QuintanaRoo Yucatan
   Puebla  Guanajuato  Nayarit  Tabasco  Mexico  Hidalgo Queretaro Colima
   Aguascalientes Morelos Tlaxcala DistritoFederal;
local popNum 8 26 5 10 20 28 14 32 3 7 30 2 19 12 24 16 4 25 23 31 21 11 18 27
   15 13 22 6 1 17 29 9;
#delimit cr

*-------------------------------------------------------------------------------
*--- (2a) Format state income sheets
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir income
!ssconvert -S siha_2_1_1.xlsx income/years.csv
foreach num of numlist 6(1)18 {
    insheet using income/years.csv.`num', comma clear
    keep in 4/35
    keep v1 v13
    rename v1 fullName
    rename v13 totalIncome
    gen year = 1995+`num'
    tempfile f`num'
    save `f`num''
}

clear all
append using `f6' `f7' `f8' `f9' `f10' `f11' `f12'
append using `f13' `f14' `f15' `f16' `f17' `f18'
save "$DAT/stateIncome", replace

*-------------------------------------------------------------------------------
*--- (2b) Format state spending sheets
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir spending
!ssconvert -S siha_2_1_2.xlsx spending/years.csv
foreach num of numlist 6(1)18 {
    insheet using spending/years.csv.`num', comma clear
    keep in 4/35
    keep v1 v13
    rename v1 fullName
    rename v13 totalSpending
    gen year = 1995+`num'
    tempfile f`num'
    save `f`num''
}

clear all
append using `f6' `f7' `f8' `f9' `f10' `f11' `f12'
append using `f13' `f14' `f15' `f16' `f17' `f18'
save "$DAT/stateSpending", replace


*-------------------------------------------------------------------------------
*--- (2c) Regional GDP
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir GDP
!ssconvert siha_2_1_5.xlsx GDP/GDP.csv

insheet using GDP/GDP.csv, comma clear
keep in 4/35
rename v1 fullName
destring v12, replace
reshape long v, i(fullName) j(year)
rename v GDP
replace year=2001+year
expand 4 if year==2003
bys fullName year: gen n=_n
replace GDP = . if n != 1
replace year = year-n+1 if n != 1
drop n
bys fullName (year): ipolate GDP year, gen(GDPfull) epolate
gen GDP03 = GDP if year==2003
bys fullName: egen GDPreplace = min(GDP03)
replace GDP = GDPfull
replace GDP = GDPreplace if GDP<0
drop GDPfull GDP03 GDPreplace
save "$DAT/stateGDP", replace

*-------------------------------------------------------------------------------
*--- (2d) Social variables
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir social
!ssconvert siha_3_1_2_5.xlsx social/social.csv

insheet using social/social.csv, comma clear
keep v1 v5-v7 v8-v10 v11-v13 v14-v16 v38-v40 
keep in 7/38
rename v5  noRead0
rename v6  noRead5
rename v7  noRead10
rename v8  noSchool0
rename v9  noSchool5
rename v10 noSchool10
rename v11 noPrimary0
rename v12 noPrimary5
rename v13 noPrimary10
rename v14 noHealth0
rename v15 noHealth5
rename v16 noHealth10
rename v38 vulnerable0
rename v39 vulnerable5
rename v40 vulnerable10
rename v1 fullName

reshape long noRead noSchool noPrimary noHealth vulnerable, i(fullName) j(year)
replace year = year+2000
foreach var of varlist no* vulnerable {
    replace `var' = subinstr(`var',",",".", 1)
    destring `var', replace
}
expand 5
bys fullName year: gen n=_n
foreach var of varlist no* vulnerable {
    replace `var'=. if n!=1
}
replace year = year+n-1 if n!=1 
drop if year==2014
foreach var of varlist no* vulnerable {
    bys fullName (year): ipolate `var' year, epolate gen(i_`var')
    replace `var'=i_`var' if `var'==.
    drop i_`var'
}
drop n
save "$DAT/socialIndicators", replace

*-------------------------------------------------------------------------------
*--- (2e) Social variables
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir corrup
!ssconvert siha_3_1_3_1.xlsx corrup/corruption.csv

insheet using corrup/corruption.csv, comma clear
keep in 4/35
rename v1 fullName

reshape long v, i(fullName) j(year)
replace year= 1997+2*year
replace year=2010 if year==2009
expand 2 if year<2007
bys fullName year: gen n=_n
replace year=year+n-1 if n!=1&year<2007 
drop n
expand 3 if year==2007
bys fullName year: gen n=_n
replace year=year+n-1 if n!=1
drop n
expand 4 if year==2010
bys fullName year: gen n=_n
replace year=year+n-1 if n!=1
drop n
destring v, replace
rename v corruption

replace fullName = "Coahuila"  if fullName=="Coahuila de Zaragoza"
replace fullName = "Jalisco"   if regexm(fullName,"Jalisco")
replace fullName = "Michoacán" if fullName=="Michoacán de Ocampo"
replace fullName = "Puebla"    if regexm(fullName, "Puebla")
replace fullName = "Veracruz"  if fullName=="Veracruz de Ignacio de la Llave"

replace corruption = subinstr(corruption, ",", ".", 1)
destring corruption, replace

save "$DAT/corruption", replace

*-------------------------------------------------------------------------------
*--- (2f) Seguro popular by state
*-------------------------------------------------------------------------------
use "$MUN/seguroPopularMonth"
collapse SP, by(id year)
destring id, gen(munid)
gen stateid = floor(munid/1000)
collapse SP, by(stateid year)

expand 4 if year==2010
bys stateid year: gen n=_n-1
replace year=year+n if n!=0
replace SP = 1 if year>2010
rename stateid stateNum
drop n

save "$DAT/seguroPopular", replace

*-------------------------------------------------------------------------------
*--- (2g) Labour market participation by state
*-------------------------------------------------------------------------------
foreach ENT of local lName {
    insheet using "$LAB/`ENT'.csv", comma names clear
    keep state number year trimeter desocup dsea
    drop if year<=2001|year>2013
    rename trimeter trimester
    rename desocup unemployment
    rename dsea deseasonUnemployment
    destring unemp, replace
    destring desea, replace
    expand 3
    bys state year trimester: gen month=_n
    replace month=month+3 if trimester=="II"
    replace month=month+6 if trimester=="III"
    replace month=month+9 if trimester=="IV"
    save "$LAB/`ENT'", replace
}
clear

foreach ENT of local lName {
    append using "$LAB/`ENT'"
}
tostring number, gen(id)

gen length=length(id)
gen zero="0" if length==1
egen stateid=concat(zero id)
drop id zero length number

collapse unemployment deseasonUnemp, by(year state stateid)
destring stateid, gen(stateNum)

sort state year

save "$DAT/Labour", replace




*-------------------------------------------------------------------------------
*--- (3) Merge everything together
*-------------------------------------------------------------------------------
use "$POP/populationStateYear"
drop month
keep if Age<100
keep Age stateName stateNum year_2002-year_2013
reshape long year_, i(Age stateName stateNum) j(year)
rename year_ population
reshape wide population, i(stateName stateNum year) j(Age)
drop stateNum
gen  stateNum = .


tokenize `popName'
foreach num of numlist `popNum' {
    replace stateNum = `num' if stateName == "`1'"
    macro shift
}


merge 1:1 stateNum year using "$DAT/Labour"
drop _merge 
merge 1:1 stateid year using "$CON/Contraception"
drop if year==2013|year==2000|year==2001
drop _merge
merge 1:1 stateNum year using "$DAT/seguroPopular"
drop if year==2013
drop _merge

gen fullName = ""
tokenize `lName'
foreach name of local fName {
    replace fullName = "`name'" if state=="`1'" 
    macro shift
}

foreach dat in stateIncome stateSpending stateGDP socialIndicators corruption {
    merge 1:1 fullName year using "$DAT/`dat'"
    drop if year==2013|year==2001|year==2000
    drop _merge
}

save "$DAT/stateData", replace

*-------------------------------------------------------------------------------
*--- (4) Birth data
*-------------------------------------------------------------------------------
use "$BIR/ENTMUN"
keep if cve_mun==0
drop v4
tempfile areas
save `areas'

foreach yy in 02 03 04 05 06 07 08 09 10 11 12 13 {
    use "$BIR/NACIM`yy'"
    keep if ano_nac>2001&ano_nac<2013
    gen birthsRegistered=1
    gen birthsResidents=1
    gen birthsOccurring=1
    gen rural = tloc_regis<=7

    preserve
    collapse (count) birthsRegistered, by(ent_regis edad_madn ano_nac)
    rename ent_regis cve_ent
    reshape wide birthsRegistered, i(cve_ent ano_nac) j(edad_madn)
    foreach num of numlist 10(1)50 99 {
        replace birthsRegistered`num'=0 if birthsRegistered`num'==.
    }
    tempfile registered
    save `registered'

    restore
    preserve
    collapse (count) birthsResidents, by(ent_resid edad_madn ano_nac)
    rename ent_resid cve_ent
    reshape wide birthsResidents, i(cve_ent ano_nac) j(edad_madn)
    foreach num of numlist 10(1)50 99 {
        replace birthsResidents`num'=0 if birthsResidents`num'==.
    }
    tempfile residents
    save `residents'

    restore
    preserve
    collapse (count) birthsOccurring, by(ent_ocurr edad_madn ano_nac)
    rename ent_ocurr cve_ent
    reshape wide birthsOccurring, i(cve_ent ano_nac) j(edad_madn)
    foreach num of numlist 10(1)50 99 {
        replace birthsOccurring`num'=0 if birthsOccurring`num'==.
    }
    tempfile occurring
    save `occurring'

    restore
    collapse rural, by(ent_regis ano_nac)
    rename ent_regis cve_ent
    tempfile rural
    save `rural'


    use `occurring', clear
    merge 1:1 cve_ent ano_nac using `residents'
    drop _merge
    merge 1:1 cve_ent ano_nac using `registered'
    drop _merge
    
    merge m:1 cve_ent using `areas'
    drop if _merge==2
    drop _merge cve_mun
    merge 1:1 cve_ent ano_nac using `rural'
    drop _merge

    tempfile f`yy'
    save `f`yy''
}
append using `f02' `f03' `f04' `f05' `f06' `f07' `f08' `f09' `f10' `f11' `f12'
collapse rural (rawsum) births* [pw=birthsOccurring30], by(cve_ent ano_nac nomb)
rename ano_nac year
rename cve_ent stateNum
save "$DAT/births"


*-------------------------------------------------------------------------------
*--- (5) Merge covariates to birth data
*-------------------------------------------------------------------------------
merge 1:1 stateNum year using "$DAT/stateData"


*-------------------------------------------------------------------------------
*--- (6) Rename, label
*-------------------------------------------------------------------------------
order state stateid stateName stateNum fullName nombre

egen populationWomen   = rowsum(population0-population99)
replace totalIncome    = totalIncome  /populationWomen
replace totalSpending  = totalSpending/populationWomen
replace GDP            = GDP          /populationWomen

rename nombre birthStateName
rename SP     seguroPopular
rename _merge mergedBirths

foreach num of numlist 10(1)50 99 {
    lab var birthsOccurring`num'  "Number of births occurring in state: age `num'"
    lab var birthsRegistered`num' "Number of births registered in state: age `num'"
    lab var birthsResidents`num'  "Number of births of state residents: age `num'"
}
lab var state          "State name: lower case, underscore instead of spaces"
lab var stateid        "INEGI state identifier: string, two digits"
lab var stateName      "State name: upper and lower case, no spaces"
lab var stateNum       "INEGI state identifier: numeric"
lab var fullName       "State name: With accents, and spaces"
lab var birthStateName "State name as per birth records"
lab var rural          "Proportion of births occurring in rural areas"
lab var unemployment   "Unemployment rate (INEGI)"
lab var deseasonUnempl "Unemployment rate deseasoned (INEGI)"
lab var condomFirstTee "Teenagers used condom at first intercourse"
lab var condomRecentTe "Teenagers used condom at most recent intercourse"
lab var anyFirstTeen   "Teenagers used any protection at first intercourse"
lab var adolescentKnow "Teenager reports knowing about contraceptives"
lab var condomRecent   "Adults used condom at most recent intercourse"
lab var anyRecent      "Adults used any protection at most recent intercourse"
lab var seguroPopular  "Percent of municipalities in state with Seguro Popular"
lab var totalIncome    "Total state income divided by number of women 0-99"
lab var totalSpending  "Total state spending divided by number of women 0-99"
lab var totalIncome    "Total state GDP divided by number of women 0-99"
lab var populationWome "Total number of women aged 0-99"
lab var noRead         "Percent of people over age 14 who can't read"
lab var noSchool       "Percent of people aged 6-14 who aren't enroled"
lab var noPrimary      "Percent of people over 14 who haven't completed primary"
lab var noHealth       "Percent of residents with no health rights"
lab var vulnerable     "Vulnerabilty index (lower=less vulnerable)"
lab var corruption     "Degree of corruption (lower=less corrupt)"

lab data "State*year varying controls and birth data (DCC, Aug 2015)"

*-------------------------------------------------------------------------------
*--- (X) Clean up
*-------------------------------------------------------------------------------
save "$DAT/stateData", replace
log close
cd "$SOR"

