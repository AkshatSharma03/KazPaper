/*===========================================================================
  CALCULATE_TRADE_INDICES.do

  Purpose:
    Compute bilateral trade indices for Kazakhstan-China analysis:
      1) Import Dependence (ID)
      2) Export Dependence (ED)
      3) Asymmetry Ratio (AR)
      4) Revealed Comparative Advantage (RCA, Balassa)
      5) Trade Intensity Index (TII)
      6) Trade Complementarity Index (TCI)

  Expected input file (CSV):
    year, sector, x_kz_chn, m_kz_chn, x_kz_world, m_kz_world,
    x_kz_sector_world, x_world_sector, x_world_total,
    m_chn_world, m_chn_sector, m_world_total

  Notes:
    - Minimum required for ID/ED/AR:
      year, x_kz_chn, m_kz_chn, x_kz_world, m_kz_world
    - Additional variables are required for RCA/TII/TCI.
    - One row per year-sector is recommended.
  ===========================================================================*/

version 17.0
clear all
set more off

*--------------------------------------------------------------------------
* USER SETTINGS
*--------------------------------------------------------------------------
cd "`c(pwd)'"

local input_csv  "tables/trade_indices_input.csv"
local outdir     "tables"

capture mkdir "`outdir'"
capture mkdir "logs"

capture log close
log using "logs/calculate_trade_indices.log", replace text

di _newline(2) "==============================================================="
di "  CALCULATE TRADE INDICES (KAZ-CHN)"
di "==============================================================="
di "Input:  `input_csv'"
di "Output: `outdir'"

*--------------------------------------------------------------------------
* LOAD INPUT
*--------------------------------------------------------------------------
capture confirm file "`input_csv'"
if _rc != 0 {
    di as error "Missing input file: `input_csv'"
    di as error "Create CSV with required columns and rerun."
    log close
    exit 601
}

import delimited "`input_csv'", clear varnames(1) stringcols(_all)

* Convert all possible numeric columns from string safely
local maybe_numeric year x_kz_chn m_kz_chn x_kz_world m_kz_world ///
    x_kz_sector_world x_world_sector x_world_total m_chn_world ///
    m_chn_sector m_world_total

foreach v of local maybe_numeric {
    capture confirm variable `v'
    if _rc == 0 {
        quietly destring `v', replace ignore(", ")
    }
}

capture confirm variable year
if _rc != 0 {
    di as error "Missing required variable: year"
    log close
    exit 498
}

sort year

*--------------------------------------------------------------------------
* REQUIRED CHECKS FOR CORE INDICES
*--------------------------------------------------------------------------
local core_vars x_kz_chn m_kz_chn x_kz_world m_kz_world
foreach v of local core_vars {
    capture confirm variable `v'
    if _rc != 0 {
        di as error "Missing core variable: `v'"
        log close
        exit 498
    }
}

*--------------------------------------------------------------------------
* 1) ID, 2) ED, 3) AR
*--------------------------------------------------------------------------
gen import_dependence = m_kz_chn / m_kz_world if m_kz_world > 0
label var import_dependence "ID: M(KZ,CHN)/M(KZ,World)"

gen export_dependence = x_kz_chn / x_kz_world if x_kz_world > 0
label var export_dependence "ED: X(KZ,CHN)/X(KZ,World)"

gen asymmetry_ratio = m_kz_chn / x_kz_chn if x_kz_chn > 0
label var asymmetry_ratio "AR: M(KZ,CHN)/X(KZ,CHN)"

*--------------------------------------------------------------------------
* 4) RCA (Balassa) - sector-level
*--------------------------------------------------------------------------
local has_rca 1
foreach v in sector x_kz_sector_world x_world_sector x_world_total x_kz_world {
    capture confirm variable `v'
    if _rc != 0 local has_rca 0
}

if `has_rca' == 1 {
    gen kz_sector_share = x_kz_sector_world / x_kz_world if x_kz_world > 0
    gen world_sector_share = x_world_sector / x_world_total if x_world_total > 0
    gen rca = kz_sector_share / world_sector_share if world_sector_share > 0
    label var rca "Balassa RCA"
}
else {
    di as text "RCA skipped: missing one or more required variables."
}

*--------------------------------------------------------------------------
* 5) TII - annual
*--------------------------------------------------------------------------
local has_tii 1
foreach v in m_chn_world m_world_total {
    capture confirm variable `v'
    if _rc != 0 local has_tii 0
}

if `has_tii' == 1 {
    gen china_world_import_share = m_chn_world / m_world_total if m_world_total > 0
    gen kz_export_share_to_china = x_kz_chn / x_kz_world if x_kz_world > 0
    gen tii = kz_export_share_to_china / china_world_import_share if china_world_import_share > 0
    label var tii "TII: (X_KZ,CHN/X_KZ,World)/(M_CHN,World/M_World)"
}
else {
    di as text "TII skipped: missing m_chn_world or m_world_total."
}

*--------------------------------------------------------------------------
* 6) TCI - sector-year
*--------------------------------------------------------------------------
local has_tci 1
foreach v in sector x_kz_sector_world x_kz_world m_chn_sector m_chn_world {
    capture confirm variable `v'
    if _rc != 0 local has_tci 0
}

if `has_tci' == 1 {
    gen kz_export_share = x_kz_sector_world / x_kz_world if x_kz_world > 0
    gen chn_import_share = m_chn_sector / m_chn_world if m_chn_world > 0
    gen abs_diff = abs(kz_export_share - chn_import_share) if !missing(kz_export_share, chn_import_share)

    bysort year: egen sum_abs_diff = total(abs_diff)
    gen tci = 100 * (1 - 0.5 * sum_abs_diff) if !missing(sum_abs_diff)
    label var tci "TCI (0-100)"
}
else {
    di as text "TCI skipped: missing one or more required sector variables."
}

*--------------------------------------------------------------------------
* EXPORT RESULTS
*--------------------------------------------------------------------------
tempfile full
save `full', replace

* Annual outputs: keep first non-missing per year
preserve
sort year
by year: egen id_y  = max(import_dependence)
by year: egen ed_y  = max(export_dependence)
by year: egen ar_y  = max(asymmetry_ratio)

capture confirm variable tii
if _rc == 0 {
    by year: egen tii_y = max(tii)
}

capture confirm variable tci
if _rc == 0 {
    by year: egen tci_y = max(tci)
}

keep year id_y ed_y ar_y tii_y tci_y
rename id_y import_dependence
rename ed_y export_dependence
rename ar_y asymmetry_ratio
capture rename tii_y tii
capture rename tci_y tci
duplicates drop year, force
sort year
export delimited using "`outdir'/trade_indices_annual.csv", replace
save "`outdir'/trade_indices_annual.dta", replace
restore

* Sector outputs (RCA + shares) when available
capture confirm variable rca
if _rc == 0 {
    preserve
    keep year sector x_kz_sector_world x_kz_world x_world_sector x_world_total ///
         kz_sector_share world_sector_share rca
    sort year sector
    export delimited using "`outdir'/trade_indices_rca_sector.csv", replace
    save "`outdir'/trade_indices_rca_sector.dta", replace
    restore
}

* TCI by year (if available)
capture confirm variable tci
if _rc == 0 {
    preserve
    keep year tci
    duplicates drop year, force
    sort year
    export delimited using "`outdir'/trade_indices_tci_year.csv", replace
    save "`outdir'/trade_indices_tci_year.dta", replace
    restore
}

* Full working file
use `full', clear
save "`outdir'/trade_indices_full_working.dta", replace

di _newline as result "Created:"
di as result "  - `outdir'/trade_indices_annual.csv"
capture confirm file "`outdir'/trade_indices_rca_sector.csv"
if _rc == 0 di as result "  - `outdir'/trade_indices_rca_sector.csv"
capture confirm file "`outdir'/trade_indices_tci_year.csv"
if _rc == 0 di as result "  - `outdir'/trade_indices_tci_year.csv"
di as result "  - `outdir'/trade_indices_full_working.dta"

di _newline(1) "Done."
log close
