*------------------------------------------------------------------------------*
/*
*/

vers 11
clear all
set more off
cap log close
*------------------------------------------------------------------------------*
* Globals
*------------------------------------------------------------------------------*
set more off
global REG "~/investigacion/2014/MexAbort/Source/Aug2016/tables"
global DAT "~/investigacion/2014/MexAbort/Source/Aug2016"
global LOG "~/investigacion/2014/MexAbort/Source/Aug2016"

log using "$LOG/ILE-sex.txt", text replace

use "$DAT/MxFLS-sexBehaviour.dta", clear
replace regressive = 1 if ymonth>=201008 & stateNum==30 & ymonth!=.

rename ContraKnow        _v1
rename mod_contrcep      _v2
rename any_contra_method _v3
rename num_sex_partners  _v4
rename regressive Regressive

#delimit ;
keep Reform Regressive round stateNum age ReformClose weight _v* EducLevel
     Indigenous edad hh_id;
#delimit cr
egen Nmiss = rowmiss(_v*)
keep if Nmiss==0


*------------------------------------------------------------------------------*
*---- Romano Wolf (Panel)
*------------------------------------------------------------------------------*
local Treat Reform Regressive  
local FE    i.round i.stateNum i.age ReformClose
local CoVar EducLevel Indigenous
local wt    [pw=weight]
local cnd   if Nmiss==0&edad>14&edad<45
local se    absorb(hh_id) robust

set seed 82130
local Nreps 150


**RUN REGRESSIONS AND BOOTSTRAP SAMPLE
foreach num of numlist 1 2 3 4 {
    dis "Estimation and bootstrapping with variable `num'"
    qui eststo: areg _v`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
    foreach ivar of varlist Reform Regressive {
        if `"`ivar'"'=="Reform" local a a
        if `"`ivar'"'=="Regressive" local a b
                
        local t`num'`a' = abs(_b[`ivar']/_se[`ivar'])
        local b`num'`a' = string(_b[`ivar'],"%5.3f")
        local s`num'`a' = string(_se[`ivar'],"%5.3f")
        local n`num'`a' = e(N)
    }
    local r`num' = string(e(r2),"%5.3f")
    sum _v`num' `cnd'
    local m`num' = string(r(mean),"%5.3f")
    
    qui gen b_Reps`num'a = .
    qui gen b_Reps`num'b = .
    foreach bnum of numlist 1(1)`Nreps' {
        preserve
        bsample
        qui areg _v`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
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
    local cand 1 2 3 4
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

        if `pval'<0.01      local b`maxv'`a' = "`b`maxv'`a''***"
        else if `pval'<0.05 local b`maxv'`a' = "`b`maxv'`a''**"
        else if `pval'<0.1  local b`maxv'`a' = "`b`maxv'`a''*"
        
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
local lc "\label{tab:sex}"
file open results using "$REG/SexBehaviour-Main.tex", write replace
#delimit ;
file write results "\begin{table}[htbp]\centering
\caption{The Effect of the Abortion Reform on Reported Sexual
Behaviour (Panel Specification)`lc'}
\begin{tabular}{l*{4}{c}}  \toprule
&(1)&(2)&(3)&(4) \\
& Modern Contracep & Any           & Modern        & Num of\\
& Knowledge        & Contraception & Contraception & Sex Partners\\
\midrule  ILE Reform &`b1a'&`b2a'&`b3a'&`b4a'\\
&(`p1a')&(`p2a')&(`p3a')&(`p4a')\\
&[`prm1a']&[`prm2a']&[`prm3a']&[`prm4a']\\
&&&&\\
Regressive Law Change &`b1b'&`b2b'&`b3b'&`b4b'\\
&(`p1b')&(`p2b')&(`p3b')&(`p4b')\\
&[`prm1b']&[`prm2b']&[`prm3b']&[`prm4b']\\
\midrule  Observations &`n1a'&`n2a'&`n3a'&`n4a'\\
R-Squared &`r1'&`r2'&`r3'&`r4'\\
Mean of Dep Var &`m1'&`m2'&`m3'&`m4'\\
\bottomrule
\multicolumn{5}{p{15.6cm}}{\begin{footnotesize} Each column presents a seperate
regression of a contraceptive or sexual behaviour variable on abortion reform
measures, house-hold fixed effects, year fixed effects and time-varying
controls.  In order to correct for Family Wise Error Rates from multiple
hypothesis testing, we calculate \citet{RomanoWolf2005} p-values, using their
Stepdown methods. Romano-Wolf p-values are presented in square brackets, and
traditional (uncorrected) p-values are presented in round brackets.
Significance stars refer to significance at 10\% (*), 5\% (**) or 1\% (***)
levels, and are based on Romano-Wolf p-values.
\end{footnotesize}}
\end{tabular}\end{table}";
#delimit cr
file close results

#delimit ;
keep Reform Regressive round stateNum age ReformClose weight _v* EducLevel
     Indigenous edad hh_id;
#delimit cr
egen Nmiss = rowmiss(_v*)
keep if Nmiss==0


*------------------------------------------------------------------------------*
*---- Romano Wolf (Cross-section)
*------------------------------------------------------------------------------*
local Treat Reform Regressive  
local FE    i.round i.stateNum i.age ReformClose
local CoVar EducLevel Indigenous
local wt    [pw=weight]
local cnd   if Nmiss==0&edad>14&edad<45
local se    robust


**RUN REGRESSIONS AND BOOTSTRAP SAMPLE
foreach num of numlist 1 2 3 4 {
    dis "Estimation and bootstrapping with variable `num'"
    qui eststo: reg _v`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
    foreach ivar of varlist Reform Regressive {
        if `"`ivar'"'=="Reform" local a a
        if `"`ivar'"'=="Regressive" local a b
                
        local t`num'`a' = abs(_b[`ivar']/_se[`ivar'])
        local b`num'`a' = string(_b[`ivar'],"%5.3f")
        local s`num'`a' = string(_se[`ivar'],"%5.3f")
        local n`num'`a' = e(N)
    }
    local r`num' = string(e(r2),"%5.3f")
    sum _v`num' `cnd'
    local m`num' = string(r(mean),"%5.3f")
    
    qui gen b_Reps`num'a = .
    qui gen b_Reps`num'b = .
    foreach bnum of numlist 1(1)`Nreps' {
        preserve
        bsample
        qui reg _v`num' `CoVar' `FE' `Treat' `wt' `cnd', `se'
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
    local cand 1 2 3 4
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

        if `pval'<0.01      local b`maxv'`a' = "`b`maxv'`a''***"
        else if `pval'<0.05 local b`maxv'`a' = "`b`maxv'`a''**"
        else if `pval'<0.1  local b`maxv'`a' = "`b`maxv'`a''*"
        
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
local lc "\label{tab:sex}"
file open results using "$REG/SexBehaviour-CrossSection.tex", write replace
#delimit ;
file write results "\begin{table}[htbp]\centering
\caption{The Effect of the Abortion Reform on Reported Sexual
Behaviour (Repeated Cross-Section Specification)`lc'}
\begin{tabular}{l*{4}{c}}  \toprule
&(1)&(2)&(3)&(4) \\
& Modern Contracep & Any           & Modern        & Num of\\
& Knowledge        & Contraception & Contraception & Sex Partners\\
\midrule  ILE Reform &`b1a'&`b2a'&`b3a'&`b4a'\\
&(`p1a')&(`p2a')&(`p3a')&(`p4a')\\
&[`prm1a']&[`prm2a']&[`prm3a']&[`prm4a']\\
&&&&\\
Regressive Law Change &`b1b'&`b2b'&`b3b'&`b4b'\\
&(`p1b')&(`p2b')&(`p3b')&(`p4b')\\
&[`prm1b']&[`prm2b']&[`prm3b']&[`prm4b']\\
\midrule  Observations &`n1a'&`n2a'&`n3a'&`n4a'\\
R-Squared &`r1'&`r2'&`r3'&`r4'\\
Mean of Dep Var &`m1'&`m2'&`m3'&`m4'\\
\bottomrule
\multicolumn{5}{p{15.6cm}}{\begin{footnotesize} Each column presents a
seperate regression of a contraceptive or sexual behaviour variable on
abortion reform measures, year fixed effects and time-varying
controls.  In order to correct for Family Wise Error Rates from multiple
hypothesis testing, we calculate \citet{RomanoWolf2005} p-values, using their
Stepdown methods. Romano-Wolf p-values are presented in square brackets, and
traditional (uncorrected) p-values are presented in round brackets.
Significance stars refer to significance at 10\% (*), 5\% (**) or 1\% (***)
levels, and are based on Romano-Wolf p-values.
\end{footnotesize}}
\end{tabular}\end{table}";
#delimit cr
file close results
