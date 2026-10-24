# Memory File: NetHealth Religion Project

Working log for resuming this project. Section 0 is the current state. Methods advisory for future agents: `METHODS_SUMMARY_2026-10-23.md` (read before designing analyses). Last updated 2026-10-23 (fourth session).

---

## 0. Current state — READ FIRST (2026-10-23, third session)

- **Fourth session (2026-10-23): WC-AS-v1 implemented and run.** `Code/12_within_cohort_choice_model.R` now runs M1, S1–S5, S2 and S10 (plan Sections 4 and 8.3), with two-way SEs (all but S3), C1–C5, D1–D4 and the overlap audit printed before each block. The tests (T1–T6) and the smoke test pass. Checksums are frozen in plan Section 13. Full run: Hoffman2 job 15258479 completed (exit 0; 356 s; 2.06 GB). Output copied to `Data/within_cohort_preregistered_20261023.RDS` (md5 fe79ac58…). M1 Δ = −0.60 (two-way 95% CI −1.21 to 0.02): D1 inconclusive; D2 Catholic in-group elevated; D3 no detectable non-Catholic excess; D4 FALSE (S1 θ_N sign differs, both near zero). Results are recorded in plan Section 13 and are not confirmatory. The exploratory script is archived at `Archive/within_cohort_exploratory_2026-10-23/`. Plan amendments (S10 fixed effects; two-way SE scope; `R_ENVIRON_USER=/dev/null` in the analysis job) are in plan Section 14. Results and D1–D4 are not yet read or interpreted; the plan's "not confirmatory" status still applies.

- **Resume here.** (1) Read `NEXT_STEPS_2026-10-23.md`. (2) Plan decisions O1–O6 are signed off (plan Section 12). (3) WC-AS-v1 has run (job 15258479, Section 0 fourth-session bullet). Next: review the results against the plan's reporting rules (Section 10); decide whether to run the S9 bootstrap (plan Section 5.5 fallback, not needed for M1 since its checks passed); decide the S10 LPM and S3 reporting; and sign off or reject the campus-wide and manuscript items (9, 11, 22, 23). (4) Hoffman2 `~/religious-homophily` holds the frozen run files and `Data/within_cohort_preregistered_20261023.RDS`. Do not overwrite the frozen outputs.

- **Third session (2026-10-23): within-cohort analysis run on Hoffman2 (exploratory; Section 11).** Within the Tier 1/3 roster (595 egos, waves 3–8), the alter-stratified conditional logit (popularity-free, no reciprocity) gives a Catholic in-group log-odds of 0.58 (SE 0.19) and a non-Catholic in-group log-odds of −0.01 (SE 0.20). The non-Catholic minus Catholic contrast is −0.60 (SE 0.34; 95% CI −1.27 to 0.07). A popularity-adjusted ego-stratified check agrees (0.56 and 0.03). A headcount-type model gives +0.20 for the contrast, so the choice of chance model decides the sign.
- **Recommended, not signed off:** make the alter-stratified design primary for the within-cohort claim, and drop headcount as the primary chance model (R1). See Section 9, items 11 and 18.
- **Requested, in progress:** (a) a pre-registration plan for the alter-stratified design (written 2026-10-23 as WC-AS-v1, `.posit/assistant/plans/2026-10-23-1510-preregistration-alter-stratified.md`; not executed; the primary contrast was observed first, so the plan cannot make it confirmatory; O1–O6 signed off 2026-10-23 with the plan's defaults); (b) two-way ego/alter clustering. fixest 0.14.2 is installed on Hoffman2 (job 15256131, exit 0, 2026-10-23) and passes a two-way clustering smoke test. The earlier job 15255991 failed on a library conflict (Section 11.1). Caution: `feglm` is an unconditional fixed-effects logit, and it is biased with sparse strata (about 0.8 nominations per alter-wave stratum). It cannot replace the conditional-logit coefficients (Section 9, item 19).
- **Data:** NetHealth is public. The user approved copies of `BasicSurvey.csv` and `NetWorkSurvey.csv` on Hoffman2 (2026-10-23).
- **Git:** Commits this session: `b90623f` (`docs: pre-register within-cohort plan WC-AS-v1 with signed-off defaults`), then `ea82ef4` (`docs: record plan commit, WC-AS-v1 sign-offs, and fixest install`). `README.md` is still modified (the change predates this session); the plan file is modified again (uncommitted) with the Section 13 checksums and test/smoke-test results from `cluster_vcov.R`. New untracked files as of this point: `Code/12_within_cohort_choice_model.R`, `Code/cluster_vcov.R`, `Code/test_cluster_vcov.R`, `Code/submit_12_within_cohort_choice_model.sh`, `Code/submit_install_fixest.sh`, `Code/check_fixest_install.R`, `Data/within_cohort_choice_models.RDS`.

- **Methods bottom line** (full summary: `METHODS_SUMMARY_2026-10-23.md`):
  - *Settled:* the Catholic/non-Catholic contrast depends on the chance model. On the 10,046-tie baseline sample, headcount gives a No Religion log-odds contrast of about +0.10 (no detectable difference); nominations received gives about +0.83. These data cannot identify which is right, because group-level popularity is unobserved for non-egos.
  - *Proposed (needs user sign-off):* headcount as the primary chance expectation, with its assumption stated (no group-level popularity beyond headcount). Nominations received and nominations made become alternative readings, not co-primary estimates.
  - *Assessment:* do not generate offsets from Smith-type simulated networks. Their calibration reproduces the observed homophily (Step 8), and their independence and sampling assumptions fail.
  - *Requested:* a within-cohort choice model (exploratory run done 2026-10-23; Section 11) and alter–alter closure controls (Section 10.3).
- **Second session (2026-10-23, before reset).** No manuscript or analysis-script changes. Added the NetHealth alter–alter edge list to `Data/` with a checksum-guarded loader and provenance README (Section 10.1). Exploratory calculations ran in the console only (Section 10.2).
- **Pending decision (not made):** baseline framing. The 2026-10-23 co-primary framing stands until the user signs off on the proposal above.
- **Working tree at end of second session (superseded by the third-session bullets above):** modified `AGENTS.md` and root `README.md` (the README change predates this session). Untracked: `Code/load_alter_alter_edgelist.R`, `Data/AlterAlterEdgeList.csv`, `Data/AlterAlterEdgeList_codebook.pdf`, `Data/README.md`, `METHODS_SUMMARY_2026-10-23.md`, and the two Smith PDFs at the root. Nothing committed this session.
- **User action outstanding:** complete the NetHealth usage form and email publications to nethealth@nd.edu (Section 9, item 15).

- **Two opportunity baselines are co-primary.** Every regression table and figure reports both. Conclusions are stated only where both agree, or explicitly as conditional on the baseline.
  - **Cohort** (`_pooled` suffix; primary in the tables): Wave 1 religion of all 718 egos with religion known. Time-invariant, so the offset is constant within group.
  - **Pool** (`_pool` suffix; sensitivity): wave-specific composition of nominated student alters. Partly determined by the outcome ties.
- **Headline result (post-fix sample, 8,562 ties / 422 egos):** single non-Catholic indicator $\beta$ = 0.633 (SE 0.169, p < 0.001) under the pool; 0.035 (SE 0.165, p = 0.83) under the cohort. Leave-own-ego-out pool: 0.638. The Catholic/non-Catholic contrast is reliable only under the pool. No ranking among minority groups under either baseline.
- **Manuscript was rewritten 2026-10-23** for co-primary reporting (see Section 6). It compiles to 28 pages with no undefined references or citations. It has **not** been read end-to-end by a human; the abstract and discussion framing need review.
- **Git:** `my-new-branch`. Commits from 2026-10-23: `ceb96b6` (code, regenerated RDS/CSV/tables/figures) and `3d86b05` (`paper.tex`, `paper.pdf`). Prior checkpoint `79bca7c` (2026-10-22 audit fixes). **Not pushed.** `AGENTS.md` is uncommitted (this file). The untracked plan file is `.posit/assistant/plans/2026-10-23-0825-plan.md`.
- **Overleaf has not been synced** for any 2026-10-22 or 2026-10-23 change. The prose changes are large. Coordinate with co-authors before pushing.
- **Before every push to Overleaf:** `git fetch overleaf && git diff HEAD overleaf/main`, then `git merge-base --is-ancestor overleaf/main HEAD` to confirm a fast-forward. Co-authors edit prose in the Overleaf web editor.
- **Overleaf push refspec:** `.git/config`, `[remote "overleaf"]`, has `push = refs/heads/my-new-branch:refs/heads/main`. Overleaf accepts only `main`.
- **Compile:** `latexmk -pdf paper.tex`. Run it twice if references look stale. The final pass must show no "undefined" warnings.
- **Audit:** `AUDIT_2026-10-22.md` at the project root. Its §1.1 (baseline), §1.2 (excess comparability), and §1.3 (degree) are now addressed by the co-primary design and the leave-focal-tie-out alter popularity. §2 (smaller code/doc items) is partly open. See Section 9.

---

## 1. Project

The project studies religious homophily in friendship formation among NetHealth students at the University of Notre Dame (N = 722 egos, Waves 1–8). It tests the Minority Distinctiveness Hypothesis (MDH) against the Majority Exclusiveness Hypothesis (MEH) using tie-level logistic regressions with an opportunity offset, supplemented by group-level Yule's Q trajectories.

Reviewer objections and how the project responds:
- **Group-size artifact:** the E-I index was replaced by baseline-adjusted Yule's Q, and dyadic models carry an opportunity offset. The offset corrects *bias* only if the baseline is correct. It does **not** equalize *precision* across group sizes; the permutation test, bootstrap, and inference checks address precision.
- **Opportunity baseline:** now reported under two baselines (cohort, pool). Results depend on the choice. See Section 5.
- **Foci and alternative homophilies:** dorm co-residence, roommates, gender, race, closeness, and religious salience are controls.
- **Activity/popularity confound (Reviewer 1):** ego log out-degree and alter log(1 + in-degree excluding the focal nomination) are added. The group coefficients change by 0.012 or less. The focal tie is excluded from alter popularity, so the control does not mechanically contain the outcome tie.
- **ERGMs:** infeasible for the whole network. Only about 32% of `alterid` values resolve to surveyed egos, so the whole network is not closed. A within-cohort ego-to-ego sociomatrix is observed (Section 10.3). The Smith-type simulation is not used for offsets (Section 7).
- **Mediation:** not pursued. The Wave 3 total effect is null, so there is nothing to decompose.
- **Reciprocity and directed ties (Reviewer 2):** not addressed. Directed nominations are treated as separate observations. Only the limitation is stated in the manuscript.

Current manuscript framing (2026-10-23): under the alter-pool baseline, non-Catholic students show higher same-religion tie odds than Catholic students; under the cohort baseline the contrast is near zero. The Catholic/non-Catholic distinction is therefore consistent with MDH only conditional on the pool baseline. No reliable ranking among Protestant, No Religion, and Other Religion students under either baseline.

---

## 2. Data and Samples

**Files in `Data/`:**
- `BasicSurvey.csv`: ego-level survey, key `egoid`. Used: `yourelig_1` (religion), `gender_1` (coded Female/Male), `race_1`, `discussrelig_2` (salience, Wave 2).
- `NetWorkSurvey.csv`: nominations (`egoid` → `alterid`, `wave`). Used: `altrelucat`, `family`, `altrelig`, `altsex` (coded Female/Male), `altwhite`/`altblack`/`altasian`/`althisla`, `roommates`, `samedorm`, `close`.
- `AlterAlterEdgeList.csv` (with `AlterAlterEdgeList_codebook.pdf`): NetHealth Alter–Alter Edge List, retrieved 2026-10-23. Each record says that, in a wave, the ego reported that two named alters know each other. Read it with `Code/load_alter_alter_edgelist.R`. Provenance and checks: `Data/README.md`.

**Sample flow** (`Code/00_sample_descriptives.R`; 36 Methods values match the data):
- 722 egos; 4 with missing religion.
- 35,912 nominations (all waves). 17,452 are to student alters (48.6%). 312 on-campus family nominations are removed, leaving **17,140 analytic student ties** (all waves). 14,364 of these have alter religion reported.
- **Baseline sample** (Waves 3–8, no covariate filtering; Table 3 Panels A–B and Model 1 check): **472 egos / 10,046 ties**.
- **Complete-case analytic sample** (Tables 1–3 Panels C–D, Figure 3 uses its own per-wave sample): **422 egos / 8,562 ties** after the `same_race` fix. By group (egos / ties): Catholic 320 / 6,735; No Religion 37 / 575; Other Religion 19 / 292; Protestant 46 / 960. Before the fix it was 428 / 9,522.
- **Missing-indicator sample** (sensitivity, `Code/11`): 9,961 ties.

**Group composition shift:** the complete-case filter removes disproportionately many No Religion egos. Among No Religion egos, 24.7% report a race outside the four coded categories (Catholic 5.3%, Other Religion 9.1%, Protestant 7.0%). The No Religion share of ties falls from 8.5% (baseline) to 6.7% (analytic).

**Opportunity baseline shares** (for reference):
- Cohort (Wave 1, 718 egos): Catholic 73.1%, No Religion 12.4%, Other Religion 4.6%, Protestant 9.9%.
- Pool (wave-averaged alter shares): Catholic about 80%, No Religion about 9.0%, Other Religion about 2.7%, Protestant about 8.9%.

**Family-tie exclusion** (`family == FALSE` after `altrelucat == "Student"`) is applied in every script that builds the analytic tie sample. Siblings who both attend the university would otherwise be counted as friends.

**Variables** (regression scripts):
- Outcome `same_religion`. Offsets: `offset_cohort = log(prop_cohort/(1-prop_cohort))` (primary) and `offset_pool = log(prop_pool/(1-prop_pool))` (sensitivity).
- `same_gender`; `same_race` is NA when ego race is outside the four coded categories or the alter's indicator for the ego's race group is missing. Pre-2026-10-22, unknown alter race was coded 0. Foreign Student and Other-race egos were NA in both versions.
- `roommates`; `samedorm` (both missing for about 31% of ties).
- `close_num`: ordinal 1–4 via `case_when` (Distant, LessThanClose, MerelyClose, EspeciallyClose).
- `discuss_num`: 1–5 from `discussrelig_2`.
- `log_ego_degree` = log(out-degree in that wave's full roster, which includes the focal tie; always ≥ 1). `log_alter_pop` = log1p(in-degree − 1), i.e. excluding the focal tie.
- `wave_num` = wave − 3 (interaction model only).

**Known label issue:** the manuscript uses "Woman/Man" (kept per the 2026-10-23 decision), with a footnote that the survey codes are Female/Male. The data codes are Female/Male.

---

## 3. Statistical Specification

- **Dyadic logit:** `glm(..., family = binomial, offset = offset_*)` with ego-clustered SEs (`sandwich::vcovCL`, cluster = `egoid`). Every model is fit under both baselines.
  - Model 1: `ego_rel` only.
  - Model 2: + `same_gender`, `same_race`, `roommates`, `samedorm`, `close_num`, `discuss_num`.
  - Model 3: + `log_ego_degree`, `log_alter_pop`.
  - Interaction: Model 3 structure with `ego_rel * wave_num`. Joint Wald test of the three group × wave terms (3 df), ego-clustered vcov.
- **Single non-Catholic indicator** (`non_cath`): the headline contrast. Reported in `Code/08` under cohort, pool, and leave-own-ego-out pool.
- **Leave-own-ego-out pool** (`Code/08`): the pool share for tie (i, w) excludes ego i's own nominations: `(n_wg − a_iw) / (N_w − b_iw)`.
- **Yule's Q** (Code 01): group-level, margin-free. Observed Q is computed from the tie table alone and does **not** depend on the baseline. Only the null depends on it. Magnitudes are not comparable across group sizes. Do not rank groups by Q.
- **Permutation test** (Code 07): 1,000 permutations per wave per null. Pool null: `set.seed(6142)`, reproduces the 2026-10-22 values exactly. Cohort null: `set.seed(6143)`. Two-sided p-values are reported; one-sided p-values are the basis of the pre-2026-10-23 table and are no longer shown.
- **Bootstrap** (Code 10): ego-level cluster bootstrap, 2,000 replicates. Pool: `set.seed(6284)` (reproduces the committed Panel A exactly). Cohort: `set.seed(6285)`. Excess = observed same-religion rate minus mean baseline. Panels A–B are descriptive.
- **Wald tests** (Code 10): manual contrasts `L'b`, variance `L'V L` with the ego-clustered vcov, χ² with 1 df, Holm across six contrasts, under Model 1 and Model 3, both baselines. Catholic-vs-X rows are Catholic minus X (sign fixed 2026-10-22). `car::linearHypothesis()` fails on level names with spaces.
- **Inference checks** (Code 09): two-way clustering by egoid and alterid (`vcovCL` with two cluster columns; 3,011 unique alters, none missing). Ego-cluster pairs bootstrap (**1,000 replicates**, seeds 6286–6289; reduced from 2,000 for run time). Leave-one-ego-out influence (422 refits per model and baseline).
- **Baseline sensitivity** (Code 08): headline indicator, group coefficients under three baselines, break-even baseline shares, and a free offset coefficient (pool only; not identified under cohort because the offset is constant within group).
  - Break-even shares are approximate. They use group-mean offsets and hold the Catholic share at its cohort value.
  - Results: break-even share is about 10.5% (No Religion), 9.3% (Other Religion), 9.9% (Protestant). Free offset on the pool is 0.88 (SE 0.28), p = 0.67 vs. 1.
- **Figure 3** (Code 05): a separate cross-sectional logit per wave with the Model 2 covariates **including** salience (changed 2026-10-23 from excluding it). Average marginal effects of each non-Catholic group vs. Catholic, averaged over all observed ties, with offset fixed at 0 (equal-opportunity counterfactual). Three versions: `fig-active-coefs.png` (cohort, offset 0; in the paper), `fig-active-coefs-pool.png` (pool, offset 0; in the paper), `fig-active-coefs-observed.png` (cohort, observed offsets; generated but **not** in the paper). CIs ego-clustered. Estimates are in `Data/active_coefs_me.csv`.
- **Interpreting absence of change:** group × wave terms are not significant under the pool, but the cohort No Religion × wave term is significant (p = 0.006). The non-Catholic groups have few unique egos (37 and 19). Report both baselines. Describe null results as absence of evidence, not evidence of stability.

---

## 4. Pipeline

| Script | Output | Manuscript element |
|---|---|---|
| `Code/00_sample_descriptives.R` | `Data/sample_descriptives.csv` | Methods §2 quoted values (36 checked, match) |
| `Code/01_longitudinal_descriptives.R` | `Data/longitudinal_yules_q.csv`, `Plots/fig-yules-q.png` | Figure 2 (Yule's Q, Waves 1–8) |
| `Code/04_plot_opportunity_stability.R` | `Plots/fig-opportunity-stability.png` | Figure 1 |
| `Code/02_dyadic_models_pooled.R` | `Data/pooled_clusted_models.RDS` (Models 1–3 under both baselines) | Table 1, Table (pool sensitivity); sourced by 02b, 08, 09, 10, 11 |
| `Code/02_dyadic_models_interaction.R` | `Data/interaction_model_results.RDS` (cohort), `Data/interaction_model_results_pool.RDS` (pool + joint Wald) | Table 1 and pool-sensitivity interaction columns; sourced by 02b |
| `Code/02b_build_pooled_table.R` | `Tabs/tbl-pooled-interaction-reg.tex`, `Tabs/tbl-pool-baseline-sensitivity.tex` | Table 1 (cohort), pool-sensitivity table |
| `Code/05_plot_active_coefficients.R` | `Plots/fig-active-coefs*.png`, `Data/active_coefs_me.csv` | Figure 3 (cohort, pool) |
| `Code/07_yules_q_permutation_test.R` | `Data/yules_q_permutation_null.csv`, `Tabs/tbl-yules-q-null.tex` | Table 2 (both nulls) |
| `Code/10_bootstrap_sensitivity.R` | `Data/bootstrap_sensitivity_results.RDS`, `Tabs/tbl-bootstrap-sensitivity.tex` (cohort), `Tabs/tbl-bootstrap-sensitivity-pool.tex` | Table 3 (two tables) |
| `Code/08_baseline_sensitivity.R` | `Tabs/tbl-baseline-sensitivity.tex`, `Data/baseline_sensitivity.RDS` | Baseline sensitivity table |
| `Code/09_inference_robustness.R` | `Tabs/tbl-inference-robustness.tex`, `Data/inference_robustness.RDS` | Inference table (about 23 minutes to run) |
| `Code/11_sample_missingness.R` | `Tabs/tbl-missingness.tex`, `Data/missingness_summary.RDS` | Missingness table |
| `Code/12_within_cohort_choice_model.R` (exploratory; not in run order; runs on Hoffman2 via `Code/submit_12_within_cohort_choice_model.sh`) | `Data/within_cohort_choice_models.RDS` (exploratory, frozen); `Data/within_cohort_preregistered_<YYYYMMDD>.RDS` (non-smoke runs after the two-way wiring, Section 11) | None yet (within-cohort analysis, Section 11) |
| `Code/cluster_vcov.R` (`cluster_meat`, `one_way_vcov`, `two_way_vcov`, `min_eigenvalue`; sourced by `Code/12`) | None (library of functions) | Supplies M1/S1's two-way ego/alter clustered SEs (plan WC-AS-v1 Section 5.2) |
| `Code/test_cluster_vcov.R` (T1–T6 unit tests for `cluster_vcov.R`) | None (prints a pass/fail table; run with `Rscript -e 'source(here::here("Code","test_cluster_vcov.R"))'`) | Validates `cluster_vcov.R` against `sandwich::vcovCL` and `coxph`'s own cluster-robust vcov |
| `Code/submit_install_fixest.sh`, `Code/check_fixest_install.R` (Hoffman2 setup) | None | Installs fixest into `~/R/religious-homophily-lib`; synthetic two-way clustering check |

Helper, not in the run order: `Code/load_alter_alter_edgelist.R` (checksum-guarded loader for the alter–alter edge list; no pipeline output). No script sources it yet.

**Run order:** 00, 01, 04, 02b (sources 02 pooled and interaction), 05, 07, 08, 09, 11, 10. Code 02b, 08, 09, 10, and 11 source Code 02 into dedicated environments (`env_pooled`, `env_interaction`, `pooled_env`). None uses `local = TRUE`.

**Archived** (`Archive/`, not read by any script or the manuscript): `orphaned_scripts/`, `orphaned_data/`, `orphaned_tables/`, `orphaned_plots/`. Do not use these for the manuscript.

**Unchanged outputs (verified byte-identical 2026-10-23):** `Data/sample_descriptives.csv`, `Data/longitudinal_yules_q.csv`, `Plots/fig-yules-q.png`, `Plots/fig-opportunity-stability.png`. The pool-null rows of `Data/yules_q_permutation_null.csv` and the pool-baseline Panel A of Table 3 also reproduce exactly.

---

## 5. Current Key Results (post-fix, 2026-10-23)

**Table 1, cohort baseline** (Waves 3–8, clustered SEs, 422 egos / 8,562 ties):
- Model 1: intercept 0.638 (p < 0.001). No Religion −0.170 (p = 0.44). Other Religion 0.769 (p = 0.14). Protestant 0.006 (p = 0.98).
- Model 2: Race 0.280 (p = 0.030). Same dorm −0.249 (p = 0.063). No Religion, Other Religion, and Protestant all n.s.
- Model 3: No Religion −0.166 (p = 0.44); Other Religion 0.757 (p = 0.14); Protestant 0.007 (p = 0.97). Ego activity 0.130 (p = 0.18). Alter popularity −0.118 (p = 0.17).
- Interaction: No Religion −0.721 (p = 0.007) at Wave 3; No Religion × wave 0.233 (p = 0.006); Other Religion × wave 0.026 (p = 0.83); Protestant × wave 0.036 (p = 0.61). Joint group × wave p = 0.056.

**Table 1 sensitivity, alter-pool baseline:**
- Model 1: intercept 0.281 (p < 0.001). No Religion 0.553 (p = 0.012). Other Religion 1.694 (p = 0.001). Protestant 0.479 (p = 0.016).
- Model 2: No Religion 0.552 (p = 0.011); Other Religion 1.696 (p < 0.001); Protestant 0.476 (p = 0.017). Race 0.268 (p = 0.037). Same dorm −0.253 (p = 0.058).
- Model 3: No Religion 0.553 (p = 0.010); Other Religion 1.684 (p < 0.001); Protestant 0.480 (p = 0.017). Race 0.263 (p = 0.040). Dorm −0.247 (p = 0.063). Ego activity 0.127 (p = 0.19). Alter popularity −0.125 (p = 0.14).
- Interaction: No Religion × wave 0.080 (p = 0.35). Joint p = 0.69.

**Table 2** (permutation, Waves 1–8, two-sided): observed Q lies above the null mean in 32 of 32 group-waves under both nulls. Significant at p < 0.05 in 31 of 32 under both. The exception is Protestant, Wave 1 (cohort p = 0.126; pool p = 0.172). z-scores under the pool null range from 1.3 to 7.5.

**Table 3, excess (descriptive):**
- Pool: Catholic 0.038 (0.021, 0.055); No Religion 0.138 (0.083, 0.199); Other Religion 0.125 (0.027, 0.275); Protestant 0.094 (0.049, 0.146). Catholic vs. No Religion and Catholic vs. Protestant exclude zero.
- Cohort: Catholic 0.104 (0.086, 0.120); No Religion 0.101 (0.045, 0.165); Other Religion 0.107 (0.007, 0.252); Protestant 0.084 (0.037, 0.134). No pairwise difference excludes zero.

**Table 3, Wald (Holm across six contrasts, Model 1):**
- Pool: Catholic-vs-X Holm p = 0.061 (No Religion), 0.006 (Other Religion), 0.064 (Protestant). No Religion vs Other Religion raw p = 0.040 (Holm 0.079). Other Religion vs Protestant raw p = 0.026 (Holm 0.078). No Religion vs Protestant p = 0.79.
- Cohort: no contrast significant (smallest raw p = 0.09).
- Model 3 pool: Catholic-vs-X Holm p = 0.049, 0.006, 0.069.

**Two-way clustering (Code 09), Model 1:** pool p = 0.017 (No Religion), 0.001 (Other Religion), 0.030 (Protestant). Cohort p = 0.47, 0.14, 0.98.

**Bootstrap percentile CIs (Code 09, 1,000 reps), Model 1:** pool No Religion (0.088, 0.979); Other Religion (0.375, 2.56); Protestant (0.095, 0.847). Cohort: all three include zero.

**Leave-one-ego-out:** pool Other Religion ranges 1.00–1.80. The most influential ego is Other Religion, ID 63904 (35 ties). Removing that ego moves the pool coefficient from 1.69 to 1.00 and the cohort coefficient from 0.77 to 0.07. Pool No Religion and Protestant ranges: 0.41–0.63 and 0.37–0.53.

**Figure 3** (average marginal effects, probability scale, offset = 0, ego-clustered CIs):
- Pool: Other Religion positive with CI excluding zero in all waves (0.27–0.34). No Religion positive with CI excluding zero in Waves 4, 5, and 8 (0.13–0.19); CI includes zero in Waves 3, 6, 7. Protestant CI excludes zero in Wave 4 and borderline Wave 5 (lower bound 0.00), includes zero otherwise.
- Cohort: no interval excludes zero except No Religion in Waves 3 (−0.27) and 4 (−0.14), both negative.

**Missingness (Code 11):** Model 1 on the baseline sample (10,046 ties): pool No Religion 0.844, Other Religion 1.66; cohort 0.104, 0.716. Missing-indicator Models 2–3 (9,961 ties): pool No Religion ≈ 0.80, Other Religion ≈ 1.64, Protestant ≈ 0.56; cohort No Religion ≈ 0.06, Protestant ≈ 0.07, both n.s.

**Interpretation the manuscript supports:** the Catholic/non-Catholic contrast is reliable only under the pool baseline, and it persists across degree controls, leave-own-ego-out pool, two-way clustering, and missing-indicator coding. Under the cohort baseline it is not distinguishable from zero in any specification run. Neither baseline supports a ranking among minority groups. Other Religion's estimate depends on individual egos under both baselines.

---

## 6. Manuscript (`paper.tex`)

**Structure (2026-10-23):**
- Abstract (conditional framing); §1 Introduction; §2 Methods (2.1 data, 2.2 variables, 2.3 opportunity offset with two baselines as bullets). The E-I and mixed-model discussion is Appendix A (`app:methodological-advantages`).
- §3 Results:
  - §3.1 Preliminary Checks: Opportunity Structure Stability (Figure 1), Baseline Mixing Patterns (Yule's Q, Figure 2).
  - §3.2 Primary Analysis: pooled regressions under both baselines (Table 1 and the pool-sensitivity table), single-indicator headline, interaction, Figure 3 (cohort and pool).
  - §3.3 Robustness Checks (`sec:robustness`):
    - Yule's Q permutation test (Table 2, both nulls).
    - Bootstrap and Wald tests (Table 3 cohort and pool).
    - Baseline sensitivity (table).
    - Inference with few clusters (table).
    - Missingness and sample composition (`sec:missingness`; table).
    - Synthesis.
- Discussion; bibliography; Appendix A.

**Removed from the manuscript:** the Wave 3 cross-sectional check and wave-by-wave decomposition (2026-09-24, user decision); the formal mediation analysis (2026-09-24, total effect null); the point-biserial footnote (2026-10-22, no supporting analysis); the Appendix A claims about mixed-model estimation (2026-10-23, unverified; replaced with a conceptual comparison).

**Wording rules:**
- Lead with the baseline. Say "under the alter-pool baseline" or "under the ego-cohort baseline" for any group claim. Do not state a group result without naming the baseline.
- Describe the Catholic/non-Catholic contrast as "conditional on the baseline." Do not write "supports MDH" without the qualifier.
- Describe a cohort-baseline null as "not distinguishable from zero," with the interval. Do not describe it as "no effect" or as "evidence of equality."
- Describe the Catholic excess as small under the pool (about 4 pp) and about 10 pp under the cohort. Do not call it "largely structural" without the baseline qualifier.
- Describe Figure 3 as average marginal effects with offset = 0, a counterfactual. Its magnitudes are not comparable to Table 1 log-odds.
- Report that the cohort No Religion × wave term is significant (p = 0.006) with a caveat about 37 egos. Do not describe the pool result as "stable trajectories."
- Avoid "strong evidence," "ruling out," "durable separation," and "extreme flatness."
- Do not say excess rates or Yule's Q are "comparable across groups of different sizes." Do not say the expected value of Q under random mixing is 0 "regardless of group size" (Table 2 null means are negative for Other Religion under the pool).
- Use 19 egos for Other Religion in the regression sample. 22 is the bootstrap sample.
- Protestant Figure 3 Wave 5 interval is borderline (lower bound 0.00). Say so.

**Known manuscript issues (not yet fixed):**
- The Results prose was drafted quickly on 2026-10-23. It needs a full human read-through for accuracy and tone.
- The Figure 3 observed-offset version is generated but not in the manuscript.
- The Methods paragraph on discussion-frequency missingness (85/722 = 11.8%) is in Section 3.3, not Methods.
- The dorm-assignment rationale in Results (dorm assignment "based on data obtained at matriculation") has no source in the analysis materials. Add a citation or hedge.
- The "approximately 72.7%" figure in the Introduction cites `purta2016` and describes egos, not the student body. Check the citation.

---

## 7. Decisions That Still Govern the Analysis

- **ERGMs dropped** (2026-09-23): alter resolution is about 32%.
- **Yule's Q is descriptive only** (2026-09-23).
- **Offset corrects bias only if the baseline is correct; it does not equalize precision** (2026-09-23).
- **Two opportunity baselines are co-primary** (2026-10-23, user decision). The cohort is the primary column in Table 1 and Figure 3. The pool is reported beside it with equal weight. Conclusions are stated only where both agree, or as conditional on the baseline.
- **Pooled Waves 3–8 is the primary test** (2026-09-24). Wave 3 cross-section and wave-by-wave decomposition were removed.
- **Family ties excluded** from every analytic sample (2026-09-24).
- **Unknown alter race is NA, not 0** (2026-10-22). Pre-fix it was coded 0. The fix changed the Table 1 sample to 422 egos / 8,562 ties.
- **Leave-focal-tie-out alter popularity** (2026-10-23): alter popularity excludes the focal nomination. The ego out-degree is unchanged.
- **Figure 3 uses ego-clustered CIs and includes religious salience** (2026-10-23), matching Model 2.
- **Permutation null: two-sided p-values** (2026-10-23). The cohort null is primary, with the pool null alongside.
- **Woman/Man** kept in text with a footnote (2026-10-23, user decision).
- **Framing is conditional on the baseline.** The user chose to set the framing after the reruns (2026-10-23), and the current abstract and discussion reflect that. Revisit only with new evidence.
- **Methods descriptives** are generated by `Code/00_sample_descriptives.R`, which also checks each quoted value.
- **Sourced model scripts use dedicated environments, not `local = TRUE`.**
- **Smith (2012, 2015) simulation approach not used for offsets** (assessment, 2026-10-23; `METHODS_SUMMARY_2026-10-23.md`, R3).
- **PROPOSED, not decided (2026-10-23): headcount as the primary chance expectation**, with nominations received and nominations made as alternative readings, not co-primary. This would revise the framing decision above. The current co-primary framing stands until the user signs off.
- **Within-cohort primary candidate (2026-10-23; recommendation, not signed off):** the alter-stratified conditional logit on the Tier 1/3 roster, with self-reported religion for both parties, no reciprocity term, and controls for gender, race, first-year hall, and log out-degree. Estimand: non-Catholic minus Catholic in-group log-odds (a difference-in-differences). Section 9, item 18.
- **Headcount as primary chance model (R1): recommended against** (2026-10-23) on within-roster evidence. Alter-group popularity departs from headcount (Protestant alters draw about 1.8× the odds of Catholic alters per candidate after adjustment), and the non-Catholic contrast changes sign. Pending sign-off (item 11).
- **Ego-reported alter religion** raises same-religion rates in every group, more in odds for minorities (2026-10-23). Re-estimate the campus-wide outcome with self-reports for roster alters before citing its non-Catholic results (item 22).
- **NetHealth copies on Hoffman2 approved** by the user (2026-10-23). The data are public.
- **fixest approved for Hoffman2** (2026-10-23). Local installs (`clubSandwich`, `geepack`) still need approval (item 1).

---

## 8. Pitfalls

- **Ordinal coding:** `close_num` must use `case_when`. `as.numeric(as.factor(close))` alphabetizes and produces wrong coefficients.
- **Stale artifacts:** a `.tex` table and its script can diverge. Confirm every quoted number against a fresh run.
- **Text versus table:** check every significance claim against the table it cites. Pre-2026-10-23 text was written against pre-fix tables and no longer matches.
- **Global environment:** `source(..., local = TRUE)` assigns into the global environment at top level. Use `new.env()` and reference objects explicitly.
- **`here()` caching:** `here()` fixes the project root when first loaded in the session. `setwd()` to a scratch copy does not redirect `here()` paths. Verify output locations before comparing reruns.
- **Legacy regression test (2026-10-23):** to check the pipeline against pre-fix numbers, apply text substitution to a copy of the source lines (e.g. `gsub` on `as.numeric(altwhite)` → `dplyr::coalesce(as.numeric(altwhite), 0)`) and `eval(parse(text=...))` into a new environment. This leaves production code untouched. Pre-fix pool Model 1 is 0.267 / 0.549 / 1.718 / 0.497 on 9,522 ties / 428 egos.
- **Model offsets:** pass the offset as a column name in the formula (`offset(offset_pool)`) and write each model with an explicit `glm()` call. An earlier draft used `update(model, offset = ...)`; it was replaced before it was verified.
- **Run time:** Code 09 takes about 23 minutes (1,000 bootstrap refits × 4 plus 1,688 leave-one-out refits). Running it inside one `executeCode` call was canceled by the user on 2026-10-23. Run it alone, or reduce replicates, when iterating.
- **Complete-case composition:** the analytic sample loses No Religion egos disproportionately (race not coded). Report the composition change with any group result.
- **Pool shares are endogenous:** the pool includes the nominations being modeled. The leave-own-ego-out version removes the ego's own contribution, but not group-level feedback.
- **Break-even shares** (`Code/08`) use group-mean offsets and are approximate.
- **Excess versus logit scale:** the excess-probability bootstrap is baseline-dependent. Use the log-odds contrasts (Wald Panels C–D, Code 09 bootstrap) for group comparisons.
- **Alter popularity:** the leave-focal-tie-out version is used everywhere. Ego out-degree still includes the focal tie.
- **`marginaleffects`:** `newdata` should contain only the model variables. Use `offset()` in the formula so predictions take the offset from `newdata`.
- **Editing in batches:** do not `sed -i` a file in the same batch as a pending edit to that file. Re-grep after editing.
- **LaTeX table generation:** check each `sprintf` row against its header's column count. Several alignment errors in 2026-10-23 came from missing `\\` terminators and mismatched column counts.
- **latexmk:** run twice if references look stale. Confirm with a clean final pass.
- **Overleaf:** fetch and diff before every push. Co-authors edit prose mid-session.
- **Mediation:** do not reintroduce an ACME decomposition of an already-null total effect.
- **Activity denominators:** use observed ego-waves (ego-waves with at least one nomination), not cohort headcount × waves. Participation falls from 400 ego-waves in Wave 3 to 185 in Wave 8. A 2026-10-23 simulation used headcount × waves and was superseded.
- **Nominations received is not neutral availability.** It counts the outcome ties (63% of nominations are Catholic-to-Catholic).
- **Wave coding:** the edge list uses numeric waves 1–8; `NetWorkSurvey.csv` uses `Wave3`–`Wave8`. The loader adds `wave_label`.
- **Absent alter–alter pairs** are read as "not reported as knowing." The response options are unverified.
- **Large files and PDFs:** the `read` tool refuses files over 5 MB. Read CSV headers with `readr::read_csv(..., n_max = 0)`. Use `pdftotext -layout` for PDFs. The NetHealth questionnaire PDF has no text layer.
- **Google Drive downloads:** `curl -sSL -o FILE 'https://drive.google.com/uc?export=download&id=ID'`; if the response is HTML, repeat with `&confirm=t`.
- **Testing sourced functions:** use `sys.source(file, envir = new.env())` so the global environment stays clean.
- **Closure controls are descriptive.** The named-alter set is the outcome sample; do not read them causally.
- **Sequential evaluation in `mutate()` and `transmute()`.** Overwriting `egoid` and then using it in the same call (`alt_egoid = egoid`) created self-keys and silently zeroed the reciprocity term. Rename first, then transmute.
- **`clogit(method = "exact")` does not accept `cluster()`,** and dfbeta residuals are unavailable for the exact method. Use exact point estimates and clustered SEs from the Breslow Cox fit (`strata()` plus `cluster()`). Report the exact-vs-Breslow gap.
- **Breslow SEs fail under very large weights.** Reciprocity (log-odds ≈ 6.5) gives an exact-vs-Breslow gap of about 1.9. Do not use those SEs. For the same-religion and popularity terms in the no-reciprocity models checked (AS_A, ES_D_no_recip), the gap is ≤0.02.
- **Alter-wave strata are sparse.** About 0.8 nominations per alter-wave stratum on average. The exact conditional likelihood handles this. The unconditional fixed-effects logit (`fixest::feglm`) does not, so do not substitute it for the primary coefficients.
- **`recip_obs` is collinear with alter-wave strata** (constant within each alter in each wave). Drop it from alter-stratified models. With it included, `recip` came back NA.
- **Reciprocity cannot be estimated in the alter-stratified design.** The reciprocity-only exact MLE does not converge (the fit reaches 24). Estimate reciprocity only in the ego-stratified design.
- **Dyad tables have about one million rows.** The local R session ran out of memory (14 GB, no swap). Run full models on Hoffman2 (`#$ -pe shared 1`, `#$ -l h_data=8G`; peak about 2 GB).
- **Hoffman R 4.2.2.** `module load gcc/10.2.0` switches to a second R build with its own system library, which lacked `dplyr` and `tidyr`. Use a dedicated `R_LIBS` directory. Current CRAN `bit64` will not load on R 4.2.2 (it needs R ≥ 4.3), so the project reads CSVs with base `read.csv(na.strings = c("", "NA"))` and converts "True"/"False" with `as.logical`.
- **dplyr 1.2 deprecates `case_match()`** (a warning on the local machine). Use `case_when()`, which works on dplyr 1.1.4 (Hoffman) and 1.2.x (local).
- **Hoffman `-o` logs.** A reused log name (`within_cohort_12.log`) contains output from several attempts. Use a unique log name per job and check `qacct -j <id>` for exit status.
- **Checksums across hosts.** Compare hashes with `awk '{print $1}'`. Paths differ between local and remote, so comparing full `md5sum` lines gives false mismatches.
- **Library conflict on Hoffman2 (2026-10-23).** `~/.Renviron` puts `~/R/x86_64-pc-linux-gnu-library/4.5` (Rcpp 1.1.2, built for R 4.5.1) first on the search path. R 4.2.2 jobs then load incompatible shared objects (`undefined symbol: R_getVarEx`), and `install.packages` skips installing compatible copies, because it sees the existing ones. Fix applied and verified: `export R_ENVIRON_USER=/dev/null` in the install job script makes R ignore `.Renviron`, and `R_LIBS` supplies the job library (fixest 0.14.2 installed in job 15256131). The analysis job (`Code/submit_12_within_cohort_choice_model.sh`) does not set this yet; decide whether it should.

---

## 9. Open Items

1. **Install approval.** On Hoffman2, `fixest` was approved. The install ran as job 15255991 (submitted 2026-10-23, about 14:54 Pacific; failed with exit status 1 after about 20 minutes, because of the library conflict (Section 11.1). The fix (`R_ENVIRON_USER=/dev/null` in the install script) was applied, and the install was resubmitted as job 15256131: exit status 0, fixest 0.14.2 installed, and the two-way clustering smoke test passed). Local `clubSandwich` (CR2 small-sample SEs) and `geepack` (GEE population-average model) are not installed and still need approval. If approved, add CR2 to `Code/09` and a GEE comparison. Wild cluster bootstrap was not attempted (needs a logit-compatible implementation).
2. **Manuscript read-through.** The Results and Discussion were drafted quickly. A full human review is needed before the framing is final. Check every quoted number against `Tabs/`, `Data/`, and `Plots/`.
3. **Number-trace file.** `Data/manuscript_numbers_check.csv` (planned in Stage 6) has not been produced.
4. **README.** Sections 4 and 5, the data filenames (`BasicSurvey(3-6-20).csv`, `NetWorkSurvey(2-28-20).csv`), and step numbering are out of date. The README also describes an Intimacy × Religion interaction and `marginaleffects` interaction terms, which are not in the code.
5. **Stale comments.** Several scripts still reference the archived `02_dyadic_models.R`. A grep on 2026-10-23 found none in the code, but confirm before closing this item.
6. **Overleaf sync.** After user approval, fetch, diff, and fast-forward check, then push `my-new-branch` to `overleaf/main`. Co-authors may have edited the prose.
7. **Observed-offset Figure 3.** Decide whether to include `Plots/fig-active-coefs-observed.png` in the manuscript.
8. **Reciprocity and directed ties (Reviewer 2).** Not addressed. Decide whether a descriptive mutual-nomination analysis (among alters who are surveyed egos, about 32%) is in scope.
9. **Dorm-assignment citation** (Results, §3.2 footnote). Find a source or hedge.
10. **`purta2016` citation** for the 72.7% figure in the Introduction. Check that it describes the cohort.
11. **Baseline framing sign-off (PROPOSED).** Headcount primary versus co-primary. See Section 7 and `METHODS_SUMMARY_2026-10-23.md`, R1. Approval would revise the 2026-10-23 framing decision. Within-roster evidence (Section 11) argues against headcount as primary. Plan WC-AS-v1, decision O2, was signed off on 2026-10-23 for the within-cohort analysis only; this campus-wide item is still open.
12. **Within-cohort model (requested).** WC-AS-v1 has run (Hoffman2 job 15258479, 2026-10-23; plan Section 13). M1 Δ = −0.60 (two-way 95% CI −1.21 to 0.02): D1 inconclusive; D2 Catholic in-group elevated; D3 no detectable non-Catholic excess; D4 FALSE (θ_N sign differs between M1 and S1, both near zero). Not confirmatory. Items 18–19 are complete.
13. **Alter–alter closure controls (requested).** Specification in Section 10.3(B). Confirm the definition first, because the two requested controls coincide.
14. **Commit decision.** Untracked: `Code/load_alter_alter_edgelist.R`, `Data/AlterAlterEdgeList.csv`, `Data/AlterAlterEdgeList_codebook.pdf`, `Data/README.md`, `METHODS_SUMMARY_2026-10-23.md`, and the two Smith PDFs at the root. Modified: the root `README.md` (the change predates this session) and the plan file (Section 13 checksums and test results, uncommitted). `AGENTS.md`, the plan, and the checklist were committed on 2026-10-23 (`b90623f`, `ea82ef4`). The two survey CSVs in `Data/` are already tracked, so decide whether raw NetHealth files belong in git. Also untracked since 2026-10-23: `Code/12_within_cohort_choice_model.R`, `Code/cluster_vcov.R`, `Code/test_cluster_vcov.R`, `Code/submit_12_within_cohort_choice_model.sh`, `Code/submit_install_fixest.sh`, `Code/check_fixest_install.R`, `Data/within_cohort_choice_models.RDS`.
15. **NetHealth usage form and publication email** (user action). The data page asks users to complete a Google Form and to email publications to nethealth@nd.edu. Not done.
16. **Questionnaire response options** for the alter–alter item are unverified (the questionnaire PDF has no text layer).
17. **Re-create exploratory calculations as scripts** before citing them (Section 10.2).
18. **Pre-registration of the alter-stratified design (done).** Plan WC-AS-v1 at `.posit/assistant/plans/2026-10-23-1510-preregistration-alter-stratified.md`; O1–O6 signed off 2026-10-23; frozen checksums in Section 13 (committed status: check `git status`). The plan cannot make the primary contrast confirmatory, because the primary contrast was observed before the plan and the release holds waves 1–8 only. Amendments (S10 fixed effects; two-way SE scope; analysis-job `R_ENVIRON_USER`) are in Section 14.
19. **Two-way ego/alter clustering (done 2026-10-23).** `Code/cluster_vcov.R` passes T1–T6 (`Code/test_cluster_vcov.R`, max diff 4.5e-13). `Code/12` computes two-way SEs for M1, S1, S2, S4 and S5 (S3 is point-estimate only, C5). C1–C4 pass for M1. S10 (fixest LPM, alter-wave and chooser FE) is a labelled robustness check, and its scale differs from log-odds. Remaining within this item: S9 bootstrap if the two-way intervals are used for a claim beyond D1–D4, and the overlap audit output in Section 13 should be read by a human before the results are reported.
20. **Overlap audit for two-way clustering** (AGENTS.md guidance on two-way dyadic clustering): report crossed alters (roster members who are also choosers), ego–alter pairs, and dyad-periods for the alter-stratified sample.
21. **Within-cohort sensitivity checks (not run):** alter-stratified with Tier 2 included (the ego-stratified Tier 2 model with reciprocity did not converge); same-wave religion for waves 7–8; closure controls from observed roster nominations (item 13); religion × first-year-hall interaction.
22. **Campus-wide headline with self-reported religion (not run).** Re-estimate using self-reports for the roughly 3,200 roster-nominated ties, and report the change. Until then, do not cite the campus-wide non-Catholic in-group result.
23. **Manuscript implications (not started).** If the within-cohort design is adopted, the abstract and discussion would change. Likely framing: Catholic in-group odds elevated; non-Catholic in-group odds not detectably elevated; MDH direction not supported; Other Religion uninformative (9 nominations).

---

## 10. Session notes, 2026-10-23 (second session)

The methods rationale and recommendations are in `METHODS_SUMMARY_2026-10-23.md`. Read it before designing new analyses.

### 10.1 Data added (provenance in `Data/README.md`)
- `Data/AlterAlterEdgeList.csv`: MD5 `a55a32c387ab057f30aff9531b4ed366`; 174,748 records (35,890 ego-alter; 138,858 alter-alter); 709 egos; waves 1–8. Codebook: `Data/AlterAlterEdgeList_codebook.pdf` (MD5 `019091221d1a3791ef16df4c615ee741`).
- Loader `Code/load_alter_alter_edgelist.R`: `load_alter_alter_edgelist(type = c("all", "alter_alter", "ego_alter"))`. Refuses a file whose MD5 differs. Validates counts, wave counts, distinct IDs, duplicates, and pair structure. Tested in an isolated environment, where a tampered copy was refused.
- `Data/NetWorkSurvey.csv` (MD5 `eb7c31002f7ce0360ce9a5bac775faa3`) and `Data/BasicSurvey.csv` (MD5 `db97dbc53768b3f8f4526886e5a43347`) match the current release. `NetWorkSurvey.csv` has 35,912 rows; 22 repeat an existing (egoid, alterid, wave), leaving 35,890 unique nominations.

### 10.2 Exploratory results (console only; re-create as scripts before citing)
- Group flows, shares, implied odds ratios, Monte Carlo summaries, and within-cohort counts: see `METHODS_SUMMARY_2026-10-23.md`. Simulation seed 4815 is the corrected run. Seed 7418 is superseded (activity rates used headcount × waves).
- Participation: observed ego-waves (at least one nomination) fall from 400 in Wave 3 to 185 in Wave 8. No Religion has 178 of 1,870 observed ego-waves (9.5%) in Waves 3–8, against 12.4% of the cohort.
- Recruitment sensitivity: excluding tier 2 moves cohort shares by at most 0.6 points; in-study-only moves them by at most 0.2.
- Naming cap: 32 of 1,875 ego-waves (1.7%, Waves 3–8) reached 25 names.

### 10.3 Requested next tasks (A run in exploratory form on 2026-10-23; see Section 11)

**(A) Within-cohort model (baseline-free check on the cohort result).**
- Roster: 722 egos in `BasicSurvey.csv`. Religion `yourelig_1` (718 with one of the four groups). In-study: `StudyStatus == "In Study"` (698). Tier 2: `Tier == "Tier 2"` (94 in study).
- Sociomatrix, per wave: rows are responding ego-waves (an ego with at least one nomination in the wave; 1,870 in Waves 3–8, for egos in the four groups). Columns are the other 721 roster egos (about 1.35 million dyads). y_ij = 1 if ego j's `egoid` appears in ego i's `alterid` list for that wave.
- The reverse dyad y_ji is observed only if j responded in that wave. Treat it as missing otherwise, not zero.
- Specification as requested: ego fixed effects; alter fixed effects; same-religion effects by ego group; a reciprocity term; two-way clustering by ego and alter; wave handling (to decide); tier-2 exclusion (drop tier 2 egos from the roster on both sides; the alternative is dropping ties that involve them); robustness check on in-study egos only.
- Check installed packages before fitting. Installs need approval (Section 9, item 1).
- The Other Religion cell has 9 same-religion within-cohort ties, so expect wide intervals.

**(B) Alter–alter closure controls (campus-wide model, Waves 3–8).**
- For ego i, wave w, and alter j: `mutual_alters = #{k in N_iw, k != j : {j, k} in AA_iw}`. N_iw is the set of alters the ego named in that wave (`NetWorkSurvey.csv`). AA_iw is the set of alter-alter records for that ego and wave (loader, `type = "alter_alter"`). Treat absent pairs as zero.
- Redundancy: "mutual alters" and "the alter's degree among the ego's named alters" are the same variable within an ego-wave, because the ego is tied to every named alter and every alter-alter record has both alters named by that ego. Include one. Optional normalization: divide by (|N_iw| − 1).
- A different measure would pool an alter's degree across egos' reports, using global IDs. That was not requested. Confirm before building it.
- Purpose: Reviewer 2's point that network processes amplify homophily (Moody 2001; Wimmer and Lewis 2010, as cited in the reviewer comments). Use as robustness columns in Models 2–3 under both baselines. Describe as descriptive controls.
- Ego-waves with one named alter have no pairs, so the control is zero there. Check sensitivity to excluding them.

### 10.4 Decisions needed from the user
- Sign off on or reject the headcount-primary proposal (Section 9, item 11).
- Confirm the closure-control definition (item 13).
- Decide on commits (item 14).

---

## 11. Session notes, 2026-10-23 (third session)

Status: the exploratory within-cohort analysis (Section 10.3A) runs on Hoffman2. Nothing here is in the manuscript, the pipeline run order, or a commit.

### 11.1 Hoffman2 setup and job history
- Remote mirror: `~/religious-homophily/` with `Code/`, `Data/` (`BasicSurvey.csv`, MD5 `db97dbc…`; `NetWorkSurvey.csv`, MD5 `eb7c310…`), and a `.here` root marker so `here()` resolves there. Global Hoffman rules: `~/.config/agents/AGENTS.md` (Supercomputing section).
- Job script `Code/submit_12_within_cohort_choice_model.sh`: `-pe shared 1`, `h_data=8G`, `h_rt=23:50:00`; loads `gcc/10.2.0` then `R/4.2.2`; sets `R_LIBS="$HOME/R/religious-homophily-lib"`; installs any missing `dplyr` (≥ 1.1.0), `tidyr` (≥ 1.0.0), `here`, or `survival` (≥ 3.0.0) into that library; then runs the script. Submit from the project directory with `qsub`.
- Jobs: 15254804 failed (no `dplyr` on the gcc10 library path). Two earlier attempts failed on `readr`/`bit64`. 15254921 completed (exit 0; 689 s; 1.9 GB). 15255017 completed (exit 0; 628 s; 2.0 GB) and produced the current `Data/within_cohort_choice_models.RDS`. 15255991 (fixest install) failed with exit status 1 after 1,169 s, and fixest was not installed. The log shows the cause: `Rcpp` 1.1.2 in `~/R/x86_64-pc-linux-gnu-library/4.5` was built for R 4.5.1, so loading it under R 4.2.2 fails with `undefined symbol: R_getVarEx`. `install.packages` saw that copy as installed and did not install a compatible one. The dependency chain then failed (curl, RcppArmadillo, collapse, MatrixModels, pander, stringmagic, and so dreamerr). The job library `~/R/religious-homophily-lib` now holds about 65 packages from that attempt, including `lfe` and `emmeans` (both fixest Suggests), plus a `00LOCK-plm` directory from an interrupted `plm` install. That lock directory had already gone when job 15255991 exited, so no manual removal was needed.
- Job 15256131 (fixest install, with `R_ENVIRON_USER=/dev/null`): exit 0; 735 s; 2.3 GB. `fixest` 0.14.2 is in `~/R/religious-homophily-lib` (built for R 4.2.2), and the two-way clustering smoke test passed. The library also holds Suggests-chain packages (`lfe`, `emmeans`, `plm`). `MatrixModels`, `nloptr`, and `curl` failed to build and are not installed.
- `~/R/x86_64-pc-linux-gnu-library/4.5` (set by `~/.Renviron`) holds `readr`, `here`, and their dependencies from the first attempts. It holds your R 4.5.1 packages (for example Rcpp 1.1.2, which causes the conflict) as well as R 4.2.2 builds of `readr` and `here`. Do not remove it.
- No `qdel` was run.

### 11.2 Sample and designs
- Roster: in-study Tier 1 and Tier 3 egos with religion, gender, race, and first-year hall (`reshallyear1`) known: 595 egos (430 Catholic, 73 No Religion, 28 Other Religion, 64 Protestant). Tier 2 is excluded from the primary models. Waves 3–8.
- Responding ego-waves (at least one nomination of any type): 1,673. Candidate dyads: 993,740. Nominations among candidates (non-family): 2,752.
- Ego-stratified (ES): stratum = ego-wave; candidates = other roster members. Alter popularity is modeled through alter-group indicators and leave-own-out log in-degree.
- Alter-stratified (AS): stratum = alter-wave (3,570 strata; 1,769 contain at least one nomination). Alter popularity is absorbed by design. Ego activity enters as log out-degree.
- Estimation: `survival::clogit` (exact) for point estimates. Ego-clustered SEs from `coxph(…, cluster(egoid), ties = "breslow")`. Exact-vs-Breslow gaps are ≤0.02 for the same-religion and popularity terms in AS_A and ES_D_no_recip, and about 1.9 for reciprocity models.
- `alterid` is the roster `egoid` (stable across waves), so roster members are both choosers and targets.

### 11.3 Results (log-odds; ego-clustered Breslow SE; exploratory)

| Model | Catholic in-group | Non-Catholic in-group | Non-Catholic minus Catholic |
|---|---|---|---|
| AS_A: alter-stratified, no reciprocity | 0.58 (0.19) | −0.01 (0.20) | −0.60 (0.34); 95% CI −1.27 to 0.07; p = 0.08 |
| ES_D_no_recip: ego-stratified, alter-group terms and log in-degree | 0.56 (0.19) | 0.03 (0.21) | not computed |
| ES_D_primary: as above, with reciprocity | 0.55 (0.18) | −0.01 (0.21) | −0.56 (0.34) |
| ES_E_no_recip: no alter-group terms; log in-degree kept | 0.15 (0.09) | 0.43 (0.15) | not computed |
| ES_E_no_alter_groups: as above, with reciprocity | 0.15 (0.09) | 0.35 (0.17) | +0.20 (0.19) |

- Group-specific (AS_C, no reciprocity): No Religion 0.08 (0.29); Other Religion 1.08 (0.66; 9 same-religion nominations); Protestant −0.24 (0.28). Catholic in-group in this model 0.60 (0.19).
- Alter popularity (ES_D_no_recip, relative to Catholic alters): Protestant 0.60 (0.18); No Religion 0.33 (0.16); Other Religion 0.00 (0.29). Log in-degree 0.32 (0.06).
- Reciprocity (ES): log-odds 6.5 (SE 0.14), an odds ratio of about 700; `recip_obs` −0.38 (0.08). In AS, reciprocity cannot be estimated (Section 8).
- ES_G (Tier 2, with reciprocity) hit the iteration limit and is not reported. AS with Tier 2 was not run.
- Observed vs headcount-expected same-religion share among ES nominations: Catholic 0.770 vs 0.722; No Religion 0.157 vs 0.121; Other 0.097 vs 0.046; Protestant 0.153 vs 0.106.
- Residence and race: 49.2% of nominations go to same-first-year-hall candidates, vs 3.8% of candidates. All 29 halls are single-sex. Religion does not cluster by hall (same-religion rate 0.555 within halls vs 0.551 across). Same race: 59.7% of nominations vs 46.6% of candidates. Raw gender homophily (73.5% vs 50.0%) disappears once hall is in the model (AS_A gender −0.02, SE 0.11).

### 11.4 Measurement (roster ties with both reports; n = 3,213)
- Ego-reported vs alter's self-report agreement: 87.1% (wave-1 self-report); 88.6% with same-wave self-report for waves 7–8 (n = 370).
- Self-reported No Religion alters recorded as Catholic: 105 of 329 (32%).
- Same-religion rate, self-report vs ego report: Catholic 0.797 vs 0.818 (n = 2,368); No Religion 0.198 vs 0.243 (n = 288); Other 0.078 vs 0.148 (n = 115); Protestant 0.136 vs 0.167 (n = 442).
- On the odds scale, ego reports raise same-religion odds by about 14% for Catholics, about 30% for No Religion and Protestant, and about 105% for Other. The campus-wide ego-reported outcome therefore probably inflates non-Catholic in-group odds relative to Catholic ones. That is the direction of MDH. It reverses an earlier expectation from this session that misreporting works against MDH.

### 11.5 Interpretation, caveats, and pending work
- The chance model changes the answer. With alter popularity held fixed (AS), the Catholic in-group log-odds is 0.58 and the non-Catholic one is near zero. The headcount-type model gives 0.15 and 0.43. Protestant alters draw about 1.8× the odds of Catholic alters per candidate after adjustment. Headcount-primary (R1) is therefore not supported in this roster.
- Current reading (not signed off): Catholic students nominate co-religionists at elevated odds relative to other roster members (odds ratio about 1.7–1.8 in both the popularity-adjusted and popularity-free designs). Non-Catholic students show no detectable excess (odds ratio about 1.0). The minority-minus-majority contrast is negative and imprecise (95% CI for the odds ratio 0.28 to 1.08), so the data do not support the MDH direction.
- Caveats: the roster covers about 36% of analytic ties; minority groups are small (73 No Religion, 28 Other, 64 Protestant egos); Other Religion has 9 same-religion nominations; religion is wave-1 for waves 3–6; first-year hall is a time-invariant proxy for residence in waves 3–8; responding egos are the only choosers.
- Pending (updated 2026-10-23, fourth session): (a) WC-AS-v1 has run (Section 0, fourth-session bullet); (b) the two-way variance is implemented and validated, and M1 passes C1–C4. Results are in plan Section 13 and are not confirmatory. The rest of the original line is superseded.
- Commits: the plan (`b90623f`) and the memory and checklist (the next commit). No manuscript or Overleaf changes.

### 11.6 Files created or changed this session
- Exploratory: `Code/12_within_cohort_choice_model.R`; `Data/within_cohort_choice_models.RDS` (output of job 15255017, including fit warnings and exact-vs-Breslow gaps).
- Hoffman2 setup: `Code/submit_12_within_cohort_choice_model.sh`, `Code/submit_install_fixest.sh`, `Code/check_fixest_install.R` (synthetic two-way clustering check).
- Plan written: `.posit/assistant/plans/2026-10-23-1510-preregistration-alter-stratified.md` (WC-AS-v1; not executed; see item 18).
