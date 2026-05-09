# Article A2 — submission package skeleton

**Article.** *Mathematical and statistical foundations of the FDEP-TP framework: covariance operators, spectral decomposition, and BLUP estimation in sparse periprandial data*

**Branch.** `lancet-A2-mathematical` · **Phase.** 0 (pre-flight, initial draft) · **Date.** 2026-05-09

This subdirectory contains the A2 (mathematical/statistical layer) of the FDEP-TP trilogy for *The Lancet Diabetes & Endocrinology*. Companion articles A1 (conceptual/physiological layer) and A3 (procedural/translational layer) live in `../A1/` and `../A3/` (created on Days 8 and 15 per meta-prompt §10·2).

## Contents

| Path | Description |
|---|---|
| `manuscript.qmd` | Quarto source for the A2 manuscript (~3,000 words main text, with margin under the 5,000-word Lancet cap; Supplementary S1–S3 included inline for editorial review). |
| `refs_A2.bib` | 27 BibTeX entries: methodological FDA core (Mercer 1909, Hsing–Eubank 2015, Ramsay 2005, Wang 2016), sparse FPCA (Yao 2005, Hall 2006, Li–Hsing 2010, Xiao 2018 FACEs), multivariate FPCA (Happ–Greven 2018, Chiou 2014, Li 2021 mFACEs, Golovkine 2025, Haghbin 2026, Nolan 2025, Sartini 2025), bootstrap and simultaneous bands (Goldsmith 2013, Degras 2011, Diquigiovanni 2022 conformal), phase-amplitude separation (Tucker–Wu 2014), tensor decompositions (Sidiropoulos–Bro 2000, Shi 2024), component-selection heuristics (Cattell 1966), covariance-operator geometry (Masarotto 2019), pseudo-IPD / ecological inference (Robinson 1950, Papadimitropoulou 2020, Rohatgi 2022 WPD), TRIPOD (Collins 2024), Lancet D&E framing (Frøslie 2013), and clinical citations for Theorem S1.8 (Laferrère 2008, Rubino 2025). |
| `numerical_ledger_A2.md` | Single source of truth for every numerical claim in A2; ✶-flagged figures must reconcile across A1/A2/A3 (anti-F8). |
| `verification_A2.md` | F1–F9 failure-mode audit, reviewer-comment matrix (C2/C3/C5/C6/C7), forbidden-words check, word counts, theorem and proof grep, canonical-figures cross-check, iThenticate-prevention diff command, verbatim disclosure status. |
| `cover_letter.md` | Cover letter (≤ 500 words) — methodological gap, Lancet D&E precedent, contribution, reproducibility, suggested reviewers. |
| `display_items/` | DI1 (KL schema), DI2 (kernel pipeline FACEs vs PACE), DI3 (eigenvalue spectrum + Golovkine threshold), DI4 (BLUP scores + simultaneous bands). Captions are present in `manuscript.qmd`; figures are generated on Day 3 by `02_code/10_A2_mathematical_figs.R`. |
| `outputs/tables/` | Tabular outputs specific to A2: eigenvalues, FVE comparisons, FACEs vs PACE, ρ-sensitivity. Populated on Day 3. |
| `supplementary/` | Reserved for assets exceeding the inline Supplementary S1–S3 in `manuscript.qmd`, if needed. |

## Build pipeline (Day 3 onward)

The A2 manuscript reuses the canonical pipeline outputs at `../../03_outputs/lancet_run_2026-05-08/` (frozen). Article-specific figures are produced by `../../02_code/10_A2_mathematical_figs.R` (to be created on Day 3) and written to `../../03_outputs/A2_run_2026-05-09/`, with symlinks or copies to `display_items/`.

## Render

```bash
cd ~/Research/PTP_JCEM/04_manuscript/A2
quarto render manuscript.qmd --to docx        # primary Lancet submission format
quarto render manuscript.qmd --to pdf         # PDF native (BasicTeX installed Phase 0)
```

## Phase 0 deliverables (this session)

- ☑ Workspace `04_manuscript/A2/{display_items,outputs/tables,supplementary}/` created
- ☑ Lancet CSL downloaded to `../lancet.csl`
- ☑ Git initialised; branch `lancet-A2-mathematical` created from `554f51e` baseline commit
- ☑ BasicTeX installed via Homebrew; tlmgr packages: `xetex`, `unicode-math`, `fontspec`, `mathtools`, `tabularx`, `booktabs`, `caption`, `ifsym`, `collection-fontsrecommended`
- ☑ R packages verified: `face` 0·1-8, `MFPCA` 1·3-11, `fdapace` 0·6-0, `funData` 1·3-9, `fdasrvf` 2·4-4, `ggsci` 5·0-0, `officer` 0·7-4, `flextable` 0·9-11
- ☑ `master_table.csv` SHA-256 reconfirmed `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`
- ☑ `manuscript.qmd` initial draft (~3,000 main words; 4 display item captions; Supplementary S1–S3 inline)
- ☑ `refs_A2.bib`, `numerical_ledger_A2.md`, `verification_A2.md`, `cover_letter.md`, `README.md`
- ☐ DI1–DI4 figures (Day 3)
- ☐ `manuscript.docx` render (Day 7)
- ☐ Submission package empaquetado as `lancet_de_A2_submission_package/` (Day 7)
- ☐ Zenodo v2·0-A2 deposit + GitHub tag `A2-submitted-YYYY-MM-DD` (Day 7)
