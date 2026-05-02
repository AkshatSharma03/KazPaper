/*===========================================================================
   VERIFY TABLE FIXES - Check that Table 2 and Table 11 are properly revised
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
di "  VERIFYING TABLE FIXES"
di "==============================================================="
di ""

*--------------------------------------------------------------------------
* VERIFY TABLE 2
*--------------------------------------------------------------------------

di "=== CHECKING TABLE 2 ==="

capture confirm file "tables/table2_sectoral_balance_change.csv"
if _rc == 0 {
    import delimited "tables/table2_sectoral_balance_change.csv", clear
    
    di _newline "Original Table 2:"
    di "Sectors with missing 2022 data:"
    count if missing(net_balance2022)
    if r(N) > 0 {
        list sector net_balance2022 if missing(net_balance2022), noobs
    }
    
    di _newline "Checking if Vehicles and Machinery_Electrical have 2022 values..."
    levelsof sector if missing(net_balance2022), local(missing_sectors)
    if strpos("`missing_sectors'", "Vehicles") > 0 | strpos("`missing_sectors'", "Machinery") > 0 {
        di as error "WARNING: Original table missing 2022 values for key sectors"
    }
}

capture confirm file "tables/table2_sectoral_balance_change_REVISED.csv"
if _rc == 0 {
    import delimited "tables/table2_sectoral_balance_change_REVISED.csv", clear
    
    di _newline "Revised Table 2:"
    di "Sectors with missing 2022 data:"
    count if missing(net_balance2022)
    if r(N) == 0 {
        di as result "✓ No missing values - all sectors have 2022 data"
    }
    else {
        di as error "✗ Still has missing values"
        list sector net_balance2022 if missing(net_balance2022), noobs
    }
    
    di _newline "Values for Vehicles and Machinery_Electrical:"
    list sector net_balance2022 net_balance2023 net_balance2024 if strpos(sector, "Vehicles") > 0 | strpos(sector, "Machinery") > 0, noobs
}
else {
    di as error "Revised Table 2 not found - run IMPLEMENT_REVISIONS.do"
}

*--------------------------------------------------------------------------
* VERIFY TABLE 11
*--------------------------------------------------------------------------

di _newline(3) "=== CHECKING TABLE 11 ==="

capture confirm file "tables/table11_statistical_significance.csv"
if _rc == 0 {
    import delimited "tables/table11_statistical_significance.csv", clear
    
    di _newline "Original Table 11:"
    di "Checking for duplicate 'China Import Share Trend':"
    quietly count if strpos(test_name, "China Import Share") > 0
    di "Found " r(N) " rows with 'China Import Share'"
    
    di _newline "Checking 'Export Growth Volatility' completeness:"
    list test_name estimate std_error p_value if strpos(test_name, "Volatility") > 0, noobs
}

capture confirm file "tables/table11_statistical_significance_REVISED.csv"
if _rc == 0 {
    import delimited "tables/table11_statistical_significance_REVISED.csv", clear
    
    di _newline "Revised Table 11:"
    di "Checking for duplicate 'China Import Share Trend':"
    quietly count if strpos(test_name, "China Import Share") > 0
    if r(N) == 1 {
        di as result "✓ Only 1 row - duplicate removed"
    }
    else {
        di as error "✗ Still has " r(N) " rows"
    }
    
    di _newline "Checking 'Export Growth Volatility' completeness:"
    list test_name estimate std_error p_value significance if strpos(test_name, "Volatility") > 0, noobs
    
    di _newline "All statistical tests with p-values:"
    list test_name p_value significance if p_value < 999, noobs
}
else {
    di as error "Revised Table 11 not found - run IMPLEMENT_REVISIONS.do"
}

*--------------------------------------------------------------------------
* SUMMARY
*--------------------------------------------------------------------------

di _newline(3) "==============================================================="
di "  VERIFICATION COMPLETE"
di "==============================================================="
di ""
di "To create revised files, run:"
di "  do IMPLEMENT_REVISIONS.do"
di ""
di "To create improved Figure 10, run:"
di "  do FINAL_FIGURE10_REVISION.do"
di ""
di "See FIGURE10_PUBLICATION_TEXT.md for manuscript wording"
di ""
di "==============================================================="
