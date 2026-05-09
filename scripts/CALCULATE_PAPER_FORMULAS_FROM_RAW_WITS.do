/*===========================================================================
  CALCULATE_PAPER_FORMULAS_FROM_RAW_WITS.do

  Purpose:
    Compute paper formulas using current local files:
      1) TII
      2) RCA
      3) HHI
      4) TCI
      5) ToT (if price indices exist)

  Inputs:
    - sinokaz_summary_master.dta
    - sectoral_trade_clean.dta
    - data/raw/DataJobID-3082405_3082405_tii.csv   (CHN->WLD imports by grouped sector)
    - data/raw/DataJobID-3082411_3082411_world.csv (All->WLD imports by product)
    - data/Kazakhstan API Data/API_KAZ_DS2_en_csv_v2_18751.csv (WDI indicators)

  Outputs:
    - tables/paper_formulas_from_raw_wits_annual.csv
    - tables/paper_formulas_from_raw_wits_rca_sector_year.csv
    - logs/calculate_paper_formulas_from_raw_wits.log
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

local y0 2015
local y1 2024
local china_csv "data/raw/DataJobID-3082405_3082405_tii.csv"
local world_csv "data/raw/DataJobID-3082411_3082411_world.csv"
local wdi_csv "data/Kazakhstan API Data/API_KAZ_DS2_en_csv_v2_18751.csv"

capture mkdir "tables"
capture mkdir "logs"
capture log close
log using "logs/calculate_paper_formulas_from_raw_wits.log", replace text

foreach f in sinokaz_summary_master.dta sectoral_trade_clean.dta "`china_csv'" "`world_csv'" "`wdi_csv'" {
    capture confirm file "`f'"
    if _rc != 0 {
        di as error "Missing required file: `f'"
        log close
        exit 601
    }
}

tempfile annual_base tii_annual hhi_annual tci_annual tot_annual rca_sector
tempfile chn_totals world_totals chn_sector kz_sector

*--------------------------------------------------------------------------
* Annual base from project summary
*--------------------------------------------------------------------------
use "sinokaz_summary_master.dta", clear
keep if inrange(year, `y0', `y1')
gen x_kz_chn_bn = exports_bn
gen m_kz_chn_bn = imports_bn
gen x_kz_world_bn = kaz_exports_bn
keep year x_kz_chn_bn m_kz_chn_bn x_kz_world_bn
sort year
save `annual_base', replace

*--------------------------------------------------------------------------
* Build CHN world-import totals and CHN sector shares from china_csv
*--------------------------------------------------------------------------
import delimited "`china_csv'", clear varnames(1)
rename *, lower

capture confirm variable tradevaluein1000usd
if _rc == 0 rename tradevaluein1000usd trade_value_1000
else {
    capture confirm variable tradevalue_in_1000_usd
    if _rc == 0 rename tradevalue_in_1000_usd trade_value_1000
}
capture confirm numeric variable trade_value_1000
if _rc != 0 quietly destring trade_value_1000, replace ignore(", ")

keep if inrange(year, `y0', `y1')
keep if reporteriso3 == "CHN" & partneriso3 == "WLD" & tradeflowname == "Import"

* CHN total imports from world by year (sum detailed lines)
preserve
collapse (sum) m_chn_world_1000 = trade_value_1000, by(year)
save `chn_totals', replace
restore

* Map grouped product labels to project sectors for TCI
gen str30 sector = ""
replace sector = "Agriculture"          if strpos(productcode, "01-05_") == 1
replace sector = "Agriculture"          if strpos(productcode, "06-15_") == 1
replace sector = "Agriculture"          if strpos(productcode, "16-24_") == 1
replace sector = "Metals_Minerals"      if strpos(productcode, "25-26_") == 1
replace sector = "Energy"               if strpos(productcode, "27-27_") == 1
replace sector = "Chemicals"            if strpos(productcode, "28-38_") == 1
replace sector = "Plastics_Rubber"      if strpos(productcode, "39-40_") == 1
replace sector = "Other"                if strpos(productcode, "41-43_") == 1
replace sector = "Wood_Paper"           if strpos(productcode, "44-49_") == 1
replace sector = "Textiles"             if strpos(productcode, "50-63_") == 1
replace sector = "Other"                if strpos(productcode, "64-67_") == 1
replace sector = "Stone_Ceramics"       if strpos(productcode, "68-70_") == 1
replace sector = "Metals_Minerals"      if strpos(productcode, "71-83_") == 1
replace sector = "Machinery_Electrical" if strpos(productcode, "84-85_") == 1
replace sector = "Other"                if strpos(productcode, "86-86_") == 1
replace sector = "Vehicles"             if strpos(productcode, "87-89_") == 1
replace sector = "Other"                if strpos(productcode, "90-92_") == 1
replace sector = "Other"                if strpos(productcode, "93-93_") == 1
replace sector = "Other"                if strpos(productcode, "94-96_") == 1
replace sector = "Other"                if strpos(productcode, "97-99_") == 1
replace sector = "Other"                if sector == ""

collapse (sum) m_chn_sector_1000 = trade_value_1000, by(year sector)
merge m:1 year using `chn_totals', nogen keep(master match)
gen chn_import_share = m_chn_sector_1000 / m_chn_world_1000 if m_chn_world_1000 > 0
keep year sector chn_import_share
save `chn_sector', replace

*--------------------------------------------------------------------------
* Build world-total imports denominator from world_csv (sum detailed rows)
*--------------------------------------------------------------------------
import delimited "`world_csv'", clear varnames(1)
rename *, lower

capture confirm variable tradevaluein1000usd
if _rc == 0 rename tradevaluein1000usd trade_value_1000
else {
    capture confirm variable tradevalue_in_1000_usd
    if _rc == 0 rename tradevalue_in_1000_usd trade_value_1000
}
capture confirm numeric variable trade_value_1000
if _rc != 0 quietly destring trade_value_1000, replace ignore(", ")

keep if inrange(year, `y0', `y1')
keep if reporteriso3 == "All" & partneriso3 == "WLD" & tradeflowname == "Import"
collapse (sum) m_world_total_1000 = trade_value_1000, by(year)
save `world_totals', replace

*--------------------------------------------------------------------------
* TII
*--------------------------------------------------------------------------
use `annual_base', clear
merge 1:1 year using `chn_totals', nogen keep(master match)
merge 1:1 year using `world_totals', nogen keep(master match)
gen kz_export_share_to_china = x_kz_chn_bn / x_kz_world_bn if x_kz_world_bn > 0
gen china_world_import_share = m_chn_world_1000 / m_world_total_1000 if m_world_total_1000 > 0
gen tii = kz_export_share_to_china / china_world_import_share if china_world_import_share > 0
gen str120 tii_note = "Computed from CHN/WLD and All/WLD detailed rows (summed by year)."
keep year tii tii_note
save `tii_annual', replace

*--------------------------------------------------------------------------
* HHI export concentration
*--------------------------------------------------------------------------
use "sectoral_trade_clean.dta", clear
keep if inrange(year, `y0', `y1')
keep if partner == "CHN" & flow_name == "Export"
collapse (sum) value_million, by(year sector)
bysort year: egen total_exports = total(value_million)
gen export_share = value_million / total_exports if total_exports > 0
gen share_sq = export_share^2
collapse (sum) hhi_export = share_sq, by(year)
gen str120 hhi_note = "Computed as annual export HHI to China."
save `hhi_annual', replace

*--------------------------------------------------------------------------
* TCI
*--------------------------------------------------------------------------
use "sectoral_trade_clean.dta", clear
keep if inrange(year, `y0', `y1')
keep if partner == "CHN" & flow_name == "Export"
collapse (sum) x_kz_sector_chn_mil = value_million, by(year sector)
bys year: egen x_kz_chn_total_mil = total(x_kz_sector_chn_mil)
gen kz_export_share = x_kz_sector_chn_mil / x_kz_chn_total_mil if x_kz_chn_total_mil > 0
keep year sector kz_export_share
save `kz_sector', replace

use `kz_sector', clear
merge 1:1 year sector using `chn_sector', nogen keep(master match)
replace kz_export_share = 0 if missing(kz_export_share)
replace chn_import_share = 0 if missing(chn_import_share)
gen abs_diff = abs(kz_export_share - chn_import_share)
bys year: egen sum_abs_diff = total(abs_diff)
gen tci = 100 * (1 - 0.5 * sum_abs_diff)
keep year tci
duplicates drop
gen str120 tci_note = "Computed from CHN grouped-sector import structure."
save `tci_annual', replace

*--------------------------------------------------------------------------
* ToT
*--------------------------------------------------------------------------
tempfile wdi_long wdi_uvi wdi_tpri
import delimited "`wdi_csv'", clear varnames(5)
keep countryname countrycode indicatorname indicatorcode v*
keep if countrycode == "KAZ"
keep if inlist(indicatorcode, "TX.UVI.MRCH.XD.WD", "TM.UVI.MRCH.XD.WD", "TT.PRI.MRCH.XD.WD")

reshape long v, i(countrycode indicatorcode) j(colidx)
destring colidx, replace
gen year = colidx + 1955
drop colidx
destring v, replace force
keep if inrange(year, `y0', `y1')
drop if missing(v)
save `wdi_long', replace

* Preferred ToT: derive from export/import unit value indices
use `wdi_long', clear
keep if inlist(indicatorcode, "TX.UVI.MRCH.XD.WD", "TM.UVI.MRCH.XD.WD")
keep indicatorcode year v
gen str12 series = ""
replace series = "uvi_exp" if indicatorcode == "TX.UVI.MRCH.XD.WD"
replace series = "uvi_imp" if indicatorcode == "TM.UVI.MRCH.XD.WD"
drop indicatorcode
reshape wide v, i(year) j(series) string
rename vuvi_exp export_uvi_2015base
rename vuvi_imp import_uvi_2015base
gen tot = 100 * (export_uvi_2015base / import_uvi_2015base) if import_uvi_2015base > 0
gen str120 tot_note_uvi = "Computed from WDI unit value indices: TX.UVI / TM.UVI * 100."
rename tot tot_uvi
keep year tot_uvi tot_note_uvi
save `wdi_uvi', replace

* Fallback ToT: WDI net barter terms of trade index
use `wdi_long', clear
keep if indicatorcode == "TT.PRI.MRCH.XD.WD"
keep indicatorcode year v
rename v tot
gen str120 tot_note_tpri = "From WDI net barter terms of trade index (TT.PRI.MRCH.XD.WD)."
rename tot tot_tpri
keep year tot_tpri tot_note_tpri
save `wdi_tpri', replace

use `annual_base', clear
keep year
duplicates drop
gen tot = .
gen str120 tot_note = "Not computed."
merge 1:1 year using `wdi_uvi', nogen keep(master match)
merge 1:1 year using `wdi_tpri', nogen keep(master match)
replace tot = tot_uvi if !missing(tot_uvi)
replace tot_note = tot_note_uvi if !missing(tot_uvi)
replace tot = tot_tpri if missing(tot) & !missing(tot_tpri)
replace tot_note = tot_note_tpri if missing(tot) & !missing(tot_tpri)
drop tot_uvi tot_note_uvi tot_tpri tot_note_tpri
replace tot_note = "Not computed (missing WDI ToT indicators for this year)." if missing(tot)
save `tot_annual', replace

*--------------------------------------------------------------------------
* RCA sector-year
*--------------------------------------------------------------------------
use "sectoral_trade_clean.dta", clear
keep if inrange(year, `y0', `y1')
keep if flow_name == "Export"
gen chn_export = value_million if partner == "CHN"
replace chn_export = 0 if missing(chn_export)
bysort year sector: egen sector_world = total(value_million)
bysort year sector: egen sector_china = total(chn_export)
bysort year: egen total_world = total(value_million)
collapse (max) sector_world sector_china total_world, by(year sector)
bysort year: egen total_china = total(sector_china)
gen rca = (sector_china / total_china) / (sector_world / total_world) if total_china > 0 & sector_world > 0 & total_world > 0
gen str120 rca_note = "Computed using sectoral_trade_clean world export baseline."
keep year sector rca rca_note
sort year sector
save "tables/paper_formulas_from_raw_wits_rca_sector_year.dta", replace
export delimited using "tables/paper_formulas_from_raw_wits_rca_sector_year.csv", replace

*--------------------------------------------------------------------------
* Final annual merge
*--------------------------------------------------------------------------
use `annual_base', clear
merge 1:1 year using `tii_annual', nogen keep(master match)
merge 1:1 year using `hhi_annual', nogen keep(master match)
merge 1:1 year using `tci_annual', nogen keep(master match)
merge 1:1 year using `tot_annual', nogen keep(master match)
sort year
save "tables/paper_formulas_from_raw_wits_annual.dta", replace
export delimited using "tables/paper_formulas_from_raw_wits_annual.csv", replace

di as result "Created:"
di as result "  - tables/paper_formulas_from_raw_wits_annual.csv"
di as result "  - tables/paper_formulas_from_raw_wits_rca_sector_year.csv"
di as result "  - logs/calculate_paper_formulas_from_raw_wits.log"
log close
