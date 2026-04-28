# YEAR RANGE UPDATE SUMMARY

## Changes Made: 2014-2024 → 2015-2024

**Date:** April 6, 2026  
**Analysis Period:** Changed from 11 years (2014-2024) to 10 years (2015-2024)

---

## WHY 2015?

The analysis now starts from **2015** because:

1. 2015 marks the beginning of the EAEU (Eurasian Economic Union) era
2. More consistent policy environment
3. Better data availability from 2015 onwards
4. Aligns with major trade policy shifts

---

## FILES MODIFIED

All 9 production .do files have been updated:

### 1. RUN_ALL_ANALYSIS.do

- ✅ Changed `local start_year` from 2014 to 2015
- ✅ Updated analysis window message: "n=10 years"
- ✅ Updated summary: "n=10 refers to 10 years of annual data (2015-2024)"
- ✅ Fixed hard-coded result descriptions

### 2. sinokaz_sectoral_analysis.do

- ✅ Updated header: "Window: 2015-2024 only"
- ✅ Changed `inrange(year, 2014, 2024)` → `inrange(year, 2015, 2024)`
- ✅ Updated `gen t = year - 2014` → `gen t = year - 2015`
- ✅ Updated forvalues loops: `2014/2024` → `2015/2024`
- ✅ Updated xlabel ranges: `2014(2)2024` → `2015(2)2024`
- ✅ Updated display messages with year references

### 3. sinokaz_analysis.do

- ✅ Updated `local start_year` from 2014 to 2015
- ✅ Changed year filters to 2015
- ✅ Updated trend variable label: "Year trend, 2015=0"
- ✅ Updated period descriptions

### 4. sinokaz_summary_table_1_fixed.do

- ✅ Updated header: "Window: 2015-2024 only"
- ✅ Changed `local start_year` from 2014 to 2015
- ✅ Updated all year references in scalars: `_2014` → `_2015`
- ✅ Updated `year == 2014` → `year == 2015`
- ✅ Updated display messages: "bn (2015)" instead of "bn (2014)"
- ✅ Updated table expectations to 10 years

### 5. sinokaz_theory_visualizations.do

- ✅ Updated `local start_year` from 2014 to 2015
- ✅ Updated pre-2023 period description: "2015-2022" instead of "2014-2022"
- ✅ Changed xlabel ranges

### 6. sinokaz_summary_quick.do

- ✅ Updated header: "Analysis window: 2015-2024"
- ✅ Changed year filters
- ✅ Updated year offset calculation: `year - 2015`
- ✅ Updated table descriptions

### 7. extract_weo_gdp_source.do

- ✅ Updated column range: v101-v110 (2015-2024) instead of v100-v110
- ✅ Removed duplicate y2015 mapping
- ✅ Updated validation: `inrange(year, 2015, 2024)`
- ✅ Updated comment to reflect correct column mapping

### 8. extract_worldbank_trade.do

- ✅ Changed year filter: `inrange(Year, 2015, 2024)`
- ✅ Updated validation assertion

### 9. VALIDATION_CHECKS.do

- ✅ Already had correct year range (2015-2024)
- ✅ Validation logic unchanged

---

## WHAT WAS CHANGED

### Critical Updates:

1. **Year Range Variables:** All `start_year` locals now set to 2015
2. **Data Filters:** All `inrange()` calls updated to (2015, 2024)
3. **Time Trend Calculations:** `gen t = year - 2015` (not 2014)
4. **Axis Labels:** All graph xlabels start from 2015
5. **Year References:** All year equality checks (`year == 2015`)
6. **Display Messages:** All user-facing text shows 2015
7. **Column Mappings:** WEO extraction uses v101-v110

### Row Counts Updated:

- **Table 9:** Now expects 10 rows (10 years of data: 2015-2024)
- **Table 10:** Still 10 rows (10 empirical claims, unchanged)
- **Table 11:** Still 15+ rows (statistical tests, unchanged)

---

## VERIFICATION

To verify the updates work correctly:

```stata
* Check that no 2014 references remain in active code
grep "2014" *.do

* Should only show references in:
* - Comments explaining the change
* - Deprecated folder files
* - Variable names that happen to contain 2014

* Run the complete pipeline
do RUN_ALL_ANALYSIS.do

* Check outputs
describe using sinokaz_summary_master.dta
tab year  /* Should show 2015-2024 */
```

---

## EXPECTED OUTPUTS

With the 2015-2024 window:

### Data Files:

- `sinokaz_summary_master.dta` - 10 observations (one per year: 2015-2024)
- `kaz_china_trade_panel.dta` - 10 observations
- `sectoral_trade_clean.dta` - All years 2015-2024

### Tables:

- `table9_trade_evolution.csv` - 10 data rows + 1 header
- `table10_empirical_summary.csv` - 10 data rows + 1 header
- `table11_statistical_significance.csv` - 15+ rows of statistical tests

### Figures:

- All figures now show 2015-2024 on x-axis
- Time series graphs start from 2015
- Chow tests and break analyses reference 2015+ data

---

## IMPORTANT NOTES

### COVID Analysis:

- COVID year is still 2020
- COVID impact calculated relative to 2019 (which is now in the dataset)
- This provides 5 years pre-COVID (2015-2019) and 4 years post-COVID (2020-2024)

### Structural Breaks:

- Chow tests at 2020 now compare 2015-2019 vs 2020-2024
- More balanced pre/post periods than with 2014 start

### Sample Size:

- **n=10 years** of annual data
- Statistical tests have appropriate degrees of freedom
- Significance thresholds remain the same (\* p<0.05, ** p<0.01, \*** p<0.001)

---

## TROUBLESHOOTING

### If you see "year 2014 not found" errors:

The source data files (WITS and WEO) still contain 2014 data, but it's now being filtered out. This is expected behavior.

### If row counts are off:

- Table 9 should have 10 rows (not 11)
- Check that all scripts ran without errors
- Delete .dta files and re-run from scratch if needed

### If figures still show 2014:

- Delete existing PNG/PDF files in figures/ folder
- Re-run the analysis
- Graphs are generated fresh each time

---

## BACKWARD COMPATIBILITY

If you need to run the original 2014-2024 analysis:

1. Change `local start_year 2015` back to `local start_year 2014` in:
   - RUN_ALL_ANALYSIS.do
   - sinokaz_analysis.do
   - sinokaz_summary_table_1_fixed.do
   - sinokaz_theory_visualizations.do

2. Update WEO extraction to use v100-v110 (includes 2014)

3. Search/replace 2015 back to 2014 in year filters

However, **2015-2024 is now the recommended and default analysis window**.

---

## SUMMARY

✅ All 9 production .do files updated  
✅ 11 deprecated files unchanged (in deprecated/ folder)  
✅ Year range consistently set to 2015-2024 throughout  
✅ No hard-coded 2014 references remain in active code  
✅ Documentation updated to reflect new window  
✅ Ready for production use

**Status: COMPLETE** ✅

---

_Update completed: April 6, 2026_
