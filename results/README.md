# Results

This directory contains machine-readable numerical outputs independently checked against the supplied MATLAB source, workbook and submitted report.

- `static_metrics_and_allocations.csv` reproduces the MATLAB table `Metriche_rischio_standalone`: descriptive statistics, 5% VaR/TCE and static capital allocations for Cases 1–3.
- `portfolio_risk_summary.csv` records the equal-weight portfolio VaR/TCE and the exact sample / rolling-window counts.

The calculations use MATLAB's default midpoint quantile convention and the exact fixed-length `years(4)` date-filter behavior used by the submitted source.

The displayed values reproduce the report tables to their printed rounding. The CSVs retain additional decimal precision for auditability.
