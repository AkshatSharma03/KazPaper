/*===========================================================================
  THEORETICAL FRAMEWORK VISUALIZATIONS
  Corrected version
  Window: 2015-2024 only
  ===========================================================================*/

version 17.0
clear all
set more off

* --------------------------------------------------------------------------
* Project settings
* --------------------------------------------------------------------------
local project_root "`c(pwd)'"
local start_year 2015
local end_year   2024

cd "`project_root'"

capture mkdir "figures"
capture mkdir "tables"

capture log close
log using "sinokaz_theory_viz.log", replace

/*===========================================================================
  CHECK DEPENDENCIES
  ===========================================================================*/

di _newline(2) "Checking for required data files..."

local required_files ///
    "sectoral_trade_clean.dta" ///
    "sectoral_composition_chn.dta" ///
    "tables/table4_multivector_diversification.csv" ///

* Check for .dta files by trying to load them
capture use "sectoral_trade_clean.dta", clear
if _rc != 0 {
    di as error "Missing required file: sectoral_trade_clean.dta"
    log close
    exit 601
}
di as result "Found: sectoral_trade_clean.dta"

capture use "sectoral_composition_chn.dta", clear
if _rc != 0 {
    di as error "Missing required file: sectoral_composition_chn.dta"
    log close
    exit 601
}
di as result "Found: sectoral_composition_chn.dta"

* Check for CSV files (fig5 removed - see audit)
capture confirm file "tables/table4_multivector_diversification.csv"
if _rc != 0 {
    di as error "Missing required file: tables/table4_multivector_diversification.csv"
    log close
    exit 601
}
di as result "Found: tables/table4_multivector_diversification.csv"

capture confirm file "tables/table6_concentration_index.csv"
if _rc != 0 {
    di as error "Missing required file: tables/table6_concentration_index.csv"
    log close
    exit 601
}
di as result "Found: tables/table6_concentration_index.csv"

/*===========================================================================
  FIGURE 7: TRADE GROWTH ASYMMETRY INDEX
  Proxy for sensitivity asymmetry
  ===========================================================================*/

use "sectoral_trade_clean.dta", clear
keep if partner == "CHN"
keep if inrange(year, `start_year', `end_year')

collapse (sum) value_million, by(year flow_code)
reshape wide value_million, i(year) j(flow_code)

capture confirm variable value_million5
if _rc != 0 gen value_million5 = .
capture confirm variable value_million6
if _rc != 0 gen value_million6 = .

rename value_million5 imports
rename value_million6 exports

sort year

gen export_growth = .
replace export_growth = 100 * (exports - exports[_n-1]) / exports[_n-1] ///
    if _n > 1 & exports[_n-1] > 0 & !missing(exports[_n-1])

gen import_growth = .
replace import_growth = 100 * (imports - imports[_n-1]) / imports[_n-1] ///
    if _n > 1 & imports[_n-1] > 0 & !missing(imports[_n-1])

* Trim implausible outliers caused by very small bases
replace export_growth = . if export_growth < -500 | export_growth > 500
replace import_growth = . if import_growth < -500 | import_growth > 500

gen asymmetry_index = import_growth - export_growth

#delimit ;
twoway
    (bar asymmetry_index year, color(navy%55) barwidth(0.6))
    (line asymmetry_index year, lcolor(navy) lwidth(medthick)),
    yline(0, lcolor(black) lpattern(dash))
    xlabel(`start_year'(1)`end_year', angle(45) labsize(small))
    ytitle("Growth asymmetry (percentage points)", size(small))
    xtitle("Year", size(small))
    title("Sino-Kazakh Trade Growth Asymmetry", size(medium))
    subtitle("Positive values = imports from China grew faster than exports to China", size(small))
    note("Proxy measure based on year-over-year bilateral trade growth; 2015-2024 only", size(vsmall))
    legend(off)
    scheme(s2color);
#delimit cr

graph export "figures/fig7_asymmetry_index.png", replace width(2000)
graph export "figures/fig7_asymmetry_index.pdf", replace

/*===========================================================================
  FIGURE 8: VULNERABILITY PROXY OVER TIME
  Selected-partner shares plus diversification-based vulnerability proxy
  ===========================================================================*/

import delimited "tables/table4_multivector_diversification.csv", clear
keep if inrange(year, `start_year', `end_year')

* partner_share1 = CHN, partner_share2 = RUS, partner_share3 = EU-UK
replace partner_share1 = 0 if missing(partner_share1)
replace partner_share2 = 0 if missing(partner_share2)
replace partner_share3 = 0 if missing(partner_share3)

gen china_dependence = partner_share1 / 100
gen diversification_index = 1 - ///
    ((partner_share1/100)^2 + (partner_share2/100)^2 + (partner_share3/100)^2)

gen vulnerability_index = .
replace vulnerability_index = china_dependence / (diversification_index + 0.1) ///
    if diversification_index > -0.099

#delimit ;
twoway
    (area partner_share1 year, sort color(navy%18) lwidth(none) yaxis(1))
    (line partner_share1 year, sort lcolor(navy) lwidth(medthick) yaxis(1))
    (line partner_share2 year, sort lcolor(cranberry) lwidth(medthick) yaxis(1))
    (line partner_share3 year, sort lcolor(forest_green) lwidth(medthick) yaxis(1))
    (line vulnerability_index year, sort lcolor(black) lpattern(dash) lwidth(medthick) yaxis(2)),
    xlabel(`start_year'(1)`end_year', angle(45) labsize(small))
    ylabel(0(10)100, axis(1) labsize(small))
    ytitle("Selected-partner trade share (%)", axis(1) size(small))
    ytitle("Vulnerability proxy", axis(2) size(small))
    xtitle("Year", size(small))
    title("Kazakhstan's Trade Vulnerability and Diversification", size(medium))
    subtitle("China, Russia, and EU-UK within the selected comparison set", size(small))
    legend(order(2 "China share" 3 "Russia share" 4 "EU-UK share" 5 "Vulnerability proxy")
           position(6) rows(2) size(small))
    xline(2015, lcolor(gray) lpattern(dash))
    xline(2022, lcolor(red) lpattern(dash))
    note("Selected-partner shares, not total-world shares; 2015-2024 only", size(vsmall))
    scheme(s2color);
#delimit cr

graph export "figures/fig8_vulnerability_multivector.png", replace width(2000)
graph export "figures/fig8_vulnerability_multivector.pdf", replace

/*===========================================================================
  FIGURE 9: SECTORAL DEPENDENCY GRID
  China penetration by sector and year
  ===========================================================================*/

use "sectoral_trade_clean.dta", clear
keep if flow_code == 5
keep if inrange(year, `start_year', `end_year')

* Exclude known overlapping aggregates from denominator
drop if inlist(partner, "EU-UK", "ECS")

gen china_import_value = value_million if partner == "CHN"
replace china_import_value = 0 if missing(china_import_value)

collapse (sum) total_import_value=value_million china_import_value, by(year sector)

gen china_penetration = 100 * china_import_value / total_import_value if total_import_value > 0

keep if inlist(sector, ///
    "Machinery_Electrical", ///
    "Vehicles", ///
    "Textiles", ///
    "Chemicals", ///
    "Plastics_Rubber", ///
    "Metals_Minerals")

gen sector_num = .
replace sector_num = 1 if sector == "Machinery_Electrical"
replace sector_num = 2 if sector == "Vehicles"
replace sector_num = 3 if sector == "Textiles"
replace sector_num = 4 if sector == "Chemicals"
replace sector_num = 5 if sector == "Plastics_Rubber"
replace sector_num = 6 if sector == "Metals_Minerals"

gen str8 pen_label = string(round(china_penetration, 0.1), "%4.1f")

#delimit ;
twoway
    (scatter sector_num year, msymbol(square) msize(large) mcolor(navy%22)
        mlabel(pen_label) mlabcolor(black) mlabsize(small) mlabposition(0)),
    ylabel(1 "Machinery & Electrical"
           2 "Vehicles"
           3 "Textiles"
           4 "Chemicals"
           5 "Plastics & Rubber"
           6 "Metals & Minerals", angle(0) labsize(small))
    xlabel(`start_year'(1)`end_year', angle(45) labsize(small))
    ytitle("", size(small))
    xtitle("Year", size(small))
    title("Chinese Import Penetration by Sector", size(medium))
    subtitle("Labels show China's share of Kazakhstan's sectoral imports (%)", size(small))
    legend(off)
    note("Known aggregates excluded from denominator; 2015-2024 only", size(vsmall))
    scheme(s2color);
#delimit cr

graph export "figures/fig9_sectoral_penetration_heatmap.png", replace width(2000)
graph export "figures/fig9_sectoral_penetration_heatmap.pdf", replace

/*===========================================================================
  FIGURE 10: PRE-2023 VS POST-2023 COMPARISON
  ===========================================================================*/

use "sectoral_composition_chn.dta", clear
keep if inrange(year, `start_year', `end_year')

gen str8 period = "Pre2023" if year < 2023
replace period = "Post2023" if year >= 2023

collapse (mean) export_value import_value net_balance, by(period sector)

keep if inlist(sector, ///
    "Energy", ///
    "Machinery_Electrical", ///
    "Vehicles", ///
    "Metals_Minerals", ///
    "Textiles")

reshape wide export_value import_value net_balance, i(sector) j(period) string

capture confirm variable export_valuePre2023
if _rc != 0 gen export_valuePre2023 = .
capture confirm variable export_valuePost2023
if _rc != 0 gen export_valuePost2023 = .
capture confirm variable import_valuePre2023
if _rc != 0 gen import_valuePre2023 = .
capture confirm variable import_valuePost2023
if _rc != 0 gen import_valuePost2023 = .
capture confirm variable net_balancePre2023
if _rc != 0 gen net_balancePre2023 = .
capture confirm variable net_balancePost2023
if _rc != 0 gen net_balancePost2023 = .

gen export_change = .
replace export_change = 100 * (export_valuePost2023 - export_valuePre2023) / export_valuePre2023 ///
    if export_valuePre2023 > 0

gen import_change = .
replace import_change = 100 * (import_valuePost2023 - import_valuePre2023) / import_valuePre2023 ///
    if import_valuePre2023 > 0

gen balance_change = net_balancePost2023 - net_balancePre2023

gen sector_num = .
replace sector_num = 1 if sector == "Energy"
replace sector_num = 2 if sector == "Machinery_Electrical"
replace sector_num = 3 if sector == "Vehicles"
replace sector_num = 4 if sector == "Metals_Minerals"
replace sector_num = 5 if sector == "Textiles"

gen sector_exp = sector_num - 0.18
gen sector_imp = sector_num + 0.18

#delimit ;
twoway
    (bar export_change sector_exp, horizontal color(navy) barwidth(0.30))
    (bar import_change sector_imp, horizontal color(cranberry) barwidth(0.30)),
    xlabel(0(500)2500, labsize(small) format(%4.0f))
    ylabel(1 "Energy"
           2 "Machinery & Electrical"
           3 "Vehicles"
           4 "Metals & Minerals"
           5 "Textiles", angle(0) labsize(small))
    xtitle("Change in average trade value (%)", size(small))
    ytitle("")
    title("Structural Shift in Sino-Kazakh Trade", size(medium))
    subtitle("Pre-2023 average vs post-2023 average", size(small))
    xline(0, lcolor(black))
    legend(order(1 "Exports" 2 "Imports") position(6) rows(1) size(small))
    note("Pre-2023 = 2015-2022; Post-2023 = 2023-2024", size(vsmall))
    scheme(s2color)
    graphregion(margin(b+5 l+5 r+5))
    xscale(range(0 2500));
#delimit cr

graph export "figures/fig10_2023_structural_shift.png", replace width(2000)
graph export "figures/fig10_2023_structural_shift.pdf", replace

/*===========================================================================
  FIGURE 11: HEDGING BEHAVIOR VISUALIZATION
  China vs Russia trade ratio
  ===========================================================================*/

use "sectoral_trade_clean.dta", clear
keep if inlist(partner, "CHN", "RUS")
keep if inrange(year, `start_year', `end_year')

collapse (sum) value_million, by(year partner)

gen partner_num = 1 if partner == "CHN"
replace partner_num = 2 if partner == "RUS"

drop partner
reshape wide value_million, i(year) j(partner_num)

capture confirm variable value_million1
if _rc != 0 gen value_million1 = .
capture confirm variable value_million2
if _rc != 0 gen value_million2 = .

rename value_million1 chn_trade
rename value_million2 rus_trade

replace chn_trade = 0 if missing(chn_trade)
replace rus_trade = 0 if missing(rus_trade)

gen hedging_index = .
replace hedging_index = chn_trade / rus_trade if rus_trade > 0

gen china_advantage = chn_trade - rus_trade

#delimit ;
twoway
    (line hedging_index year, lcolor(navy) lwidth(medthick))
    (scatter hedging_index year, mcolor(navy) msymbol(O)),
    yline(1, lcolor(cranberry) lpattern(dash) lwidth(thick))
    xlabel(`start_year'(2)`end_year', angle(45))
    ytitle("China/Russia trade ratio")
    xtitle("Year")
    title("Kazakhstan's Hedging Pattern: China vs Russia")
    subtitle("Values >1 = more trade with China; values <1 = more trade with Russia")
    legend(off)
    xline(2015, lcolor(gray) lpattern(dash))
    xline(2022, lcolor(red) lpattern(dash))
    note("2015-2024 only")
    scheme(s2color);
#delimit cr

graph export "figures/fig11_hedging_behavior.png", replace width(2000)
graph export "figures/fig11_hedging_behavior.pdf", replace

/*===========================================================================
  SUMMARY TABLE: THEORETICAL INDICES
  ===========================================================================*/

tempfile base indices multiv conc

clear
set obs `=`end_year' - `start_year' + 1'
gen year = `start_year' + _n - 1
save `base', replace

preserve
use "sectoral_composition_chn.dta", clear
keep if inrange(year, `start_year', `end_year')
collapse (sum) export_value import_value, by(year)
gen trade_balance = export_value - import_value
gen total_trade = export_value + import_value
save `indices', replace
restore

preserve
import delimited "tables/table4_multivector_diversification.csv", clear
keep if inrange(year, `start_year', `end_year')
save `multiv', replace
restore

preserve
import delimited "tables/table6_concentration_index.csv", clear
keep if flow == "Exports"
rename share_sq export_concentration
keep year export_concentration
keep if inrange(year, `start_year', `end_year')
save `conc', replace
restore

use `base', clear
merge 1:1 year using `indices', nogen
merge 1:1 year using `multiv', nogen
merge 1:1 year using `conc', nogen

gen china_share = partner_share1 / 100 if !missing(partner_share1)
gen rus_share   = partner_share2 / 100 if !missing(partner_share2)

gen asymmetry_ratio = .
replace asymmetry_ratio = import_value / export_value if export_value > 0

gen chn_rus_share_ratio = .
replace chn_rus_share_ratio = partner_share1 / partner_share2 if partner_share2 > 0

keep year export_value import_value trade_balance total_trade china_share rus_share ///
    asymmetry_ratio export_concentration chn_rus_share_ratio

export delimited using "tables/table7_theoretical_indices.csv", replace

di _newline(2) "=== THEORETICAL INDICES SUMMARY ==="
di "Year | China Share | Asymmetry | Export Concentration | CHN/RUS Share Ratio"
di "-----|-------------|-----------|----------------------|--------------------"

forvalues y = `start_year'/`end_year' {
    quietly summarize china_share if year == `y', meanonly
    local cshare = r(mean)

    quietly summarize asymmetry_ratio if year == `y', meanonly
    local asym = r(mean)

    quietly summarize export_concentration if year == `y', meanonly
    local concv = r(mean)

    quietly summarize chn_rus_share_ratio if year == `y', meanonly
    local hratio = r(mean)

    di `y' " | " %6.3f `cshare' " | " %6.3f `asym' " | " %6.3f `concv' " | " %6.3f `hratio'
}

/*===========================================================================
  WRAP UP
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  THEORETICAL VISUALIZATION COMPLETE"
di "==============================================================="
di "Generated:"
di "  - figures/fig7_asymmetry_index.png/pdf"
di "  - figures/fig8_vulnerability_multivector.png/pdf"
di "  - figures/fig9_sectoral_penetration_heatmap.png/pdf"
di "  - figures/fig10_2023_structural_shift.png/pdf"
di "  - figures/fig11_hedging_behavior.png/pdf"
di "  - tables/table7_theoretical_indices.csv"

log close
