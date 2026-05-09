# Project Structure (Simplified)

## Start Here
- `manuscript/main.tex`: Current paper manuscript.
- `tables/paper_formulas_from_raw_wits_annual.csv`: Final annual formula results (TII, HHI, TCI, ToT).
- `tables/paper_formulas_from_raw_wits_rca_sector_year.csv`: RCA results by year-sector.

## Data
- `data/raw/DataJobID-3082405_3082405_tii.csv`: China import-from-world dataset used for TII/TCI.
- `data/raw/DataJobID-3082411_3082411_world.csv`: World import totals dataset used for TII denominator.
- `data/Kazakhstan API Data/API_KAZ_DS2_en_csv_v2_18751.csv`: WDI indicators used for ToT (unit value indices).
- `sinokaz_summary_master.dta`: Annual Kazakhstan-China summary inputs.
- `sectoral_trade_clean.dta`: Sector-level trade panel used for HHI/TCI/RCA.

## Scripts
- `scripts/CALCULATE_PAPER_FORMULAS_FROM_RAW_WITS.do`: Main script to compute all formula outputs.
- `scripts/CALCULATE_PAPER_FORMULAS.do`: Alternate formula pipeline.
- `scripts/CALCULATE_TII_TCI_WITH_CHINA_WORLD_DATA.do`: Canonical TII/TCI helper script.

## Outputs
- `tables/`: CSV/DTA outputs used in the manuscript.
- `figures/`: Figures used in the manuscript.

## Notes
- Logs (`*.log`), aux files (`*.aux`), and temporary output files are intentionally excluded/cleaned.
- If needed, regenerate outputs by rerunning the Stata do-files in `scripts/`.
