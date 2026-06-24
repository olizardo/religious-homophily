# Memory File: NetHealth Religion Project Revival
This file serves as a comprehensive memory log to help resume work, understand the analytical pipeline, and maintain historical context for future sessions.

---

## 1. Project Context & Objectives
This project analyzes **religious homophily and friendship formation** among college students using the **NetHealth longitudinal dataset** (from the University of Notre Dame). 

The project has been completely restructured to address and resolve the severe methodological flaws identified by journal reviewers:
1.  **Resolved the Group Size Artifact:** Corrected a calculation in the original draft that aggregated individual-level "normalized EI" indices. That aggregation was biased for minority groups due to a mathematical necessity (small group sizes are forced to have high outgroup rates). By shifting to group-level, baseline-adjusted **Yule's Q**, we proved that **all religious groups exhibit robust homophily** in every wave.
2.  **Addressed Confounding Foci & Alternative Homophilies:** Shifted from aggregate, ego-level regressions to **dyadic (tie-level) logistic regressions**. This allows us to control for physical/social foci (same dorm, roommates) and demographic homophilies (same gender, same race).
3.  **Harnessed Longitudinal Data:** Expanded the analysis from a single Wave 3 cross-section to trace the trajectory of religious homophily across **all 8 waves** of the college cohort.

---

## 2. Dataset Information

### A. Core Data Files (Located in `Data/`)
*   **`BasicSurvey(3-6-20).csv`:** Ego-level longitudinal survey.
    *   *Primary Key:* `egoid`
    *   *Key Variables:*
        *   `yourelig_1`: Baseline religious affiliation (Catholic, No Religion, Other Religion, Protestant).
        *   `gender_1`: Ego gender (Male, Female).
        *   `race_1`: Ego race (White, African-American, Asian-American, Latino/a, Foreign Student, Other).
        *   `discussrelig_2`: Frequency of discussing religion (used as a proxy for individual religious salience; 5-point Likert scale).
*   **`NetWorkSurvey(2-28-20).csv`:** Longitudinal ego-network survey detailing nominated ties.
    *   *Keys:* `egoid` (the nominator), `alterid` (the nominated friend).
    *   *Key Variables:*
        *   `wave`: Wave indicator (`Wave1` to `Wave8`).
        *   `altrelucat`: Nominator-nominee relationship context (`Student` denotes on-campus peers).
        *   `altrelig`: Alter religion (Catholic, NoReligion, OtherReligion, Protestant).
        *   `altsex`: Alter gender (Male, Female).
        *   `altwhite`, `altblack`, `altasian`, `althisla`: Logical variables representing alter race/ethnicity.
        *   `roommates`: Logical variable indicating if the alter is a roommate.
        *   `samedorm`: Logical variable indicating if the alter lives in the same dorm.
*   **`AlterAlterEdgeList(1-26-20).csv`:** Adjacency list connecting nominated alters within each ego's network.

---

## 3. Mathematical & Statistical Architecture

### A. Group-Level Yule's Q (Longitudinal Trajectory)
We calculate the $4 \times 4$ mixing matrix $M$ of ego-by-alter religion. For each religious group $G$, we map:
*   $a = M[G, G]$ (ingroup ties)
*   $b = \sum M[G, \neg G]$ (outgroup ties from group $G$)
*   $c = \sum M[\neg G, G]$ (ties from outgroup to group $G$)
*   $d = \sum M[\neg G, \neg G]$ (ties between outgroup members)

Yule's Q is defined as:
$$Q = \frac{ad - bc}{ad + bc}$$
A $Q > 0$ denotes inbreeding homophily. Yule's Q is mathematically independent of group size, enabling rigorous group comparison.

### B. Dyadic Logistic Regression with Opportunity Offset
To model the likelihood of a tie being homophilous (`same_religion` $= 1$) while adjusting for baseline group proportions, we use a logistic regression on the tie-level dataset with a **mathematical opportunity offset**:
$$\operatorname{logit}(P(\text{same\_religion} = 1)) = \beta_0 + \beta_1 \text{EgoReligion} + \mathbf{X}\mathbf{\beta} + \text{opportunity\_offset}$$
Where:
*   `opportunity_offset` $= \log\left(\frac{p}{1 - p}\right)$, with $p$ representing the overall proportion of the ego's religious group in the available alter pool for that wave.
*   $\mathbf{X}$ is a vector of dyadic controls: `same_gender`, `same_race`, `roommates`, `samedorm`, and individual religious salience `discuss_num`.
*   A positive $\beta_1$ coefficient for a minority group indicates that the group has **significantly stronger religious homophily** than the majority (Catholics), directly supporting **Minority Distinctiveness Theory**.

---

## 4. Code Pipeline & Script Executions (Located in `Code/`)

1.  **`Code/prep_data20240603.R`**
    *   *Purpose:* Legacy cleaning script.
    *   *Case-Sensitivity Workaround:* Fixed path loader to point to capital `Data/` (since Linux is case-sensitive, lowercase `'data'` was breaking execution).
2.  **`Code/01_longitudinal_descriptives.R`**
    *   *Purpose:* Computes group-level Yule's Q for Catholic, Protestant, No Religion, and Other Religion across all 8 waves of NetHealth.
    *   *Output:*
        *   Saves calculation table to `Data/longitudinal_yules_q.csv`.
        *   Generates a trajectory line plot saved to `plot_yules_q_trajectory.png`.
3.  **`Code/02_dyadic_models.R`**
    *   *Purpose:* Prepares a stacked dyadic tie-level dataset for Wave 3 and fits three nested logistic regressions of `same_religion` on ego religious groups, alternative homophilies, physical foci, and religious salience.
    *   *Results:*
        *   **Protestants** ($\beta = 0.58, p = 0.003$) and **Other Religions** ($\beta = 2.06, p < 0.001$) exhibit significantly higher opportunity-adjusted homophily than the Catholic majority, persisting even after controlling for same-gender, same-race, roommates, and same-dorm sorting.
4.  **`Code/03_whole_network_ergms.R`**
    *   *Purpose:* Structures the within-cohort network for Wave 3 and specifies Exponential Random Graph Models (ERGMs) to control for endogenous structural effects (`mutual`, `gwdegree`, `gwnsp`) alongside religious match terms.
    *   *Requirements:* `network` and `ergm` packages.

---

## 5. Next Steps for Continued Work
*   **Drafting the Manuscript:** Incorporate the new results:
    *   Present the longitudinal Yule's Q trajectory curves showing universal, persistent homophily across the 8 waves.
    *   Present the nested dyadic models to show that Protestant and Other Religion homophily is extremely robust and is *not* a byproduct of residential sorting (dorm/roommates), alternative demographics (gender/race), or individual-level religious salience.
*   **Model Extensions:**
    *   Pool the dyadic logistic regressions across multiple waves to estimate a longitudinal multilevel panel model.
    *   Install the `network` and `ergm` packages and fit the ERGM models to verify that the results hold when controlling for reciprocity and network transitivity.
