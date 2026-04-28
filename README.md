# Sino-Kazakh Trade Analysis (2015-2024)

## Overview

This project contains a complete analysis of Sino-Kazakh bilateral trade patterns from 2015 to 2024. The analysis reveals a critical structural shift in 2023 when Kazakhstan entered its first trade deficit year after 8 consecutive surplus years.

**Status:** ✅ Analysis Complete & Validated | 📊 Ready for Publication

---

## Quick Start

### For Overleaf/LaTeX

Copy the contents of `tables/Sino_Kazakh_Trade_Tables.tex` and paste into your Overleaf project. This provides all tables, analysis, and conclusions in publication-ready format.

### To Re-run Analysis

```stata
cd "<project-directory>"
do RUN_ALL_ANALYSIS.do
```

---

## 📁 Project Structure

```
KazakhIrPapaper/
│
├── 📊 MAIN SCRIPT
│   └── RUN_ALL_ANALYSIS.do              ← Run this first
│
├── 🔬 ANALYSIS SCRIPTS
│   ├── sinokaz_sectoral_analysis.do     (Step 1)
│   └── sinokaz_theory_visualizations.do (Step 4)
│
├── 📁 DATA FILES
│   ├── sectoral_composition_chn.dta
│   ├── sectoral_trade_clean.dta
│   └── sinokaz_summary_master.dta
│
├── 📊 OUTPUT
│   ├── figures/                         (14 charts in PNG/PDF)
│   ├── tables/                          (20 CSV tables)
│   │   └── Sino_Kazakh_Trade_Tables.tex ← USE THIS FOR PAPER
│   └── logs/                            (execution logs)
│
└── 📖 DOCUMENTATION
    └── README.md                        (this file)
```

## Key Findings

### Structural Inflection Point (2023)

- First trade deficit year (-$4.0B) after 8 consecutive surpluses
- Continues into 2024 (-$0.5B) indicating permanent shift

### Trade Flow Changes

- **Exports:** +120% increase (Pre-2023 to Post-2023)
- **Imports:** +280% increase (asymmetric growth)
- **Balance:** From +$5.1B surplus to -$2.3B deficit ($7.4B swing)

### Extreme Sectoral Shifts

- Machinery & Electrical exports: +2,089%
- Vehicle imports: +932%
- Textile imports: +424%

### Supply Chain Vulnerability

China's market share in Kazakhstan's imports:

- Textiles: 89.8%
- Vehicles: 84.5%
- Machinery & Electrical: 77.3%

## How to Run

### Option 1: Use Publication-Ready LaTeX Document (Recommended)

The file `tables/Sino_Kazakh_Trade_Tables.tex` contains:

- Complete analysis tables
- Full interpretation and conclusions
- Ready to paste into Overleaf

### Option 2: Re-run Analysis in Stata

```stata
cd "<project-directory>"
do RUN_ALL_ANALYSIS.do
```

This generates:

1. All figures (14 total)
2. All tables (20 total)
3. Comprehensive logs
4. All intermediate data files

## Output Files

### Data Files (.dta)

- `sectoral_trade_clean.dta` - Product-level bilateral trade data
- `sectoral_composition_chn.dta` - Sector-level trade with China
- `sinokaz_summary_master.dta` - Summary statistics

### Main LaTeX Document

- **`tables/Sino_Kazakh_Trade_Tables.tex`** ← USE THIS FOR PAPER
  - Annual bilateral trade flows
  - Sectoral composition analysis
  - Import penetration metrics
  - Period comparison summary
  - Full analysis and key findings

### Figures (figures/) - 14 Total

- **fig1-4:** Sectoral analysis visualizations
- **fig7-10:** Theory framework visualizations
- **fig12-14:** Main bilateral analysis figures
- All available in PNG and PDF format

### Tables (tables/) - 20 Total

Key tables:

- `table8_annual_bilateral_trade.csv` - Annual trade flows 2015-2024
- `table10_empirical_summary_IMPROVED.csv` - Regression results
- `table11_statistical_significance_REVISED.csv` - Statistical tests
- Additional tables 1-7 with sectoral and analytical breakdowns

## Statistical Methods

RUN_ALL_ANALYSIS.do applies advanced statistical techniques:

1. **Newey-West HAC standard errors** (lag=1) for time series regressions
2. **95% confidence intervals** for all estimates
3. **ADF unit root tests** for stationarity checking
4. **Bootstrap standard errors** (200 reps) for robustness
5. **Diagnostic tests:** VIF, RESET, leverage analysis

## Data Quality

✅ **Complete 2015-2024 coverage** (10 years)
✅ **11 major sectors** included
✅ **100% data integrity** (no missing values)
✅ **All values verified** against source data
✅ **Ready for publication**

## Troubleshooting

### "Missing source file" error

Ensure both required data files are in the project directory:

- Download WITS data from: https://wits.worldbank.org/
- Download WEO data from: https://www.imf.org/en/Publications/WEO

### "File not found" errors

- Make sure you're running Stata from the project root directory
- Check that all paths use forward slashes (/) or escaped backslashes (\\)

### Memory issues

If Stata runs out of memory:

```stata
set mem 500m    // Allocate 500MB
set matsize 500 // Increase matrix size
```

### Log files

All scripts create log files in the `logs/` directory. Check these for detailed error messages:

- `logs/sinokaz_analysis.log`
- `logs/sinokaz_summary.log`
- `logs/sinokaz_sectoral_analysis.log`
- `logs/sinokaz_theory_viz.log`

## Technical Details

### Software Requirements

- Stata 17.0 or later
- Sufficient disk space (~500MB for outputs)
- Recommended: 4GB+ RAM

### Data Processing

- All trade values converted to billions USD for readability
- Year range restricted to 2014-2024 for consistency
- Log-differences used for growth calculations where appropriate
- Chow tests used for structural break detection

### Code Quality

- No hard-coded data values (all calculated from source)
- Comprehensive error handling with `capture` commands
- Input validation for all required files
- Consistent variable naming conventions
- Detailed logging throughout

## Citation

If using this analysis in academic work, please cite:

```
Kazakhstan-China Bilateral Trade Analysis (2014-2024)
Data sources: World Bank WITS, IMF World Economic Outlook
Methodology: See DO_FILE_REVIEW.md for detailed documentation
```

## Updates and Maintenance

### Recent Changes (April 2026)

- ✅ Fixed hard-coded data values in sinokaz_summary_quick.do
- ✅ Added source file validation to all extraction scripts
- ✅ Updated RUN_ALL_ANALYSIS.do with pre-flight checks
- ✅ Removed deprecated files to deprecated/ folder
- ✅ Improved portability with `c(pwd)` instead of hard-coded paths

### Files Deprecated

The following files have been moved to `deprecated/` folder:

- sinokaz_summary_table_1.do (superseded by \_fixed version)
- create_worldbank_trade.do (incorrect approach)
- extract_weo_gdp.do (duplicate of \_source version)
- Various test/check scripts

## Support

For questions or issues:

1. Check the detailed code review in `DO_FILE_REVIEW.md`
2. Review log files in `logs/` directory
3. Run `VALIDATION_CHECKS.do` to verify outputs

## License

This analysis code is provided for academic and research purposes. Data sources (WITS, IMF WEO) have their own usage terms.

---

_Last updated: April 6, 2026_
_Stata version: 17.0_
