/*===========================================================================
  CALCULATE_PAPER_FORMULAS.do

  Purpose:
    Compute the paper's main formula-based metrics in one pipeline:
      1) Trade Intensity Index (TII)
      2) Revealed Comparative Advantage (RCA)
      3) Export Concentration Index (HHI)
      4) Trade Complementarity Index (TCI)
      5) Terms of Trade (ToT)

  Inputs:
    - sinokaz_summary_master.dta
    - sectoral_trade_clean.dta
    - archive/misc/chinaworldimports/DataJobID-3075788_3075788_chinaWorldImports.csv
      (or chinaworldimports/... if present)

  Outputs:
    - tables/paper_formula_indices_annual.csv
    - tables/paper_formula_indices_annual.dta
    - tables/paper_formula_rca_sector_year.csv
    - tables/paper_formula_rca_sector_year.dta
    - logs/calculate_paper_formulas.log
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

local y0 2015
local y1 2024

local china_csv "data/raw/DataJobID-3082405_3082405_tii.csv"
capture confirm file "`china_csv'"
if _rc != 0 {
    local china_csv "chinaworldimports/DataJobID-3075788_3075788_chinaWorldImports.csv"
    capture confirm file "`china_csv'"
    if _rc != 0 {
        local china_csv "archive/misc/chinaworldimports/DataJobID-3075788_3075788_chinaWorldImports.csv"
    }
}

capture mkdir "tables"
capture mkdir "logs"

capture log close
log using "logs/calculate_paper_formulas.log", replace text

di _newline(2) "==============================================================="
di "  CALCULATE PAPER FORMULAS (TII, RCA, HHI, TCI, ToT)"
di "==============================================================="
di "Years: `y0'-`y1'"

*--------------------------------------------------------------------------
* INPUT CHECKS
*--------------------------------------------------------------------------
foreach f in sinokaz_summary_master.dta sectoral_trade_clean.dta {
    capture confirm file "`f'"
    if _rc != 0 {
        di as error "Missing required file: `f'"
        log close
        exit 601
    }
}

local has_china_csv 1
capture confirm file "`china_csv'"
if _rc != 0 {
    local has_china_csv 0
    di as error "China world-import CSV not found. Canonical TII/TCI will be missing."
}

*--------------------------------------------------------------------------
* BUILD ANNUAL BASE TABLE
*--------------------------------------------------------------------------
use "sinokaz_summary_master.dta", clear
keep if inrange(year, `y0', `y1')

foreach v in year exports_bn imports_bn kaz_exports_bn {
    capture confirm variable `v'
    if _rc != 0 {
        di as error "Missing variable in sinokaz_summary_master.dta: `v'"
        log close
        exit 498
    }
}

gen x_kz_chn_bn = exports_bn
gen m_kz_chn_bn = imports_bn
gen x_kz_world_bn = kaz_exports_bn

keep year x_kz_chn_bn m_kz_chn_bn x_kz_world_bn
sort year
tempfile annual_base annual_tii annual_hhi annual_tci annual_tot
save `annual_base', replace

*--------------------------------------------------------------------------
* TII (canonical): (X_KZ,CHN/X_KZ,World)/(M_CHN,World/M_World)
*--------------------------------------------------------------------------
use `annual_base', clear
gen tii = .
gen str120 tii_note = "Not computed (missing China world-import CSV)."

if `has_china_csv' == 1 {
    tempfile china_raw china_totals world_totals
    tempfile world_fallback

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
    save `china_raw', replace

    local tii_ready 1

    use `china_raw', clear
    keep if reporteriso3 == "CHN" & partneriso3 == "WLD" & tradeflowname == "Import" & productcode == "Total"
    quietly count
    if r(N) == 0 {
        use `china_raw', clear
        keep if reporteriso3 == "CHN" & partneriso3 == "WLD" & tradeflowname == "Import"
        quietly count
        if r(N) == 0 {
            local tii_ready 0
        }
        else {
            collapse (sum) m_chn_world_1000 = trade_value_1000, by(year)
            save `china_totals', replace
        }
    }
    else {
        collapse (sum) m_chn_world_1000 = trade_value_1000, by(year)
        save `china_totals', replace
    }

    use `china_raw', clear
    keep if reporteriso3 == "All" & partneriso3 == "All" & tradeflowname == "Import" & productcode == "Total"
    quietly count
    if r(N) == 0 {
        capture confirm file "archive/misc/chinaworldimports/DataJobID-3075788_3075788_chinaWorldImports.csv"
        if _rc == 0 {
            import delimited "archive/misc/chinaworldimports/DataJobID-3075788_3075788_chinaWorldImports.csv", clear varnames(1)
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
            keep if reporteriso3 == "All" & partneriso3 == "All" & tradeflowname == "Import" & productcode == "Total"
            quietly count
            if r(N) == 0 {
                local tii_ready 0
            }
            else {
                collapse (sum) m_world_total_1000 = trade_value_1000, by(year)
                save `world_totals', replace
            }
        }
        else {
            local tii_ready 0
        }
    }
    else {
        collapse (sum) m_world_total_1000 = trade_value_1000, by(year)
        save `world_totals', replace
    }

    if `tii_ready' == 1 {
        use `annual_base', clear
        merge 1:1 year using `china_totals', nogen keep(master match)
        merge 1:1 year using `world_totals', nogen keep(master match)

        gen kz_export_share_to_china = x_kz_chn_bn / x_kz_world_bn if x_kz_world_bn > 0
        gen china_world_import_share = m_chn_world_1000 / m_world_total_1000 if m_world_total_1000 > 0
        gen tii = kz_export_share_to_china / china_world_import_share if china_world_import_share > 0
        gen str120 tii_note = "Canonical TII computed."
    }
    else {
        use `annual_base', clear
        gen tii = .
        gen str120 tii_note = "Not computed (missing required annual world-total import denominator for canonical TII)."
    }
}

keep year tii tii_note
sort year
save `annual_tii', replace

*--------------------------------------------------------------------------
* HHI (export concentration to China): sum_i (share_i)^2
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
sort year
save `annual_hhi', replace

*--------------------------------------------------------------------------
* TCI (canonical): 100 * (1 - 0.5 * sum_i |m_i^CHN - x_i^KAZ|)
*--------------------------------------------------------------------------
use `annual_base', clear
keep year
duplicates drop
gen tci = .
gen str120 tci_note = "Not computed (missing China world-import CSV)."
save `annual_tci', replace

if `has_china_csv' == 1 {
    tempfile china_raw china_totals china_sector kz_sector_sh tci_year

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
    save `china_raw', replace

    local tci_ready 1

    use `china_raw', clear
    keep if reporteriso3 == "CHN" & partneriso3 == "WLD" & tradeflowname == "Import" & productcode == "Total"
    quietly count
    if r(N) == 0 {
        use `china_raw', clear
        keep if reporteriso3 == "CHN" & partneriso3 == "WLD" & tradeflowname == "Import"
        quietly count
        if r(N) == 0 local tci_ready 0
        else {
            collapse (sum) m_chn_world_1000 = trade_value_1000, by(year)
            save `china_totals', replace
        }
    }
    else {
        collapse (sum) m_chn_world_1000 = trade_value_1000, by(year)
        save `china_totals', replace
    }

    if `tci_ready' == 1 {
        use `china_raw', clear
        keep if reporteriso3 == "CHN" & partneriso3 == "WLD" & tradeflowname == "Import"
        drop if productcode == "Total"
        destring productcode, gen(hs2) force

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

        * fallback for grouped product codes like "28-38_Chemicals"
        replace sector = "Agriculture"          if sector == "" & strpos(productcode, "01-05_") == 1
        replace sector = "Agriculture"          if sector == "" & strpos(productcode, "06-15_") == 1
        replace sector = "Agriculture"          if sector == "" & strpos(productcode, "16-24_") == 1
        replace sector = "Metals_Minerals"      if sector == "" & strpos(productcode, "25-26_") == 1
        replace sector = "Energy"               if sector == "" & strpos(productcode, "27-27_") == 1
        replace sector = "Chemicals"            if sector == "" & strpos(productcode, "28-38_") == 1
        replace sector = "Plastics_Rubber"      if sector == "" & strpos(productcode, "39-40_") == 1
        replace sector = "Other"                if sector == "" & strpos(productcode, "41-43_") == 1
        replace sector = "Wood_Paper"           if sector == "" & strpos(productcode, "44-49_") == 1
        replace sector = "Textiles"             if sector == "" & strpos(productcode, "50-63_") == 1
        replace sector = "Other"                if sector == "" & strpos(productcode, "64-67_") == 1
        replace sector = "Stone_Ceramics"       if sector == "" & strpos(productcode, "68-70_") == 1
        replace sector = "Metals_Minerals"      if sector == "" & strpos(productcode, "71-83_") == 1
        replace sector = "Machinery_Electrical" if sector == "" & strpos(productcode, "84-85_") == 1
        replace sector = "Other"                if sector == "" & strpos(productcode, "86-86_") == 1
        replace sector = "Vehicles"             if sector == "" & strpos(productcode, "87-89_") == 1
        replace sector = "Other"                if sector == "" & strpos(productcode, "90-92_") == 1
        replace sector = "Other"                if sector == "" & strpos(productcode, "93-93_") == 1
        replace sector = "Other"                if sector == "" & strpos(productcode, "94-96_") == 1
        replace sector = "Other"                if sector == "" & strpos(productcode, "97-99_") == 1
        replace sector = "Other"                if sector == ""

        collapse (sum) m_chn_sector_1000 = trade_value_1000, by(year sector)
        merge m:1 year using `china_totals', nogen keep(master match)
        gen chn_import_share = m_chn_sector_1000 / m_chn_world_1000 if m_chn_world_1000 > 0
        keep year sector chn_import_share
        save `china_sector', replace

    use "sectoral_trade_clean.dta", clear
    keep if inrange(year, `y0', `y1')
    keep if partner == "CHN" & flow_name == "Export"
    collapse (sum) x_kz_sector_chn_mil = value_million, by(year sector)
    bys year: egen x_kz_chn_total_mil = total(x_kz_sector_chn_mil)
    gen kz_export_share = x_kz_sector_chn_mil / x_kz_chn_total_mil if x_kz_chn_total_mil > 0
    keep year sector kz_export_share
    save `kz_sector_sh', replace

        use `kz_sector_sh', clear
        merge 1:1 year sector using `china_sector', nogen keep(master match)
        replace kz_export_share = 0 if missing(kz_export_share)
        replace chn_import_share = 0 if missing(chn_import_share)
        gen abs_diff = abs(kz_export_share - chn_import_share)
        bys year: egen sum_abs_diff = total(abs_diff)
        gen tci = 100 * (1 - 0.5 * sum_abs_diff)
        keep year tci
        duplicates drop
        gen str120 tci_note = "Canonical TCI computed."
        save `tci_year', replace

        use `annual_tci', clear
        merge 1:1 year using `tci_year', nogen update replace
        replace tci_note = "Canonical TCI computed." if !missing(tci)
        save `annual_tci', replace
    }
    else {
        use `annual_tci', clear
        replace tci_note = "Not computed (China CSV lacks CHN/WLD import structure for canonical TCI)."
        save `annual_tci', replace
    }
}

*--------------------------------------------------------------------------
* ToT: ToT_t = (P_x,t / P_m,t) * 100
*--------------------------------------------------------------------------
use `annual_base', clear
gen tot = .
gen str120 tot_note = "Not computed (no export/import price indices in local datasets)."

capture confirm variable export_price_index
local has_px = (_rc == 0)
capture confirm variable import_price_index
local has_pm = (_rc == 0)

if `has_px' == 1 & `has_pm' == 1 {
    gen tot = 100 * (export_price_index / import_price_index) if import_price_index > 0
    replace tot_note = "Computed from export/import price indices in dataset."
}

keep year tot tot_note
sort year
save `annual_tot', replace

*--------------------------------------------------------------------------
* RCA (year-sector): (x_kz_sector/x_kz_total) / (x_world_sector/x_world_total)
* Using export flows in sectoral_trade_clean as world baseline.
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

gen rca = .
replace rca = (sector_china / total_china) / (sector_world / total_world) ///
    if total_china > 0 & sector_world > 0 & total_world > 0
gen str120 rca_note = "Computed using sectoral_trade_clean world export baseline."

keep year sector rca rca_note
sort year sector
save "tables/paper_formula_rca_sector_year.dta", replace
export delimited using "tables/paper_formula_rca_sector_year.csv", replace

*--------------------------------------------------------------------------
* MERGE ANNUAL OUTPUTS
*--------------------------------------------------------------------------
use `annual_base', clear
merge 1:1 year using `annual_tii', nogen keep(master match)
merge 1:1 year using `annual_hhi', nogen keep(master match)
merge 1:1 year using `annual_tci', nogen keep(master match)
merge 1:1 year using `annual_tot', nogen keep(master match)

sort year
save "tables/paper_formula_indices_annual.dta", replace
export delimited using "tables/paper_formula_indices_annual.csv", replace

di _newline as result "Created outputs:"
di as result "  - tables/paper_formula_indices_annual.csv"
di as result "  - tables/paper_formula_rca_sector_year.csv"
di as result "  - logs/calculate_paper_formulas.log"
di _newline as result "Done."

log close
