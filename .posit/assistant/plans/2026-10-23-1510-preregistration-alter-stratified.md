# Pre-registration plan WC-AS-v1: alter-stratified within-cohort analysis of religious nomination odds

- Plan ID: WC-AS-v1
- Written: 2026-10-23, 15:10 PDT (first committed after sign-off; see O6)
- Status: written and frozen for the two-way inference step. Not executed. Not a confirmatory pre-registration (Section 0).
- Scope: NetHealth roster (Tier 1 and Tier 3, in study), waves 3–8. Campus-wide analyses are out of scope.
- Companion files at writing (md5):
  - `Code/12_within_cohort_choice_model.R`: 3748179424f8ac857476768ed6cd9410. This is the exploratory version that produced job 15255017. It does not yet implement this plan.
  - `Code/submit_12_within_cohort_choice_model.sh`: df6ffcfe3bf123202af45fbcf98cb73d
  - `Data/within_cohort_choice_models.RDS`: 9eb46649c7ae86362105764f6a0aa7b7 (exploratory output; not to be overwritten)
  - `Data/BasicSurvey.csv`: db97dbc53768b3f8f4526886e5a43347 (matches `Data/README.md`)
  - `Data/NetWorkSurvey.csv`: eb7c31002f7ce0360ce9a5bac775faa3
- Git at writing: HEAD 3d86b05 on `my-new-branch`. This plan, the new scripts, and the results file are uncommitted.

## 0. Status and provenance

This plan freezes the inference method, the decision rules, and the sensitivity list before the two-way clustered inference is computed. It does not make the primary contrast confirmatory. The primary contrast was observed before this plan was written, under one-way ego-clustered standard errors (job 15255017, 2026-10-23). The alter-stratified design was chosen after the ego-stratified popularity sensitivity appeared. The NetHealth release here holds waves 1–8 only, so no independent data exist for confirmation. Anything not listed in this plan is exploratory.

Results observed before this plan (log-odds ratios; ego-clustered Breslow standard errors; roster of 595):

| Quantity | Estimate (SE) | Model |
|---|---|---|
| θ_C, Catholic in-group | 0.58 (0.19) | M1 |
| θ_N, non-Catholic in-group | −0.01 (0.20) | M1 |
| Δ = θ_N − θ_C | −0.60 (0.34); CI −1.27 to 0.07; p = 0.08 | M1 |
| θ_C, θ_N | 0.56 (0.19), 0.03 (0.21) | S1 |
| Δ | −0.56 (0.34) | S3 (SEs invalid; see 5.4) |
| θ_C, θ_N | 0.15 (0.09), 0.43 (0.15) | S4 (headcount-type) |
| same_C, same_NR, same_OR, same_P | 0.60 (0.19), 0.08 (0.29), 1.08 (0.66), −0.24 (0.28) | S5 |
| Alter popularity vs Catholic alters: Protestant, No Religion, Other | 0.60 (0.18), 0.33 (0.16), 0.00 (0.29) | S1 |

Other facts observed before this plan:
- Reciprocity. The ego-stratified log-odds is 6.53 (SE 0.14). In the alter-stratified design the reciprocity-only exact MLE does not converge (the fit reaches 24.3), and `recip_obs` is collinear with the alter-wave strata. Reciprocity is therefore excluded from M1.
- Breslow approximation. For M1 and S1, the exact-versus-Breslow gaps for focal terms are 0.003–0.018. In the reciprocity models the gap is about 1.9, so those standard errors are unusable.
- Measurement. Ego-reported alter religion matches the alter's own report on 87.1% of 3,213 roster-nominated ties. 32% of self-reported No Religion alters are recorded as Catholic. Ego reports raise same-religion rates in every group.
- Residence. 49.2% of nominations go to same-first-year-hall candidates, against 3.8% of candidates. All 29 halls are single-sex. Religion does not cluster by hall: the same-religion rate is 0.555 within halls and 0.551 across halls.
- Fixest. At 15:10 PDT on 2026-10-23, Hoffman2 job 15255991 (the fixest install) was still running. Its log shows failed builds or loads of curl, RcppArmadillo, collapse, MatrixModels, pander, and stringmagic. dreamerr depends on stringmagic, so At that time, fixest could not install. The root cause was a library conflict: `Rcpp` 1.1.2 in `~/R/x86_64-pc-linux-gnu-library/4.5` was built for R 4.5.1 and fails to load under R 4.2.2 (`undefined symbol: R_getVarEx`). The fix was applied, and fixest 0.14.2 installed on Hoffman2 (job 15256131), with a passing two-way clustering smoke test (Section 14). M1 does not depend on fixest (5.3).

Interpretive consequence, stated before the run: with a standard error of about 0.34 for Δ, a 95% interval excludes zero only if |Δ| exceeds about 0.67 (1.96 × 0.34). An inconclusive outcome is therefore the expected default.

## 1. Question and estimands

Question. Among roster members, do Catholic students nominate co-religious roster members at higher odds than other students do, relative to the same comparison among non-Catholic students, after conditioning on target-wave availability and nominator activity?

Estimands, all from M1 (Section 4):
- θ_C: the coefficient on `same_C`, the same-religion log-odds ratio for Catholic nominators.
- θ_N: the coefficient on `same_nonC`, the pooled same-religion log-odds ratio for non-Catholic nominators (Protestant, No Religion, and Other Religion together).
- Δ = θ_N − θ_C.

Each coefficient compares a nominator's odds of nominating a same-religion target with their odds of nominating a different-religion target, within the target-wave stratum. The target's popularity is absorbed by the stratum, and the nominator's activity is controlled by `log_outdeg`.

Hypotheses. MDH (minority distinctiveness) predicts Δ > 0. MEH (majority exclusiveness) predicts Δ < 0.

Interpretive limit. The estimands describe a pattern of nominations, conditional on roster membership, Tier 1/3 selection, wave-1 religion, and first-year hall. They are not preferences or causes (Reviewer 2).

## 2. Sample

- Roster (choice set): BasicSurvey egos with `StudyStatus == "In Study"`, `Tier` in {Tier 1, Tier 3}, `yourelig_1` in {Catholic, No Religion, Other Religion, Protestant}, and non-missing `gender_1`, `race_1`, and `reshallyear1`. Observed: 595 egos (430 Catholic, 73 No Religion, 28 Other Religion, 64 Protestant).
- Waves: 3 through 8.
- Choosers: roster members with at least one nomination of any type in wave w (NetWorkSurvey). Ego-waves with no nominations are treated as non-responses. This cannot be distinguished from a true zero (Section 11).
- Targets: every roster member in every wave, whatever their response status.
- Risk set: all pairs (i, j, w) with i a chooser in wave w, j in the roster, and j ≠ i. Pairs where i's nomination of j is a family nomination are removed.
- Outcome: y = 1 if i nominated j as a non-family alter in wave w.
- Strata: alter-wave (j, w). Strata without events drop out of the conditional likelihood.
- Exclusions: egos lacking gender, race, or first-year hall (complete case). The number excluded is reported. Tier 2 is excluded from M1 and included in S2.
- Observed counts (2026-10-23 run): risk-set rows 993,740; events 2,752; alter-wave strata 3,570, of which 1,769 contain an event; responding ego-waves 1,673.

## 3. Variables (as coded in the scripts)

| Name | Definition |
|---|---|
| `rel_i`, `rel_j` | `yourelig_1` for nominator and target (wave-1 self-report, used in all waves) |
| `same_C` | 1 if rel_i = Catholic and rel_j = Catholic |
| `same_nonC` | 1 if rel_i ≠ Catholic and rel_i = rel_j |
| `ego_NR`, `ego_OR`, `ego_P` | Nominator-group indicators (reference: Catholic) |
| `log_outdeg` | log of the number of nominations i made in wave w, all alter types (at least 1 for choosers) |
| `same_gender` | `gender_1` matches |
| `same_race` | `race_1` exact category match |
| `same_hall` | `reshallyear1` matches (first-year residence hall; time-invariant) |
| `alt_NR`, `alt_OR`, `alt_P` | Target-group indicators (reference: Catholic); used in S1 and S3 only |
| `log_indeg` | log(1 + number of other roster choosers who nominated j in wave w), leave-own-out; used in S1, S3, S4 |
| `recip`, `recip_obs` | Target nominated i in wave w; target responded in wave w; used in S3 only |
| `same_NR`, `same_OR`, `same_P` | Same-religion indicators for each non-Catholic group; used in S5 only |

## 4. Models

All models use the inference in Section 5. Stratum conventions: M1, S2, and S5 are alter-stratified. S1, S3, and S4 are ego-stratified (stratum = chooser-wave; candidates = other roster members).

- M1 (primary): `same_C + same_nonC + ego_NR + ego_OR + ego_P + log_outdeg + same_gender + same_race + same_hall`. Conditional logit, stratum = alter-wave, roster Tier 1/3.
- S1 (popularity-adjusted, no reciprocity; ego-stratified): `same_C + same_nonC + alt_NR + alt_OR + alt_P + same_gender + same_race + same_hall + log_indeg`.
- S2 (Tier 2 included): M1 on the roster of Tier 1, Tier 2, and Tier 3.
- S3 (popularity-adjusted, with reciprocity; ego-stratified): S1 plus `recip + recip_obs`. Point estimates only (5.4, C5).
- S4 (headcount-type; ego-stratified): `same_C + same_nonC + same_gender + same_race + same_hall + log_indeg`. It has no alter-group indicators, so group popularity is set to zero by construction. It is a reference model for the chance-model sensitivity, not a claim.
- S5 (group-specific; alter-stratified): `same_C + same_NR + same_OR + same_P + ego_NR + ego_OR + ego_P + log_outdeg + same_gender + same_race + same_hall`. Descriptive (decision rule D6).
- S10 (optional): `fixest::feols` with two-way fixed effects and two-way clustering, on the linear probability scale. Run only if fixest installs. It is a labelled robustness check, not a log-odds estimate.

Deferred (not run in the first execution; each needs an amendment in Section 14):
- S6: same-wave religion for waves 7–8 (`yourelig_7`, `yourelig_8`), with a wave-1 fallback and counts of fallbacks.
- S7: closure controls from observed roster nominations (requires confirmation of the definition).
- S8: religion × `same_hall` interaction.
- S9: bootstrap check of the two-way standard errors (ego-cluster and two-way cluster bootstrap).

## 5. Inference

5.1 Point estimates. Exact conditional maximum likelihood (`survival::clogit`, exact method).

5.2 Variance. Two-way cluster-robust variance after Cameron, Gelbach and Miller (2011), computed from the Breslow Cox form of the same model:
- `V0` = `fit$naive.var` from `coxph(Surv(time1, y) ~ <terms> + strata(stratum) + cluster(egoid), ties = "breslow")`.
- `U` = per-observation score residuals, `residuals(fit, type = "score")`.
- For each dimension c, `M_c` = the sum over clusters g of `U_g U_gᵀ`, where `U_g` is the sum of `U` over the rows in cluster g. The dimensions are the ego (`egoid`), the alter (`alt_egoid`), and the dyad (the pair `egoid`, `alt_egoid`).
- `V_two = V0 (M_ego + M_alter − M_dyad) V0`, and `SE = sqrt(diag(V_two))`.
- One-way check: `V_ego = V0 M_ego V0`. It must reproduce the variance `coxph` reports with `cluster(egoid)` (C2).

5.3 Why not fixest for M1. `fixest::feglm` is the unconditional fixed-effects logit. Alter-wave strata average about 0.8 nominations each, which is the sparse regime where that estimator is biased. It is therefore not used for any point estimate in this plan. `fixest::feols` is a linear probability model and estimates a different quantity; it appears only as optional S10. Fixest was not installed on Hoffman2 at 15:10 PDT on 2026-10-23 (Section 0), so M1 inference does not depend on it.

5.4 Validity checks. Each must pass before any standard error is used in a claim.
- C1 (approximation): for the focal terms (`same_C`, `same_nonC`, `same_NR`, `same_OR`, `same_P`, `alt_NR`, `alt_OR`, `alt_P`), |exact − Breslow| ≤ 0.05.
- C2 (implementation): max |V_ego − vcov(coxph)| ≤ 1e-8, on the real data and in the simulated test in Section 8.
- C3 (positive semidefinite): `V_two` is symmetric, and its minimum eigenvalue is ≥ −1e-10.
- C4 (convergence): no `clogit` or `coxph` warnings for M1.
- C5 (reciprocity): S3 standard errors are never used in a claim.

5.5 Fallback. If C2 or C3 fails, two-way standard errors are not reported as inferential. The fallback is S9 (bootstrap), which must be run and reported before any claim.

5.6 Assumptions. There are several hundred choosers and 595 targets, which is adequate for CGM but not large. Intervals use normal critical values (1.96), with no small-sample adjustment. The Breslow approximation is checked by C1.

## 6. Decision rules

These are pre-specified. They apply to M1 unless stated otherwise.

- D1 (primary). Let [L, U] be the two-way 95% interval for Δ.
  - If L > 0: "non-Catholic in-group odds exceed Catholic in-group odds (MDH direction)."
  - If U < 0: "Catholic in-group odds exceed non-Catholic in-group odds (MEH direction)."
  - Otherwise: "inconclusive."
  Each statement is conditional on the design in Section 1.
- D2 (Catholic in-group). Report "Catholic in-group odds are elevated" only if the lower bound of the two-way interval for θ_C exceeds 0. Otherwise report the interval.
- D3 (non-Catholic in-group). Report "no detectable non-Catholic in-group excess" only if the two-way interval for θ_N includes 0. Report its upper bound as an odds ratio. No equivalence claim is made, because no margin is pre-specified (O3).
- D4 (agreement with S1). S1 agrees with M1 if θ_C and θ_N have the same signs in both models and D1 gives the same category for both (D1 is applied to S1 for this comparison only).
- D5 (p-values). Reported descriptively. They do not enter D1–D3.
- D6 (multiplicity). The primary family is {D1}. D2 and D3 concern separate estimands and are reported without adjustment. S5 contrasts are descriptive. If any of them is reported as inferential, apply Holm across the three.
- D7 (small groups). Any statement about Other Religion must give its sample size (28 egos) and its same-religion count (9 nominations).

## 7. Overlap audit

Report the following, as counts and percentages, in the run output before the model results are read:
- targets in the risk set, and targets receiving at least one nomination;
- choosers (egos with at least one nomination in some wave), and choosers who are also targets (the crossed structure, since every target is a roster member);
- ego–target pairs in the risk set, pairs with at least one nomination, and pairs nominated in two or more waves;
- dyad-periods (rows) and nominations, and the share of nominations on repeated pairs.

## 8. Implementation and tests (before the run)

8.1 Write `Code/cluster_vcov.R` with base-R functions: `cluster_meat(score, cluster)`, `one_way_vcov(score, naive_var, cluster)`, `two_way_vcov(score, naive_var, cluster_a, cluster_b)` (the dyad cluster is the paste of the two ids), and `min_eigenvalue(V)`.

8.2 Write `Code/test_cluster_vcov.R`. All tests must pass locally before the full run.
- T1: OLS with two cluster columns. `two_way_vcov` equals `sandwich::vcovCL(fit, cluster = <data frame of the two columns>, type = "HC0", cadjust = FALSE)` to 1e-10.
- T2: OLS with one cluster. `one_way_vcov` equals `vcovCL(..., cluster = ego, type = "HC0", cadjust = FALSE)`.
- T3: with a singleton second cluster (every row is its own alter), `two_way_vcov` equals `one_way_vcov` by ego.
- T4: `two_way_vcov` is symmetric in its two cluster arguments.
- T5: `cluster_meat` equals the explicit sums over clusters.
- T6: simulated stratified data fit with `coxph` (Breslow, strata, cluster). `one_way_vcov(residuals(fit, "score"), fit$naive.var, egoid)` equals `vcov(fit)` to 1e-8.

8.3 Revise `Code/12_within_cohort_choice_model.R` so that it runs M1, S1, S2, S3, S4, S5, and S10 (if available). For each model it stores the exact point estimates, the one-way and two-way standard errors, the results of C1–C5, the fit warnings, the exact-versus-Breslow gaps, and the sample sizes. It computes D1–D4 automatically, writes the overlap audit, and writes to a new output file (Section 9). The exploratory output is not overwritten.

8.4 Smoke test on the reduced sample (`WITHIN_COHORT_SMOKE=1`) must complete before the full run.

8.5 Freeze. Record the md5 of `cluster_vcov.R`, `test_cluster_vcov.R`, the revised `12_within_cohort_choice_model.R`, and the submit script in Section 13 before the full run. The exploratory script at writing (md5 3748179424f8ac857476768ed6cd9410) does not implement this plan.

## 9. Run procedure

- Environment: Hoffman2. Submit with `qsub` from `~/religious-homophily`. Grid Engine settings: `-pe shared 1`, `-l h_data=8G`, `-l h_rt=23:50:00`. R: `module load gcc/10.2.0`, then `module load R/4.2.2`. `R_LIBS=$HOME/R/religious-homophily-lib`.
- Log: a unique `-o` name for each run, for example `wc-as-v1_<YYYYMMDD>.log`.
- Output: `Data/within_cohort_preregistered_<YYYYMMDD>.RDS` on Hoffman2, copied back to the project with rsync in the background. The exploratory file `Data/within_cohort_choice_models.RDS` is not overwritten.
- Record in Section 13: the job ID, the `qacct` exit status, wall-clock time, peak memory, and the output checksum.
- Preconditions: O1–O6 are signed off or their defaults are recorded; the tests in 8.2 and the smoke test in 8.4 pass; checksums are frozen (8.5).
- The full dyad table is not run locally. The local session has run out of memory on it before.

## 10. Reporting rules

- Report the Δ, θ_C, and θ_N of M1 with their two-way 95% intervals. One-way ego intervals appear only in a comparison column.
- Report the D1–D3 wording exactly as defined.
- Report S1–S5 (and S10 if run) with their own intervals, whatever their direction. Report S3 as point estimates only.
- Report C1–C5, the exact-versus-Breslow gaps for every model, and the overlap audit.
- Report group sizes, including Other Religion (28 egos; 9 same-religion nominations).
- Use "pattern of nominations" wording. Do not use "preference", "cause", or "generalizes to the campus".
- Describe any interval that includes zero as "not distinguishable from zero", giving the interval. Do not describe it as evidence of no difference.
- This plan makes no statement about the campus. The campus-wide headline is re-estimated separately (AGENTS.md, Section 9, item 22).

## 11. Limitations

- The roster covers Tier 1/3 in-study students, about 36% of the analytic ties in the campus-wide analysis. Results do not extend to non-surveyed students or to the campus.
- Minority groups are small: 73 No Religion, 28 Other Religion, and 64 Protestant egos.
- Religion is the wave-1 self-report for all waves. Some responders changed religion by wave 8 (S6 is deferred).
- First-year hall is a time-invariant proxy for residence in waves 3–8. Its association with nominations is large, so its measurement matters for interpretation.
- Non-response is treated as zero nominations, and responders are the only choosers. Whether non-response is related to religion cannot be tested here.
- Standard errors rely on the Breslow approximation (C1) and on cluster-robust asymptotics with several hundred choosers and 595 targets.
- Several specifications were examined before this plan (Section 0). Inferences are conditional on the frozen design.

## 12. Decisions needed before the run

Signed off by the user on 2026-10-23 (after the 15:34 PDT memory updates), at the user's instruction. The defaults below are adopted. Scope notes are included where they apply.

- O1 (primary inference). Default: custom two-way CGM variance, as in Section 5. Alternative: fixest::feols as the primary. That would change the estimand (a linear probability model) and require an amendment. fixest::feols stays as the optional S10 check (fixest 0.14.2 is installed; job 15256131).
- O2 (primary model). Default: M1 (alter-stratified) is primary. Headcount as the primary chance model (R1) is dropped.
- O3 (equivalence margin). Default: none. If you want claims of the form "no excess above odds ratio x", give x before the run.
- O4 (Tier 2). Default: S2 runs in the first execution.
- O5 (deferred items). Default: S6–S9 stay deferred. S7 needs its definition confirmed.
- O6 (timestamp). Default: optional. Committing this plan before the run gives a timestamp that can be checked.

## 13. Execution record (to be completed)

- Plan frozen: 2026-10-23, 15:10 PDT (file time at freezing). First committed on 2026-10-23, after sign-off; the hash is in AGENTS.md (Section 0).
- Checksums at freeze: `cluster_vcov.R` [pending]; `test_cluster_vcov.R` [pending]; `12_within_cohort_choice_model.R` [pending]; submit script [pending].
- Tests (8.2): [pending].
- Smoke test (8.4): [pending].
- Full run: job ID [pending]; `qacct` exit status [pending]; wall-clock time [pending]; peak memory [pending]; output checksum [pending].
- Results and decisions D1–D4: [pending].

## 14. Deviations and amendments

Correction (2026-10-23, after freezing, before any run): added the root cause of the fixest install failure to Section 0. This is factual background only, with no analysis change. No other deviations at writing.
Correction 2 (2026-10-23, after freezing, before any run): the fixest status in Section 0 is superseded. fixest 0.14.2 installed on Hoffman2 in job 15256131, after the `R_ENVIRON_USER=/dev/null` fix, and its two-way clustering smoke test passed. The analysis design is unchanged.
Correction 3 (2026-10-23, after freezing, before any run): decisions O1–O6 in Section 12 are signed off at the user's instruction, with the defaults. O2 covers the within-cohort plan only; the campus-wide chance-model framing (AGENTS.md, Section 9, item 11) is not covered. O6: the plan was committed on 2026-10-23, after sign-off. The commit hash is recorded in AGENTS.md (Section 0). No analysis change. Any change after freezing, including changes to samples, variables, models, or decision rules, is logged here with the date, the reason, and whether results had been seen.
