# Lancet Diabetes & Endocrinology — Submission Package

**Manuscript.** *Periprandial Transition Profiles and Integrated Enteropancreatic Patterns I–V: multivariate functional principal component analysis of gut–pancreas hormone trajectories across health, type 2 diabetes, and metabolic surgery*

**Author.** Héctor M. Virgen-Ayala, MD · ORCID 0009-0006-2081-2286 · Universidad de Guadalajara / IMSS, Guadalajara, Mexico

**Date assembled.** 2026-05-08
**Pipeline run id.** `lancet_run_2026-05-08`
**Master input SHA-256.** `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`

---

## Contents

| File | Purpose | Format |
|---|---|---|
| `manuscript.docx` | **Main manuscript for Lancet D&E submission system** | Word .docx |
| `manuscript_preview.html` | Read-only preview (renderable in any browser) | HTML self-contained |
| `manuscript_source.qmd` | Quarto source for reproducible re-rendering | Quarto markdown |
| `cover_letter.docx` | Cover letter to the Editor | Word .docx |
| `cover_letter.md` | Cover letter source | Markdown |
| `numerical_ledger.md` | Single source of truth for every numerical claim | Markdown |
| `verification_report.md` | Pre-submission verification (L1/L2/L3, F1–F9, IF, voice) | Markdown |
| `display_items/DI1_H_space_architecture.{svg,png}` | Figure 1: PTP/IEP framework architecture and product space | SVG (master) + PNG (300 dpi) |
| `display_items/DI2_estimation_pipeline_schema.{svg,png}` | Figure 2: Estimation pipeline schema | SVG + PNG |
| `display_items/DI3_eigenfunctions_lancet.{svg,png}` | Figure 3: Cohort-stratified eigenfunctions + bootstrap bands | SVG + PNG |
| `display_items/DI4_iep_prevalence_lancet.{svg,png,csv}` | Figure 4: IEP Type prevalence by cohort | SVG + PNG + CSV data |
| `outputs/tables/*.csv` | Source CSV outputs for every numerical claim | CSV |

---

## PDF generation

`xelatex` and `pdflatex` are not available on this build host, and Microsoft Word / LibreOffice are not installed. The `.docx` is the canonical Lancet D&E submission format. To produce a PDF for archival:

1. Open `manuscript.docx` in Word, Pages, or LibreOffice and File → Export As PDF, or
2. Upload `.docx` to the Lancet D&E submission portal — the system renders PDF server-side.

`manuscript_preview.html` may be opened in any browser for an immediate visual proof of the manuscript.

---

## Pre-registration and reproducibility

- **OSF pre-registration.** DOI [10.17605/OSF.IO/3CZRE](https://doi.org/10.17605/OSF.IO/3CZRE); project at https://osf.io/tr469; frozen 2026-04-22.
- **Zenodo.** Concept DOI [10.5281/zenodo.19743544](https://doi.org/10.5281/zenodo.19743544); v1·3 DOI [10.5281/zenodo.19758429](https://doi.org/10.5281/zenodo.19758429).
- **GitHub.** `sv8wmxnbp8-hash/EPP10` v1·3.
- **License.** CC-BY 4·0 (Plan-S compliant).
- **Preprint policy.** No prior preprint deposition; manuscript not under simultaneous consideration elsewhere.

The complete 16-script pipeline (`02_code/`) and the harmonised input (`01_data/raw/master_table.csv`) regenerate every numerical claim in this manuscript with seed `20260422`.

---

## Verification summary (pre-submission)

✅ All 8 axioms (L2·1–L2·8) cited as theorems with proof references
✅ All 10 procedures (L3·1–L3·10) declared in Methods
✅ FACEs primary, PACE sensitivity (anti-F3)
✅ Zero "secretory capacity" hits (anti-F7); "physiologic periprandial responsiveness" used throughout
✅ Reference cohort named **non-obese without T2D** (canonical label `no_obese_without_T2DM`)
✅ Zero "novel/robust/comprehensive/gold standard" hits in author prose (only in cited title of Ahlqvist 2018)
✅ F values reported as cohort-separation magnitudes (anti-F9)
✅ No prior preprint deposition; no duplicate publication
✅ Word counts within Lancet caps: main 3,650 / 5,000; summary 280 / 300; cover 480 / 500; refs 30 / 30
⚠️ Clinical IF coverage 64–71 % (below 80 % strict threshold owing to retention of classic priority citations Nauck 1986, Cummings 2001, Laferrère 2008; methodological proofs exempt; flagged as advisory)

See `verification_report.md` for the full ten-section audit.

---

## Suggested reviewers

1. **Robert Wagner** (Universität Tübingen) — dynamic OGTT subphenotyping
2. **Kathrine F. Frøslie** (University of Oslo) — FPCA in glucose curves
3. **Kirstine N. Bojsen-Møller** (Hvidovre Hospital) — post-bariatric gut hormones
4. **Sonja Greven** (Humboldt-Universität zu Berlin) — mFPCA methodology
5. **Hans-Georg Müller** (UC Davis) — PACE/FPCA methodology

No conflicts of interest declared. No funding received.
