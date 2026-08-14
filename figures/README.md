# Figures

This directory contains the **nine raster charts embedded in the submitted group report**, exported to PNG while preserving their original pixel content. They are not reconstructed, smoothed or restyled.

## Archived report figures

1. `01_nvda_log_returns.png` — NVDA daily log-return series
2. `02_nvda_histogram.png` — NVDA return histogram
3. `03_nvda_qqplot.png` — NVDA normal QQ-plot
4. `04_case1_var_rolling.png` — Case 1, rolling capital allocation with K = VaR
5. `05_case1_tce_rolling.png` — Case 1, rolling capital allocation with K = TCE
6. `06_case2_var_rolling.png` — Case 2, rolling capital allocation with K = VaR
7. `07_case2_tce_rolling.png` — Case 2, rolling capital allocation with K = TCE
8. `08_case3_var_rolling.png` — Case 3, rolling capital allocation with K = VaR
9. `09_case3_tce_rolling.png` — Case 3, rolling capital allocation with K = TCE

## Why nine images rather than twenty-one

The MATLAB source creates three diagnostic figures for each of five equities (15 figures) and six rolling allocation figures.

The submitted PDF report embeds only the three NVDA diagnostics as representative single-asset plots, plus all six rolling figures. The other twelve diagnostics are therefore not recoverable as exact submitted image files.

The repository deliberately avoids creating visually different replacement plots. Running the source in `../matlab/` with the original workbook generates the full diagnostic set.
