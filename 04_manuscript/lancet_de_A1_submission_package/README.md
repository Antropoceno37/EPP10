# Submission package — Article A1 · *Lancet Diabetes & Endocrinology*

**Article.** *Multivariate functional principal component eigenfunctions of the entero-pancreatic system: conceptual and physiological foundations of the FDEP-TP framework for periprandial phenotype characterisation*

**Author.** Dr. Héctor M. Virgen-Ayala, MD PhD · ORCID 0009-0006-2081-2286 · Universidad de Guadalajara / Instituto Mexicano del Seguro Social, Guadalajara, Mexico · hectorvirgenmd@gmail.com

**Date packaged.** 2026-05-09 · **Branch.** `lancet-A1-conceptual` · **Tag.** `A1-submitted-2026-05-09`

**Pre-registration.** Open Science Framework DOI 10.17605/OSF.IO/3CZRE · project `tr469` · frozen 2026-04-22.

---

## Package contents

| File / directory | Format | Description |
|---|---|---|
| `manuscript.docx` | Word | Lancet primary submission format (31 KB) |
| `manuscript.pdf` | PDF (LuaLaTeX) | Reference render (137 KB · 14 pages) |
| `manuscript_preview.html` | self-contained HTML | Editorial preview (1·3 MB) |
| `manuscript_source.qmd` | Quarto source | The verbatim Quarto file used to render the above |
| `cover_letter.docx` | Word | Cover letter (~500 words) |
| `cover_letter.md` | Markdown source of the cover letter | |
| `refs_A1.bib` | BibTeX | 27 entries — methodology core + classical entero-pancreatic physiology + clinical taxonomies + glucose-curve precedents + pharmacology + reporting |
| `lancet.csl` | CSL | The Lancet citation style |
| `numerical_ledger_A1.md` | Markdown | Single source of truth for every numerical claim; ✶ flags anti-F8 cross-article reconciliation figures |
| `verification_A1.md` | Markdown | F1–F9 audit (F4, F5, F7, F8 critical for A1) · reviewer-comments matrix |
| `display_items/` | PNG (300 dpi) + SVG | DI1 H-product space architecture · DI2 four leading mFPC eigenfunctions with physiological annotation · DI3 cohort mean trajectories with simultaneous bootstrap bands · DI4 per-analyte PTP labels heatmap by cohort |
| `outputs/tables/` | CSV | DI1 Chiou weights · master ledger excerpts (Pillai, Mahalanobis, IEP prevalence, reference adequacy, peak-time SD, sensitivity summary, source inventory) |
| `supplementary/` | reserved | for any asset exceeding inline supplementary tables |

## Reproducibility

- **Master corpus.** `~/Research/PTP_JCEM/01_data/raw/master_table.csv` SHA-256 `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117` (frozen).
- **Pipeline.** Sixteen R scripts in `~/Research/PTP_JCEM/02_code/` (canonical) plus the article-specific `02_code/10_A1_conceptual_figs.R` that produced DI1–DI4.
- **Run inputs.** `~/Research/PTP_JCEM/03_outputs/lancet_run_2026-05-08/` (frozen) — `mfpca_canonical.rds` (K=12, FVE 92 %, N/K 29·2; PYY total ‖·‖² = 0·762; integrated incretin loading 0·211), `bootstrap_envelopes.rds` (B=50 pipeline-stage), `fpca_univariate.rds`, and the eight CSV ledgers under `tables/`.
- **Run outputs.** `~/Research/PTP_JCEM/03_outputs/A1_run_2026-05-09/` mirrors `display_items/` and contains `RUN_LOG.md`.
- **Software.** R 4·6·0 with `face` 0·1-8, `MFPCA` 1·3-11, `fdapace` 0·6-0, `funData` 1·3-9, `fdasrvf` 2·4-4, `data.table`, `arrow`, `ggplot2` 4·0-3, `patchwork`, `ggsci` on macOS Sequoia with Apple Accelerate BLAS. Quarto 1·9·37, Pandoc 3·9·0·2, BasicTeX (LuaLaTeX 1·24).

## Repositories

- **Zenodo concept DOI.** 10.5281/zenodo.19743544
- **Zenodo v1·4 DOI.** 10.5281/zenodo.19758429 (frozen 2026-04-28)
- **Zenodo v2·0-A1 DOI.** *to be minted on deposit*
- **GitHub.** `sv8wmxnbp8-hash/EPP10` v1·4 (CC-BY 4·0); branch `lancet-A1-conceptual`, tag `A1-submitted-2026-05-09`

## Verbatim disclosures

**Funding.** None. The author had full access to all data and final responsibility for the decision to submit for publication.

**Competing interests.** The author declares no competing interests, no industry support, and no funding for this work.

**AI/LLM disclosure.** Analytic pipeline design, R code implementation, and manuscript drafting were supported by Claude (Anthropic, Opus 4.7 / Sonnet 4.6, May 2026). All statistical outputs, pre-registration decisions, and scientific claims were validated by the author against the v10·0 master analysis plan (OSF DOI 10.17605/OSF.IO/3CZRE) and the FDEP-TP framework v2·0 reference document.

**Data sharing.** All digitised periprandial trajectories, the harmonised cohort corpus, the 16-script analytic pipeline, the article-specific outputs, and the reproducibility scripts are deposited at Zenodo (concept DOI 10.5281/zenodo.19743544; article-specific version DOIs cited in each manuscript) and on GitHub (`sv8wmxnbp8-hash/EPP10` v1·4 and subsequent branches) under CC-BY 4·0. Pre-registration is at the Open Science Framework (DOI 10.17605/OSF.IO/3CZRE; project at https://osf.io/tr469, frozen 2026-04-22).

## Suggested reviewers

- Daniel J. Drucker (Toronto) — incretin biology
- Jens J. Holst (Copenhagen) — GLP-1 physiology
- Robert E. Steinert (Adelaide / Zurich) — Y-receptor and ghrelin physiology
- Sten Madsbad (Hvidovre) — bariatric mechanism
- Michael A. Nauck (Bochum) — incretin defect in T2DM

## Excluded reviewers

None.
