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
global POP "~/investigacion/2014/MexAbort/Data/Population"
global MUN "~/investigacion/2014/MexAbort/Data/Municip"
global LAB "~/investigacion/2014/MexAbort/Data/Labour/Desocupacion2000_2014"
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
    rename v1 stateName
    rename v13 totalIncome
    gen year = 1995+`num'
    tempfile f`num'
    save `f`num''
}

clear all
append using `f6' `f7' `f8' `f9' `f10' `f11' `f12' `f13' `f14' `f15' `f16' `f17' `f18'
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
    rename v1 stateName
    rename v13 totalIncome
    gen year = 1995+`num'
    tempfile f`num'
    save `f`num''
}

clear all
append using `f6' `f7' `f8' `f9' `f10' `f11' `f12' `f13' `f14' `f15' `f16' `f17' `f18'
save "$DAT/stateSpending", replace


*-------------------------------------------------------------------------------
*--- (2c) Regional GDP
*-------------------------------------------------------------------------------
cd "$DAT" 
cap mkdir GDP
!ssconvert siha_2_1_5.xlsx GDP/GDP.csv

insheet using GDP/GDP.csv, comma clear
keep in 4/35
rename v1 stateName
destring v12, replace
reshape long v, i(state) j(year)
rename v GDP
replace year=2001+year
expand 4 if year==2003
bys stateName year: gen n=_n
replace GDP = . if n != 1
replace year = year-n+1 if n != 1
drop n
bys stateName (year): ipolate GDP year, gen(GDPfull) epolate
gen GDP03 = GDP if year==2003
bys stateName: egen GDPreplace = min(GDP03)
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
rename v1 stateName

reshape long noRead noSchool noPrimary noHealth vulnerable, i(stateName) j(year)
replace year = year+2000
foreach var of varlist no* vulnerable {
    replace `var' = subinstr(`var',",",".", 1)
    destring `var', replace
}
expand 5
bys stateName year: gen n=_n
foreach var of varlist no* vulnerable {
    replace `var'=. if n!=1
}
replace year = year+n-1 if n!=1 
drop if year==2014
foreach var of varlist no* vulnerable {
    bys stateName (year): ipolate `var' year, epolate gen(i_`var')
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
rename v1 stateName

reshape long v, i(stateName) j(year)
replace year= 1997+2*year
replace year=2010 if year==2009
expand 2 if year<2007
bys stateName year: gen n=_n
replace year=year+n-1 if n!=1&year<2007 
drop n
expand 3 if year==2007
bys stateName year: gen n=_n
replace year=year+n-1 if n!=1
drop n
expand 4 if year==2010
bys stateName year: gen n=_n
replace year=year+n-1 if n!=1
drop n
destring v, replace
rename v corruption

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




*merge all above, merge in labour, merge in contracep


cd "$SOR"
exit
