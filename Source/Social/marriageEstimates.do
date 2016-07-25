/* marriageEstimates.do v0.00    damiancclarke             yyyy-mm-dd:2016-07-25
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Examine trends in marriage composition between states over time.

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) globals, locals
*-------------------------------------------------------------------------------
global DAT "~/database/MexDemografia/Nupcialidad/"
global OUT "~/investigacion/2014/MexAbort/Results/Marriage/"
cap mkdir "$OUT/plots"

#delimit ;
local snames `" "Aguascalientes" "Baja California" "Baja California Sur"
"Campeche" "Coahuila de Zaragoza" "Colima" "" "';
local popName Chihuahua Sonora Coahuila Durango Oaxaca Tamaulipas Jalisco     
   Zacatecas BajaCaliforniaSur Chiapas Veracruz BajaCalifornia NuevoLeon      
   Guerrero SanLuisPotosi Michoacan Campeche Sinaloa QuintanaRoo Yucatan      
   Puebla Guanajuato Nayarit Tabasco Mexico Hidalgo Queretaro Colima          
   Aguascalientes Morelos Tlaxcala DistritoFederal;
local popNum 8 26 5 10 20 28 14 32 3 7 30 2 19 12 24 16 4 25 23 31 21 11 18 27
   15 13 22 6 1 17 29 9;
#delimit cr

*-------------------------------------------------------------------------------
*--- (2) generate microdata 
*-------------------------------------------------------------------------------
foreach year in 02 03 04 05 06 07 08 09 {
    use "$DAT/MATRI`year'", clear
    gen state        = ent_regis
    gen municipality = mun_regis
    gen wifeAge      = edad_la
    gen husbandAge   = edad_el
    gen year         = anio_regis
    gen month        = mes_regis
    gen day          = dia_regis
    gen wifeJob      = ocup_la
    gen husbandJob   = ocup_el
    gen wifeEduc     = escol_la
    gen husbandEduc  = escol_el

   keep state municipality wife* husband* year month day
    tempfile y`year'
    save `y`year''
}
foreach year in 10 11 {
    use "$DAT/MATRI`year'", clear
    gen state        = ent_regis
    gen municipality = mun_regis
    gen year         = anio_regis
    gen month        = mes_regis
    gen day          = dia_regis
    drop if (sexo_con1==1&sexo_con2==1)|(sexo_con2==2&sexo_con1==2)
    
    gen wifeAge      = edad_con2
    gen husbandAge   = edad_con1
    gen wifeJob      = ocup_con2
    gen husbandJob   = ocup_con1
    gen wifeEduc     = escol_con2
    gen husbandEduc  = escol_con1
    
    keep state municipality wife* husband* year month day
    tempfile y`year'
    save `y`year''
}
clear
append using `y02' `y03' `y04' `y05' `y06' `y07' `y08' `y09' `y10' `y11'


tokenize `popName'
gen stateName = ""
foreach num of numlist `popNum' {
    replace stateName = "`1'" if state==`num'
    macro shift
}

dat lab "Microdata of all heterosexual marriages 2002-2011"
save "$DAT/nupcialidad_2002-2011"


*-------------------------------------------------------------------------------
*--- (3) Proportion of marriage under 20 in Mex DF and non-DF
*-------------------------------------------------------------------------------
foreach s in wife husband {
    gen `s'Schooling = 1 if `s'Educ == 1
    replace `s'Schooling = 2 if `s'Educ>=2&`s'Educ<=4
    replace `s'Schooling = 3 if `s'Educ==5
    replace `s'Schooling = 4 if `s'Educ==6
    replace `s'Schooling = 5 if `s'Educ==7|`s'Educ==8
    replace `s'Schooling = `s'Educ if year<2009
    replace `s'Schooling = . if `s'Educ==9
}


preserve
gen under21 = wifeAge<21
gen      DF = state==9
replace  DF = 2 if state==15
collapse under21, by(DF year month)
gen time = year+(month-1)/12

scatter under21 time if DF==1, xline(2007.25, lcolor(red)) scheme(s1mono)
graph export "$OUT/plots/under21_DF.eps", replace

scatter under21 time if DF==0, xline(2007.25, lcolor(red)) scheme(s1mono)
graph export "$OUT/plots/under21_nonDF.eps", replace

#delimit ;
twoway scatter under21 time if DF==1, xline(2007.25, lcolor(red)) ||
       scatter under21 time if DF==0, scheme(s1mono);
graph export "$OUT/plots/under21_both.eps", replace;
#delimit cr

restore


preserve
gen moreEducatedWife = wifeSchooling>husbandSchooling
replace moreEducatedWife=. if wifeSchooling==.|husbandSchooling==.
gen      DF = state==9
replace  DF = 2 if state==15
collapse moreEducatedWife, by(DF year month)
gen time = year+(month-1)/12

scatter moreEducatedWife time if DF==1, xline(2007.25, lcolor(red)) scheme(s1mono)
graph export "$OUT/plots/moreEducatedWife_DF.eps", replace

scatter moreEducatedWife time if DF==0, xline(2007.25, lcolor(red)) scheme(s1mono)
graph export "$OUT/plots/moreEducatedWife_nonDF.eps", replace

#delimit ;
twoway scatter moreEducatedWife time if DF==1, xline(2007.25, lcolor(red)) ||
       scatter moreEducatedWife time if DF==0, scheme(s1mono);
graph export "$OUT/plots/moreEducatedWife_both.eps", replace;
#delimit cr

restore

