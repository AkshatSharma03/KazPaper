/*===========================================================================
  SINO-KAZAKH MAIN BILATERAL ANALYSIS (CORE STEP 2)
  Rebuilds core Step 2 outputs from the canonical table8 input.
  Window: 2015-2024 only
  ===========================================================================*/

version 17.0
clear all
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
capture mkdir "tables"
capture mkdir "logs"

capture log close
log using "logs/sinokaz_analysis.log", replace text

local start_year 2015
local end_year   2024

di _newline(2) "==============================================================="
di "  SINO-KAZAKH MAIN BILATERAL ANALYSIS (CORE)"
di "==============================================================="

*--------------------------------------------------------------------------
* INPUT CHECK
*--------------------------------------------------------------------------

capture confirm file "tables/table8_annual_bilateral_trade.csv"
if _rc != 0 {
    di as error "Missing required input: tables/table8_annual_bilateral_trade.csv"
    log close
    exit 601
}

*--------------------------------------------------------------------------
* BUILD MAIN PANEL
*--------------------------------------------------------------------------

import delimited "tables/table8_annual_bilateral_trade.csv", clear
keep if inrange(year, `start_year', `end_year')
sort year

capture confirm variable exports_bn
if _rc != 0 {
    di as error "Missing required variable exports_bn in table8 input."
    log close
    exit 498
}

capture confirm variable imports_bn
if _rc != 0 {
    di as error "Missing required variable imports_bn in table8 input."
    log close
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
    gen deficit_ratio = (imports_bn - exports_bn) / total_trade_bn if total_trade_bn > 0
}

gen reporter = "KAZ"
gen partner  = "CHN"

tsset year
gen export_growth = 100 * (exports_bn - L.exports_bn) / L.exports_bn if L.exports_bn > 0
gen import_growth = 100 * (imports_bn - L.imports_bn) / L.imports_bn if L.imports_bn > 0

gen t = year - `start_year'
gen post2020 = (year >= 2020)

gen ln_trade   = ln(total_trade_bn) if total_trade_bn > 0
gen ln_exports = ln(exports_bn) if exports_bn > 0
gen ln_imports = ln(imports_bn) if imports_bn > 0

label variable exports_bn    "Exports to China (USD bn)"
label variable imports_bn    "Imports from China (USD bn)"
label variable total_trade_bn "Total Bilateral Trade (USD bn)"
label variable trade_balance "Trade Balance: Exports - Imports (USD bn)"
label variable deficit_ratio "Deficit Ratio: (M-X)/(M+X)"
label variable export_growth "Export growth rate (%)"
label variable import_growth "Import growth rate (%)"

save "kaz_china_trade_panel.dta", replace
di as result "Created: kaz_china_trade_panel.dta"

* Re-export canonical table8 from the rebuilt panel for consistency
export delimited year exports_bn imports_bn total_trade_bn trade_balance deficit_ratio ///
    using "tables/table8_annual_bilateral_trade.csv", replace
di as result "Updated: tables/table8_annual_bilateral_trade.csv"

*--------------------------------------------------------------------------
* FIGURES 12-14
*--------------------------------------------------------------------------

use "kaz_china_trade_panel.dta", clear

* Figure 12: Trade flows
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
    scheme(s2color)

graph export "figures/fig12_trade_flows.png", replace width(2000)
graph export "figures/fig12_trade_flows.pdf", replace

* Figure 13: Trade balance
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
    scheme(s2color)

graph export "figures/fig13_trade_balance.png", replace width(2000)
graph export "figures/fig13_trade_balance.pdf", replace

* Figure 14: Deficit ratio
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
    scheme(s2color)

graph export "figures/fig14_deficit_ratio.png", replace width(2000)
graph export "figures/fig14_deficit_ratio.pdf", replace

*--------------------------------------------------------------------------
* LIGHTWEIGHT UNIT ROOT TABLE (compatibility output)
*--------------------------------------------------------------------------

tempname h
postfile `h' str24 variable_name double adf_z_stat double p_value using "tables/unit_root_test_results.dta", replace

foreach v in trade_balance deficit_ratio total_trade_bn {
    capture noisily dfuller `v', lags(1) trend
    if _rc == 0 {
        post `h' ("`v'") (r(Zt)) (r(p))
    }
    else {
        post `h' ("`v'") (.) (.)
    }
}
postclose `h'

use "tables/unit_root_test_results.dta", clear
export delimited using "tables/unit_root_test_results.csv", replace
erase "tables/unit_root_test_results.dta"

di as result "Created: tables/unit_root_test_results.csv"

di _newline "Core outputs generated:"
di "  - kaz_china_trade_panel.dta"
di "  - tables/table8_annual_bilateral_trade.csv"
di "  - figures/fig12_trade_flows.png/pdf"
di "  - figures/fig13_trade_balance.png/pdf"
di "  - figures/fig14_deficit_ratio.png/pdf"
di "  - tables/unit_root_test_results.csv"

log close
