
********************************************************************************
* Mexico
* Regressions
* date 2015-08-20	
********************************************************************************
global DAT 	"~/investigacion/2014/MexAbort/Data/Births"
global REG 	"~/Descargas"
global GRA	"~/Descargas"
global temp "~/Descargas"

set more off
clear all
/*
use 	"$DAT/stateData.dta", clear

drop 	birthsReg* birthsOc* 

reshape long birthsResidents population, i(year stateNum) j(age)

* Merge with MMR data
merge 1:1 stateNum age year using "$temp/MMRState_resid", force

drop if stateNum>32
drop if age<10 		| age>49
drop if year>2011  	| year<2002

replace MMR				=0 if _merge==1 

gen 	birth			=birthsResidents
gen 	birthRate		=birth/population*1000 
gen 	mmr				=MMR/birth*100000 
 
gen 	DF			  	= stateNum==9
gen 	MexState	  	= stateNum==15
gen 	Reform      	= stateNum==9&year>=2008
gen 	ReformClose		= stateNum==15&year>=2008

gen 	Area			=1 if DF==1
replace Area			=2 if stateNum==15
replace Area			=0 if Area==. 

gen 	ageGroup = .
local 	a1 = 5

foreach num of numlist 1(1)8 {
	local a1=`a1'+5
	local a2=`a1'+4
	dis "Ages: `a1', `a2'"
	replace ageGroup=`num' if age>=`a1'&age<=`a2'
}

save 	"$DAT/BirthMMRCovarNew.dta", replace
*/
use "$DAT/BirthMMRCovarNew.dta", clear
********************************************************************************
* Synth
********************************************************************************

*drop if stateNum==15

#delimit ;
collapse anyFirstTeen adolescentKnows condomRecent anyRecent seguroPopular 
totalIncome totalSpending GDP noRead noSchool noPrimary noHealth vulnerable
corruption populationWomen rural population unemployment deseasonUnemployment
condomFirstTeen condomRecentTeen  birthRate mmr MMR birth [fweight=birth],
by(stateNum year);
#delimit cr
 
gen logBirth    = log(birth)
gen logMMR      = log(MMR+1)
tsset state year

gen weightVar = .
gen estimates = .
local cu 1 2 3 4 5 6 7 8 9 10 11 12 13 14 16 17 18 19 20 21 22 23 24 25 26 27 /*
*/ 28 29 30 31 32

foreach num of numlist 1(1)32 {
    preserve
    local cunit
    foreach nn of local cu {
        if `nn'!=`num' local cunit `cunit' `nn'
    }
    dis "Control units for state `num' are: `cunit'"
    #delimit ;
    synth logBirth population logBirth totalIncome totalSpending GDP noRead
    noSchool noPrimary noHealth vulnerable condomFirstTeen condomRecentTeen
    corruption populationWomen rural unemployment deseasonUnemployment mmr,
    trunit(`num') trperiod(2008) xperiod(2002(1)2007)
    counit(`cunit') fig;
    #delimit cr

    mat def weights = e(W_weights)
    mat def Y1      = e(Y_treated)
    mat def Y0      = e(Y_synthetic)

    foreach nn of numlist 1(1)30 {
        local keep`nn' = weights[`nn',1]
        local wt`nn'   = weights[`nn',2]

        if `wt`nn''==0 {
            dis "Okay, dropping state `keep`nn''"
            drop if stateNum == `keep`nn''
        }
        if `wt`nn''>0 {
            replace weightVar = `wt`nn'' if stateNum==`keep`nn''
        }
    }
    replace weightVar = 1 if stateNum==`num'
    gen treated = stateNum==`num'
    gen post    = year>2007
    gen treatedXpost = treated*post
    *reg maternDeath treated i.year treatedXpost [pw = weightVar]
    reg birth treated i.year treatedXpost [pw = weightVar]
    outreg2 using "test.txt"
    if `num'==9 local est = _b[treatedXpost]/_se[treatedXpost]
    restore
    replace estimates = _b[treatedXpost]/_se[treatedXpost] in `num'

    gen resultState`num'=.
    foreach s of numlist 1(1)10 {
        replace resultState`num' = Y1[`s',1]-Y0[`s',1] in `s'
    }



*    synth maternDeath population maternDeath(2002(1)2006) totalIncome totalSpending
*    GDP noRead noSchool noPrimary noHealth vulnerable condomFirstTeen
*    condomRecentTeen corruption populationWomen rural population unemployment
*    deseasonUnemployment, trunit(`num') trperiod(2007) xperiod(2002(1)2006)
*    counit(`cunit') fig;

}

hist estimates, xline(`est', lcolor(red)) scheme(s1mono) bin(10)
graph export test.eps, replace

gen time = .
foreach num of numlist 1(1)10 {
    replace time = 2001+`num' in `num'
}
#delimit ;
twoway line resultState1 time in 1/10, lcolor(gs12)  ||
       line resultState2 time in 1/10, lcolor(gs12)  ||
       line resultState3 time in 1/10, lcolor(gs12)  ||
       line resultState4 time in 1/10, lcolor(gs12)  ||
       line resultState5 time in 1/10, lcolor(gs12)  ||
       line resultState6 time in 1/10, lcolor(gs12)  ||
       line resultState7 time in 1/10, lcolor(gs12)  ||
       line resultState8 time in 1/10, lcolor(gs12)  ||
       line resultState10 time in 1/10, lcolor(gs12) ||
       line resultState11 time in 1/10, lcolor(gs12) ||
       line resultState12 time in 1/10, lcolor(gs12) ||
       line resultState13 time in 1/10, lcolor(gs12) ||
       line resultState14 time in 1/10, lcolor(gs12) ||
       line resultState16 time in 1/10, lcolor(gs12) ||
       line resultState17 time in 1/10, lcolor(gs12) ||
       line resultState18 time in 1/10, lcolor(gs12) ||
       line resultState19 time in 1/10, lcolor(gs12) ||
       line resultState20 time in 1/10, lcolor(gs12) ||
       line resultState21 time in 1/10, lcolor(gs12) ||
       line resultState22 time in 1/10, lcolor(gs12) ||
       line resultState23 time in 1/10, lcolor(gs12) ||
       line resultState24 time in 1/10, lcolor(gs12) ||
       line resultState25 time in 1/10, lcolor(gs12) ||
       line resultState26 time in 1/10, lcolor(gs12) ||
       line resultState27 time in 1/10, lcolor(gs12) ||
       line resultState28 time in 1/10, lcolor(gs12) ||
       line resultState29 time in 1/10, lcolor(gs12) ||
       line resultState30 time in 1/10, lcolor(gs12) ||
       line resultState31 time in 1/10, lcolor(gs12) ||
       line resultState32 time in 1/10, lcolor(gs12) ||
       line resultState9 time in 1/10, lwidth(thick) lcolor(black)
scheme(s1mono) legend(off);
#delimit cr
graph export test2.eps, replace
exit
*line resultState15 time in 1/10, lcolor(gs12) ||


synth birthRate seguroPopular  population ///
totalIncome totalSpending GDP noRead noSchool noPrimary noHealth vulnerable ///
rural deseasonUnemployment corruption  ///     
birthRate(2002(1)2007), trunit(9) ///
trperiod(2008) xperiod(2002(1)2007) nested fig
 
synth mmr seguroPopular  ///
totalIncome GDP noRead noSchool noPrimary noHealth vulnerable ///
populationWomen rural deseasonUnemployment corruption   ///
mmr(2002(1)2006), trunit(9) ///
trperiod(2007) xperiod(2002(1)2006) nested fig

exit

********************************************************************************
* Plots
********************************************************************************

use "$DAT/BirthMMRCovarNew.dta", clear
drop if stateNum==15	  
la var 	birthRate 	"Birth rate"
la var 	mmr		 	"MMR"

local 	varList  birthRate mmr

foreach vari of local varList{
	local mylabel_`vari': var label `vari'
}		  
collapse (sum) birth population	MMR, by(Area year)
gen birthRate=birth/population*1000
gen mmr=MMR/birth*100000
  
#delimit ;	
foreach vari in mmr birthRate {; 
twoway line `vari' year if  Area==1 , yaxis(1)
|| line `vari' year if  Area==0, yaxis(1)
scheme(sj)
ytitle("`mylabel_`vari''") xtitle("Year") xline(2008, lpat(dash))
legend(label(1 "Federal District")label(2 "All other districts")   
ring(1) 		
pos(6) 
col(1)  
colgap(.5)
rowgap(.8)
region(lstyle(none))
symxsize(6)
size(small) )
graphr(fcolor(white))
plotregion(margin(zero))
ylabel(, angle(2)  labsize(small) nogrid)
xlabel(, angle(0) labsize(small) nogrid)
scale(1)
aspectratio(0);

graph export "$GRA/Trend_`vari'.pdf", as(pdf) replace;
};
********************************************************************************
* Trends in age specific birthrates and mmr
********************************************************************************
use "$DAT/BirthMMRCovarNew.dta", clear
drop if stateNum==15	  
collapse (sum) birth MMR population, by(Area year ageGroup) 
gen birthRate=birth/population*1000
gen mmr=MMR/birth*100000

la var 	birthRate 	"Birth rate"
la var 	mmr		 	"MMR"

local 	varList  birthRate mmr

foreach vari of local varList{
	local mylabel_`vari': var label `vari'
}	
#delimit ;	
foreach vari in birthRate mmr  {;
local upage 14 19 24 29 34 39 44 49;
tokenize `upage';
foreach ageG of numlist 1(1)8 {;
	if `ageG'==1 local lb=10;
	if `ageG'==2 local lb=15;
	if `ageG'==3 local lb=20;
	if `ageG'==4 local lb=25;
	if `ageG'==5 local lb=30;
	if `ageG'==6 local lb=35;
	if `ageG'==7 local lb=40;
	if `ageG'==8 local lb=45;
	set scheme  s2mono; 
	twoway line `vari' year if  Area==1& ageGroup==`ageG' , yaxis(1)
	|| line `vari' year if  Area==0&  ageGroup==`ageG' , yaxis(1)
	title("Ages `lb'-``ageG''")
	ytitle("`mylabel_`vari''") xtitle("Year") xline(2008, lpat(dash))
	legend(label(1 "Federal District")label(2 "All other districts")
	ring(1)
	pos(6) 
	col(1)  
	colgap(.5)
	rowgap(.8)
	region(lstyle(none))
	symxsize(6)
	size(small) )
	graphr(fcolor(white))
	plotregion(margin(zero))
	ylabel(, angle(10)  labsize(small) nogrid)
	xlabel(, angle(10) labsize(small) nogrid)
	aspectratio(0);
	graph export "$GRA/Trend_`vari'AgeG`ageG'.pdf", as(pdf) replace; 
	};
	 
	
};


********************************************************************************
* regressions
********************************************************************************
use "$DAT/BirthMMRCovarNew.dta", clear 
la var 	birthRate 	"Birth rate"
la var 	mmr		 	"MMR"

local 	varList  birthRate mmr

foreach vari of local varList{
	local mylabel_`vari': var label `vari'
}

tab year, gen(_year)
tab stateNum, gen(_state)
tab age, gen(_age)
foreach state of varlist _state* {
	gen _trend`state'=`state'*year
	*gen _trend2`state'=`state'*(year^2)
}

set more off
local Treat Reform  ReformClose  
local FE _year* _state* _age*
local StateTrend _trend* 
local clus stateNum
local CoVar deseasonUnemployment totalIncome GDP ///
	  noHealth vulnerable corruption rural seguroPopular  
local fmtopt "sdec(2) nocons nonot label tex(frag)"

foreach vari in birthRate mmr{ 

	preserve
*  keep if age>=15&age<=44
	#delimit;
*	clustse regress  `vari'  `Treat' `FE' `StateTrend', cluster(`clus') method(wild) reps(100);
  regress  `vari'  `Treat' `FE' `StateTrend' [pw=birthsResidents], cluster(`clus');
	outreg2 using "$REG/All`vari'.tex", tex(frag) replace keep(`Treat') nonotes 
	addtext(Year FE, YES, State FE, YES, Age FE, YES, State specific time trend, YES, Controls, NO) 
	label ctitle("`mylabel_`vari''")  nocons;


*  clustse regress `vari'  `Treat' `FE' `StateTrend' `CoVar', cluster(`clus') method(wild) reps(100);
  regress  `vari'  `Treat' `FE' `StateTrend' `CoVar' [pw=birthsResidents], cluster(`clus');
	outreg2 using "$REG/All`vari'.tex", tex(frag) append keep(`Treat') nonotes 
	addtext(Year FE, YES, State FE, YES, Age FE, YES, State specific time trend, YES, Controls, YES) 
	label ctitle("`mylabel_`vari''")  nocons;
	#delimit cr;
restore
}
exit


foreach vari in   birthRate mmr{  
set more off
local Treat Reform ReformClose    
local FE i.year i.stateNum i.age
local StateTrend i.stateNum#c.year 
local clus stateNum
local CoVar deseasonUnemployment totalIncome GDP ///
	  noHealth vulnerable corruption rural seguroPopular  
local fmtopt "sdec(2) nocons nonot label tex(frag)"

#delimit;
foreach age of numlist 1(1)8 {;
		regress  `vari' `Treat' `FE' `StateTrend' `CoVar' if ageGroup==`age', vce(cluster `clus');
		
est sto AgeGroup_`age';
	};
outreg2 [AgeGroup_1 AgeGroup_2 AgeGroup_3 AgeGroup_4 AgeGroup_5 AgeGroup_6 AgeGroup_7 AgeGroup_8]
using "$REG/AG_Reg_`vari'.tex", ctitle("`mylabel_`vari''")
 st(coef se) keep(`Treat') `fmtopt' replace 
addtext(Muncip FE, YES, Year FE, YES, State specific time trend, NO, Controls, NO);


 
#delimit;
foreach age of numlist 1(1)8 {;
		regress  `vari' `Treat' `FE' `StateTrend' `CoVar' [pweight=population] if ageGroup==`age', vce(cluster `clus');
		
est sto AgeGroup_`age';
	};
outreg2 [AgeGroup_1 AgeGroup_2 AgeGroup_3 AgeGroup_4 AgeGroup_5 AgeGroup_6 AgeGroup_7 AgeGroup_8]
using "$REG/AG_Reg_`vari'_weight.tex", ctitle("`mylabel_`vari''")
 st(coef se) keep(`Treat') `fmtopt' replace 
addtext(Muncip FE, YES, Year FE, YES, State specific time trend, NO, Controls, NO);


};
