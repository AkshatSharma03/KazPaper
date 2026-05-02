/*===========================================================================
   FALLBACK: GENERATE STEP 2 FIGURES FROM TABLE 8
   Creates figures 12-14 when sinokaz_analysis_improved.do is unavailable.
   ===========================================================================*/

version 17.0
set more off

local script_dir "`c(pwd)'"
capture confirm file "analysis/do/RUN_ALL_ANALYSIS.do"
if _rc == 0 {
    local project_root "`script_dir'"
}
else {
    local project_root = subinstr("`script_dir'", "/analysis/do", "", .)
    local project_root = subinstr("`project_root'", "/scripts", "", .)
}
cd "`project_root'"
capture mkdir "figures"

capture confirm file "tables/table8_annual_bilateral_trade.csv"
if _rc != 0 {
    di as error "Missing tables/table8_annual_bilateral_trade.csv"
    exit 601
}

import delimited "tables/table8_annual_bilateral_trade.csv", clear

* Keep standard analysis window only
keep if inrange(year, 2015, 2024)
sort year

* Ensure required variables exist
capture confirm variable exports_bn
if _rc != 0 {
    di as error "Missing required variable exports_bn in table8 file."
    exit 498
}
capture confirm variable imports_bn
if _rc != 0 {
    di as error "Missing required variable imports_bn in table8 file."
    exit 498
}

capture confirm variable total_trade_bn
if _rc != 0 {
    gen total_trade_bn = exports_bn + imports_bn
}

capture confirm variable trade_balance
if _rc != 0 {
    gen trade_balance = exports_bn - imports_bn
}

capture confirm variable deficit_ratio
if _rc != 0 {
    gen deficit_ratio = (imports_bn - exports_bn) / (imports_bn + exports_bn) ///
        if (imports_bn + exports_bn) > 0
}

local start_year 2015
local end_year 2024

* Figure 12: Trade Flows
twoway ///
    (line exports_bn year, lcolor(navy) lwidth(medthick) lpattern(solid)) ///
    (line imports_bn year, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
    (line total_trade_bn year, lcolor(forest_green) lwidth(thin) lpattern(dot)), ///
    xline(2015, lcolor(gray) lpattern(shortdash) lwidth(thin)) ///
    xline(2020, lcolor(black) lpattern(dash) lwidth(thin)) ///
    xlabel(`start_year'(1)`end_year', angle(45) labsize(small)) ///
    ylabel(0(10)35, format(%9.0f) labsize(small)) ///
    ytitle("USD Billions", size(small)) ///
    xtitle("Year", size(small)) ///
    title("Kazakhstan-China Bilateral Trade, 2015-2024", size(medium)) ///
    subtitle("Exports, imports, and total trade", size(small)) ///
    legend(order(1 "Exports to China" 2 "Imports from China" 3 "Total trade") ///
           position(6) rows(1) size(small)) ///
    note("Fallback figure generated from tables/table8_annual_bilateral_trade.csv", size(vsmall)) ///
    scheme(s2color)

graph export "figures/fig12_trade_flows.png", replace width(2000)
graph export "figures/fig12_trade_flows.pdf", replace

* Figure 13: Trade Balance
twoway ///
    (bar trade_balance year, color(navy%60) barwidth(0.7)) ///
    (line trade_balance year, lcolor(navy) lwidth(medthick)), ///
    yline(0, lcolor(black) lwidth(thin)) ///
    xline(2015, lcolor(gray) lpattern(shortdash)) ///
    xline(2020, lcolor(black) lpattern(dash)) ///
    xlabel(`start_year'(1)`end_year', angle(45) labsize(small)) ///
    ylabel(-10(5)15, format(%9.0f) labsize(small)) ///
    ytitle("Trade Balance (USD bn)", size(small)) ///
    xtitle("Year", size(small)) ///
    title("Kazakhstan-China Trade Balance", size(medium)) ///
    subtitle("Exports minus imports", size(small)) ///
    legend(off) ///
    note("Fallback figure generated from tables/table8_annual_bilateral_trade.csv", size(vsmall)) ///
    scheme(s2color)

graph export "figures/fig13_trade_balance.png", replace width(2000)
graph export "figures/fig13_trade_balance.pdf", replace

* Figure 14: Deficit Ratio
twoway ///
    (connected deficit_ratio year, lcolor(maroon) mcolor(maroon) msymbol(O) msize(medlarge)), ///
    yline(0, lcolor(black) lwidth(thin)) ///
    xline(2015, lcolor(gray) lpattern(shortdash)) ///
    xline(2020, lcolor(black) lpattern(dash)) ///
    xlabel(`start_year'(1)`end_year', angle(45) labsize(small)) ///
    ytitle("Deficit Ratio: (M - X) / (M + X)", size(small)) ///
    xtitle("Year", size(small)) ///
    title("Kazakhstan-China Trade Asymmetry", size(medium)) ///
    subtitle("Positive values indicate China-favored imbalance", size(small)) ///
    note("Fallback figure generated from tables/table8_annual_bilateral_trade.csv", size(vsmall)) ///
    scheme(s2color)

graph export "figures/fig14_deficit_ratio.png", replace width(2000)
graph export "figures/fig14_deficit_ratio.pdf", replace

di as result "Fallback Step 2 figures created: fig12-14"
