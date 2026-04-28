/*===========================================================================
  COMPATIBILITY WRAPPER
  Keeps existing RUN_ALL_ANALYSIS.do Step 2 call intact.
  ===========================================================================*/

version 17.0
clear all
set more off

cd "`c(pwd)'"

di _newline(2) "==============================================================="
di "  SINOKAZ ANALYSIS (IMPROVED WRAPPER)"
di "==============================================================="
di "Delegating to sinokaz_analysis.do"

do sinokaz_analysis.do

di _newline "Wrapper completed."
