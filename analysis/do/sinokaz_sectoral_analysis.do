/*===========================================================================
  COMPREHENSIVE SINO-KAZAKH SECTORAL TRADE ANALYSIS
  Corrected version
  Window: 2015-2024 only
  ===========================================================================*/

version 17.0
clear all
set more off

* Set working directory
cd "`c(pwd)'"

* Create output directories
capture mkdir "figures"
capture mkdir "tables"
capture mkdir "sectoral_data"

* Start logging
capture log close
log using "sinokaz_sectoral_analysis.log", replace

/*===========================================================================
  SECTION 1: IMPORT AND CLEAN WITS DATA
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 1: DATA IMPORT AND CLEANING"
di "==============================================================="

* Import WITS detailed bilateral trade data
local wits_file "3063878_F1AFE25F-9/DataJobID-3063878_3063878_DetailedBilateralTrade.csv"
capture confirm file "`wits_file'"
if _rc != 0 {
    local wits_file "3063878_F1AFE25F-9:DataJobID-3063878_3063878_DetailedBilateralTrade.csv"
    capture confirm file "`wits_file'"
}

if _rc != 0 {
    di as error "WITS source file not found."
    di as error "Expected either:"
    di as error "  1) 3063878_F1AFE25F-9/DataJobID-3063878_3063878_DetailedBilateralTrade.csv"
    di as error "  2) 3063878_F1AFE25F-9:DataJobID-3063878_3063878_DetailedBilateralTrade.csv"
    exit 601
}

di as result "Using WITS file: `wits_file'"
import delimited "`wits_file'", ///
    clear varnames(1) case(preserve)

* Clean variable names
rename Nomenclature nomen
rename ReporterISO3 reporter
rename ProductCode product_code
rename ReporterName reporter_name
rename PartnerISO3 partner
rename PartnerName partner_name
rename Year year
rename TradeFlowName flow_name
rename TradeFlowCode flow_code
rename TradeValuein1000USD value_usd

* Keep analysis window only
keep if inrange(year, 2015, 2024)

* Convert value to millions USD
gen value_million = value_usd / 1000

* Create flow indicator
gen flow = .
replace flow = 1 if flow_code == 6
replace flow = -1 if flow_code == 5

* Preserve HS leading zeros before deriving HS2
capture confirm string variable product_code
if _rc == 0 {
    gen str20 product_str = trim(product_code)
}
else {
    gen str20 product_str = trim(string(product_code, "%12.0f"))
    replace product_str = "0" + product_str if inlist(length(product_str), 1, 3, 5)
}

gen hs2 = real(substr(product_str, 1, 2))
drop if missing(hs2)

* Create broad sector categories
gen str30 sector = ""
replace sector = "Energy"                 if hs2 == 27
replace sector = "Metals_Minerals"        if inlist(hs2, 26, 71, 72, 73, 74, 75, 76, 78, 79, 80, 81, 82, 83)
replace sector = "Agriculture"            if hs2 >= 1  & hs2 <= 24
replace sector = "Machinery_Electrical"   if inlist(hs2, 84, 85)
replace sector = "Vehicles"               if hs2 == 87
replace sector = "Textiles"               if hs2 >= 50 & hs2 <= 63
replace sector = "Chemicals"              if hs2 >= 28 & hs2 <= 38
replace sector = "Plastics_Rubber"        if inlist(hs2, 39, 40)
replace sector = "Wood_Paper"             if hs2 >= 44 & hs2 <= 49
replace sector = "Stone_Ceramics"         if hs2 >= 68 & hs2 <= 70
replace sector = "Other"                  if sector == ""

* Product-level trade balance
gen trade_balance_mil = value_million * flow

label variable year "Year"
label variable partner "Trading Partner"
label variable value_million "Trade Value (Million USD)"
label variable sector "Product Sector"
label variable hs2 "HS 2-digit Code"

di _newline(2) "=== DATA COVERAGE SUMMARY: CHINA, 2015-2024 ==="
tabstat value_million if partner == "CHN", by(year) stat(sum n) format(%12.2f)

save "sectoral_trade_clean.dta", replace

/*===========================================================================
  SECTION 2: SECTORAL COMPOSITION ANALYSIS - CHINA ONLY
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 2: SECTORAL COMPOSITION WITH CHINA"
di "==============================================================="

use "sectoral_trade_clean.dta", clear
keep if partner == "CHN"

collapse (sum) value_million trade_balance_mil, by(year sector flow_name)

reshape wide value_million trade_balance_mil, i(year sector) j(flow_name) string

capture confirm variable value_millionExport
if _rc != 0 gen value_millionExport = .
capture confirm variable value_millionImport
if _rc != 0 gen value_millionImport = .
capture confirm variable trade_balance_milExport
if _rc != 0 gen trade_balance_milExport = .
capture confirm variable trade_balance_milImport
if _rc != 0 gen trade_balance_milImport = .

rename value_millionExport export_value
rename value_millionImport import_value
rename trade_balance_milExport export_balance
rename trade_balance_milImport import_balance

replace export_value   = 0 if missing(export_value)
replace import_value   = 0 if missing(import_value)
replace export_balance = export_value if missing(export_balance)
replace import_balance = -import_value if missing(import_balance)

gen net_balance = export_balance + import_balance

* Recalculate shares cleanly from final values
bysort year: egen total_exports = total(export_value)
bysort year: egen total_imports = total(import_value)

gen export_share = .
replace export_share = 100 * export_value / total_exports if total_exports > 0

gen import_share = .
replace import_share = 100 * import_value / total_imports if total_imports > 0

sort year sector
save "sectoral_composition_chn.dta", replace

* Table 1: Top sectors by average trade value (2015-2024)
di _newline(2) "=== TABLE 1: TOP SECTORS BY AVERAGE TRADE VALUE (2015-2024) ==="

preserve
keep if inrange(year, 2015, 2024)
collapse (mean) export_value import_value net_balance, by(sector)
gen total_avg = export_value + import_value
gsort -total_avg
gen rank = _n

local nshow = cond(_N < 10, _N, 10)

di _newline "Rank | Sector | Avg Exports | Avg Imports | Net Balance | Total"
di          "-----|--------|-------------|-------------|-------------|----------"
forvalues i = 1/`nshow' {
    di %4.0f rank[`i'] " | " %-22s sector[`i'] " | USD " %10.2f export_value[`i'] ///
       " | USD " %10.2f import_value[`i'] " | USD " %10.2f net_balance[`i'] ///
       " | USD " %10.2f total_avg[`i']
}

keep in 1/`nshow'
export delimited rank sector export_value import_value net_balance total_avg ///
    using "tables/table1_top_sectors.csv", replace
restore

/*===========================================================================
  SECTION 3: VISUALIZATION - SECTORAL COMPOSITION OVER TIME
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 3: GENERATING SECTORAL COMPOSITION FIGURES"
di "==============================================================="

use "sectoral_composition_chn.dta", clear

* Figure 1: Export Composition - true stacked area
preserve
keep year sector export_value
collapse (sum) export_value, by(year sector)
reshape wide export_value, i(year) j(sector) string

foreach s in Energy Metals_Minerals Agriculture Chemicals Other {
    capture confirm variable export_value`s'
    if _rc != 0 gen export_value`s' = 0
    replace export_value`s' = 0 if missing(export_value`s')
}

sort year
gen exp_c1 = export_valueEnergy
gen exp_c2 = exp_c1 + export_valueMetals_Minerals
gen exp_c3 = exp_c2 + export_valueAgriculture
gen exp_c4 = exp_c3 + export_valueChemicals
gen exp_c5 = exp_c4 + export_valueOther

#delimit ;
twoway
    (area exp_c5 year, sort color(gs14))
    (area exp_c4 year, sort color(gold))
    (area exp_c3 year, sort color(forest_green))
    (area exp_c2 year, sort color(cranberry))
    (area exp_c1 year, sort color(navy)),
    xlabel(2015(1)2024, angle(45) labsize(small))
    ylabel(, format(%9.0fc) labsize(small))
    ytitle("Export Value (Million USD)", size(small))
    xtitle("Year", size(small))
    title("Kazakhstan's Exports to China by Sector", size(medium))
    subtitle("Composition over time (2015-2024)", size(small))
    legend(order(5 "Energy" 4 "Metals & Minerals" 3 "Agriculture" 2 "Chemicals" 1 "Other")
           position(6) rows(2) size(small))
    note("HS 2-digit aggregation; 2015-2024 only", size(vsmall))
    scheme(s2color);
#delimit cr

graph export "figures/fig1_export_composition.png", replace width(2000)
graph export "figures/fig1_export_composition.pdf", replace
restore

* Figure 2: Import Composition - true stacked area
preserve
keep year sector import_value
collapse (sum) import_value, by(year sector)
reshape wide import_value, i(year) j(sector) string

foreach s in Machinery_Electrical Vehicles Textiles Chemicals Plastics_Rubber Metals_Minerals Other {
    capture confirm variable import_value`s'
    if _rc != 0 gen import_value`s' = 0
    replace import_value`s' = 0 if missing(import_value`s')
}

sort year
gen imp_c1 = import_valueMachinery_Electrical
gen imp_c2 = imp_c1 + import_valueVehicles
gen imp_c3 = imp_c2 + import_valueTextiles
gen imp_c4 = imp_c3 + import_valueChemicals
gen imp_c5 = imp_c4 + import_valuePlastics_Rubber
gen imp_c6 = imp_c5 + import_valueMetals_Minerals
gen imp_c7 = imp_c6 + import_valueOther

#delimit ;
twoway
    (area imp_c7 year, sort color(gs14))
    (area imp_c6 year, sort color(purple))
    (area imp_c5 year, sort color(orange))
    (area imp_c4 year, sort color(gold))
    (area imp_c3 year, sort color(forest_green))
    (area imp_c2 year, sort color(cranberry))
    (area imp_c1 year, sort color(navy)),
    xlabel(2015(1)2024, angle(45) labsize(small))
    ylabel(, format(%9.0fc) labsize(small))
    ytitle("Import Value (Million USD)", size(small))
    xtitle("Year", size(small))
    title("Kazakhstan's Imports from China by Sector", size(medium))
    subtitle("Composition over time (2015-2024)", size(small))
    legend(order(7 "Machinery & Electrical" 6 "Vehicles" 5 "Textiles" 4 "Chemicals" 3 "Plastics" 2 "Metals" 1 "Other")
           position(6) rows(2) size(small))
    note("HS 2-digit aggregation; 2015-2024 only", size(vsmall))
    scheme(s2color);
#delimit cr

graph export "figures/fig2_import_composition.png", replace width(2000)
graph export "figures/fig2_import_composition.pdf", replace
restore

/*===========================================================================
  SECTION 4: TRADE BALANCE BY SECTOR
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 4: SECTORAL TRADE BALANCE ANALYSIS"
di "==============================================================="

use "sectoral_composition_chn.dta", clear

preserve
keep if inlist(sector, "Energy", "Metals_Minerals", "Machinery_Electrical", "Vehicles")

#delimit ;
twoway
    (connected net_balance year if sector == "Energy", lcolor(navy) mcolor(navy) msymbol(O) lwidth(medthick))
    (connected net_balance year if sector == "Metals_Minerals", lcolor(cranberry) mcolor(cranberry) msymbol(S) lwidth(medthick))
    (connected net_balance year if sector == "Machinery_Electrical", lcolor(forest_green) mcolor(forest_green) msymbol(T) lwidth(medthick))
    (connected net_balance year if sector == "Vehicles", lcolor(purple) mcolor(purple) msymbol(D) lwidth(medthick)),
    xlabel(2015(1)2024, angle(45) labsize(small))
    ylabel(, format(%9.0fc) labsize(small))
    yline(0, lcolor(black) lpattern(dash) lwidth(thin))
    ytitle("Net Trade Balance (Million USD)", size(small))
    xtitle("Year", size(small))
    title("Kazakhstan-China Trade Balance by Major Sector", size(medium))
    subtitle("Positive = Surplus, Negative = Deficit", size(small))
    legend(order(1 "Energy" 2 "Metals & Minerals" 3 "Machinery & Electrical" 4 "Vehicles")
           position(6) rows(2) size(small))
    note("2015-2024 only", size(vsmall))
    scheme(s2color);
#delimit cr

graph export "figures/fig3_sectoral_balance.png", replace width(2000)
graph export "figures/fig3_sectoral_balance.pdf", replace
restore

* Table 2: Sectoral contributions to 2023 deficit
di _newline(2) "=== TABLE 2: SECTORAL CONTRIBUTIONS TO 2023 DEFICIT ==="

preserve
keep if inlist(year, 2022, 2023, 2024)
collapse (sum) net_balance, by(year sector)
reshape wide net_balance, i(sector) j(year)

capture confirm variable net_balance2022
if _rc != 0 gen net_balance2022 = 0
capture confirm variable net_balance2023
if _rc != 0 gen net_balance2023 = 0
capture confirm variable net_balance2024
if _rc != 0 gen net_balance2024 = 0

gen change_2022_2023 = net_balance2023 - net_balance2022
gen change_2023_2024 = net_balance2024 - net_balance2023

sort change_2022_2023
local nshow = cond(_N < 5, _N, 5)

di _newline "Sectors with largest balance deterioration 2022->2023:"
di "Sector | 2022 Balance | 2023 Balance | Change"
di "-------|--------------|--------------|-------"
forvalues i = 1/`nshow' {
    di %-25s sector[`i'] " | USD " %10.2f net_balance2022[`i'] ///
       " | USD " %10.2f net_balance2023[`i'] " | USD " %10.2f change_2022_2023[`i']
}

export delimited sector net_balance2022 net_balance2023 net_balance2024 ///
    change_2022_2023 change_2023_2024 ///
    using "tables/table2_sectoral_balance_change.csv", replace
restore

/*===========================================================================
  SECTION 5: CHINA IMPORT PENETRATION
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 5: CHINA IMPORT PENETRATION ANALYSIS"
di "==============================================================="

use "sectoral_trade_clean.dta", clear
keep if flow_code == 5

* Exclude known aggregates from denominator
drop if inlist(partner, "EU-UK", "ECS")

collapse (sum) value_million, by(year sector partner)

gen chn_import = value_million if partner == "CHN"
bysort year sector: egen total_imports = total(value_million)
bysort year sector: egen chn_imports = total(chn_import)
replace chn_imports = 0 if missing(chn_imports)

gen china_penetration = 100 * chn_imports / total_imports if total_imports > 0

collapse (max) china_penetration total_imports chn_imports, by(year sector)

preserve
keep if inlist(sector, "Machinery_Electrical", "Vehicles", "Textiles", "Chemicals", "Plastics_Rubber")

#delimit ;
twoway
    (connected china_penetration year if sector == "Machinery_Electrical", lcolor(navy) mcolor(navy) msymbol(O) lwidth(medthick))
    (connected china_penetration year if sector == "Vehicles", lcolor(cranberry) mcolor(cranberry) msymbol(S) lwidth(medthick))
    (connected china_penetration year if sector == "Textiles", lcolor(forest_green) mcolor(forest_green) msymbol(T) lwidth(medthick))
    (connected china_penetration year if sector == "Chemicals", lcolor(purple) mcolor(purple) msymbol(D) lwidth(medthick))
    (connected china_penetration year if sector == "Plastics_Rubber", lcolor(orange) mcolor(orange) msymbol(+) lwidth(medthick)),
    xlabel(2015(1)2024, angle(45) labsize(small))
     ylabel(0(10)50, format(%9.0f) labsize(small) grid)
     yscale(r(0 50))
    ytitle("China's Share of Total Imports (%)", size(small))
    xtitle("Year", size(small))
    title("China's Import Penetration by Sector", size(medium))
    subtitle("Chinese imports as % of Kazakhstan's sectoral imports", size(small))
    legend(order(1 "Machinery & Electrical" 2 "Vehicles" 3 "Textiles" 4 "Chemicals" 5 "Plastics & Rubber")
           position(6) rows(2) size(small))
    note("Known aggregates excluded from denominator; 2015-2024 only" "Dashed line at 5%; 2020-2022 min ~5% (real COVID trade collapse)", size(vsmall))
    scheme(s2color);
#delimit cr

graph export "figures/fig4_china_penetration.png", replace width(2000)
graph export "figures/fig4_china_penetration.pdf", replace
restore

di _newline(2) "=== TABLE 3: SECTORS WITH HIGHEST CHINESE IMPORT DEPENDENCY (2023) ==="

preserve
keep if year == 2023
gsort -china_penetration
local nshow = cond(_N < 10, _N, 10)

di "Sector | China Share | Total Imports | China Imports"
di "-------|-------------|---------------|--------------"
forvalues i = 1/`nshow' {
    di %-25s sector[`i'] " | " %6.2f china_penetration[`i'] "% | USD " ///
       %10.2f total_imports[`i'] " | USD " %10.2f chn_imports[`i']
}

keep in 1/`nshow'
export delimited sector china_penetration total_imports chn_imports ///
    using "tables/table3_china_penetration_2023.csv", replace
restore

/*===========================================================================
  SECTION 6: MULTIVECTOR TRADE ANALYSIS
  ===========================================================================*/
  
* FIGURE 5 DELETED - See audit notes: mixes single countries with bloc, misleading
* The comparison-set shares are still computed for internal use (fig8) below

di _newline(2) "==============================================================="
di "  SECTION 6: MULTIVECTOR TRADE ANALYSIS (fig5 SKIPPED - SEE AUDIT)"
di "==============================================================="

use "sectoral_trade_clean.dta", clear
keep if inlist(partner, "CHN", "RUS", "EU-UK")

collapse (sum) value_million, by(year partner)

bysort year: egen selected_total = total(value_million)
gen partner_share = 100 * value_million / selected_total if selected_total > 0

gen partner_num = 1 if partner == "CHN"
replace partner_num = 2 if partner == "RUS"
replace partner_num = 3 if partner == "EU-UK"

drop partner
reshape wide value_million partner_share, i(year) j(partner_num)

foreach v in partner_share1 partner_share2 partner_share3 {
    capture confirm variable `v'
    if _rc != 0 gen `v' = 0
    replace `v' = 0 if missing(`v')
}

#delimit ;
* FIGURE 5 DELETED - See audit notes: mixes single countries with bloc, misleading
* twoway
*     (connected partner_share1 year, lcolor(navy) mcolor(navy) msymbol(O) lwidth(medthick))
*     (connected partner_share2 year, lcolor(cranberry) mcolor(cranberry) msymbol(S) lwidth(medthick))
*     (connected partner_share3 year, lcolor(forest_green) mcolor(forest_green) msymbol(T) lwidth(medthick)),
*     xlabel(2015(2)2024, angle(45))
*     ylabel(0(10)100, format(%9.0f))
*     ytitle("Share among selected partners (%)")
*     xtitle("Year")
*     title("Kazakhstan's Multivector Trade Relations")
*     subtitle("China vs Russia vs EU-UK within selected comparison set")
*     legend(order(1 "China" 2 "Russia" 3 "EU-UK")
*            position(6) rows(1))
*     xline(2015, lcolor(gray) lpattern(dash) lwidth(thin))
*     xline(2022, lcolor(red) lpattern(dash) lwidth(thin))
*     note("Comparison-set shares, not world-total shares; 2015-2024 only")
*     scheme(s2color);
* #delimit cr
#delimit cr

* graph export "figures/fig5_multivector_shares.png", replace width(2000)
* graph export "figures/fig5_multivector_shares.pdf", replace

* Save 3-partner diversification data for Figure 8 (still needed)
export delimited year partner_share1 partner_share2 partner_share3 ///
    using "tables/table4_multivector_diversification.csv", replace

* Also calculate and save world-total shares for Figure 5
use "sectoral_trade_clean.dta", clear
keep if inrange(year, 2015, 2024)

collapse (sum) value_million, by(year partner)

bysort year: egen world_total = total(value_million)
gen world_share = 100 * value_million / world_total

keep if partner == "CHN" | partner == "RUS"

gen partner_num = 1 if partner == "CHN"
replace partner_num = 2 if partner == "RUS"

drop partner
reshape wide value_million world_share, i(year) j(partner_num)

foreach v in world_share1 world_share2 {
    capture confirm variable `v'
    if _rc != 0 gen `v' = 0
    replace `v' = 0 if missing(`v')
}

* table4_multivector_shares.csv - DEPRECATED (was for fig5, now deleted)
* export delimited year world_share1 world_share2 ///
*     using "tables/table4_multivector_shares.csv", replace

/*===========================================================================
  SECTION 7: EXPORT SPECIALIZATION PROXY
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 7: EXPORT SPECIALIZATION PROXY"
di "==============================================================="

use "sectoral_trade_clean.dta", clear
keep if flow_code == 6
drop if inlist(partner, "EU-UK", "ECS")

collapse (sum) value_million, by(year sector partner)

gen chn_export = value_million if partner == "CHN"
replace chn_export = 0 if missing(chn_export)

bysort year sector: egen sector_world = total(value_million)
bysort year sector: egen sector_china = total(chn_export)
bysort year: egen total_world = total(value_million)

collapse (max) sector_world sector_china total_world, by(year sector)
bysort year: egen total_china = total(sector_china)

gen specialization_index = .
replace specialization_index = (sector_china / total_china) / (sector_world / total_world) ///
    if total_china > 0 & sector_world > 0 & total_world > 0

di _newline(2) "=== TABLE 5: EXPORT SPECIALIZATION BY SECTOR (2022-2024 avg) ==="

preserve
keep if inrange(year, 2022, 2024)
collapse (mean) specialization_index sector_china, by(sector)
gsort -specialization_index

local nshow = cond(_N < 10, _N, 10)

di "Sector | Specialization Index | Avg Exports to CHN"
di "-------|----------------------|-------------------"
forvalues i = 1/`nshow' {
    di %-25s sector[`i'] " | " %8.4f specialization_index[`i'] ///
       " | USD " %10.2f sector_china[`i']
}

keep in 1/`nshow'
export delimited sector specialization_index sector_china ///
    using "tables/table5_rca_analysis.csv", replace
restore

/*===========================================================================
  SECTION 8: TRADE CONCENTRATION INDEX (HHI)
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 8: TRADE CONCENTRATION ANALYSIS"
di "==============================================================="

use "sectoral_trade_clean.dta", clear
keep if partner == "CHN"

collapse (sum) value_million, by(year sector flow_code)

bysort year flow_code: egen total = total(value_million)
gen share = value_million / total if total > 0
gen share_sq = share^2

collapse (sum) share_sq, by(year flow_code)

reshape wide share_sq, i(year) j(flow_code)

capture confirm variable share_sq5
if _rc == 0 {
    rename share_sq5 share_sq_imp
} else {
    gen share_sq_imp = 0
}

capture confirm variable share_sq6
if _rc == 0 {
    rename share_sq6 share_sq_exp
} else {
    gen share_sq_exp = 0
}

replace share_sq_imp = 0 if missing(share_sq_imp)
replace share_sq_exp = 0 if missing(share_sq_exp)

twoway (connected share_sq_exp year, lcolor(navy) mcolor(navy) msymbol(O) lwidth(medthick)) ///
       (connected share_sq_imp year, lcolor(cranberry) mcolor(cranberry) msymbol(S) lwidth(medthick)), ///
       xlabel(2015(2)2024, angle(45)) ///
       ylabel(0(0.1)0.6, format(%9.2f)) ///
       ytitle("Herfindahl-Hirschman Index") ///
       xtitle("Year") ///
       title("Trade Concentration with China") ///
       subtitle("Higher values = more concentrated") ///
       legend(order(1 "Exports" 2 "Imports") position(6) rows(1)) ///
       note("2015-2024 only") ///
       scheme(s2color)

graph export "figures/fig6_concentration_index.png", replace width(2000)
graph export "figures/fig6_concentration_index.pdf", replace

gen str10 flow_type = "Exports"
replace flow_type = "Imports" if share_sq_imp > 0 & share_sq_exp == 0
gen share_sq_combined = share_sq_exp + share_sq_imp
export delimited year flow_type share_sq_combined using "tables/table6_concentration_index.csv", replace

/*===========================================================================
  SECTION 9: STRUCTURAL BREAK TESTS
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 9: STRUCTURAL BREAK TESTS"
di "==============================================================="

use "sectoral_composition_chn.dta", clear

capture program drop breaktest
program define breaktest
    syntax , Sector(string) Label(string)

    preserve
    keep if sector == "`sector'"
    sort year

    quietly count
    if r(N) < 6 {
        di _newline "`label': insufficient observations for break test."
        restore
        exit
    }

    gen t = year - 2015

    quietly regress net_balance t
    scalar rss_r = e(rss)

    gen post2020 = year >= 2020
    gen post2023 = year >= 2023
    gen t_post2020 = t * post2020
    gen t_post2023 = t * post2023

    quietly regress net_balance t post2020 t_post2020
    scalar rss_u_2020 = e(rss)
    scalar df_u_2020 = e(df_r)
    scalar q = 2
    scalar chow_2020 = ((rss_r - rss_u_2020) / q) / (rss_u_2020 / df_u_2020)
    scalar p_2020 = Ftail(q, df_u_2020, chow_2020)

    quietly regress net_balance t post2023 t_post2023
    scalar rss_u_2023 = e(rss)
    scalar df_u_2023 = e(df_r)
    scalar chow_2023 = ((rss_r - rss_u_2023) / q) / (rss_u_2023 / df_u_2023)
    scalar p_2023 = Ftail(q, df_u_2023, chow_2023)

    di _newline "`label':"
    di "  Chow F (2020 break): " %6.3f chow_2020 " (p = " %6.4f p_2020 ")"
    di "  Chow F (2023 break): " %6.3f chow_2023 " (p = " %6.4f p_2023 ")"

    restore
end

di _newline(2) "=== CHOW TESTS FOR STRUCTURAL BREAKS BY SECTOR ==="
breaktest, sector("Energy") label("ENERGY SECTOR")
breaktest, sector("Machinery_Electrical") label("MACHINERY & ELECTRICAL SECTOR")
breaktest, sector("Vehicles") label("VEHICLES SECTOR")

/*===========================================================================
  SECTION 10: SUMMARY STATISTICS
  ===========================================================================*/

di _newline(2) "==============================================================="
di "  SECTION 10: SUMMARY STATISTICS"
di "==============================================================="

di _newline(2) "=== KEY FINDINGS SUMMARY ==="

use "sectoral_composition_chn.dta", clear

preserve
collapse (sum) export_value import_value net_balance, by(year)
di _newline "Total Trade with China (Million USD):"
di "Year | Exports | Imports | Balance"
di "-----|---------|---------|-------"
forvalues y = 2015/2024 {
    quietly sum export_value if year == `y'
    local exp = r(mean)
    quietly sum import_value if year == `y'
    local imp = r(mean)
    quietly sum net_balance if year == `y'
    local bal = r(mean)
    di `y' " | USD " %10.2f `exp' " | USD " %10.2f `imp' " | USD " %10.2f `bal'
}
restore

use "sectoral_trade_clean.dta", clear
keep if inlist(partner, "CHN", "RUS", "EU-UK")
collapse (sum) value_million, by(year partner)
bysort year: egen selected_total = total(value_million)
gen share = 100 * value_million / selected_total if selected_total > 0
keep if partner == "CHN"

di _newline "China's Share among Selected Comparison Partners:"
forvalues y = 2015(2)2024 {
    quietly sum share if year == `y'
    di `y' ": " %5.2f r(mean) "%"
}

di _newline "Export Concentration (HHI) by Year:"
use "sectoral_trade_clean.dta", clear
keep if partner == "CHN" & flow_code == 6
collapse (sum) value_million, by(year sector)
bysort year: egen total = total(value_million)
gen share = value_million / total if total > 0
gen share_sq = share^2
collapse (sum) share_sq, by(year)

forvalues y = 2015(2)2024 {
    quietly sum share_sq if year == `y'
    di `y' ": " %5.3f r(mean)
}

/*===========================================================================
  WRAP UP
  ===========================================================================*/

di _newline(3) "==============================================================="
di "  ANALYSIS COMPLETE"
di "==============================================================="
di _newline "Files generated:"
di "  Data: sectoral_composition_chn.dta, sectoral_trade_clean.dta"
di "  Figures:"
di "    - figures/fig1_export_composition.png/pdf"
di "    - figures/fig2_import_composition.png/pdf"
di "    - figures/fig3_sectoral_balance.png/pdf"
di "    - figures/fig4_china_penetration.png/pdf"
di "    - figures/fig5_multivector_shares.png/pdf  [DELETED - SEE AUDIT]"
di "    - figures/fig6_concentration_index.png/pdf"
di "  Tables:"
di "    - tables/table1_top_sectors.csv"
di "    - tables/table2_sectoral_balance_change.csv"
di "    - tables/table3_china_penetration_2023.csv"
di "    - tables/table4_multivector_shares.csv  [DEPRECATED]"
di "    - tables/table4_multivector_diversification.csv"
di "    - tables/table5_rca_analysis.csv"
di "    - tables/table6_concentration_index.csv"
di _newline "Log file: sinokaz_sectoral_analysis.log"

log close
