# Methods Executive Summary: NetHealth Religious Homophily

Date: 2026-10-23. For future agents and co-authors. Read `AGENTS.md` Section 0 first. This document gives the reasoning behind the recommendations and the evidence trail.

**Status labels.** *Settled*: supported by analysis and not in dispute. *Proposed*: recommended; needs user sign-off. *Assessment*: my evaluation; holds unless new evidence appears. *Requested*: asked for by the user; not started.

## Bottom line

1. **Settled.** The Catholic/non-Catholic contrast depends on the chance model. On the 10,046-tie baseline sample, the No Religion log-odds contrast is about +0.10 under headcount and about +0.83 under nominations received.
2. **Settled.** These data cannot say which chance model is right. Group-level popularity among non-egos is not observed. The only group-level measure available is the nominations themselves, which are the outcome.
3. **Proposed.** Use headcount as the primary chance expectation, state its assumption, and report the other readings as alternatives. The 2026-10-23 co-primary framing stands until the user signs off.
4. **Assessment.** Do not generate offsets from Smith-type simulated networks.
5. **Requested.** Add a within-cohort choice model and alter–alter closure controls as robustness checks.

## R1. Chance model (opportunity offset)

**Proposed:** headcount, meaning the Wave 1 religious composition of the 718 egos with religion known (Catholic 73.1%, No Religion 12.4%, Other Religion 4.6%, Protestant 9.9%).

Why:
- It is fixed at Wave 1, so it is exogenous to the nominations being modeled.
- It is the random-respondent-pair chance expectation of case-control homophily models (Smith 2012, §4.2).
- In simulated worlds with no group-level popularity, it recovered known minority coefficients within about 0.05 (three worlds, 100 replications each). The nominations-received offset was biased upward by 0.4 to 0.8 in the same worlds.

State this assumption wherever a group contrast is reported: nominations are not weighted by group-level popularity beyond headcount. Individual activity and popularity controls leave the No Religion estimate almost unchanged (cohort −0.170 to −0.166; pool 0.553 to 0.553), so the untestable part is group-level popularity.

Alternative readings (report; do not treat as co-primary):
- **Nominations received** is outcome-dependent. It includes the same-religion nominations being modeled. 63% of analytic nominations are Catholic-to-Catholic, which dilutes minority shares.
- **Nominations made** is confounded by panel participation. No Religion egos are 9.5% of observed ego-waves against 12.4% of the cohort. About two-thirds of the shortfall is participation.

The same logic applies to every pool-based panel: the Table 2 pool null, the Table 3 pool panels, and the pool version of Figure 3.

Odds ratios of same-religion ties against each column's chance expectation (10,046-tie baseline sample, Waves 3–8, no covariates; approximate):

| Group | Observed rate | Headcount (proposed) | Nominations made | Nominations received |
|---|---|---|---|---|
| Catholic | 0.83 | 1.9 | 1.6 | 1.3 |
| No Religion | 0.23 | 2.1 | 3.2 | 3.0 |
| Other Religion | 0.15 | 3.8 | 4.6 | 6.8 |
| Protestant | 0.18 | 2.0 | 1.7 | 2.3 |

## R2. Interpreting the Catholic/non-Catholic contrast

- Headcount: No Religion vs Catholic is about +0.10 on the baseline sample, and −0.17 in the Table 1 complete-case sample. Say "not distinguishable from zero under the headcount chance model," with the interval.
- Nominations received: about +0.83. Nominations made: about +0.68.
- Parsimony (an argument, not identification): one common in-group odds ratio of about 1.9, with nomination feedback, reproduces the in-group rates for Catholic, No Religion, and Protestant students and the received composition within about one point. The received reading needs group-specific odds ratios (No Religion about 3.0, Protestant about 2.3, Catholic about 1.3). Other Religion (91 ego-waves; 19 egos in the regression sample) is not reproduced by the common-odds world under either baseline, so its estimates are fragile.
- Reviewer 2's objection stands: baseline-adjusted group comparisons cannot show which group has the stronger preference. Use "conditional on the chance model" in every group claim.

## R3. Smith-type simulation: not for offsets (Assessment)

- The calibration step makes simulated mixing match observed ego-alter mixing (Smith 2012, Step 8 and §4.2). Offsets read from that network already contain the effect being tested.
- A homophily-free version returns headcount or degree-weighted headcount. The degree-weighted version needs symmetric ties. Nominations are not symmetric: 30.7% of resolved ego-to-ego nominations are reciprocated.
- Other assumptions fail: independent ego networks (89% of the 722 egos are named by another ego), and random sampling from a defined population of known size (tiered recruitment, referral, compliance-based attrition).
- The reusable part is the random-pair chance expectation, which is the headcount offset in R1.

## R4. Within-cohort choice model (Requested; baseline-free check)

Design: the choice set is the cohort roster. y_ij = 1 if ego i named ego j in a wave. Ego and alter fixed effects; same-religion effects by ego group; a reciprocity term; two-way clustering by ego and alter; tier-2 exclusion and in-study restriction as robustness. Full specification: `AGENTS.md` Section 10.3(A).

Strengths: the choice set is observed, so no external baseline is needed. Fixed effects absorb activity and popularity (Reviewer 1). Reciprocity is observed.

Costs: the estimand is cohort-internal (about 36% of analytic student ties; 3,651 ego-to-ego nominations in Waves 3–8). Minority counts are small (No Religion 65 same-religion of 327; Other Religion 9 of 131). Recruitment and attrition selection and dyadic dependence also apply.

First look (unadjusted, unclustered; headcount chance among the other 717 egos): odds ratios vs headcount are Catholic 1.28, No Religion 1.77, Other Religion 1.58, Protestant 1.41. No Religion vs Catholic is +0.33 on the log-odds scale. Treat this as hypothesis-generating until the fixed-effects model is fit with clustering.

## R5. Alter–alter closure controls (Requested)

- Within an ego-wave, "mutual alters" and "the alter's degree among the ego's named alters" are the same variable, because the ego is tied to every named alter. Include one.
- Purpose: Reviewer 2's point that network processes amplify homophily (Moody 2001; Wimmer and Lewis 2010).
- Treat as descriptive controls. The named-alter set is part of the outcome sample, so do not read them causally.
- Before building: confirm whether a cross-ego pooled degree was intended instead.

## R6. Sampling and data facts to report with any result

- Recruitment: Tier 1 pre-arrival (Summer 2015); Tier 2 referrals from Tier 1 students (Fall 2015); Tier 3 open call (Spring 2016). Population: first-year undergraduates entering in Fall 2015 (size not in project materials).
- Attrition: about 190 students removed for low compliance in Year 2. Ego-waves with nominations fall from 400 (Wave 3) to 185 (Wave 8). Use observed ego-waves as denominators.
- Recruitment sensitivity is small: excluding tier 2 moves cohort shares by at most 0.6 points, and in-study-only moves them by at most 0.2.
- Name generator: up to 20 names, plus up to 5 from the prior list from Wave 3 (cap 25). About 1.7% of ego-waves in Waves 3–8 reach the cap.
- Absence of an alter–alter pair means "not reported as knowing." The questionnaire response options are unverified.
- `NetWorkSurvey.csv` has 35,912 rows, of which 22 repeat an (egoid, alterid, wave) combination.

## R7. Reporting and code discipline

- Name the chance model in every table caption and every group claim.
- Describe null results as "not distinguishable from zero under [chance model]," with the interval.
- Use observed ego-waves as denominators. Do not use cohort headcount × waves.
- Re-create exploratory calculations as scripts before citing them. The 2026-10-23 calculations ran only in the console.
- Check Monte Carlo claims against the recorded seeds (4815 corrected; 7418 superseded).
- Protect raw inputs with checksum guards, and test sourced functions with `sys.source(file, envir = new.env())`.

## R8. What would change these recommendations

- An external population composition for the Fall 2015 entering class would give a larger-frame headcount.
- A two-step sample (interviewing a subsample of alters) would observe in-degree for non-egos, the information needed to test the popularity channel. Smith (2012, Conclusion) proposes this design for directed networks.
- Confirmation that the alter–alter questionnaire offered a "don't know" option would change how absence is read.
- A within-cohort fixed-effects result, with clustering and the tier-2 exclusion, that shows a robust minority contrast would justify revisiting R2.

## Do not

- Describe nominations received as neutral availability.
- Report a group contrast without naming the chance model.
- Generate offsets from calibrated simulated networks.
- Compute activity rates as headcount × waves.
- Read closure controls causally.
- Generalize within-cohort estimates to the campus.
- Cite console-only calculations.

## Evidence index

- `AGENTS.md`: Section 0 (state), Section 7 (decisions), Section 8 (pitfalls), Section 9 (open items), Section 10 (data, exploratory results, specifications).
- `Data/README.md` and `Code/load_alter_alter_edgelist.R`: provenance, checks, and loader for the alter–alter edge list.
- `AUDIT_2026-10-22.md` §1.1: the original baseline issue.
- `reviewer_comments_dump.txt`: Reviewer 1 and Reviewer 2 comments.
- `smith-2012-macrostructure-from-microstructure.pdf` (§4.2; Step 8; Conclusion) and `smith-sampled.pdf` (footnote 1; §§2–4).

## Decisions needed from the user

1. Baseline framing: headcount as primary, or the co-primary framing.
2. Closure-control definition (the two requested controls coincide).
3. Approval to fit the within-cohort model, including any package installs.
4. Commit decisions for the new files and for raw NetHealth data in git.
5. NetHealth usage form and publication email (user action).
