# Trade Indices from Existing Project Data

Generated outputs:
- `tables/trade_indices_from_existing_annual.csv`
- `tables/trade_indices_from_existing_rca.csv`
- `tables/trade_indices_from_existing_tci_proxy.csv`

## What is fully identified
- Import Dependence (ID): `M(KZ,CHN)/M(KZ,World)`
- Export Dependence (ED): `X(KZ,CHN)/X(KZ,World)`
- Asymmetry Ratio (AR): `M(KZ,CHN)/X(KZ,CHN)`
- RCA: from existing `table5_rca_analysis.csv`

## What is not fully identified from current files
- Canonical TII requires `M(CHN,World)` and `M(World,World)` by year.
- Canonical TCI requires China global import shares by sector (`m_k^CHN`).

A bilateral sector-structure complementarity proxy is provided instead in
`trade_indices_from_existing_tci_proxy.csv`.
