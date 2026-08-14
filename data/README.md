# Data

The MATLAB source expects a local workbook named:

`Dataset_risk_measure.xlsx`

with worksheet `Sheet1` and columns:

`Date, NVDA, TSLA, JPM, XOM, KO`

The workbook supplied with the university assignment contains third-party daily market-price data and is **not redistributed** in this public repository.

## Exact sample produced by the submitted code

The workbook's last date is `2025-11-26`.

The script uses:

```matlab
data_inizio = data_finale - years(4);
Dataset = Dataset(Dataset.Date >= data_inizio,:);
```

In MATLAB, `years(4)` is a fixed-length duration of `4 × 365.2425` days. The threshold is therefore `2021-11-26 00:43:12`, so the first retained daily observation is `2021-11-29`.

That produces:

- 1,004 retained price rows;
- 1,003 log-return observations;
- 204 rolling windows when `window = 800`.

To reproduce the submitted results, keep the original workbook structure and filename unchanged.
