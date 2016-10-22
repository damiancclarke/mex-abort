////////////////////////////////////////////////////////////////////////////////
/// Author: 	Hanna Mühlrad	    			 	             ///
/// File name: 	Birth_Outcomes						     ///
/// Created: 	2016-01-31						     ///	
/// Last Vers: 	OutputLog						     ///	
/// Data:  	"stateData" is created by Damian Clarke. The generating file ///
///		is Dropbox\Mexico\Source\dataPrep\stateContrPoisson.do	     ///	
///		"MMRState_resid" is created by Hanna Mühlrad. The generating ///
///		file is Dropbox\Mexico\Source\HannaSyntax\MMR_Generate.do    ///
////////////////////////////////////////////////////////////////////////////////

vers 11
clear all
set more off
cap log close

********************************************************************************	
*** (0) Setup
********************************************************************************
global DAT "~/investigacion/2014/MexAbort/Source/Aug2016"
global REG "~/investigacion/2014/MexAbort/Source/Aug2016/tables"
global GRA "~/investigacion/2014/MexAbort/Source/Aug2016/graphs"
global LOG "~/investigacion/2014/MexAbort/Source/Aug2016/log"

log  using "$LOG/output.txt", replace

foreach ado in ebalance esttab {
    cap which `ado'
    if _rc!=0 ssc install `ado'
}
  
********************************************************************************	
*** (1) MAIN TABLES
********************************************************************************
use "$DAT/BirthMMRCovarNew_year.dta", clear 

generat regressive = 1 if year > 2008 & stateName=="BajaCalifornia"
replace regressive = 1 if year > 2007 & stateName=="Chiapas"
replace regressive = 1 if year > 2008 & stateName=="Chihuahua"
replace regressive = 1 if year > 2009 & stateName=="Colima"
replace regressive = 1 if year > 2008 & stateName=="Durango"
replace regressive = 1 if year > 2008 & stateName=="Guanajuato"
replace regressive = 1 if year > 2009 & stateName=="Jalisco"
replace regressive = 1 if year > 2008 & stateName=="Morelos"
replace regressive = 1 if year > 2010 & stateName=="Nayarit"
replace regressive = 1 if year > 2009 & stateName=="Oaxaca"
replace regressive = 1 if year > 2010 & stateName=="Puebla"
replace regressive = 1 if year > 2009 & stateName=="Queretaro"
replace regressive = 1 if year > 2008 & stateName=="QuintanaRoo"
replace regressive = 1 if year > 2009 & stateName=="SanLuisPotosi"
replace regressive = 1 if year > 2008 & stateName=="Sonora"
replace regressive = 1 if year > 2009 & stateName=="Tamaulipas"
replace regressive = 1 if year > 2009 & stateName=="Yucatan"
replace regressive = 1 if year > 2010 & stateName=="Veracruz"
replace regressive = 1 if year > 2010 & stateName=="Campeche"
replace regressive = 0 if regressive!=1

#delimit ;
gen regressiveYear=2008 if stateName=="Chiapas";
replace regressiveYear=2009 if
stateName=="BajaCalifornia"|
stateName=="Chihuahua"     |
stateName=="Durango"       |
stateName=="Guanajuato"    |
stateName=="Morelos"       |
stateName=="QuintanaRoo"   |
stateName=="Sonora"        ;
replace regressiveYear=2010 if
stateName=="Colima"        |
stateName=="Jalisco"       |
stateName=="Oaxaca"        |
stateName=="Queretaro"     |
stateName=="SanLuisPotosi" |
stateName=="Tamaulipas"    |
stateName=="Yucatan"       ;
replace regressiveYear=2011 if
stateName=="Campeche"      |
stateName=="Nayarit"       |
stateName=="Puebla"        |
stateName=="Veracruz"      ;
gen progressiveYear=2008 if stateName=="DistritoFederal";
#delimit cr

gen dynamicRegres=year+1-regressiveYear
gen dynamicProgres=year+1-progressiveYear
foreach num of numlist 0(1)8 {
    gen regressiveN`num'=dynamicRegres==-`num'
    gen regressiveP`num'=dynamicRegres==`num'
    gen progressiveN`num'=dynamicProgres==-`num'
    gen progressiveP`num'=dynamicProgres==`num'
}

local Treat 	 Reform ReformClose regressive
local FE    	 i.year i.stateNum i.age
local StateTrend i.stateNum#c.year   
local clus 	     stateNum
local CoVar1 	 deseasonUnemployment totalIncome rural
local CoVar2 	 noRead noSchool
local CoVar3 	 noHealth seguroPopular
local con1 `FE'
local con2 `FE' `StateTrend'
local con3 `FE' `StateTrend' `CoVar1'
local con4 `FE' `StateTrend' `CoVar1' `CoVar2'
local con5 `FE' `StateTrend' `CoVar1' `CoVar2' `CoVar3'

********************************************************************************	
*** (1a) log(births) no entropy weights
********************************************************************************
local pwt  [aw=population]
estimates clear
eststo: regress ln_birth `Treat' `con1' `pwt', `se'
eststo: regress ln_birth `Treat' `con2' `pwt', `se'
eststo: regress ln_birth `Treat' `con3' `pwt', `se'
eststo: regress ln_birth `Treat' `con4' `pwt', `se'
eststo: regress ln_birth `Treat' `con5' `pwt', `se'

local cn if age<20
eststo: regress ln_birth `Treat' `con1' `pwt' `cn', `se'
eststo: regress ln_birth `Treat' `con2' `pwt' `cn', `se'
eststo: regress ln_birth `Treat' `con3' `pwt' `cn', `se'
eststo: regress ln_birth `Treat' `con4' `pwt' `cn', `se'
eststo: regress ln_birth `Treat' `con5' `pwt' `cn', `se'
lab var regressive "Regressive Law Change"
lab var Reform     "ILE Reform"
lab var ln_birth   "ln(Birth)"

#delimit ;
esttab est1 est2 est5 est6 est7 est10 using "$REG/Births-wRegressive.tex",
replace cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(N, fmt(%9.0g) label(Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
keep(Reform regressive _cons)
mgroups("All Women" "Teen-aged Women", pattern(1 0 0 1 0 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Effect of the ELA Reform and Resulting Law Changes on Birth Rates")
postfoot("State and Year FEs    & Y & Y & Y & Y & Y & Y \\             "
         "State Linear Trends   &   & Y & Y &   & Y & Y \\             "
         "Time-Varying Controls &   &   & Y &   &   & Y \\             "
         "\bottomrule\multicolumn{7}{p{14.8cm}}{\begin{footnotesize}   "
         " Difference-in-difference estimates of the reform on rates   "
         " of births are displayed.  Standard errors clustered by      "
         "state are presented in parentheses.  All regressions are     "
         "weighted by population of women of the relevant age group    "
         "in each state and year. ***p-value$<$0.01, **p-value$<$0.05, "
         "*p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

local pwt  [aw=birth]
gen MMratio = (MMR/birth)*100000
eststo: regress MMratio `Treat' `con1' `pwt', `se'
eststo: regress MMratio `Treat' `con2' `pwt', `se'
eststo: regress MMratio `Treat' `con3' `pwt', `se'
eststo: regress MMratio `Treat' `con4' `pwt', `se'
eststo: regress MMratio `Treat' `con5' `pwt', `se'

local cn if age<20
eststo: regress MMratio `Treat' `con1' `pwt' `cn', `se'
eststo: regress MMratio `Treat' `con2' `pwt' `cn', `se'
eststo: regress MMratio `Treat' `con3' `pwt' `cn', `se'
eststo: regress MMratio `Treat' `con4' `pwt' `cn', `se'
eststo: regress MMratio `Treat' `con5' `pwt' `cn', `se'
lab var MMratio "MMR"

#delimit ;
esttab est1 est2 est5 est6 est7 est10 using "$REG/MMR-wRegressive.tex",
replace cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(N, fmt(%9.0g) label(Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
keep(Reform regressive _cons)
mgroups("All Women" "Teen-aged Women", pattern(1 0 0 1 0 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Effect of the ELA Reform and Resulting Law Changes on Maternal Mortality Ratio")
postfoot("State and Year FEs    & Y & Y & Y & Y & Y & Y \\             "
         "State Linear Trends   &   & Y & Y &   & Y & Y \\             "
         "Time-Varying Controls &   &   & Y &   &   & Y \\             "
         "\bottomrule\multicolumn{7}{p{14.8cm}}{\begin{footnotesize}   "
         " Difference-in-difference estimates of the reform on the     "
         "maternal mortality ratio (deaths per 100,000 live births)    "
         "are displayed.  Standard errors clustered by state are       "
         "presented in parentheses.  All regressions are weighted by   "
         "the number of births occurring to the relevant age group     "
         "in each state and year. ***p-value$<$0.01, **p-value$<$0.05, "
         "*p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


********************************************************************************	
*** (1b) log(births) with wild bootstrapping
********************************************************************************
local pwt  [aw=population]
local cse  
tab year    , gen(_year)
tab stateNum, gen(_snum)
tab age     , gen(_age)
foreach num of numlist 1(1)32 {
    gen _Tsnum`num' = _snum`num'*year
}
local FE    	 _year* _snum* _age*
local StateTrend _Tsnum*

foreach num of numlist 1 2 3 {
    if `num'==1 {
        #delimit ;
        clustse regress ln_birth Reform ReformClose regressive _year*
        _snum* _age*, cluster(stateNum) method(wild) reps(200) seed(272);
       #delimit cr
    }
    if `num'==2 {
        #delimit ;
        clustse regress ln_birth Reform ReformClose regressive _year*
        _snum* _Tsnum* _age*, cluster(stateNum) method(wild) reps(200) seed(272);
       #delimit cr
    }
    if `num'==3 {
        #delimit ;
        clustse regress ln_birth Reform ReformClose regressive _year*
        _snum* _Tsnum* _age* deseasonUnemployment totalIncome rural noRead
        noSchool noHealth seguroPopular, cluster(stateNum) method(wild)
        reps(200) seed(272);
       #delimit cr
    }
    foreach v of numlist 1 3 {
        local nB = `v'+3
        mat def Allboot = e(bootresults)
        mat def Refboot = Allboot[201...,`nB']
        mat def Ests    = e(b)
        svmat Refboot
        sort Refboot1
        mkmat Refboot1, nomissing
        drop Refboot1
        local lb = string(Refboot1[5,1], "%5.3f")
        local ub = string(Refboot1[195,1], "%5.3f")
        local ci`num'A`v' = "[`lb',`ub']"
        local b`num'A`v' = string(Ests[1,`v'], "%5.3f")
        if `lb'>0&`ub'>0 local b`num'A`v' = "`b`num'A`v''$^{\ddagger} $"
        if `lb'<0&`ub'<0 local b`num'A`v' = "`b`num'A`v''$^{\ddagger} $"        
    }
}

preserve
keep if age<20
foreach num of numlist 1 2 3 {    
    if `num'==1 {
        #delimit ;
        clustse regress ln_birth Reform ReformClose regressive _year*
        _snum* _age*, cluster(stateNum) method(wild) reps(200) seed(272);
       #delimit cr
    }
    if `num'==2 {
        #delimit ;
        clustse regress ln_birth Reform ReformClose regressive _year*
        _snum* _Tsnum* _age*, cluster(stateNum) method(wild) reps(200) seed(272);
       #delimit cr
    }
    if `num'==3 {
        #delimit ;
        clustse regress ln_birth Reform ReformClose regressive _year*
        _snum* _Tsnum* _age* deseasonUnemployment totalIncome rural noRead
        noSchool noHealth seguroPopular, cluster(stateNum) method(wild)
        reps(200) seed(272);
       #delimit cr
    }
    foreach v of numlist 1 3 {
        local nB = `v'+3
        mat def Allboot = e(bootresults)
        mat def Refboot = Allboot[201...,`nB']
        mat def Ests    = e(b)
        svmat Refboot
        sort Refboot1
        mkmat Refboot1, nomissing
        drop Refboot1
        local lb = string(Refboot1[5,1], "%5.3f")
        local ub = string(Refboot1[195,1], "%5.3f")
        local ci`num'Y`v' = "[`lb',`ub']"
        local b`num'Y`v' = string(Ests[1,`v'], "%5.3f")
        if `lb'>0&`ub'>0 local b`num'Y`v' = "`b`num'Y`v''$^{\ddagger} $"
        if `lb'<0&`ub'<0 local b`num'Y`v' = "`b`num'Y`v''$^{\ddagger} $"        
    }
}
file open results using "$REG/Births-wild.tex", write replace
#delimit ;
file write results "\begin{table}[htbp]\centering 
\caption{Replicating Fertility Results with Wild Cluster Bootstrapping} 
\begin{tabular}{l*{6}{c}}  \toprule
&\multicolumn{3}{c}{All Women}&\multicolumn{3}{c}{Teen-aged Women} \\
\cmidrule(lr){2-4}\cmidrule(lr){5-7} 
&(1)&(2)&(3)&(4)&(5)&(6) \\ 
&ln(Birth)&ln(Birth)&ln(Birth)&ln(Birth)&ln(Birth)&ln(Birth) \\ 
\midrule  ILE Reform &`b1A1'&`b2A1'&`b3A1'&`b1Y1'&`b2Y1'&`b3Y1'\\ 
&`ci1A1'&`ci2A1'&`ci3A1'&`ci1Y1'&`ci2Y1'&`ci3Y1'\\ 
Regressive Law Change&`b1A3'&`b2A3'&`b3A3'&`b1Y3'&`b2Y3'&`b3Y3'\\ 
&`ci1A3'&`ci2A3'&`ci3A3'&`ci1Y3'&`ci2Y3'&`ci3Y3'\\ 
\midrule  Observations & 9600& 9600& 9600& 1600& 1600& 1600\\ 
State and Year FEs    & Y & Y & Y & Y & Y & Y \\ 
State Linear Trends   &   & Y & Y &   & Y & Y \\ 
Time-Varying Controls &   &   & Y &   &   & Y \\ 
\bottomrule
\multicolumn{7}{p{18cm}}{\begin{footnotesize} Results replicate unweighted
difference-in-difference estimates of the effect of reforms on rates of
birth, however now using wild bootstrapped standard errors in place of
analytical standard errors clustered at the level of the state.  Point
estimates are presented, along with 95\% confidence intervals of these
estimates in parentheses.  $^\ddagger $ Significant at the 95\% level.
\end{footnotesize}}
\end{tabular}\end{table}";
#delimit cr
file close results
restore
exit

********************************************************************************	
*** (2) Entropy weighting
********************************************************************************
foreach yr of numlist 2002(1)2007 {
    gen birthtemp = ln_birth if year==`yr'
    bys stateNum age: egen bAve`yr' = mean(birthtemp)
    drop birthtemp
}
gen treat = stateNum==9
local preYears bAve2002 bAve2003 bAve2004 bAve2005 bAve2006 bAve2007
ebalance treat `preYears', gen(entropyWt)

preserve
collapse ln_birth MMR [pw=entropyWt], by(treat year)
#delimit ;
twoway line ln_birth year if treat==1, lcolor(black)
lwidth(thick) lpattern(dash) ||
    line ln_birth year if treat==0, lcolor(black)
xline(2007.25, lcolor(red)) ytitle("log(Number of Births)")
legend(lab(1 "Mexico DF") lab(2 "Rest of Mexico")) scheme(s1mono);
graph export "$GRA/entropyBirths.eps", as(eps) replace;
#delimit cr
restore

foreach yr of numlist 2002(1)2007 {
    gen mmrtemp = MMratio if year==`yr'
    bys stateNum age: egen mAve`yr' = mean(mmrtemp)
    drop mmrtemp
}
local preYears mAve2002 mAve2003 mAve2004 mAve2005 mAve2006 mAve2007
ebalance treat `preYears', gen(entropyWtMMR)

preserve
collapse MMratio [pw=entropyWtMMR], by(treat year)
#delimit ;
twoway line MMratio year if treat==1, lcolor(black)
lwidth(thick) lpattern(dash) ||
    line MMratio year if treat==0, lcolor(black)
xline(2007.25, lcolor(red)) ytitle("Maternal Mortality Ratio")
legend(lab(1 "Mexico DF") lab(2 "Rest of Mexico")) scheme(s1mono);
graph export "$GRA/entropyMMR.eps", as(eps) replace;
#delimit cr
restore


drop bAve* mAve*
local ageTitle 15-18 19-24 25-34 35-39 40-44 
tokenize `ageTitle'

generate 	ageGroup2 = .
replace 	ageGroup2=1 if age>=15&age<19
replace 	ageGroup2=2 if age>=19&age<25
replace 	ageGroup2=3 if age>=25&age<35
replace 	ageGroup2=4 if age>=35&age<40
replace 	ageGroup2=5 if age>=40&age<45

foreach iter of numlist 1 2 3 4 5 {
    preserve
    keep if ageGroup2==`iter'
    foreach yr of numlist 2002(1)2007 {
        gen birthtemp = ln_birth if year==`yr'
        bys stateNum age: egen bAve`yr' = mean(birthtemp)
        drop birthtemp
    }
    local preYears bAve2002 bAve2003 bAve2004 bAve2005 bAve2006 bAve2007
    ebalance treat `preYears', gen(entropyWt`iter')

    collapse ln_birth [pw=entropyWt`iter'], by(treat year)
    #delimit ;
    twoway line ln_birth year if treat==1, lcolor(black) lwidth(thick)
    lpattern(dash) || line ln_birth year if treat==0, lcolor(black)
    xline(2007.25, lcolor(red))
    ytitle("log(Number of Births)")
    legend(lab(1 "Mexico DF") lab(2 "Rest of Mexico")) scheme(s1mono);
    graph export "$GRA/entropyBirths_age``iter''.eps", as(eps) replace;
    #delimit cr
    restore
}

tokenize `ageTitle'
foreach iter of numlist 1 2 3 4 5 {
    preserve
    keep if ageGroup2==`iter'
    foreach yr of numlist 2002(1)2007 {
        gen mmrtemp = MMratio if year==`yr'
        bys stateNum age: egen mAve`yr' = mean(mmrtemp)
        drop mmrtemp
    }
    local preYears mAve2002 mAve2003 mAve2004 mAve2005 mAve2006 mAve2007 
    ebalance treat `preYears', gen(entropyWt`iter')

    collapse MMratio [pw=entropyWt`iter'], by(treat year)
    #delimit ;
    twoway line MMratio year if treat==1, lcolor(black) lwidth(thick)
    lpattern(dash) || line MMratio year if treat==0, lcolor(black)
    xline(2007.25, lcolor(red))
    ytitle("Maternal Mortality Ratio") legend(lab(1 "Mexico DF") lab(2
    "Rest of Mexico")) scheme(s1mono); graph export
    "$GRA/entropyMMR_age``iter''.eps", as(eps) replace;
    #delimit cr
    restore
}


local ewt [pw=entropyWt]
eststo: regress ln_birth `Treat' `con1' `ewt', `se'
eststo: regress ln_birth `Treat' `con2' `ewt', `se'
eststo: regress ln_birth `Treat' `con3' `ewt', `se'
eststo: regress ln_birth `Treat' `con4' `ewt', `se'
eststo: regress ln_birth `Treat' `con5' `ewt', `se'

local cn if age<20
eststo: regress ln_birth `Treat' `con1' `ewt' `cn', `se'
eststo: regress ln_birth `Treat' `con2' `ewt' `cn', `se'
eststo: regress ln_birth `Treat' `con3' `ewt' `cn', `se'
eststo: regress ln_birth `Treat' `con4' `ewt' `cn', `se'
eststo: regress ln_birth `Treat' `con5' `ewt' `cn', `se'

#delimit ;
esttab est1 est2 est5 est6 est7 est10 using "$REG/Births-entropyWt.tex",
replace cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(N, fmt(%9.0g) label(Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
keep(Reform regressive _cons)
mgroups("All Women" "Teen-aged Women", pattern(1 0 0 1 0 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Effect of the ELA Reform and Resulting Law Changes on Birth Rates
(Entropy Weighting)")
postfoot("State and Year FEs    & Y & Y & Y & Y & Y & Y \\          "
         "State Linear Trends   &   & Y & Y &   & Y & Y \\          "
         "Time-Varying Controls &   &   & Y &   &   & Y \\          "
         "\bottomrule\multicolumn{7}{p{14.8cm}}{\begin{footnotesize}"
         "Specifications replicate those in table 1, however now    "
         "using entropy re-weighting to balance pre-reform trends in"
         "births as described in \citet{Hainmueller2012}.  Standard "
         "errors clustered by state are presented in parentheses.   "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear

local ewt  [pw=entropyWtMMR]
eststo: regress MMratio `Treat' `con1' `ewt', `se'
eststo: regress MMratio `Treat' `con2' `ewt', `se'
eststo: regress MMratio `Treat' `con3' `ewt', `se'
eststo: regress MMratio `Treat' `con4' `ewt', `se'
eststo: regress MMratio `Treat' `con5' `ewt', `se'

local cn if age<20
eststo: regress MMratio `Treat' `con1' `ewt' `cn', `se'
eststo: regress MMratio `Treat' `con2' `ewt' `cn', `se'
eststo: regress MMratio `Treat' `con3' `ewt' `cn', `se'
eststo: regress MMratio `Treat' `con4' `ewt' `cn', `se'
eststo: regress MMratio `Treat' `con5' `ewt' `cn', `se'
lab var MMratio "MMR"

#delimit ;
esttab est1 est2 est5 est6 est7 est10 using "$REG/MMR-entropyWt.tex",
replace cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(N, fmt(%9.0g) label(Observations))
starlevel ("*" 0.10 "**" 0.05 "***" 0.01) collabels(none) label
keep(Reform regressive _cons)
mgroups("All Women" "Teen-aged Women", pattern(1 0 0 1 0 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
title("The Effect of the ELA Reform and Resulting Law Changes on MMR
(Entropy Weighting)")
postfoot("State and Year FEs    & Y & Y & Y & Y & Y & Y \\             "
         "State Linear Trends   &   & Y & Y &   & Y & Y \\             "
         "Time-Varying Controls &   &   & Y &   &   & Y \\             "
         "\bottomrule\multicolumn{7}{p{14.8cm}}{\begin{footnotesize}   "
         "Specifications replicate those in table 1, however now    "
         "using entropy re-weighting to balance pre-reform trends in"
         "births as described in \citet{Hainmueller2012}.  Standard "
         "errors clustered by state are presented in parentheses.   "
         "***p-value$<$0.01, **p-value$<$0.05, *p-value$<$0.01."
         "\end{footnotesize}}\end{tabular}\end{table}") style(tex);
#delimit cr
estimates clear


********************************************************************************	
*** (3) Event Studies
********************************************************************************
local pwt  [aw=population]
#delimit ;
local events regressiveN8 regressiveN7 regressiveN6 regressiveN5 regressiveN4
regressiveN3 regressiveN2 regressiveN1 progressiveN5 progressiveN4 progressiveN3
progressiveN2 progressiveN1 regressiveP1 regressiveP2 regressiveP3 regressiveP4 
progressiveP1 progressiveP2 progressiveP3 progressiveP4;
#delimit cr
eststo: regress ln_birth `con1' `CoVar1' `CoVar2' `CoVar3' `events' `pwt', `se' 

gen EST = .
gen LB  = .
gen UB  = .
gen NUM = .
local j=1

foreach num of numlist 5(-1)1 {
    replace EST = _b[progressiveN`num'] in `j'
    replace LB  = _b[progressiveN`num']-1.96*_se[progressiveN`num'] in `j'
    replace UB  = _b[progressiveN`num']+1.96*_se[progressiveN`num'] in `j'
    replace NUM = -`num' in `j'
    local ++j
}
replace EST = 0 in `j'
replace LB  = 0 in `j'
replace UB  = 0 in `j'
replace NUM = 0 in `j'
local ++j

foreach num of numlist 1(1)4 {
    replace EST = _b[progressiveP`num'] in `j'
    replace LB  = _b[progressiveP`num']-1.96*_se[progressiveP`num'] in `j'
    replace UB  = _b[progressiveP`num']+1.96*_se[progressiveP`num'] in `j'
    replace NUM = `num' in `j'
    local ++j
}
#delimit ;
twoway line EST NUM in 1/`j', lcolor(black) lwidth(medthick) scheme(s1mono)
  || rcap LB UB NUM in 1/`j', lcolor(gs3) xtitle("Time") ytitle("Estimate")
  yline(0, lcolor(black) lpattern(dash)) xlabel(-5 -4 -3 -2 -1 0 1 2 3 4)
  legend(order(1 "Point Estimate" 2 "95% CI"));
graph export "$GRA/birthEvent.eps", replace as(eps);
#delimit cr


********************************************************************************	
*** (5) Close
********************************************************************************
log close
dis _newline(3) "Exiting without error" _newline(3)

