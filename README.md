# Replication Archive: Birds of a Bounded Feather

This repository contains the replication package for our paper: **"Birds of a Bounded Feather: Religious Homophily, Opportunity Structure, and Friendship Formation in a Highly Homogeneous Cohort"** (NetHealth Religion Project).

The analysis runs as a sequence of R scripts in `Code/`. Each script writes its outputs to `Data/`, `Tabs/`, or `Plots/`, and `paper.tex` `\include`s or `\includegraphics`s those files. Scripts assume the project root as the working directory (paths use `here()`).

---

## 1. Directory Structure

```
├── README.md                # This replication guide
├── AGENTS.md                # Project memory: sample flow, specification, decisions, open items
├── paper.tex                # LaTeX manuscript
├── paper.pdf                # Compiled manuscript
├── references.bib           # Bibliography
├── Data/                    # Survey inputs (BasicSurvey.csv, NetWorkSurvey.csv) and script outputs (*.RDS, *.csv)
├── Plots/                   # Figures included in paper.tex (fig-*.png)
├── Tabs/                    # LaTeX tables included in paper.tex (tbl-*.tex)
├── Code/                    # Analysis scripts (see Section 4)
└── Archive/                 # Superseded or orphaned material, kept for reference only
```

`Archive/` holds material that does not produce the current manuscript: an earlier Quarto pipeline (`analysis.qmd`, `analysis.html`), superseded regression and figure outputs, and standalone HTML tables from `Code/06_save_tables_html.R`, which was removed from the pipeline. Nothing in `Archive/` is read by `paper.tex` or by any script in `Code/`.

---

## 2. Software Requirements

- **R (4.1.0 or higher).** The results were produced with R 4.5.3.
- **A LaTeX distribution** (TeX Live, MacTeX, or TinyTeX) for compiling the manuscript.

### Required R packages

```R
install.packages(c(
  "here", "readr", "dplyr", "tidyr", "tibble",
  "sandwich", "lmtest", "marginaleffects", "ggplot2"
))
```

---

## 3. Data

`Data/` must contain the two NetHealth survey files, under these names:

- `BasicSurvey.csv`: ego-level survey, key `egoid`. Used variables include `yourelig_1` (religion), `gender_1`, `race_1`, and `discussrelig_2` (religious salience, Wave 2).
- `NetWorkSurvey.csv`: ego-network nominations (`egoid` → `alterid`, by `wave`). Used variables include `altrelucat`, `family`, `altrelig`, `altsex`, the alter race indicators, `roommates`, `samedorm`, and `close`.

The variable schema and sample construction are documented in `AGENTS.md`, Section 2.

These data come from the NetHealth project. Researchers are asked to register their use through the [NetHealth Data Portal](https://sites.nd.edu/nethealth/data-2/).

---

## 4. Running the Pipeline

Run the scripts in this order. Each script can be run on its own once its inputs exist.

| Step | Script | Writes | Paper element |
|---|---|---|---|
| 1 | `Code/00_sample_descriptives.R` | `Data/sample_descriptives.csv` | Methods Section 2 values. Checks all 36 quoted values against the data. |
| 2 | `Code/01_longitudinal_descriptives.R` | `Data/longitudinal_yules_q.csv`, `Plots/fig-yules-q.png` | Figure 2 (Yule's Q, Waves 1–8) |
| 3 | `Code/04_plot_opportunity_stability.R` | `Plots/fig-opportunity-stability.png` | Figure 1 |
| 4 | `Code/02b_build_pooled_table.R` | `Tabs/tbl-pooled-interaction-reg.tex`, `Tabs/tbl-pool-baseline-sensitivity.tex` | Table 1 (cohort baseline) and its alter-pool sensitivity table |
| 5 | `Code/05_plot_active_coefficients.R` | `Plots/fig-active-coefs.png`, `fig-active-coefs-pool.png`, `fig-active-coefs-observed.png`, `Data/active_coefs_me.csv` | Figure 3 (the first two are in the paper; the third is not) |
| 6 | `Code/07_yules_q_permutation_test.R` | `Data/yules_q_permutation_null.csv`, `Tabs/tbl-yules-q-null.tex` | Table 2 (cohort and pool nulls) |
| 7 | `Code/08_baseline_sensitivity.R` | `Tabs/tbl-baseline-sensitivity.tex`, `Data/baseline_sensitivity.RDS` | Baseline sensitivity table |
| 8 | `Code/09_inference_robustness.R` | `Tabs/tbl-inference-robustness.tex`, `Data/inference_robustness.RDS` | Two-way clustering, pairs bootstrap, leave-one-ego-out. About 23 minutes. |
| 9 | `Code/11_sample_missingness.R` | `Tabs/tbl-missingness.tex`, `Data/missingness_summary.RDS` | Missingness and sample composition table |
| 10 | `Code/10_bootstrap_sensitivity.R` | `Tabs/tbl-bootstrap-sensitivity.tex` (cohort), `Tabs/tbl-bootstrap-sensitivity-pool.tex`, `Data/bootstrap_sensitivity_results.RDS` | Table 3 (bootstrap and Wald tests, both baselines) |

`Code/02_dyadic_models_pooled.R` and `Code/02_dyadic_models_interaction.R` are the model specifications. Step 4 (`02b`) sources both. Steps 7–10 (`08`, `09`, `11`, `10`) source the pooled script. Each source call uses its own environment, so nothing is assigned to the global workspace. Running the two model scripts directly rewrites their RDS outputs, which is harmless but unnecessary.

Step 8 and step 10 are the slow steps. Step 8 (about 23 minutes) refits the model once per ego for leave-one-ego-out and 1,000 times for the bootstrap. Step 10 runs 2,000 bootstrap replicates for each baseline.

### Compiling the manuscript

```bash
latexmk -pdf paper.tex
```

Run it twice if cross-references look stale. A clean final pass should show no undefined references or citations. The output is `paper.pdf`.

---

## 5. Methodological Notes

- **Opportunity baseline (co-primary).** Dyadic tie-level logistic regressions include an opportunity offset, $\log(p_g/(1-p_g))$, with the coefficient fixed at 1. The baseline share $p_g$ can be defined in two ways, and the paper reports both:
  - *Ego-cohort baseline* (primary in the tables): the Wave 1 religious composition of all 718 egos with religion known. It is constant over time.
  - *Alter-pool baseline* (sensitivity): the wave-specific composition of nominated student alters. This pool is built from the ties being modeled, so it is partly determined by the outcome.

  The two baselines give different answers for the Catholic/non-Catholic contrast. Conclusions are stated only where both agree, or explicitly as conditional on the baseline (see `AGENTS.md`, Section 5).
- **Offset precision.** The offset corrects bias in point estimates when the baseline is correct. It does not equalize precision across groups of very different sizes. The permutation test, bootstrap, two-way clustering, and leave-one-ego-out checks address precision.
- **Yule's Q.** Observed Q is computed from the tie table and does not depend on the baseline. Only its permutation null does. Q is used descriptively, to establish that each group exceeds its own chance mixing. Its magnitude is not comparable across groups of different sizes, so groups are not ranked by Q.
- **Excess rates.** The bootstrap excess (Table 3, Panels A–B) depends on each group's baseline share by construction. Group comparisons use the log-odds contrasts (Table 3, Panels C–D).
- **Activity and popularity controls.** Ego log out-degree and alter log(1 + in-degree excluding the focal nomination) are included in Model 3. The focal tie is removed from alter popularity so the control does not mechanically contain the outcome.
- **Marginal effects.** Figure 3 shows wave-specific average marginal effects on the probability scale, computed with `marginaleffects`, with the opportunity offset fixed at 0. This is a counterfactual in which every group has a 50% share. Its magnitudes are not comparable to Table 1 log-odds.
- **No formal mediation analysis.** An earlier draft cited mediation estimates for structural foci. Those numbers could not be traced to a script and were removed. A mediation script is archived in `Archive/orphaned_scripts/` and is not cited, because the Wave 3 total effect it would decompose is statistically null.
- **Removed analyses.** The Wave 3 cross-sectional check and the wave-by-wave decomposition of the No Religion coefficient were removed from the manuscript on 2026-09-24. Their scripts and outputs are archived.

See `AGENTS.md` for the full methodological history, the sample flow, the decisions log, and open items.

---

## 6. Contact and Data Use

- For questions about the code or the analytical pipeline, contact the corresponding author.
- The NetHealth datasets are publicly available. Researchers are asked to register their use through the [NetHealth Project Form](https://sites.nd.edu/nethealth/data-2/).
