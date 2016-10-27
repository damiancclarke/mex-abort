*------------------------------------------------------------------------------*
/*
Author: Hanna Mühlrad
Created: 2016-08-17
Previous Versions: MXFLS
Data: MXFLS, Book IIIA Characteristics of Adult Household Members. 
Data prep: Susanna L, Panel book3a
*/
/*1. The food that is eaten in the house 2. Your clothes 
3. Your spouses/couples clothes 4. Your childrens clothes 
5. The education of your children 
6 Health services and medicine of your children. 
7. Strong expenditures for the house (refrigerator, car, furniture, etc.)
8. Money that is given to your parents/relatives 9. Money that is given to
your parents/relatives of your spouse/couple 10. If you should work or
not 11. If your spouse/couple should work or not 12. If you or your
spouse/couple use contraceptives (for not having children) */

vers 11
clear all
set more off
cap log close
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
* Globals
set more off
global REG 	 	 "~/investigacion/2014/MexAbort/Source/Aug2016/tables"
global DAT_MXFLS ""
global temp 	 ""
global Temp		 ""

log using "MxFLS-results.txt", text replace

use book3a2Damian

keep 		if sex==3 
 

* Generate 
generate     Indigenous			= ed03==1 	& ed03!=.
generate     Noscooling			= ed05==3 	& ed05!=.
generate     EducLevel			= ed07_1 	& ed07_1!=.
replace      EducLevel			= . 	    if ed07_1==8 | ed07_1==98
generate     stateNum			= ent
generate 	 age				= edad
generate 	 str2 month 		= string(mes,"%02.0f") 	 if  mes!=.
generate 	 str4 yyear 		= string(vyear,"%04.0f") if  vyear!=.  
generate 	 year_month 		= yyear + month 		 if  vyear!=. | mes!=.
destring 	 year_month			, gen(ymonth)
replace 	 ymonth  			=. 						 if ymonth<200907
 

generate	 Reform				=	ent==9&round==3 
replace 	 Reform				=. 	if ent==.|round==.
generate	 ReformClose		=	ent==15&round==3 if ent!=.|round!=.
replace 	 ReformClose		=. 	if ent==.|round==.
* Regressive states:
*Durango, May 31, 2009, with lag: March 7 2010
generate 	Regressive = 1 if  ymonth>=201003 & stateNum==10 & ymonth!=.
*Guanajuato, May 26, 2009, with lag: March 2 2010
replace 	Regressive = 1 if ymonth>=201003 & stateNum==11 & ymonth!=.
*Jalisco, Jul 02, 2009, with lag: April 8 2010 
replace 	Regressive = 1 if ymonth>=201004 & stateNum==14 & ymonth!=.
*Morelos, Dec 11, 2008, with lag: September 17 2009 
replace 	Regressive = 1 if ymonth>=201009 & stateNum==16 & ymonth!=.
*Oaxaca, Sep 11, 2009, with lag: June 18 2010
replace 	Regressive = 1 if ymonth>=201006 & stateNum==20 & ymonth!=.
*Puebla, Jun 03, 2009, with lag: March 10 2010
replace 	Regressive = 1 if ymonth>=201003 & stateNum==21 & ymonth!=.
*Queretaro, Sep 18, 2009, with lag: June 25 2010
replace 	Regressive = 1 if ymonth>=201006 & stateNum==22 & ymonth!=.
* Quintana Roo, May 15, 2009, with lag: February 19 2010
replace 	Regressive = 1 if ymonth>=201002 & stateNum==23 & ymonth!=.
* Sonora Apr 06, 2009, with lag: January 11 2010
replace 	Regressive = 1 if ymonth>=201001 & stateNum==26 & ymonth!=.
* Tamaulipas, Dec 23, 2009, with lag: September 29 2010 
replace 	Regressive = 1 if ymonth>=201010 & stateNum==28 & ymonth!=.
* Yucatan, Aug 07, 2009, with lag: May 14 2010
replace 	Regressive = 1 if ymonth>=201005 & stateNum==31 & ymonth!=.
* Veracruz, has there been a change?
*replace Regressive = 0.75 if round==3 & stateNum==30
replace 	Regressive = 0 if Regressive==. 
replace 	Regressive = . if round==. | stateNum==. 

*--- Generate placebo treatment status
generate	 placeboReform		=en	==9&round==2
replace 	 placeboReform		=. 	if ent==.|round==.
generate	 placeboReformClose	=ent==15&round==2
replace 	 placeboReformClose	=. 	if ent==.|round==.

generate 	 pregressive=.
foreach 	 s_num in 10 11 14 16 20 21 22 23 26 28 31{ 
	replace 	pregressive = 1 if round==2 & stateNum==`s_num'
}
replace 	 pregressive = 0 if pregressive!=1



*------------------------------------------------------------------------------*
*---- Romano Wolf (full Sample)
*------------------------------------------------------------------------------*
local Treat Reform Regressive  
local FE    i.round i.stateNum i.age ReformClose
local CoVar EducLevel Indigenous
local wt    [pw=weight]
local cnd   if Nmiss==0&edad>14&edad<45
local se    absorb(hh_id) robust

keep HH_barg* hh_index Reform Regressive round stateNum age ReformClose  /*
*/ EducLevel Indigenous weight edad hh_id

egen Nmiss = rowmiss(HH_bargDep5 HH_bargDep6 HH_bargDep7 HH_bargDep10 HH_bargDep12)
keep if Nmiss==0

set seed 82130
local Nreps 150


**RUN REGRESSIONS AND BOOTSTRAP SAMPLE
foreach num of numlist 5 6 7 10 12 {
    qui eststo: areg HH_bargDep`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
    foreach ivar of varlist Reform Regressive {
        if `"`ivar'"'=="Reform" local a a
        if `"`ivar'"'=="Regressive" local a b
                
        local t`num'`a' = abs(_b[`ivar']/_se[`ivar'])
        local b`num'`a' = string(_b[`ivar'],"%5.3f")
        local s`num'`a' = string(_se[`ivar'],"%5.3f")
        local n`num'`a' = e(N)
    }
    local r`num' = string(e(r2),"%5.3f")
    sum HH_bargDep`num'
    local m`num' = string(r(mean),"%5.3f")
    
    qui gen b_Reps`num'a = .
    qui gen b_Reps`num'b = .
    foreach bnum of numlist 1(1)`Nreps' {
        preserve
        bsample
        qui areg HH_bargDep`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
        restore
        qui replace b_Reps`num'a=_b[Reform] in `bnum'
        qui replace b_Reps`num'b=_b[Regressive] in `bnum'
    }
    foreach ivar of varlist Reform Regressive {
        if `"`ivar'"'=="Reform" local a a
        if `"`ivar'"'=="Regressive" local a b
    
        qui sum b_Reps`num'`a'
        local se`num' = r(sd)
        qui gen t_Reps`num'`a'=abs((b_Reps`num'`a'-r(mean))/`se`num'')
        sum t_Reps`num'`a'
    }
}

**CALCULATE STEPDOWN VALUE (ITERATE ON MAX-T)
foreach ivar of varlist Reform Regressive {
    if `"`ivar'"'=="Reform" local a a
    if `"`ivar'"'=="Regressive" local a b

    local maxt = 0
    local maxv = 0
    local pval = 0
    local cand 5 6 7 10 12
    local rank

    while `pval'<1&length("`cand'")!=0 {
        local donor_tvals
        *dis "Potential Candidates are now `cand'"
    
        foreach num of numlist `cand' {
            if `t`num'`a''>`maxt' {
                local maxt = `t`num'`a''
                local maxv = `num'
            }
            dis "Maximum t among candidates is `maxt' (option `maxv')"
            dis `maxt'
            local donor_tvals `donor_tvals' t_Reps`num'`a'
        }
        *sum `donor_tvals'
        qui egen empiricalDist = rowmax(`donor_tvals')
        sort empiricalDist
        
        foreach cnum of numlist 1(1)`Nreps' {
            qui sum empiricalDist in `cnum'
            local cval = r(mean)
            *dis "comparing `maxt' to `cval'"
            if `maxt'>`cval' {
                local pval = 1-(`cnum'/`Nreps')
                *dis "Marginal p-value is `pval'"
            }
        }
        local p`maxv'`a'   = string(ttail(`n`maxv'`a'',`maxt')*2,"%5.3f")
        local prm`maxv'`a' = string(`pval',"%5.3f")
        local ph`maxv'`a'  = ttail(`n`maxv'`a'',`maxt')*2*length("`cand'")
        
        dis "Original p-value is `p`maxv'`a''" 
        dis "Romano Wolf p-value is `prm`maxv'`a''"
        dis "Holm p-value is `ph`maxv'`a''" 
        
        drop empiricalDist
        local rank `rank' `maxv'
        local candnew
        foreach c of local cand {
            local match = 0
            foreach r of local rank {
                if `r'==`c' local match = 1
            }
            if `match'==0 local candnew `candnew' `c'
        }
        local cand `candnew'
        local maxt = 0
        local maxv = 0
    }
}
**EXPORT TABLE

qui eststo: areg hh_index `CoVar' `FE' `Treat' `wt' `cnd', `se'
foreach ivar of varlist Reform Regressive {
    if `"`ivar'"'=="Reform" local a a
    if `"`ivar'"'=="Regressive" local a b
    local tInd`a' = abs(_b[`ivar']/_se[`ivar'])
    local bInd`a' = string(_b[`ivar'],"%5.3f")
    local sInd`a' = string(_se[`ivar'],"%5.3f")
    local tInd`a' = _b[`ivar']/_se[`ivar']
    local nInd`a' = e(N)
    local pInd`a' = string(ttail(`nInd`a'',`tInd`a'')*2,"%5.3f")
}
local rInd = string(e(r2),"%5.3f")
sum hh_index
local mInd = string(r(mean),"%5.3f")

file open results using "$REG/Empowerment-Main.tex", write replace
#delimit ;
file write results "\begin{table}[htbp]\centering
\caption{The Effect of the Abortion Reform on Women's Empowerment in the Household}
\begin{tabular}{l*{6}{c}}  \toprule
&\multicolumn{5}{c}{Individual Elements}&Index  \\ \cmidrule(lr){2-6}
&(1)&(2)&(3)&(4)&(5)&(6) \\
& Child Educ & Child Health & Expenditure & Work & Contracep \\
\midrule  ILE Reform &`b5a'&`b6a'&`b7a'&`b10a'&`b12a'&`bInda'\\
&(`p5a')&(`p6a')&(`p7a')&(`p10a')&(`p12a')&(`pInda')\\
&[`prm5a']&[`prm6a']&[`prm7a']&[`prm10a']&[`prm12a']&\\
&&&&&&\\
Regressive Law Change &`b5b'&`b6b'&`b7b'&`b10b'&`b12b'&`bIndb'\\
&(`p5b')&(`p6b')&(`p7b')&(`p10b')&(`p12b')&(`pIndb')\\
&[`prm5b']&[`prm6b']&[`prm7b']&[`prm10b']&[`prm12b']&\\
\midrule  Observations &`n5a'&`n6a'&`n7a'&`n10a'&`n12a'&`nInda'\\
R-Squared &`r5'&`r6'&`r7'&`r10'&`r12'&`rInd'\\
Mean of Dep Var &`m5'&`m6'&`m7'&`m10'&`m12'&`mInd'\\
\bottomrule
\multicolumn{7}{p{16cm}}{\begin{footnotesize} Each column presents a seperate
regression of an empowerment variable or the empowerment index including
house-hold fixed effects, year fixed effects and time-varying controls.  In
order to correct for Family Wise Error Rates from multiple hypothesis testing,
we calculate \citet{RomanoWolf2005} p-values, using their Stepdown methods.
Romano-Wolf p-values are presented in square brackets, and traditional
(uncorrected) p-values are presented in round brackets.
\end{footnotesize}}
\end{tabular}\end{table}";
#delimit cr
file close results


*------------------------------------------------------------------------------*
*---- Romano Wolf (Placebo test using older women)
*------------------------------------------------------------------------------*
local Treat Reform Regressive  
local FE    i.round i.stateNum i.age ReformClose
local CoVar EducLevel Indigenous
local wt    [pw=weight]
local cnd   if Nmiss==0&edad>44
local se    absorb(hh_id) robust

keep HH_barg* hh_index Reform Regressive round stateNum age ReformClose  /*
*/ EducLevel Indigenous weight edad hh_id

egen Nmiss = rowmiss(HH_bargDep5 HH_bargDep6 HH_bargDep7 HH_bargDep10 HH_bargDep12)
keep if Nmiss==0

set seed 82130
local Nreps 150



**RUN REGRESSIONS AND BOOTSTRAP SAMPLE
foreach num of numlist 5 6 7 10 12 {
    qui eststo: areg HH_bargDep`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
    foreach ivar of varlist Reform Regressive {
        if `"`ivar'"'=="Reform" local a a
        if `"`ivar'"'=="Regressive" local a b
                
        local t`num'`a' = abs(_b[`ivar']/_se[`ivar'])
        local b`num'`a' = string(_b[`ivar'],"%5.3f")
        local s`num'`a' = string(_se[`ivar'],"%5.3f")
        local n`num'`a' = e(N)
    }
    local r`num' = string(e(r2),"%5.3f")
    sum HH_bargDep`num'
    local m`num' = string(r(mean),"%5.3f")
    
    qui gen b_Reps`num'a = .
    qui gen b_Reps`num'b = .
    foreach bnum of numlist 1(1)`Nreps' {
        preserve
        bsample
        qui areg HH_bargDep`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
        restore
        qui replace b_Reps`num'a=_b[Reform] in `bnum'
        qui replace b_Reps`num'b=_b[Regressive] in `bnum'
    }
    foreach ivar of varlist Reform Regressive {
        if `"`ivar'"'=="Reform" local a a
        if `"`ivar'"'=="Regressive" local a b
    
        qui sum b_Reps`num'`a'
        local se`num' = r(sd)
        qui gen t_Reps`num'`a'=abs((b_Reps`num'`a'-r(mean))/`se`num'')
        sum t_Reps`num'`a'
    }
}

**CALCULATE STEPDOWN VALUE (ITERATE ON MAX-T)
foreach ivar of varlist Reform Regressive {
    if `"`ivar'"'=="Reform" local a a
    if `"`ivar'"'=="Regressive" local a b

    local maxt = 0
    local maxv = 0
    local pval = 0
    local cand 5 6 7 10 12
    local rank

    while `pval'<1&length("`cand'")!=0 {
        local donor_tvals
        *dis "Potential Candidates are now `cand'"
    
        foreach num of numlist `cand' {
            if `t`num'`a''>`maxt' {
                local maxt = `t`num'`a''
                local maxv = `num'
            }
            dis "Maximum t among candidates is `maxt' (option `maxv')"
            dis `maxt'
            local donor_tvals `donor_tvals' t_Reps`num'`a'
        }
        *sum `donor_tvals'
        qui egen empiricalDist = rowmax(`donor_tvals')
        sort empiricalDist
        
        foreach cnum of numlist 1(1)`Nreps' {
            qui sum empiricalDist in `cnum'
            local cval = r(mean)
            *dis "comparing `maxt' to `cval'"
            if `maxt'>`cval' {
                local pval = 1-(`cnum'/`Nreps')
                *dis "Marginal p-value is `pval'"
            }
        }
        local p`maxv'`a'   = string(ttail(`n`maxv'`a'',`maxt')*2,"%5.3f")
        local prm`maxv'`a' = string(`pval',"%5.3f")
        local ph`maxv'`a'  = ttail(`n`maxv'`a'',`maxt')*2*length("`cand'")
        
        dis "Original p-value is `p`maxv'`a''" 
        dis "Romano Wolf p-value is `prm`maxv'`a''"
        dis "Holm p-value is `ph`maxv'`a''" 
        
        drop empiricalDist
        local rank `rank' `maxv'
        local candnew
        foreach c of local cand {
            local match = 0
            foreach r of local rank {
                if `r'==`c' local match = 1
            }
            if `match'==0 local candnew `candnew' `c'
        }
        local cand `candnew'
        local maxt = 0
        local maxv = 0
    }
}
**EXPORT TABLE

qui eststo: areg hh_index `CoVar' `FE' `Treat' `wt' `cnd', `se'
foreach ivar of varlist Reform Regressive {
    if `"`ivar'"'=="Reform" local a a
    if `"`ivar'"'=="Regressive" local a b
    local tInd`a' = abs(_b[`ivar']/_se[`ivar'])
    local bInd`a' = string(_b[`ivar'],"%5.3f")
    local sInd`a' = string(_se[`ivar'],"%5.3f")
    local tInd`a' = _b[`ivar']/_se[`ivar']
    local nInd`a' = e(N)
    local pInd`a' = string(ttail(`nInd`a'',`tInd`a'')*2,"%5.3f")
}
local rInd = string(e(r2),"%5.3f")
sum hh_index
local mInd = string(r(mean),"%5.3f")

file open results using "$REG/Empowerment-45plus.tex", write replace
#delimit ;
file write results "\begin{table}[htbp]\centering
\caption{Placebo Test of the Effect of the Reform on Women's Empowerment (Women Aged 45+}
\begin{tabular}{l*{6}{c}}  \toprule
&\multicolumn{5}{c}{Individual Elements}&Index  \\ \cmidrule(lr){2-6}
&(1)&(2)&(3)&(4)&(5)&(6) \\
& Child Educ & Child Health & Expenditure & Work & Contracep \\
\midrule  ILE Reform &`b5a'&`b6a'&`b7a'&`b10a'&`b12a'&`bInda'\\
&(`p5a')&(`p6a')&(`p7a')&(`p10a')&(`p12a')&(`pInda')\\
&[`prm5a']&[`prm6a']&[`prm7a']&[`prm10a']&[`prm12a']&\\
&&&&&&\\
Regressive Law Change &`b5b'&`b6b'&`b7b'&`b10b'&`b12b'&`bIndb'\\
&(`p5b')&(`p6b')&(`p7b')&(`p10b')&(`p12b')&(`pIndb')\\
&[`prm5b']&[`prm6b']&[`prm7b']&[`prm10b']&[`prm12b']&\\
\midrule  Observations &`n5a'&`n6a'&`n7a'&`n10a'&`n12a'&`nInda'\\
R-Squared &`r5'&`r6'&`r7'&`r10'&`r12'&`rInd'\\
Mean of Dep Var &`m5'&`m6'&`m7'&`m10'&`m12'&`mInd'\\
\bottomrule
\multicolumn{7}{p{16cm}}{\begin{footnotesize} Each column presents a seperate
regression of an empowerment variable or the empowerment index including
house-hold fixed effects, year fixed effects and time-varying controls.  In
order to correct for Family Wise Error Rates from multiple hypothesis testing,
we calculate \citet{RomanoWolf} p-values, using their Stepdown methods. Romano
Wolf p-values are presented in square brackets, and traditional (uncorrected)
p-values are presented in round brackets.
\end{footnotesize}}
\end{tabular}\end{table}";
#delimit cr
file close results


*------------------------------------------------------------------------------*
*---- Romano Wolf (Pre-trend test using prior rounds)
*------------------------------------------------------------------------------*
* For placebo test, drop round 3 and treat round 2 as treated. 
drop  if round==3
drop Reform ReformClose Regressive
rename placeboReform Reform
rename placeboReformClose ReformClose
rename pregressive Regressive

local Treat Reform Regressive
local FE    i.round i.stateNum i.age ReformClose
local CoVar EducLevel Indigenous
local wt    [pw=weight]
local cnd   if Nmiss==0&edad>44
local se    absorb(hh_id) robust

keep HH_barg* hh_index Reform Regressive round stateNum age ReformClose  /*
*/ EducLevel Indigenous weight edad hh_id

egen Nmiss = rowmiss(HH_bargDep5 HH_bargDep6 HH_bargDep7 HH_bargDep10 HH_bargDep12)
keep if Nmiss==0

set seed 82130
local Nreps 150



**RUN REGRESSIONS AND BOOTSTRAP SAMPLE
foreach num of numlist 5 6 7 10 12 {
    qui eststo: areg HH_bargDep`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
    foreach ivar of varlist Reform Regressive {
        if `"`ivar'"'=="Reform" local a a
        if `"`ivar'"'=="Regressive" local a b
                
        local t`num'`a' = abs(_b[`ivar']/_se[`ivar'])
        local b`num'`a' = string(_b[`ivar'],"%5.3f")
        local s`num'`a' = string(_se[`ivar'],"%5.3f")
        local n`num'`a' = e(N)
    }
    local r`num' = string(e(r2),"%5.3f")
    sum HH_bargDep`num'
    local m`num' = string(r(mean),"%5.3f")
    
    qui gen b_Reps`num'a = .
    qui gen b_Reps`num'b = .
    foreach bnum of numlist 1(1)`Nreps' {
        preserve
        bsample
        qui areg HH_bargDep`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
        restore
        qui replace b_Reps`num'a=_b[Reform] in `bnum'
        qui replace b_Reps`num'b=_b[Regressive] in `bnum'
    }
    foreach ivar of varlist Reform Regressive {
        if `"`ivar'"'=="Reform" local a a
        if `"`ivar'"'=="Regressive" local a b
    
        qui sum b_Reps`num'`a'
        local se`num' = r(sd)
        qui gen t_Reps`num'`a'=abs((b_Reps`num'`a'-r(mean))/`se`num'')
        sum t_Reps`num'`a'
    }
}

**CALCULATE STEPDOWN VALUE (ITERATE ON MAX-T)
foreach ivar of varlist Reform Regressive {
    if `"`ivar'"'=="Reform" local a a
    if `"`ivar'"'=="Regressive" local a b

    local maxt = 0
    local maxv = 0
    local pval = 0
    local cand 5 6 7 10 12
    local rank

    while `pval'<1&length("`cand'")!=0 {
        local donor_tvals
        *dis "Potential Candidates are now `cand'"
    
        foreach num of numlist `cand' {
            if `t`num'`a''>`maxt' {
                local maxt = `t`num'`a''
                local maxv = `num'
            }
            dis "Maximum t among candidates is `maxt' (option `maxv')"
            dis `maxt'
            local donor_tvals `donor_tvals' t_Reps`num'`a'
        }
        *sum `donor_tvals'
        qui egen empiricalDist = rowmax(`donor_tvals')
        sort empiricalDist
        
        foreach cnum of numlist 1(1)`Nreps' {
            qui sum empiricalDist in `cnum'
            local cval = r(mean)
            *dis "comparing `maxt' to `cval'"
            if `maxt'>`cval' {
                local pval = 1-(`cnum'/`Nreps')
                *dis "Marginal p-value is `pval'"
            }
        }
        local p`maxv'`a'   = string(ttail(`n`maxv'`a'',`maxt')*2,"%5.3f")
        local prm`maxv'`a' = string(`pval',"%5.3f")
        local ph`maxv'`a'  = ttail(`n`maxv'`a'',`maxt')*2*length("`cand'")
        
        dis "Original p-value is `p`maxv'`a''" 
        dis "Romano Wolf p-value is `prm`maxv'`a''"
        dis "Holm p-value is `ph`maxv'`a''" 
        
        drop empiricalDist
        local rank `rank' `maxv'
        local candnew
        foreach c of local cand {
            local match = 0
            foreach r of local rank {
                if `r'==`c' local match = 1
            }
            if `match'==0 local candnew `candnew' `c'
        }
        local cand `candnew'
        local maxt = 0
        local maxv = 0
    }
}
**EXPORT TABLE

qui eststo: areg hh_index `CoVar' `FE' `Treat' `wt' `cnd', `se'
foreach ivar of varlist Reform Regressive {
    if `"`ivar'"'=="Reform" local a a
    if `"`ivar'"'=="Regressive" local a b
    local tInd`a' = abs(_b[`ivar']/_se[`ivar'])
    local bInd`a' = string(_b[`ivar'],"%5.3f")
    local sInd`a' = string(_se[`ivar'],"%5.3f")
    local tInd`a' = _b[`ivar']/_se[`ivar']
    local nInd`a' = e(N)
    local pInd`a' = string(ttail(`nInd`a'',`tInd`a'')*2,"%5.3f")
}
local rInd = string(e(r2),"%5.3f")
sum hh_index
local mInd = string(r(mean),"%5.3f")

file open results using "$REG/Empowerment-preReform.tex", write replace
#delimit ;
file write results "\begin{table}[htbp]\centering
\caption{Identification Test of the Effect of the Reform on Women's Empowerment (Pre-Reform)}
\begin{tabular}{l*{6}{c}}  \toprule
&\multicolumn{5}{c}{Individual Elements}&Index  \\ \cmidrule(lr){2-6}
&(1)&(2)&(3)&(4)&(5)&(6) \\
& Child Educ & Child Health & Expenditure & Work & Contracep \\
\midrule  ILE Reform &`b5a'&`b6a'&`b7a'&`b10a'&`b12a'&`bInda'\\
&(`p5a')&(`p6a')&(`p7a')&(`p10a')&(`p12a')&(`pInda')\\
&[`prm5a']&[`prm6a']&[`prm7a']&[`prm10a']&[`prm12a']&\\
&&&&&&\\
Regressive Law Change &`b5b'&`b6b'&`b7b'&`b10b'&`b12b'&`bIndb'\\
&(`p5b')&(`p6b')&(`p7b')&(`p10b')&(`p12b')&(`pIndb')\\
&[`prm5b']&[`prm6b']&[`prm7b']&[`prm10b']&[`prm12b']&\\
\midrule  Observations &`n5a'&`n6a'&`n7a'&`n10a'&`n12a'&`nInda'\\
R-Squared &`r5'&`r6'&`r7'&`r10'&`r12'&`rInd'\\
Mean of Dep Var &`m5'&`m6'&`m7'&`m10'&`m12'&`mInd'\\
\bottomrule
\multicolumn{7}{p{16cm}}{\begin{footnotesize} Each column presents a seperate
regression of an empowerment variable or the empowerment index including
house-hold fixed effects, year fixed effects and time-varying controls.  In
order to correct for Family Wise Error Rates from multiple hypothesis testing,
we calculate \citet{RomanoWolf} p-values, using their Stepdown methods. Romano
Wolf p-values are presented in square brackets, and traditional (uncorrected)
p-values are presented in round brackets.
\end{footnotesize}}
\end{tabular}\end{table}";
#delimit cr
file close results
