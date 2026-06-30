# Replication Archive: Birds of a Bounded Feather

This repository contains the complete replication package for our paper: **"Birds of a Bounded Feather: Religious Homophily, Opportunity Structure, and Friendship Formation in a Highly Homogeneous Cohort"** (NetHealth Religion Project).

This project complies with high open science and replication standards. The entire analytical pipeline—from raw data downloading to data wrangling, model fitting, plot generation, and manuscript compilation—is completely automated.

---

## 1. Directory Structure

The project directory is structured as follows:

```
├── README.md               # This replication guide
├── AGENTS.md               # Memory log detailing analytical and mathematical architecture
├── analysis.qmd            # Primary reproducible pipeline (Quarto document)
├── paper.tex               # LaTeX manuscript file
├── references.bib          # Bibliography file
├── Data/                   # Data directory (empty initially, populated automatically)
├── Plots/                  # Generated high-resolution figures (.png)
├── Tabs/                   # Generated LaTeX tables
└── Code/                   # Modular R scripts (legacy/alternative execution methods)
```

---

## 2. Software Requirements

To successfully replicate the study, ensure the following software is installed on your system:

- **R (version 4.1.0 or higher)**
- **Quarto** (for compiling `analysis.qmd`)
- **A LaTeX distribution** (e.g., TeX Live, MacTeX, or TinyTeX) for compiling the manuscript.

### Required R Packages
You can install all necessary dependencies by running the following command in your R console:

```R
install.packages(c("here", "readr", "dplyr", "tidyr", "ggplot2", "sandwich", "lmtest", "knitr", "kableExtra", "network", "ergm"))
```

---

## 3. One-Click Replication Pipeline

We provide a streamlined Quarto pipeline that executes the data download, cleaning, analysis, and visualization in a single step.

### Step 1: Render the Analysis Pipeline
Execute the Quarto document from your terminal (or render it directly from Positron/RStudio):

```bash
quarto render analysis.qmd
```

**What this does:**
1. **Automated Data Download:** Automatically fetches the public, anonymized raw data (`BasicSurvey.csv` and `NetWorkSurvey.csv`) from the NetHealth project's Google Drive repository directly into the `Data/` folder.
2. **Data Imputation & Preparation:** Cleans the longitudinal data and merges alter religious demographics, imputing missing information longitudinally.
3. **Statistical Modeling:** Fits dyadic logistic regressions with opportunity offsets, pooled temporal models, and interaction models.
4. **Artifact Generation:** Saves output figures (`fig-yules-q.png`, `fig-active-coefs.png`, etc.) directly into `Plots/` and raw LaTeX tables into `Tabs/`.

### Step 2: Compile the Manuscript
Once the Quarto script has generated all tables and figures, compile the LaTeX manuscript:

```bash
pdflatex paper.tex
bibtex paper
pdflatex paper.tex
pdflatex paper.tex
```

*Outputs:* This generates the final `paper.pdf` containing the fully reproducible results, figures, and tables exactly as submitted.

---

## 4. Alternative: Modular Script Execution

For users who prefer to run the analysis step-by-step interactively without Quarto, the `Code/` directory contains modular R scripts matching the steps in the paper. 

**Note:** If running the standalone scripts, you must first manually download the raw CSV files (`BasicSurvey.csv` and `NetWorkSurvey.csv`) from the [NetHealth Data Portal](https://sites.nd.edu/nethealth/data-2/) and place them in the `Data/` directory.

Scripts should be executed in the following order:
1. `Code/01_longitudinal_descriptives.R`
2. `Code/02_dyadic_models.R`
3. `Code/02_dyadic_models_pooled.R`
4. `Code/02_dyadic_models_interaction.R`
5. `Code/04_plot_opportunity_stability.R`
6. `Code/05_plot_active_coefficients.R`

---

## 5. Methodological Notes

- **The Group-Size Artifact:** We employ group-level, baseline-adjusted Yule's Q, which isolates active homophily preferences independent of numeric group size imbalances.
- **Opportunity Offset:** Our dyadic tie-level logistic regressions utilize a strictly constrained mathematical opportunity offset term ($\log(p / (1-p))$). This analytically simulates an "equal opportunity" scenario, effectively correcting for structural probability differences.
- **Marginal Effects:** Interaction parameters involving nonlinear functions are carefully plotted utilizing probability-scale marginal effects. 

---

## 6. Contact & Data Use Inquiries

- For questions regarding code modification or the analytical pipeline, please contact the corresponding author.
- The NetHealth datasets used in this repository are freely available to the public. However, researchers are requested to register their usage via the [NetHealth Project Form](https://sites.nd.edu/nethealth/data-2/).
