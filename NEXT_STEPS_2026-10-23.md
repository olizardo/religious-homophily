# Next steps: religious homophily project

Last updated 2026-10-23 (third session). Companion to `AGENTS.md`: Section 9 lists the open items, and Section 11 holds the third-session notes. Tick items here, and record finished steps in `AGENTS.md`.

Owner tags: **[user]** needs your decision or action. **[assistant]** is an analysis or coding step.

## 1. Finish the fixest install (Hoffman2 job 15255991)

- [x] [assistant] Check the job with `qstat -u olizardo` and `qacct -j 15255991` (done 15:10 PDT: still running, with a library conflict; the job later failed, and job 15256131 succeeded after the fix). The log is `~/religious-homophily/install_fixest.log`.
- [x] [assistant] Confirm that the log prints `fixest installed:` with a version, and that the smoke test prints `two-way clustering smoke test passed` (done: job 15256131, fixest 0.14.2).
- [x] [assistant] If the install failed, diagnose it from the log. Cause found (AGENTS.md Section 11.1): `Rcpp` 1.1.2 in `~/R/x86_64-pc-linux-gnu-library/4.5` was built for R 4.5.1 and fails under R 4.2.2. Background: fixest 0.14.2 needs R 3.5.0 or later on CRAN. Its Imports include `sandwich`, `dreamerr` (1.4.0 or later), `stringmagic` (1.2.0 or later), `nlme`, `numDeriv`, and `Rcpp` (1.0.5 or later). Some newer dependencies may require R 4.3 or later, as `bit64` did.
- [x] [user] Approve the fix: set `R_ENVIRON_USER=/dev/null` in the install script, delete the leftover `00LOCK-plm` directory in `~/R/religious-homophily-lib`, and resubmit. (Done. The lock directory had already gone, and job 15256131 succeeded.)
- [x] [assistant] Record the version and outcome in `AGENTS.md` (Section 9, item 1, and Section 11.1).

## 2. Two-way ego/alter clustering (requested 2026-10-23)

- [x] [user] Choose the estimator for the two-way standard errors. Signed off 2026-10-23 as the custom CGM variance (plan O1). fixest::feols stays as the optional S10 check. Options, for the record:
  - (a) `fixest::feols` (linear two-way fixed effects) with two-way clustering, as a robustness check. The slope has no incidental-parameter bias here, unlike the logit.
  - (b) A custom Cameron–Gelbach–Miller variance for the conditional logit, built from score residuals and `coxph`'s naive variance. Validate it against `sandwich::vcovCL` (OLS) and `coxph`'s one-way robust variance before use.
- [ ] [assistant] Do not use `fixest::feglm` for the primary coefficients. It is the unconditional fixed-effects logit. The alter-wave strata average about 0.8 nominations each, which is the sparse regime where it is biased.
- [ ] [assistant] Implement the chosen method. Add unit tests for any new utility function (global guidance).
- [ ] [assistant] Run it on Hoffman2 with a unique log name. Record the job ID and exit status (`qacct -j`) in `AGENTS.md`.
- [ ] [assistant] Audit overlap in the alter-stratified sample: crossed alters, ego–alter pairs, and dyad-periods, as counts and percentages.
- [ ] [user] Decide on the CR2 and GEE checks (`clubSandwich`, `geepack`; Section 9, item 1). Install them locally, or run them on Hoffman2 once fixest works.

## 3. Pre-registration and sign-off

- [x] [assistant] Write the plan file in `.posit/assistant/plans/` for the alter-stratified design (done 2026-10-23 as WC-AS-v1). It should cover the sample, variables, estimand (non-Catholic minus Catholic in-group log-odds), model, inference, decision rules, sensitivity list, and reporting rules. State that the primary contrast (−0.60) was observed before the plan, so the plan cannot make it confirmatory. The NetHealth release holds waves 1–8 only.
- [x] [user] Commit the plan before the two-way run (plan O6). Committed as `b90623f` on 2026-10-23, after sign-off. The memory and checklist commit follows it. A commit is the only timestamp that would count.
- [x] [user] Sign off on the alter-stratified design as primary (`AGENTS.md`, Section 9, item 18). Signed off 2026-10-23 (plan O2).
- [x] [user] Sign off on dropping headcount as the primary chance model, R1 (item 11). Signed off for the within-cohort plan only (plan O2). The campus-wide framing in item 11 is still open.

## 4. Within-cohort sensitivity checks (not run)

- [ ] [assistant] Run the alter-stratified model with Tier 2 included, without reciprocity. The ego-stratified Tier 2 model with reciprocity hit the iteration limit and is not reported.
- [ ] [assistant] Run same-wave religion for waves 7–8 (`yourelig_7`, `yourelig_8`), using wave-1 religion otherwise. Some responders changed religion by wave 8.
- [ ] [user] Confirm the closure-control definition (item 13). Then build the closure controls from observed roster nominations.
- [ ] [assistant] Run the religion × first-year-hall interaction, to test within-hall religious homophily.
- [ ] [assistant] Document that reciprocity is not estimable in the alter-stratified design (the reciprocity-only MLE does not converge). Keep reciprocity in the ego-stratified sensitivity only.
- [ ] [assistant] Optional: run an ego-cluster or two-way bootstrap for the primary contrast, to check the analytic two-way standard errors.

## 5. Campus-wide headline and measurement

- [ ] [assistant] Re-estimate the campus-wide non-Catholic headline with self-reported religion for roster alters (about 3,200 ties). Report the change (item 22).
- [ ] [user] Until that is done, do not cite the campus-wide non-Catholic in-group result. Ego-reported religion inflates same-religion rates in every group, more in odds for minorities.
- [ ] [user] Decide whether a misclassification-corrected analysis is worth the effort. It needs the self-report validation sample.

## 6. Manuscript (only after sign-off on the design)

- [ ] [user] Decide whether the within-cohort result changes the abstract and discussion (item 23). If adopted, the framing would be: Catholic in-group odds elevated; non-Catholic in-group odds not detectably elevated; MDH direction not supported; Other Religion uninformative (9 same-religion nominations).
- [ ] [user] If this is a journal revision (the reviewer comments suggest it is), the global guidance says to write changes to a tagged file, for example `paper_R1.tex`, and keep `paper.tex` frozen. Confirm the workflow.
- [ ] [user] Complete a human read-through of Results and Discussion (item 2).
- [ ] [user] Decide whether to include the observed-offset Figure 3 (item 7).
- [ ] [assistant] Add a citation or a hedge for the dorm-assignment rationale (item 9).
- [ ] [assistant] Check that the `purta2016` citation for the 72.7% figure describes the cohort (item 10).
- [ ] [assistant] Move the discussion-frequency missingness paragraph (85/722 = 11.8%) from Results §3.3 to Methods.
- [ ] [assistant] Verify the Appendix A mixed-model claims against the literature, and propose wording for your review (2026-10-23 plan, Stage 4). Do not edit them without review.
- [ ] [assistant] Add the canonical NetHealth citations (global config, Social Signatures section 4) to any revised manuscript.

## 7. Commits, documentation, and data use

- [ ] [user] Make the remaining commit decisions (item 14): the other untracked files, `README.md`, and whether raw NetHealth CSVs belong in git.
- [ ] [assistant] Rewrite the README: sections 4 and 5, data filenames, and step numbering. Remove the Intimacy × Religion and `marginaleffects` descriptions, which are not in the code (item 4).
- [ ] [assistant] Remove the stale references to the archived `02_dyadic_models.R` (item 5).
- [ ] [assistant] Produce the number-trace file `Data/manuscript_numbers_check.csv` (item 3).
- [ ] [user] Complete the NetHealth usage form and the publication email (item 15). Not done yet.
- [ ] [user] Verify the questionnaire response options for the alter–alter item (item 16). The PDF has no text layer.
- [ ] [user] Decide whether the mutual-nomination (reciprocity) descriptive analysis is in scope (item 8).
- [ ] [assistant] Re-create the exploratory calculations as scripts before citing them (item 17).
- [ ] [user] For Overleaf, run `git fetch overleaf` and diff before any push. Push only after you approve (item 6).

## 8. Housekeeping (optional; your decision)

- [ ] [user] On Hoffman2, do not remove `~/R/x86_64-pc-linux-gnu-library/4.5`. It holds your R 4.5.1 packages (for example Rcpp 1.1.2), and `.Renviron` puts it on the search path. The `readr` and `here` installs from the first attempts are there too, and they are harmless.
- [ ] [user] On Hoffman2, decide whether to keep the copies of `BasicSurvey.csv` and `NetWorkSurvey.csv` in `~/religious-homophily/`. You approved them as public data.
- [ ] [user] Save the cross-project Hoffman2 lessons to your user memory file (`~/.posit/assistant/AGENTS.md`). The last attempt was refused because that file is outside the workspace. Open it in the editor, then ask me to retry.
- [ ] [user] Optional: `~/R/religious-homophily-lib` holds about 80 entries from the fixest attempts, including `lfe`, `emmeans`, and `plm` (Suggests of fixest). They are harmless for fixest. `MatrixModels`, `nloptr`, and `curl` did not install.
- [ ] [assistant] Decide whether the analysis job (`Code/submit_12_within_cohort_choice_model.sh`) should also set `R_ENVIRON_USER=/dev/null`. It has not been changed.
