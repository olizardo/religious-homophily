# Replication Archive: NetHealth Religious Homophily Project

This repository contains the complete replication package for our paper: **"Birds of a Bounded Feather: Religious Homophily, Opportunity Structure, and Friendship Formation in a Highly Homogeneous Cohort"**. 

The code is structured as a fully reproducible, modular pipeline in R, allowing users to reconstruct all datasets, run the dyadic regression models, fit advanced Exponential Random Graph Models (ERGMs), and regenerate all tabular and visual assets.

---

## 1. Directory Structure

The project directory is structured as follows:

```
├── README.md               # This replication guide
├── AGENTS.md               # Memory log detailing analytical and mathematical architecture
├── Data/                   # Raw and cleaned analytical datasets
│   ├── BasicSurvey(3-6-20).csv          # Ego survey (baseline attributes)
│   ├── NetWorkSurvey(2-28-20).csv       # Longitudinal network survey
│   ├── AlterAlterEdgeList(1-26-20).csv  # Alter-alter edges
│   ├── cleaned_wave3_model_data.RDS     # Archived clean Wave 3 ego data
│   └── pooled_clean_dyads.RDS           # Archived clean 8-wave pooled dyadic dataset
├── Code/                   # Replication scripts
│   ├── prep_data20240603.R              # Master data cleaning and prep pipeline
│   ├── 01_longitudinal_descriptives.R   # Longitudinal Yule's Q trajectories and tables
│   ├── 02_dyadic_models.R               # Wave 3 cross-sectional regressions
│   ├── 02_dyadic_models_pooled.R        # Pooled Waves 3-8 regressions with clustered SEs
│   ├── 02_dyadic_models_interaction.R   # Interactive waves 3-8 regressions (group x wave)
│   ├── 02_dyadic_models_close.R         # Intimate "Especially Close" ties sub-analysis
│   ├── 03_whole_network_ergms.R         # Within-cohort directed ERGM specification (statnet 4.0+)
│   ├── 04_plot_opportunity_stability.R  # Generates the opportunity pool stability plot
│   ├── 05_plot_active_coefficients.R    # Generates the wave-by-wave active coefficients plot
│   ├── 06_save_tables_html.R            # Compiles and saves all tables as styled HTML
│   └── archive/                         # Legacy/obsolete files (archived)
├── Plots/                  # Archived high-resolution figures (.png, 300 DPI)
│   ├── plot_yules_q_trajectory.png       # Figure 1: Longitudinal trajectories of Yule's Q
│   ├── plot_opportunity_pool_stability.png # Figure 2: Alter pool composition stability
│   └── plot_active_homophily_coefficients.png # Figure 3: Active coefficients over time
└── Tabs/                   # Archived publication-ready HTML tables
    ├── Table_A1_Yules_Q.html             # Longitudinal Yule's Q values
    ├── Table_B1_Opportunity_Structure.html # Opportunity base rates & offset values
    ├── Table_C1_Wave3_Regressions.html   # Wave 3 cross-sectional regressions
    ├── Table_C2_Pooled_Regressions.html  # Pooled models (full vs. intimate ties)
    ├── Table_C3_Interaction_Regression.html # Interaction model results (clustered SEs)
    └── Table_C4_ERGM_Results.html        # Table 6: ERGM results for Wave 3 Network
```

---

## 2. Replication Pipeline Execution Order

To replicate the paper's findings in full, execute the R scripts in the following order. All scripts utilize the `here` package to ensure robust relative path resolution from the root folder.

### Step 0: Package Requirements
Ensure that you have the required R packages installed. You can install them by running:
```R
install.packages(c("here", "readr", "dplyr", "tidyr", "ggplot2", "sandwich", "lmtest", "network", "ergm"))
```

### Step 1: Data Preparation
Run the master cleaning and preparation script to generate the archived RDS files:
```bash
Rscript Code/prep_data20240603.R
```
*Outputs:* `Data/cleaned_wave3_model_data.RDS` and `Data/pooled_clean_dyads.RDS`

### Step 2: Longitudinal Trajectories
Generate the baseline-adjusted group-level Yule's Q values:
```bash
Rscript Code/01_longitudinal_descriptives.R
```
*Outputs:* Tracing data `Data/longitudinal_yules_q.csv`, raw markdown and LaTeX tables, and `Plots/plot_yules_q_trajectory.png`.

### Step 3: Dyadic Regression Modeling
Fit the cross-sectional, pooled longitudinal, and closeness-specific models:
```bash
Rscript Code/02_dyadic_models.R
Rscript Code/02_dyadic_models_pooled.R
Rscript Code/02_dyadic_models_interaction.R
Rscript Code/02_dyadic_models_close.R
```
*Outputs:* Models summary console reports, and saved model RDS structures in `Data/`.

### Step 4: Advanced Network Modeling (ERGMs)
To fit whole-network models controlling for reciprocity, popularity, and transitivity on the directed within-cohort network:
```bash
Rscript Code/03_whole_network_ergms.R
```
*Note:* This script uses Markov Chain Monte Carlo (MCMC) simulations. It has been updated to use directed `gwidegree` and `gwodegree` terms to ensure full compatibility with **`statnet 4.0+`**.

### Step 5: Visualizations & Styled Tables
Generate the paper's final figures and export styled, publication-ready tables:
```bash
Rscript Code/04_plot_opportunity_stability.R
Rscript Code/05_plot_active_coefficients.R
Rscript Code/06_save_tables_html.R
```
*Outputs:* High-resolution figures saved to `Plots/` and styled HTML tables saved to `Tabs/`.

---

## 3. Contact & Inquiries
For questions regarding data access, IRB compliance, or code modifications, please contact the corresponding author at **[Your Email Address]**.
