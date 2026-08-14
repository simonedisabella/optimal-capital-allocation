# Optimal Capital Allocation — VaR, TCE & Rolling Tail-Risk Attribution

University group coursework for **Risk Measures** at the University of Milano-Bicocca, implemented in MATLAB.

The project applies the quadratic optimal-capital-allocation framework of **Dhaene, Tsanakas, Valdez & Vanduffel (2012)** to five equities — **NVDA, TSLA, JPM, XOM and KO** — using empirical 5% VaR and Tail Conditional Expectation (TCE), an equal-weight portfolio, three scenario-weighting schemes and an 800-observation rolling analysis.

The original coursework was completed by **Ernesto Michele Ruschena, Alberto Preti, Simone D'Isabella and Gianluca De Pieri**.

## Assignment scope

The course assignment required a concise review of Dhaene et al. (2012), a focus on the **quadratic deviation criterion**, four years of daily prices for five equities, log-return diagnostics and descriptive statistics, 5% VaR/CVaR-TCE, optimal capital allocation, and an 800-observation rolling analysis.

The MATLAB implementation translates the paper's loss convention into the course convention by working with left-tail returns and positive loss magnitudes:

`VaR_5 = -q_0.05(r)` and `TCE_5 = -E[r | r <= q_0.05(r)]`.

## Quadratic allocation rule

For the quadratic criterion, the paper's closed-form solution is

`K_i = E[zeta_i X_i] + v_i (K - sum_j E[zeta_j X_j])`.

In the empirical implementation:

- `v_i = 1/5`;
- the loss contribution is represented as `X_i = -v_i r_i`;
- aggregate capital `K` is set in turn to the equal-weight portfolio's **VaR** and **TCE**.

Three scenario-weighting cases are compared:

1. **Case 1 — benchmark:** `zeta_i = 1`.
2. **Case 2 — aggregate-portfolio driven:** observations are reweighted when the equal-weight portfolio is in its 5% left tail.
3. **Case 3 — business-unit driven:** each asset is reweighted when its own loss contribution is in its 5% tail.

The source checks the full-allocation condition numerically in both the static and rolling sections.

## Exact data window and rolling design

The supplied workbook ends on **26 Nov 2025**. The MATLAB source uses `data_finale - years(4)`. Since MATLAB `years` represents fixed-length years of 365.2425 days, the resulting cutoff falls just after midnight on 26 Nov 2021; the first retained daily price observation is therefore **29 Nov 2021**.

With the supplied workbook this gives:

- **1,004 price observations**;
- **1,003 daily log-return observations**;
- **204 rolling windows** of length 800.

This confirms that the submitted report's statement of **204 windows** is consistent with the actual source and workbook. A calendar-year filter based on `calyears(4)` would be a different specification.

The rolling stage blends the full-sample and current-window conditional means as

`60% × full-sample estimate + 40% × current-window estimate`.

Because the 60% component uses the full retained sample, the rolling exercise is best interpreted as a **retrospective stability / attribution analysis**, not as a leakage-free out-of-sample backtest.

## Submitted numerical results

For the equal-weight portfolio:

- **VaR 5%:** approximately **2.5651%**
- **TCE 5%:** approximately **3.5179%**

Static VaR capital allocation becomes strongly concentrated in NVDA and TSLA once tail-state weights are introduced:

- **Case 1:** approximately 20% per asset;
- **Case 2:** NVDA **39.73%**, TSLA **49.45%**;
- **Case 3:** NVDA **36.61%**, TSLA **48.23%**.

KO receives a small negative VaR allocation in Cases 2 and 3. This arises mechanically from the submitted closed-form implementation, which does not impose an explicit `K_i >= 0` constraint. The repository reports the submitted result rather than retroactively imposing a different constrained allocation rule.

Complete static outputs are available in:

- [`results/static_metrics_and_allocations.csv`](results/static_metrics_and_allocations.csv)
- [`results/portfolio_risk_summary.csv`](results/portfolio_risk_summary.csv)

## Exact submitted MATLAB output gallery

**Output policy:** no chart below has been redrawn, smoothed or restyled. The nine PNGs preserve the pixels of the raster images embedded in the submitted PDF report.

The MATLAB source creates **three diagnostics for each of the five equities** (15 diagnostic figures) plus **six rolling allocation figures**. The submitted report archives the three NVDA diagnostics as representative examples and all six rolling figures. This repository therefore publishes **all nine graphical outputs recoverable exactly from the submitted report** and does **not fabricate the other twelve diagnostic exports**.

### NVDA diagnostics archived in the submitted report

<table><tr>
<td width="50%" valign="top"><strong>Log-return time series</strong><br><img src="figures/01_nvda_log_returns.png" alt="NVDA log-return time series" width="100%"></td>
<td width="50%" valign="top"><strong>Return histogram</strong><br><img src="figures/02_nvda_histogram.png" alt="NVDA return histogram" width="100%"></td>
</tr></table>

<p align="center"><strong>Normal QQ-plot</strong><br><img src="figures/03_nvda_qqplot.png" alt="NVDA QQ plot" width="72%"></p>

### Case 1 — benchmark

<table><tr>
<td width="50%" valign="top"><strong>Rolling allocation — K = VaR</strong><br><img src="figures/04_case1_var_rolling.png" alt="Case 1 rolling VaR allocation" width="100%"></td>
<td width="50%" valign="top"><strong>Rolling allocation — K = TCE</strong><br><img src="figures/05_case1_tce_rolling.png" alt="Case 1 rolling TCE allocation" width="100%"></td>
</tr></table>

### Case 2 — aggregate-portfolio driven

<table><tr>
<td width="50%" valign="top"><strong>Rolling allocation — K = VaR</strong><br><img src="figures/06_case2_var_rolling.png" alt="Case 2 rolling VaR allocation" width="100%"></td>
<td width="50%" valign="top"><strong>Rolling allocation — K = TCE</strong><br><img src="figures/07_case2_tce_rolling.png" alt="Case 2 rolling TCE allocation" width="100%"></td>
</tr></table>

### Case 3 — business-unit driven

<table><tr>
<td width="50%" valign="top"><strong>Rolling allocation — K = VaR</strong><br><img src="figures/08_case3_var_rolling.png" alt="Case 3 rolling VaR allocation" width="100%"></td>
<td width="50%" valign="top"><strong>Rolling allocation — K = TCE</strong><br><img src="figures/09_case3_tce_rolling.png" alt="Case 3 rolling TCE allocation" width="100%"></td>
</tr></table>

## Repository structure

```text
.
├── matlab/
│   └── codice_risk_measures_VaR_TCE.m
├── data/
│   └── README.md
├── figures/
│   ├── 01_nvda_log_returns.png
│   ├── 02_nvda_histogram.png
│   ├── 03_nvda_qqplot.png
│   ├── 04_case1_var_rolling.png
│   ├── 05_case1_tce_rolling.png
│   ├── 06_case2_var_rolling.png
│   ├── 07_case2_tce_rolling.png
│   ├── 08_case3_var_rolling.png
│   ├── 09_case3_tce_rolling.png
│   └── README.md
├── results/
│   ├── portfolio_risk_summary.csv
│   ├── static_metrics_and_allocations.csv
│   └── README.md
├── .gitignore
└── README.md
```

## Reproducibility and data policy

The source expects `Dataset_risk_measure.xlsx`, worksheet `Sheet1`, with columns `Date, NVDA, TSLA, JPM, XOM, KO`.

The raw workbook is **not redistributed** because the price series are third-party market data. The full group report is also omitted; only the analytical outputs and machine-readable result tables needed to understand and audit the project are included.

## Audit notes

A fresh audit of the supplied **MATLAB source + workbook + submitted report** confirmed that:

- the public `.m` file is byte-for-byte identical to the source in the submitted ZIP;
- the 5% VaR/TCE convention used in the source matches the assignment instruction to translate the paper's notation into the lecture convention;
- the exact four-year filter produces **1,003 returns and 204 rolling windows**;
- the static VaR/TCE and capital-allocation tables reproduce the submitted report to its displayed rounding;
- the three archived NVDA diagnostics and all six rolling images match the raster images embedded in the submitted report;
- no synthetic replacement chart is used.

## Reference

Dhaene, J., Tsanakas, A., Valdez, E. A. & Vanduffel, S. (2012), **Optimal Capital Allocation Principles**, *The Journal of Risk and Insurance*, 79(1), 1–28.

## Authorship

The original coursework was completed by **Ernesto Michele Ruschena, Alberto Preti, Simone D'Isabella and Gianluca De Pieri**. Publication under this GitHub account reflects portfolio curation of a group assignment and does **not** imply sole authorship.

## Scope disclaimer

This repository documents university coursework and historical empirical analysis. It is not investment advice or a production risk-management system.
