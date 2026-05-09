/*===========================================================================
  CALCULATE_TII_TCI_WITH_CHINA_WORLD_DATA.do

  Purpose:
    Compute canonical Trade Intensity Index (TII) and Trade Complementarity
    Index (TCI) using existing Kazakhstan project data plus downloaded China
    world-import CSV.

  Inputs:
    - sinokaz_summary_master.dta
    - sectoral_trade_clean.dta
    - chinaworldimports/DataJobID-3075788_3075788_chinaWorldImports.csv

  Outputs:
    - tables/trade_intensity_index_tii.csv
    - tables/trade_intensity_index_tii.dta
    - tables/trade_complementarity_tci_year.csv
    - tables/trade_complementarity_tci_year.dta
    - tables/trade_complementarity_tci_sector_detail.csv
    - tables/trade_complementarity_tci_sector_detail.dta
    - logs/calculate_tii_tci_with_china_world_data.log

  Formulae:
    TII_t = (X_KZ,CHN,t / X_KZ,World,t) / (M_CHN,World,t / M_World,t)
    TCI_t = 100 * (1 - 0.5 * sum_k |x_k,t^KZ->CHN - m_k,t^CHN<-World|)
  ===========================================================================*/

version 17.0
clear all
set more off

*--------------------------------------------------------------------------
* SETTINGS
*--------------------------------------------------------------------------
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

local china_csv "chinaworldimports/DataJobID-3075788_3075788_chinaWorldImports.csv"
capture confirm file "`china_csv'"
if _rc != 0 {
    local china_csv "archive/misc/chinaworldimports/DataJobID-3075788_3075788_chinaWorldImports.csv"
}
local y0 2015
local y1 2024

capture mkdir "tables"
capture mkdir "logs"

capture log close
log using "logs/calculate_tii_tci_with_china_world_data.log", replace text

di _newline(2) "==============================================================="
di "  CALCULATE TII + TCI (WITH CHINA WORLD DATA)"
di "==============================================================="
di "China CSV: `china_csv'"
di "Years:     `y0'-`y1'"

*--------------------------------------------------------------------------
* INPUT CHECKS
*--------------------------------------------------------------------------
foreach f in sinokaz_summary_master.dta sectoral_trade_clean.dta "`china_csv'" {
    capture confirm file "`f'"
    if _rc != 0 {
        di as error "Missing required file: `f'"
        log close
        exit 601
    }
}

*--------------------------------------------------------------------------
* LOAD + STANDARDIZE CHINA CSV
*--------------------------------------------------------------------------
import delimited "`china_csv'", clear varnames(1)

rename *, lower

* Standardize key variable names across possible import-delimited variants
capture confirm variable reporteriso3
if _rc != 0 {
    di as error "Variable reporteriso3 not found in China CSV"
    log close
    exit 498
}

capture confirm variable partneriso3
if _rc != 0 {
    di as error "Variable partneriso3 not found in China CSV"
    log close
    exit 498
}

capture confirm variable year
if _rc != 0 {
    di as error "Variable year not found in China CSV"
    log close
    exit 498
}

capture confirm variable tradeflowname
if _rc != 0 {
    di as error "Variable tradeflowname not found in China CSV"
    log close
    exit 498
}

capture confirm variable productcode
if _rc != 0 {
    di as error "Variable productcode not found in China CSV"
    log close
    exit 498
}

capture confirm variable tradevaluein1000usd
if _rc == 0 {
    rename tradevaluein1000usd trade_value_1000
}
else {
    capture confirm variable tradevalue_in_1000_usd
    if _rc == 0 {
        rename tradevalue_in_1000_usd trade_value_1000
    }
    else {
        di as error "Could not locate trade value column in China CSV"
        log close
        exit 498
    }
}

capture confirm numeric variable trade_value_1000
if _rc != 0 {
    quietly destring trade_value_1000, replace ignore(", ")
}

replace reporteriso3 = trim(reporteriso3)
replace partneriso3  = trim(partneriso3)
replace tradeflowname = trim(tradeflowname)

capture confirm string variable productcode
if _rc == 0 {
    replace productcode = trim(productcode)
}
else {
    tostring productcode, replace force format(%12.0f)
    replace productcode = trim(productcode)
}

keep if inrange(year, `y0', `y1')
drop if missing(year)

tempfile china_raw china_totals world_totals china_sector
save `china_raw', replace

*--------------------------------------------------------------------------
* CHINA TOTAL IMPORTS: M_CHN,World,t
*--------------------------------------------------------------------------
use `china_raw', clear
keep if reporteriso3 == "CHN" & partneriso3 == "WLD" & tradeflowname == "Import"
keep if productcode == "Total"
collapse (sum) m_chn_world_1000 = trade_value_1000, by(year)
sort year
save `china_totals', replace

*--------------------------------------------------------------------------
* WORLD TOTAL IMPORTS: M_World,t
*--------------------------------------------------------------------------
use `china_raw', clear
keep if reporteriso3 == "All" & partneriso3 == "All" & tradeflowname == "Import"
keep if productcode == "Total"
collapse (sum) m_world_total_1000 = trade_value_1000, by(year)
sort year
save `world_totals', replace

*--------------------------------------------------------------------------
* CHINA SECTOR IMPORTS FROM WORLD: m_k,t^CHN<-World
*--------------------------------------------------------------------------
use `china_raw', clear
keep if reporteriso3 == "CHN" & partneriso3 == "WLD" & tradeflowname == "Import"
drop if productcode == "Total"

destring productcode, gen(hs2) force
drop if missing(hs2)

gen str30 sector = ""
replace sector = "Energy"               if hs2 == 27
replace sector = "Metals_Minerals"      if inlist(hs2,26,71,72,73,74,75,76,78,79,80,81,82,83)
replace sector = "Agriculture"          if hs2 >= 1  & hs2 <= 24
replace sector = "Machinery_Electrical" if inlist(hs2,84,85)
replace sector = "Vehicles"             if hs2 == 87
replace sector = "Textiles"             if hs2 >= 50 & hs2 <= 63
replace sector = "Chemicals"            if hs2 >= 28 & hs2 <= 38
replace sector = "Plastics_Rubber"      if inlist(hs2,39,40)
replace sector = "Wood_Paper"           if hs2 >= 44 & hs2 <= 49
replace sector = "Stone_Ceramics"       if hs2 >= 68 & hs2 <= 70
replace sector = "Other"                if sector == ""

collapse (sum) m_chn_sector_1000 = trade_value_1000, by(year sector)
sort year sector
save `china_sector', replace

*--------------------------------------------------------------------------
* TII BUILD: merge Kazakhstan annual exports with China/world totals
*--------------------------------------------------------------------------
use "sinokaz_summary_master.dta", clear
keep if inrange(year, `y0', `y1')

foreach v in year exports_bn kaz_exports_bn {
    capture confirm variable `v'
    if _rc != 0 {
        di as error "Missing variable in sinokaz_summary_master.dta: `v'"
        log close
        exit 498
    }
}

rename exports_bn x_kz_chn_bn
rename kaz_exports_bn x_kz_world_bn

gen kz_export_share_to_china = x_kz_chn_bn / x_kz_world_bn if x_kz_world_bn > 0

merge 1:1 year using `china_totals', nogen keep(master match)
merge 1:1 year using `world_totals', nogen keep(master match)

gen china_world_import_share = m_chn_world_1000 / m_world_total_1000 if m_world_total_1000 > 0
gen tii = kz_export_share_to_china / china_world_import_share if china_world_import_share > 0

label var tii "Trade Intensity Index"
label var kz_export_share_to_china "X(KZ,CHN)/X(KZ,World)"
label var china_world_import_share "M(CHN,World)/M(World)"

keep year x_kz_chn_bn x_kz_world_bn kz_export_share_to_china ///
     m_chn_world_1000 m_world_total_1000 china_world_import_share tii
sort year

save "tables/trade_intensity_index_tii.dta", replace
export delimited using "tables/trade_intensity_index_tii.csv", replace

*--------------------------------------------------------------------------
* TCI BUILD: combine KZ export shares and China import shares by sector/year
*--------------------------------------------------------------------------
tempfile kz_sector kz_sector_sh china_sector_sh sector_panel tci_detail

* KZ sector exports to China
use "sectoral_trade_clean.dta", clear
keep if inrange(year, `y0', `y1')
keep if partner == "CHN" & flow_name == "Export"

collapse (sum) x_kz_sector_chn_mil = value_million, by(year sector)
bys year: egen x_kz_chn_total_mil = total(x_kz_sector_chn_mil)
gen kz_export_share = x_kz_sector_chn_mil / x_kz_chn_total_mil if x_kz_chn_total_mil > 0
keep year sector x_kz_sector_chn_mil x_kz_chn_total_mil kz_export_share
sort year sector
save `kz_sector_sh', replace

* China sector import shares (world source)
use `china_sector', clear
merge m:1 year using `china_totals', nogen keep(master match)
gen chn_import_share = m_chn_sector_1000 / m_chn_world_1000 if m_chn_world_1000 > 0
keep year sector m_chn_sector_1000 m_chn_world_1000 chn_import_share
sort year sector
save `china_sector_sh', replace

* Union panel of (year, sector) to avoid dropping sectors present only on one side
use `kz_sector_sh', clear
keep year sector
save `sector_panel', replace

use `china_sector_sh', clear
keep year sector
append using `sector_panel'
duplicates tag year sector, gen(dup_key)
quietly count if dup_key > 0
if r(N) > 0 {
    di as error "Duplicate year-sector keys found in combined sector panel. Aborting to avoid silent row loss."
    duplicates list year sector if dup_key > 0
    log close
    exit 459
}
drop dup_key
sort year sector
save `sector_panel', replace

* Merge shares, fill missing with zero
use `sector_panel', clear
merge 1:1 year sector using `kz_sector_sh', nogen keep(master match)
merge 1:1 year sector using `china_sector_sh', nogen keep(master match)

replace kz_export_share = 0 if missing(kz_export_share)
replace chn_import_share = 0 if missing(chn_import_share)

gen abs_diff = abs(kz_export_share - chn_import_share)
bys year: egen sum_abs_diff = total(abs_diff)
gen tci = 100 * (1 - 0.5 * sum_abs_diff)

label var tci "Trade Complementarity Index (0-100)"
label var abs_diff "|x_k - m_k|"

sort year sector
save `tci_detail', replace
save "tables/trade_complementarity_tci_sector_detail.dta", replace
export delimited using "tables/trade_complementarity_tci_sector_detail.csv", replace

* Year-level TCI
preserve
keep year tci sum_abs_diff
duplicates tag year, gen(dup_year)
quietly count if dup_year > 0
if r(N) > 0 {
    di as error "Duplicate years found in year-level TCI output. Aborting to avoid silent row loss."
    duplicates list year if dup_year > 0
    log close
    exit 459
}
drop dup_year
sort year
save "tables/trade_complementarity_tci_year.dta", replace
export delimited using "tables/trade_complementarity_tci_year.csv", replace
restore

*--------------------------------------------------------------------------
* QUICK CONSOLE SUMMARY
*--------------------------------------------------------------------------
di _newline as result "Created:"
di as result "  - tables/trade_intensity_index_tii.csv"
di as result "  - tables/trade_complementarity_tci_year.csv"
di as result "  - tables/trade_complementarity_tci_sector_detail.csv"

quietly summarize tii
di _newline "TII mean (`y0'-`y1'): " %6.3f r(mean)

use "tables/trade_complementarity_tci_year.dta", clear
quietly summarize tci
di "TCI mean (`y0'-`y1'): " %6.3f r(mean)

di _newline(1) "Done."
log close
