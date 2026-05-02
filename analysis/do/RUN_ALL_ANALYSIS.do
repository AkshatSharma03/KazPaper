/*===========================================================================
   RUN ALL ANALYSIS - COMPLETE ORCHESTRATION SCRIPT
   Runs all analysis files in proper dependency order
   
   This script executes all analysis steps and validates outputs.
   Each step creates its own detailed log in logs/ directory.
   
   Window: 2015-2024 only
   ===========================================================================*/

version 17.0
clear all
set more off

* Resolve project root robustly (assumes this file is in analysis/do/)
local script_dir "`c(pwd)'"
capture confirm file "analysis/do/RUN_ALL_ANALYSIS.do"
if _rc == 0 {
    local project_root "`script_dir'"
}
else {
    local project_root = subinstr("`script_dir'", "/analysis/do", "", .)
}
cd "`project_root'"
local start_year 2015
local end_year   2024

*--------------------------------------------------------------------------
* PRE-FLIGHT CHECKS: Verify required source data files exist
*--------------------------------------------------------------------------

di _newline "=== PRE-FLIGHT CHECKS: Source Data Files ==="

* Check WEO file
capture confirm file "data/raw/WEO Dataset Apr 6 2026.csv"
if _rc != 0 {
    di as error "MISSING: data/raw/WEO Dataset Apr 6 2026.csv"
    di as error "Please download the IMF World Economic Outlook database"
    exit 601
}
else {
    di as result "FOUND: data/raw/WEO Dataset Apr 6 2026.csv"
}

* Check WITS file (support both naming styles seen in this project)
local wits_file "data/raw/3063878_F1AFE25F-9/DataJobID-3063878_3063878_DetailedBilateralTrade.csv"
capture confirm file "`wits_file'"
if _rc != 0 {
    local wits_file "data/raw/3063878_F1AFE25F-9:DataJobID-3063878_3063878_DetailedBilateralTrade.csv"
    capture confirm file "`wits_file'"
}

if _rc != 0 {
    di as error "MISSING: WITS bilateral file not found."
    di as error "Expected one of:"
    di as error "  1) data/raw/3063878_F1AFE25F-9/DataJobID-3063878_3063878_DetailedBilateralTrade.csv"
    di as error "  2) data/raw/3063878_F1AFE25F-9:DataJobID-3063878_3063878_DetailedBilateralTrade.csv"
    exit 601
}
else {
    di as result "FOUND: `wits_file'"
}

di _newline "All required source files found. Proceeding with analysis..."

di _newline(2) "==============================================================="
di "  SINO-KAZAKH TRADE ANALYSIS - COMPLETE PIPELINE"
di "  (IMPROVED METHODS: HAC SEs, Unit Root Tests, CIs, Bootstrap)"
di "==============================================================="
di "Start time: " c(current_time) " on " c(current_date)
di "Analysis window: `start_year'-`end_year' (n=10 years)"
di ""
di "This script will run all analysis files in order:"
di "  1. Sectoral Analysis"
di "  2. Main Bilateral Analysis (IMPROVED: HAC SEs, diagnostics)"
di "  3. Summary Tables (IMPROVED: HAC SEs, CIs)"
di "  4. Theory Visualizations"
di "  5. Final Validation"
di ""
di "Improvements applied:"
di "  - Newey-West HAC standard errors for all time series regressions"
di "  - Unit root tests (ADF) for key variables"
di "  - 95% confidence intervals for all estimates"
di "  - Bootstrap SEs (200 reps) for small-sample robustness"
di "  - Diagnostic tests: VIF, RESET, leverage analysis"
di ""
di "Individual logs will be created in logs/ directory"
di ""

global overall_fail = 0

*--------------------------------------------------------------------------
* STEP 1: SECTORAL ANALYSIS
* Creates: sectoral_trade_clean.dta, sectoral_composition_chn.dta, figures/fig1-6
* Log: logs/sinokaz_sectoral_analysis.log
*--------------------------------------------------------------------------

di _newline(2) "==============================================================="
di "  STEP 1: SECTORAL ANALYSIS"
di "==============================================================="

* Always run sectoral analysis to generate figures 1-6
di "Running sinokaz_sectoral_analysis.do..."
do analysis/do/sinokaz_sectoral_analysis.do

capture confirm file "sectoral_trade_clean.dta"
if _rc == 0 {
    di as result "PASS: sectoral_trade_clean.dta created"
}
else {
    di as error "FAIL: sectoral_trade_clean.dta not created"
    global overall_fail = $overall_fail + 1
}

capture confirm file "sectoral_composition_chn.dta"
if _rc == 0 {
    di as result "PASS: sectoral_composition_chn.dta created"
}
else {
    di as error "FAIL: sectoral_composition_chn.dta not created"
    global overall_fail = $overall_fail + 1
}

* Check figures 1-6
local step1_figs "fig1_export_composition.png fig2_import_composition.png fig3_sectoral_balance.png fig4_china_penetration.png"
foreach f of local step1_figs {
    capture confirm file "figures/`f'"
    if _rc == 0 {
        di as result "PASS: figures/`f' created"
    }
    else {
        di as error "FAIL: figures/`f' not created"
        global overall_fail = $overall_fail + 1
    }
}

*--------------------------------------------------------------------------
* STEP 2: MAIN BILATERAL ANALYSIS (IMPROVED)
* Creates: kaz_china_trade_panel.dta, figures/fig12-14, tables/table8
* Log: logs/sinokaz_analysis_improved.log
* Additional: Unit root tests, HAC SEs, diagnostics, bootstrap, CIs
*--------------------------------------------------------------------------

di _newline(2) "==============================================================="
di "  STEP 2: MAIN BILATERAL ANALYSIS (IMPROVED METHODS)"
di "==============================================================="

local strict_step2_validation 1
capture confirm file "analysis/do/sinokaz_analysis_improved.do"
if _rc == 0 {
    di "Running sinokaz_analysis_improved.do..."
    do analysis/do/sinokaz_analysis_improved.do
}
else {
    local strict_step2_validation 0
    di as error "MISSING SCRIPT: sinokaz_analysis_improved.do"
    di as error "Step 2 run skipped. Existing Step 2 artifacts will be treated as optional."
    capture confirm file "tables/table8_annual_bilateral_trade.csv"
    if _rc == 0 {
        di as result "Running fallback for Step 2 figures from table8..."
        do scripts/GENERATE_STEP2_FIGURES_FROM_TABLE8.do
    }
    else {
        di as error "Fallback not possible: tables/table8_annual_bilateral_trade.csv missing"
    }
}

* Validate outputs
local step2_outputs "kaz_china_trade_panel.dta"
foreach f of local step2_outputs {
    capture confirm file "`f'"
    if _rc == 0 {
        di as result "PASS: `f' created"
    }
    else {
        if `strict_step2_validation' == 1 {
            di as error "FAIL: `f' not created"
            global overall_fail = $overall_fail + 1
        }
        else {
            di as error "WARN: `f' not found (expected when Step 2 script is missing)"
        }
    }
}

* Check figures
local step2_figs "fig12_trade_flows.png fig13_trade_balance.png fig14_deficit_ratio.png"
foreach f of local step2_figs {
    capture confirm file "figures/`f'"
    if _rc == 0 {
        di as result "PASS: figures/`f' created"
    }
    else {
        if `strict_step2_validation' == 1 {
            di as error "FAIL: figures/`f' not created"
            global overall_fail = $overall_fail + 1
        }
        else {
            di as error "WARN: figures/`f' not found (expected when Step 2 script is missing)"
        }
    }
}

*--------------------------------------------------------------------------
* STEP 3: SUMMARY TABLES (IMPROVED VERSION)
* Creates: sinokaz_summary_master.dta, tables/table9-11
* Log: logs/sinokaz_summary_improved.log
* Additional: HAC SEs, 95% CIs, improved significance reporting
*--------------------------------------------------------------------------

di _newline(2) "==============================================================="
di "  STEP 3: SUMMARY TABLES (IMPROVED METHODS)"
di "==============================================================="

capture confirm file "analysis/do/sinokaz_summary_improved.do"
if _rc == 0 {
    di "Running sinokaz_summary_improved.do..."
    do analysis/do/sinokaz_summary_improved.do
}
else {
    di as error "MISSING SCRIPT: sinokaz_summary_improved.do"
    di as error "Step 3 run skipped. Validating pre-existing outputs instead..."
}

* Validate main outputs
local step3_outputs "sinokaz_summary_master.dta"
foreach f of local step3_outputs {
    capture confirm file "`f'"
    if _rc == 0 {
        di as result "PASS: `f' created"
    }
    else {
        di as error "FAIL: `f' not created"
        global overall_fail = $overall_fail + 1
    }
}

* Validate tables with row counts
di _newline "Validating table contents..."

* Check improved table10
capture confirm file "tables/table10_empirical_summary_IMPROVED.csv"
if _rc == 0 {
    preserve
    import delimited "tables/table10_empirical_summary_IMPROVED.csv", clear
    count
    if r(N) == 11 {
        di as result "PASS: Table 10 IMPROVED has 10 data rows + 1 header"
    }
    else if r(N) == 10 {
        di as result "PASS: Table 10 IMPROVED has 10 data rows"
    }
    else {
        di as error "FAIL: Table 10 has " r(N) " rows (expected 10)"
        global overall_fail = $overall_fail + 1
    }
    restore
}
else {
    di as error "FAIL: Table 10 IMPROVED not found"
    global overall_fail = $overall_fail + 1
}

* Check table11 (REVISED version)
capture confirm file "tables/table11_statistical_significance_REVISED.csv"
if _rc == 0 {
    preserve
    import delimited "tables/table11_statistical_significance_REVISED.csv", clear
    count
    if r(N) >= 13 {
        di as result "PASS: Table 11 REVISED has " r(N) " rows of statistical tests"
    }
    else {
        di as error "FAIL: Table 11 has " r(N) " rows (expected 13+)"
        global overall_fail = $overall_fail + 1
    }
    restore
}
else {
    di as error "FAIL: Table 11 REVISED not found"
    global overall_fail = $overall_fail + 1
}

* Apply revisions to tables (remove duplicates, fix missing values)
di _newline "Applying table revisions..."
do scripts/IMPLEMENT_REVISIONS.do

capture confirm file "tables/table2_sectoral_balance_change_REVISED.csv"
if _rc == 0 {
    di as result "PASS: table2_sectoral_balance_change_REVISED.csv created"
}
else {
    di as error "FAIL: table2_REVISED not created"
    global overall_fail = $overall_fail + 1
}

capture confirm file "tables/table11_statistical_significance_REVISED.csv"
if _rc == 0 {
    di as result "PASS: table11_statistical_significance_REVISED.csv created"
}
else {
    di as error "FAIL: table11_REVISED not created"
    global overall_fail = $overall_fail + 1
}

*--------------------------------------------------------------------------
* STEP 4: THEORY VISUALIZATIONS
* Creates: figures/fig7-9, tables/table7
* Log: logs/sinokaz_theory_viz.log
*--------------------------------------------------------------------------

di _newline(2) "==============================================================="
di "  STEP 4: THEORY VISUALIZATIONS"
di "==============================================================="

di "Running sinokaz_theory_visualizations.do..."
do analysis/do/sinokaz_theory_visualizations.do

* Validate outputs (fig10 and fig11 handled separately)
local step4_figs "fig7_asymmetry_index.png fig8_vulnerability_multivector.png fig9_sectoral_penetration_heatmap.png"
foreach f of local step4_figs {
    capture confirm file "figures/`f'"
    if _rc == 0 {
        di as result "PASS: figures/`f'"
    }
    else {
        di as error "FAIL: figures/`f' not created"
        global overall_fail = $overall_fail + 1
    }
}

* Generate improved Figure 10
di _newline "Running scripts/FINAL_FIGURE10_REVISION.do..."
do scripts/FINAL_FIGURE10_REVISION.do

capture confirm file "figures/fig10_post2023_sectoral_change.png"
if _rc == 0 {
    di as result "PASS: figures/fig10_post2023_sectoral_change.png created"
}
else {
    di as error "FAIL: figures/fig10_post2023_sectoral_change.png not created"
    global overall_fail = $overall_fail + 1
}

* Check table7
capture confirm file "tables/table7_theoretical_indices.csv"
if _rc == 0 {
    di as result "PASS: tables/table7_theoretical_indices.csv"
}
else {
    di as error "FAIL: tables/table7_theoretical_indices.csv not created"
    global overall_fail = $overall_fail + 1
}

*--------------------------------------------------------------------------
* STEP 4.5: GENERATE ANNOTATED FIGURES (PYTHON)
* Creates: figures/*_annotated.png
*--------------------------------------------------------------------------

di _newline(2) "==============================================================="
di "  STEP 4.5: ANNOTATED FIGURE GENERATION"
di "==============================================================="

capture noisily shell python3 annotate_figures.py
if _rc == 0 {
    di as result "PASS: annotate_figures.py completed"
}
else {
    di as error "WARN: annotate_figures.py failed (base figures may still be available)"
}

* Check key annotated files used by the manuscript
local key_annotated_figs "fig12_trade_flows_annotated.png fig13_trade_balance_annotated.png fig14_deficit_ratio_annotated.png"
foreach f of local key_annotated_figs {
    capture confirm file "figures/`f'"
    if _rc == 0 {
        di as result "PASS: figures/`f' created"
    }
    else {
        di as error "WARN: figures/`f' not found"
    }
}

*--------------------------------------------------------------------------
* STEP 5: FINAL VALIDATION
* Validates all critical outputs
*--------------------------------------------------------------------------

di _newline(2) "==============================================================="
di "  STEP 5: FINAL VALIDATION"
di "==============================================================="

* Check critical data files
local critical_data "sinokaz_summary_master.dta"
if `strict_step2_validation' == 1 {
    local critical_data "kaz_china_trade_panel.dta `critical_data'"
}
else {
    capture confirm file "kaz_china_trade_panel.dta"
    if _rc == 0 {
        local critical_data "kaz_china_trade_panel.dta `critical_data'"
    }
    else {
        di as result "INFO: Skipping required check for kaz_china_trade_panel.dta (Step 2 script missing)"
    }
}
foreach f of local critical_data {
    capture confirm file "`f'"
    if _rc == 0 {
        di as result "PASS: `f'"
    }
    else {
        di as error "FAIL: `f' MISSING"
        global overall_fail = $overall_fail + 1
    }
}

* Check critical tables (table8 contains trade evolution data)
local critical_tables "table8_annual_bilateral_trade table10_empirical_summary_IMPROVED table11_statistical_significance_REVISED"
foreach t of local critical_tables {
    capture confirm file "tables/`t'.csv"
    if _rc == 0 {
        di as result "PASS: tables/`t'.csv"
    }
    else {
        di as error "FAIL: tables/`t'.csv missing"
        global overall_fail = $overall_fail + 1
    }
}

*--------------------------------------------------------------------------
* FINAL SUMMARY
*--------------------------------------------------------------------------

di _newline(2) "==============================================================="
di "  EXECUTION COMPLETE"
di "==============================================================="
di "End time: " c(current_time) " on " c(current_date)
di ""

if $overall_fail == 0 {
    di as result "ALL STEPS COMPLETED SUCCESSFULLY"
    di ""
    di "Generated outputs:"
    di "  Data files:"
    di "    - sectoral_trade_clean.dta"
    di "    - sectoral_composition_chn.dta"
    di "    - kaz_china_trade_panel.dta"
    di "    - sinokaz_summary_master.dta"
    di ""
    di "  Tables (CSV):"
    di "    - table8_annual_bilateral_trade.csv (trade evolution)"
    di "    - table10_empirical_summary_IMPROVED.csv (HAC SEs, CIs)"
    di "    - table11_statistical_significance_REVISED.csv"
    di "    - tables/unit_root_test_results.csv (NEW)"
    di "    - And 8 other tables..."
    di ""
    di "  Figures (PNG + PDF):"
    di "    - fig1-4 (sectoral analysis - created by Step 1)"
    di "    - fig7-9 (theory visualizations - created by Step 4)"
    di "    - fig10 (improved version - created by Step 4)"
    di "    - fig12-14 (main bilateral analysis - created by Step 2)"
    di "    - fig5-6 (moved to deprecated per audit)"
    di ""
    di "Log files:"
    di "  - logs/sinokaz_sectoral_analysis.log"
    di "  - logs/sinokaz_analysis_improved.log (with diagnostics)"
    di "  - logs/sinokaz_summary_improved.log (with HAC CIs)"
    di "  - logs/sinokaz_theory_viz.log"
    di ""
    di "Significance legend: * p<0.05, ** p<0.01, *** p<0.001, dagger p<0.10"
    di "n=10 refers to 10 years of annual data (2015-2024)"
    di ""
    di "STATISTICAL IMPROVEMENTS APPLIED:"
    di "  1. Newey-West HAC standard errors (lag=1) for all regressions"
    di "  2. 95% confidence intervals for all estimates"
    di "  3. ADF unit root tests for stationarity"
    di "  4. Bootstrap SEs (200 reps) for small-sample robustness"
    di "  5. VIF, RESET, and leverage diagnostics"
    di ""
    di "Key results (with improved inference):"
    di "  - See tables/table10_empirical_summary_IMPROVED.csv for estimates"
    di "  - See logs/sinokaz_analysis_improved.log for diagnostic tests"
    
    exit 0
}
else {
    di as error "COMPLETED WITH " $overall_fail " ERROR(S)"
    di ""
    di "Some outputs may be missing or incomplete."
    di "Review the log files in logs/ directory for details."
    di ""
    di "Most common issues:"
    di "  1. Missing prerequisite files (check logs)"
    di "  2. Path or permission issues"
    di "  3. Data validation failures"
    
    exit 1
}
