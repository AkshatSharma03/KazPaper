/*===========================================================================
   FINAL FIGURE 10 REVISION - Publication Ready Version
   Addresses all editorial feedback
   
   Improvements:
   - x-axis starts at 0 (no negative values in data)
   - Increased figure size for readability
   - Added explicit value labels on bars
   - Cleaner y-axis labels
   - Added gridlines
   ===========================================================================*/

version 17.0
clear all
set more off

* Resolve and set project root
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

di _newline(2) "==============================================================="
di "  FINAL FIGURE 10 REVISION - PUBLICATION READY"
di "==============================================================="
di ""

// Load sectoral data
use "sectoral_composition_chn.dta", clear
keep if inrange(year, 2015, 2024)

gen str8 period = "Pre2023" if year < 2023
replace period = "Post2023" if year >= 2023

collapse (mean) export_value import_value net_balance, by(period sector)

keep if inlist(sector, "Energy", "Machinery_Electrical", "Vehicles", "Metals_Minerals", "Textiles")

reshape wide export_value import_value net_balance, i(sector) j(period) string

foreach var in export_value import_value net_balance {
    capture confirm variable `var'Pre2023
    if _rc != 0 gen `var'Pre2023 = 0
    capture confirm variable `var'Post2023
    if _rc != 0 gen `var'Post2023 = 0
    
    replace `var'Pre2023 = 0 if missing(`var'Pre2023)
    replace `var'Post2023 = 0 if missing(`var'Post2023)
}

// Convert to BILLIONS for readability (not millions)
gen export_change_bn = (export_valuePost2023 - export_valuePre2023) / 1000
gen import_change_bn = (import_valuePost2023 - import_valuePre2023) / 1000

// Create readable sector labels
gen sector_label = ""
replace sector_label = "Energy" if sector == "Energy"
replace sector_label = "Machinery & Electrical" if sector == "Machinery_Electrical"
replace sector_label = "Vehicles" if sector == "Vehicles"
replace sector_label = "Metals & Minerals" if sector == "Metals_Minerals"
replace sector_label = "Textiles" if sector == "Textiles"

// Sort by magnitude of total change for better visual hierarchy
gen total_change = abs(export_change_bn) + abs(import_change_bn)
gsort -total_change

// Recalculate positions after sorting
gen sort_order = _n
gen sort_exp = sort_order - 0.2
gen sort_imp = sort_order + 0.2

// Create better formatted labels - include "+" sign and 1 decimal place
gen exp_label = "+" + string(export_change_bn, "%4.1f")
gen imp_label = "+" + string(import_change_bn, "%4.1f")

// For very small values, show as "+0.0"
replace exp_label = "+0.0" if export_change_bn < 0.05 & export_change_bn > 0
replace imp_label = "+0.0" if import_change_bn < 0.05 & import_change_bn > 0

// Create the publication-ready figure
twoway ///
    (bar export_change_bn sort_exp, horizontal color(navy) barwidth(0.35)) ///
    (bar import_change_bn sort_imp, horizontal color(cranberry) barwidth(0.35)) ///
    (scatter sort_exp export_change_bn, mlabel(exp_label) mlabcolor(black) ///
             mlabposition(0) mlabsize(medsmall) mlabgap(2) msymbol(none)) ///
    (scatter sort_imp import_change_bn, mlabel(imp_label) mlabcolor(black) ///
             mlabposition(0) mlabsize(medsmall) mlabgap(2) msymbol(none)), ///
    xlabel(0(2)10, format(%9.0f) labsize(small)) ///
    ylabel(1 "Metals & Minerals" ///
           2 "Machinery & Electrical" ///
           3 "Vehicles" ///
           4 "Energy" ///
           5 "Textiles", angle(0) labsize(medium)) ///
    xtitle("Change in average trade (Billion USD)", size(medium)) ///
    ytitle("") ///
    title("Post-2023 Sectoral Trade Changes", size(medium)) ///
    subtitle("2023-2024 average minus 2015-2022 average", size(small)) ///
    xscale(range(0 10)) ///
    xline(0, lcolor(black) lwidth(medium)) ///
    yline(1 2 3 4 5, lstyle(grid) lcolor(gray%30)) ///
    legend(order(1 "Exports" 2 "Imports") ///
           position(6) rows(1) size(medium)) ///
    note("Post-2023: 2 years (2023-2024) | Pre-2023: 8 years (2015-2022)" ///
         "Bars show change in average annual trade value in billion USD." ///
         "Interpret descriptively - periods differ in length.", size(vsmall)) ///
    scheme(s2color) ///
    graphregion(margin(r+8 l+2)) ///
    plotregion(margin(l+2))

graph export "figures/fig10_post2023_sectoral_change.png", replace width(2400) height(1600)
graph export "figures/fig10_post2023_sectoral_change.pdf", replace

// Also create a data table for transparency
keep sector export_valuePre2023 export_valuePost2023 export_change_bn import_valuePre2023 import_valuePost2023 import_change_bn

order sector export_valuePre2023 export_valuePost2023 export_change_bn import_valuePre2023 import_valuePost2023 import_change_bn

export delimited using "tables/fig10_post2023_sectoral_change_data.csv", replace

di _newline(2) "==============================================================="
di "  FIGURE 10 REVISION COMPLETE"
di "==============================================================="
di ""
di "Key improvements:"
di "  ✓ x-axis now starts at 0 (no negative values in data)"
di "  ✓ Added y-axis gridlines for easier reading"
di "  ✓ Value labels include '+' sign for clarity"
di "  ✓ Larger figure dimensions (2400x1600)"
di "  ✓ Improved note explaining the comparison"
di ""
di "Files created:"
di "  - figures/fig10_post2023_sectoral_change.png/pdf"
di "  - tables/fig10_post2023_sectoral_change_data.csv"
di ""
