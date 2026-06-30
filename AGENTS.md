# Memory File: NetHealth Religion Project Revival
This file serves as a comprehensive memory log to help resume work, understand the analytical pipeline, and maintain historical context for future sessions.

---

## 1. Project Context & Objectives
This project analyzes **religious homophily and friendship formation** among college students using the **NetHealth longitudinal dataset** (from the University of Notre Dame). 

The project has been completely restructured to address and resolve severe methodological flaws identified by journal reviewers:
1.  **Resolved the Group Size Artifact:** Corrected a calculation in the original draft that aggregated individual-level "normalized EI" indices. By shifting to group-level, baseline-adjusted **Yule's Q**, we demonstrated that **all religious groups exhibit robust homophily** in every wave.
2.  **Addressed Confounding Foci & Alternative Homophilies:** Shifted from aggregate, ego-level regressions to **dyadic (tie-level) logistic regressions**. This allows us to control for physical/social foci (same dorm, roommates) and demographic homophilies (gender, race).
3.  **Formal Causal Mediation & Scaling Artifacts:** Conducted formal causal mediation analysis to show that physical foci (dorms/roommates) do *not* mediate secular ("No Religion") homophily, proving that earlier nested model coefficient drops were merely logit rescaling artifacts.
4.  **Longitudinal & Intimacy Interactions via Marginal Effects:** Evaluated interactions of religious affiliation over time (Waves 3-8) and across friendship intensity (1-4 scale) using proper probability-scale marginal effects to avoid non-linear scaling issues. 
5.  **Removed ERGMs:** Discarded whole-network Exponential Random Graph Models (ERGMs), as subsetting to within-cohort ties decimated the minority sample size, making the opportunity-adjusted dyadic regressions mathematically superior.

---

## 2. Dataset Information

### A. Core Data Files (Located in `Data/`)
*   **`BasicSurvey(3-6-20).csv`:** Ego-level longitudinal survey.
    *   *Primary Key:* `egoid`
    *   *Key Variables:*
        *   `yourelig_1`: Baseline religious affiliation (Catholic, No Religion, Other Religion, Protestant).
        *   `gender_1`: Ego gender (Woman, Man).
        *   `race_1`: Ego race (White, African-American, Asian-American, Latino/a, Foreign Student, Other).
        *   `discussrelig_2`: Frequency of discussing religion (used as religious salience proxy).
*   **`NetWorkSurvey(2-28-20).csv`:** Longitudinal ego-network survey detailing nominated ties.
    *   *Keys:* `egoid` (the nominator), `alterid` (the nominated friend).
    *   *Key Variables:*
        *   `wave`: Wave indicator (`Wave1` to `Wave8`).
        *   `altrelucat`: Nominator-nominee relationship context (`Student` denotes on-campus peers).
        *   `altrelig`: Alter religion (Catholic, NoReligion, OtherReligion, Protestant).
        *   `altsex`: Alter gender (Woman, Man).
        *   `altwhite`, `altblack`, `altasian`, `althisla`: Logical variables representing alter race/ethnicity.
        *   `roommates`: Logical variable indicating if the alter is a roommate.
        *   `samedorm`: Logical variable indicating if the alter lives in the same dorm.
        *   `close`: Friendship intimacy, modeled as an ordered 1-4 scale (Distant, Less Than Close, Merely Close, Especially Close).

---

## 3. Mathematical & Statistical Architecture

### A. Group-Level Yule's Q (Longitudinal Trajectory)
Yule's Q is a margin-free metric computed from the $4 \times 4$ mixing matrix $M$. It captures active sorting dynamics independent of the severe group size imbalances in our sample (range: -1 to +1, where 0 is random mixing).

### B. Dyadic Logistic Regression with Opportunity Offset
To model the likelihood of a tie being homophilous (`same_religion` $= 1$) while adjusting for baseline group proportions, we use a logistic regression on the tie-level dataset with a **mathematical opportunity offset**:
$$\operatorname{logit}(P(\text{same\_religion} = 1)) = \beta_0 + \beta_1 \text{EgoReligion} + \mathbf{X}\mathbf{\beta} + \text{opportunity\_offset}$$
Where the `opportunity_offset` $= \log\left(\frac{p}{1 - p}\right)$.

### C. Mediation & Marginal Effects
*   **Mediation (`mediation` package):** Used to formally test and reject the hypothesis that structural foci mediate the homophily of the secular group. 
*   **Marginal Effects (`marginaleffects` package):** Used to correctly evaluate interaction terms (Time $\times$ Religion and Intimacy $\times$ Religion) in logistic regression by computing excess probabilities while holding the opportunity offset at 0 (analytically simulating an equal-opportunity scenario).

---

## 4. Code Pipeline & Script Executions (Located in `Code/`)

1.  **`Code/prep_data20240603.R`**
    *   Legacy cleaning script. Fixed case-sensitivity path loader to point to capital `Data/`.
2.  **`Code/01_longitudinal_descriptives.R`**
    *   Computes group-level Yule's Q across 8 waves.
3.  **`Code/02_dyadic_models.R`**
    *   Prepares a stacked dyadic dataset. Fits nested logistic regressions, longitudinal pooled regressions, and formal interaction models for Time and Friendship Intimacy.
    *   Integrates `marginaleffects` calculations to generate properly scaled plots (`fig-marginal-effects.pdf` and `fig-marginal-effects-intimacy.pdf`) and the `mediation` package test to rule out structural mediation for the No Religion group.

*(Note: The previous ERGM script `03_whole_network_ergms.R` has been deprecated and its findings removed from the manuscript).*

---

## 5. Current Manuscript Status (`paper.tex`)
*   **Fully updated:** Technical variable names replaced with standard prose. Changed "Female/Male" to "Woman/Man". Overly strong causal language (e.g., "prove", "solve") replaced with measured scientific terminology.
*   **Structure:** Reorganized to emphasize baseline opportunity structure stability first. Nested models, pooled models, and interaction models feature intuitive labels and significance asterisks.
*   **Theoretical additions:** Causal mediation analysis integrated into the Results/Discussion. Justifications for Yule's Q and Offset terms added. Formal Appendix created for mathematical justifications (e.g., offset benefits, avoiding scaling artifacts). 
*   **Formatting:** Tables and Figures centralized at the end in an unnumbered section with dedicated page breaks. ERGM sections removed entirely. Discussion and Conclusion merged.