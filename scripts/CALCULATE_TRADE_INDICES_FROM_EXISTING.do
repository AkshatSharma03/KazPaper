/*===========================================================================
  CALCULATE_TRADE_INDICES_FROM_EXISTING.do

  Purpose:
    Build trade indices directly from existing project files (no new downloads).

  Inputs:
    - sinokaz_summary_master.dta
    - sectoral_composition_chn.dta
    - tables/table5_rca_analysis.csv

  Outputs:
    - tables/trade_indices_from_existing_annual.csv
    - tables/trade_indices_from_existing_rca.csv
    - tables/trade_indices_from_existing_tci_proxy.csv

  Important:
    Canonical TII and canonical TCI are NOT fully identifiable from current
    project files because China world-import totals and China global sectoral
    import shares are not available in the local dataset set.
  ===========================================================================*/

version 17.0
clear all
set more off

cd "`c(pwd)'"
capture mkdir "tables"
capture mkdir "logs"

capture log close
log using "logs/calculate_trade_indices_from_existing.log", replace text

di _newline(2) "==============================================================="
di "  CALCULATE TRADE INDICES FROM EXISTING FILES"
di "==============================================================="

*--------------------------------------------------------------------------
* 1) Annual ID / ED / AR from summary master
*--------------------------------------------------------------------------
capture confirm file "sinokaz_summary_master.dta"
if _rc != 0 {
    di as error "Missing required file: sinokaz_summary_master.dta"
    log close
    exit 601
}

use "sinokaz_summary_master.dta", clear

foreach v in year exports_bn imports_bn kaz_exports_bn kaz_imports_bn {
    capture confirm variable `v'
    if _rc != 0 {
        di as error "Missing required variable in sinokaz_summary_master.dta: `v'"
        log close
        exit 498
    }
}

gen x_kz_chn_bn   = exports_bn
gen m_kz_chn_bn   = imports_bn
gen x_kz_world_bn = kaz_exports_bn
gen m_kz_world_bn = kaz_imports_bn

gen import_dependence = m_kz_chn_bn / m_kz_world_bn if m_kz_world_bn > 0
gen export_dependence = x_kz_chn_bn / x_kz_world_bn if x_kz_world_bn > 0
gen asymmetry_ratio   = m_kz_chn_bn / x_kz_chn_bn   if x_kz_chn_bn > 0

gen import_dependence_pct = 100 * import_dependence
gen export_dependence_pct = 100 * export_dependence

gen tii = .
gen str120 tii_status = "Not identifiable from current files (missing M_CHN,World and M_World,World by year)."

keep year x_kz_chn_bn m_kz_chn_bn x_kz_world_bn m_kz_world_bn ///
     import_dependence export_dependence asymmetry_ratio ///
     import_dependence_pct export_dependence_pct tii tii_status
sort year

export delimited using "tables/trade_indices_from_existing_annual.csv", replace
save "tables/trade_indices_from_existing_annual.dta", replace
di as result "Created: tables/trade_indices_from_existing_annual.csv"

*--------------------------------------------------------------------------
* 2) RCA table standardization (existing computed RCA)
*--------------------------------------------------------------------------
capture confirm file "tables/table5_rca_analysis.csv"
if _rc != 0 {
    di as error "Missing required file: tables/table5_rca_analysis.csv"
    log close
    exit 601
}

import delimited "tables/table5_rca_analysis.csv", clear

capture confirm variable sector
if _rc != 0 {
    di as error "Missing variable in table5_rca_analysis.csv: sector"
    log close
    exit 498
}
capture confirm variable specialization_index
if _rc != 0 {
    di as error "Missing variable in table5_rca_analysis.csv: specialization_index"
    log close
    exit 498
}

rename specialization_index rca
gen str50 rca_interpretation = cond(rca > 1, ///
    "Comparative advantage (RCA>1)", ///
    "No revealed comparative advantage (RCA<1)")

export delimited using "tables/trade_indices_from_existing_rca.csv", replace
save "tables/trade_indices_from_existing_rca.dta", replace
di as result "Created: tables/trade_indices_from_existing_rca.csv"

*--------------------------------------------------------------------------
* 3) Bilateral complementarity proxy (not canonical TCI)
*--------------------------------------------------------------------------
capture confirm file "sectoral_composition_chn.dta"
if _rc != 0 {
    di as error "Missing required file: sectoral_composition_chn.dta"
    log close
    exit 601
}

use "sectoral_composition_chn.dta", clear

foreach v in year sector export_share import_share {
    capture confirm variable `v'
    if _rc != 0 {
        di as error "Missing required variable in sectoral_composition_chn.dta: `v'"
        log close
        exit 498
    }
}

gen x_share = export_share / 100
gen m_share = import_share / 100
gen abs_diff = abs(x_share - m_share)

bysort year: egen sum_abs_diff = total(abs_diff)
gen bilateral_complementarity_proxy = 100 * (1 - 0.5 * sum_abs_diff)
gen str120 note = "Proxy uses bilateral KAZ-CHN sector shares; not canonical TCI with China global import shares."

keep year bilateral_complementarity_proxy note
duplicates drop year, force
sort year

export delimited using "tables/trade_indices_from_existing_tci_proxy.csv", replace
save "tables/trade_indices_from_existing_tci_proxy.dta", replace
di as result "Created: tables/trade_indices_from_existing_tci_proxy.csv"

di _newline as result "Done."
log close
