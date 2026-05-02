/*===========================================================================
  COMPATIBILITY WRAPPER
  Keeps existing RUN_ALL_ANALYSIS.do Step 2 call intact.
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

di _newline(2) "==============================================================="
di "  SINOKAZ ANALYSIS (IMPROVED WRAPPER)"
di "==============================================================="
di "Delegating to sinokaz_analysis.do"

do analysis/do/sinokaz_analysis.do

di _newline "Wrapper completed."
