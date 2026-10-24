# Data

Inputs from the NetHealth release: where each came from, what it contains, and how it was checked.

## AlterAlterEdgeList.csv

- **Source.** NetHealth (University of Notre Dame), data page https://sites.nd.edu/nethealth/data-2/, item "Network Edge List" (CSV). Retrieved 2026-10-23 with a direct download from the data page's Google Drive link (`drive.google.com/uc?export=download&id=1ogoPzMCui8BpMvWw0swTNclNNeQpjkj4`).
- **Codebook.** https://sites.nd.edu/nethealth/documentation-2/ ("Alter-Alter Edge List"), Google Drive file `1QSXVyC8LZtayM89mvXdtfcOpSiQSSNxL`. A copy is saved as `AlterAlterEdgeList_codebook.pdf`. The codebook says the file was "Generated from: AlterAlterEdgeList (1-26-20).dta."
- **Integrity.** MD5 `a55a32c387ab057f30aff9531b4ed366`, 3,760,315 bytes. Codebook MD5 `019091221d1a3791ef16df4c615ee741`. `Code/load_alter_alter_edgelist.R` refuses any file whose checksum differs.
- **Contents.** 174,748 records with columns `egoid`, `vertex1`, `vertex2`, `wave` (waves 1–8). Values are NetHealth case codes (documentation, Table 2).
  - Ego-alter records: 35,890, with `vertex1 == egoid`. Each is one unique nomination in `NetWorkSurvey.csv`.
  - Alter-alter records: 138,858. Each is an unordered pair of alters that one ego named, reported as knowing each other in that wave.
- **Missing pairs.** The data page says respondents were asked whether each named alter knows each other named alter. A pair with no record is therefore read as "not reported as knowing." The questionnaire wording is unverified (see Open points).
- **Loader.** `Code/load_alter_alter_edgelist.R`: `load_alter_alter_edgelist(type = c("all", "alter_alter", "ego_alter"))`.
- **Usage terms.** The data page asks users to complete a short usage form and to email publications and reports to nethealth@nd.edu. Not yet done.

### Checks (2026-10-23)

- No missing values, self-loops, exact duplicate records, or alter pairs recorded twice in the same ego-wave.
- Records by wave match the codebook: 37,874; 37,864; 22,829; 19,824; 18,702; 14,827; 13,063; 9,765.
- 709 distinct egos, 12,968 distinct `vertex1`, and 15,753 distinct `vertex2`, matching the codebook.
- Every ego-alter record matches a nomination in `NetWorkSurvey.csv`, and every nomination there appears here.
- Both alters in every alter-alter record were named by the same ego in the same wave.

### Open points

- **Questionnaire.** The response options are unverified. The questionnaire PDF on the documentation page (Table 5) has no extractable text. "Not reported as knowing" is the working reading.
- **Name generator.** Up to 20 names, plus up to 5 from the prior list from Wave 3, so at most 25 per ego-wave. Ego-waves at the cap may be truncated.
- **Shared codes.** About 11% of alter-wave combinations are named by two or more egos. When two egos name the same pair in a wave and at least one reports it, every co-nominating ego reports it in 98% of cases.

## Companion NetHealth files

| File | MD5 | Status |
|---|---|---|
| `BasicSurvey.csv` | `db97dbc53768b3f8f4526886e5a43347` | Matches the current data-page release (checked 2026-10-23). |
| `NetWorkSurvey.csv` | `eb7c31002f7ce0360ce9a5bac775faa3` | Matches the current release (checked 2026-10-23). The site reports 35,912 records. Of these, 22 repeat an existing (egoid, alterid, wave) combination, leaving 35,890 unique nominations. That equals the ego-alter records in the edge list. |
