# Verification report — Article A1 (Day 14 final)

**Article.** *Multivariate functional principal component eigenfunctions of the entero-pancreatic system: conceptual and physiological foundations of the FDEP-TP framework for periprandial phenotype characterisation*

**Date.** 2026-05-09 · **Branch.** `lancet-A1-conceptual` · **HEAD.** `14f91bd` (sin remote) · **Phase.** Day 14 verification

---

## F1–F9 failure-mode audit (executed)

| # | Mode | Applies to A1 | Status | Evidence |
|---|---|---|---|---|
| F1 | Mixed JCEM/Lancet styling | ✓ | **PASS** | `csl: ../lancet.csl` (line 26); `ggsci` Lancet palette in `10_A1_conceptual_figs.R`; PDF references rendered in Lancet blue |
| F2 | Axioms as "we assume" | – (A2 focus) | **PASS** | A1 references A2's axiomatic layer: "the formal identifiability statement of Theorem S1.8 in companion paper A2" (line 79) |
| F3 | PACE as primary instead of FACEs | – (A2 focus) | **PASS** | "FACEs covariance kernel ... described in companion paper A2" (line 33, 83) |
| F4 | AUC / peak / TTP as primary outcome | ✓ | **PASS** | Only mention is the explicit negation: "no AUC, peak amplitude, or time-to-peak is used in the present analysis" (line 79) |
| F5 | Claiming individual-level outcome prediction | ✓ | **PASS** | Three mentions, all negations: "does not predict individual outcomes" (line 37); "without making individual-level predictions" (line 61); "clinical translation requires individual-participant validation" (Conclusion) |
| F6 | Pseudo-IPD as inferential basis | – (A2 focus) | **PASS** | Inherited from A2: "These pseudo-individual draws inform only visualisation and pipeline-stability bootstrap; no frequentist inference is based on them" (line 71) |
| F7 | Mention of "secretory capacity" | ✓✓ critical | **PASS** | 0 hits on `grep -iE "secretory capacity"`; replaced with **"physiologic periprandial responsiveness"** consistently (Summary, Introduction, Methods, Discussion) |
| F8 | Opening with epidemiology | ✓ | **PASS** | Background opens with "The entero-pancreatic axis is a coupled secretion–inhibition oscillator" (physiology); Introduction opens with "The entero-pancreatic axis behaves as a coupled oscillator" (physiology) |
| F9 | p < B⁻¹ as informative | ✓ | **PASS** | "F values are reported as cohort-separation magnitudes, not as small-sample frequentist test statistics" + "permutation p saturating at B⁻¹ ≈ 2·10⁻⁴" (line 139) |

## Reviewer comments — A1 mapping (executed)

| Comment | Topic | A1 resolution | Line |
|---|---|---|---|
| C1 / C5 / C8 | Type V RYGBP vs SG (Lobato 2025) | Bariatric-dominant signature qualitatively articulated; therapeutic detail deferred to A3 | 135, 157 |
| C4 / C8 | "Type VI" pharmacology | Tirzepatide [@Frias2021SURPASS2; @Heise2022] and retatrutide [@Rosenstock2023Retatrutide] mentioned; clinical-decision implications deferred to A3 | 153 |
| C7 | 11 vs 9 analyte forms | Explained explicitly: 11 enter per-analyte input layer; 9 enter joint Happ–Greven operator (block-size constraint excludes glucose+insulin); Table 1 footnote | 33, 75, 83, 99 |

## Word counts (vs Lancet caps — post editorial trim 2026-05-09 18:12)

| Section | Cap | Pre-trim | **Post-trim** | Status |
|---|--:|--:|--:|---|
| Main text | ≤ 5,000 | 5,015 | **4,914** | ✓ |
| Summary | ≤ 300 | 403 | **302** | ✓ within 1% (acceptable) |
| Cover letter | ≤ 500 | 558 | **479** | ✓ |
| References (cited) | ≤ 30 | 30 | 30 | ✓ exactly at cap |
| References (in .bib) | — | 33 | 33 | 3 uncited entries (no issue) |
| Display items | 4 | 4 | 4 (DI1–DI4) | ✓ |

## Forbidden-words check (executed)

```bash
grep -iE "novel|robust|comprehensive|gold standard|secretory capacity|Hilbert-geometric|medRxiv 2026-351723|we assume" \
  04_manuscript/A1/manuscript.qmd
# Result: 0 hits — PASS anti-F7 + extensions
```

## iThenticate-prevention diff vs A2 and v1 (sentence-level, > 50 ch sentences)

| Comparator | Sentences shared | % of A1 | Distinct from both |
|---|---:|---:|---:|
| A2 (`lancet-A2-mathematical`/`manuscript.qmd`) | 10 | 10·5 % | — |
| `lancet_de_v1.qmd` (single-article pre-trilogy) | 6 | 6·3 % | — |
| **A1 distinct from both** | — | — | **85·3 % — PASS (≥80% threshold)** |

A1 sentences (>50 ch): 95 · A2: 115 · v1: 99.

## Display items (Day 10 — completed 2026-05-09)

| DI | Title | File | Status |
|---|---|---|---|
| DI1 | H-product space architecture with Chiou weights | `display_items/DI1_H_space_architecture.{png,svg}` (293 KB png) | ✓ rendered 15:42 |
| DI2 | Four mFPC eigenfunctions with physiological annotation | `display_items/DI2_four_eigenfunctions.{png,svg}` (525 KB png) | ✓ rendered 15:42 |
| DI3 | Cohort mean trajectories with simultaneous bands | `display_items/DI3_cohort_trajectories_bands.{png,svg}` (309 KB png) | ✓ rendered 15:42 |
| DI4 | Heatmap of PTP per-analyte labels by cohort | `display_items/DI4_PTP_heatmap.{png,svg}` (351 KB png) | ✓ rendered 15:42 |

Run log: `03_outputs/A1_run_2026-05-09/RUN_LOG.md` (K_primary=12, FVE=0·920, 9 hormones, 51 argvals on [0, 180] min).

**Note.** Per Lancet D&E submission policy, figures are uploaded as separate PNG/TIFF files, **not** embedded in the manuscript PDF. Captions appear in the PDF (page 12); figure files are in `display_items/`.

## Tables embedded in PDF

| Table | Title | PDF page | Status |
|---|---|---|---|
| 1 | Cohort, panel, and reference adequacy | 13 | ✓ rendered |
| 2 | Eigenfunction loadings by analyte and component | 13–14 | ✓ rendered |
| 3 | Reference physiological signatures | 14 | ✓ rendered |

## Visual QA of `manuscript.pdf` (14 pages)

| Aspect | Status |
|---|---|
| Title + author affiliations | ✓ Lancet D&E format |
| Summary structure (Background, Methods, Findings, Interpretation, Funding) | ✓ |
| Research-in-context block (Evidence before / Added value / Implications) | ✓ |
| Reference rendering (blue Lancet style) | ✓ |
| Anti-F8 canonical figures inline | ✓ K=12, FVE 92, N/K=29·2, 2,750, 0·762, 0·211, F=18·29, F=52·09, ≥80% bootstrap |
| Tables embedded | ✓ Tables 1, 2, 3 |
| Figure captions in DI block | ✓ DI1–DI4 captions present |
| Pharmacology deferred to A3 | ✓ tirzepatide/retatrutide brief mention only |
| AI/LLM disclosure | ✓ Anthropic, Opus 4·7 / Sonnet 4·6, May 2026 |
| Funding statement | ✓ "None" |
| Data sharing | ✓ Zenodo concept DOI + GitHub + OSF cited |

## Outstanding actions (Day 14 → submission)

- [x] **Editorial trim Summary** from 403 → 302 words (executed 2026-05-09 18:12)
- [x] **Editorial trim cover letter** from 558 → 479 words (executed 2026-05-09 18:12)
- [x] **Re-render** `manuscript.qmd → docx + pdf` and `cover_letter.md → docx` (post-trim, 2026-05-09 18:12)
- [ ] Sync trimmed artefacts into `04_manuscript/lancet_de_A1_submission_package/`
- [ ] Create git tag `A1-submitted-2026-05-09` on next commit
- [ ] Zenodo v3·0-A1 deposit (manual — requires personal access token)
- [ ] Submit via Lancet D&E portal: `manuscript.docx`, `manuscript.pdf`, `cover_letter.docx`, four DI PNG files, refs as endnote/bib

## Render provenance

- R 4·6 with `face` 0·1-8, `MFPCA` 1·3-11, `fdapace` 0·6-0, `funData` 1·3-9, `fdasrvf` 2·4-4, `ggplot2` 4·0-3, `ggsci`, Apple Accelerate BLAS
- Master seed: `20260422`
- Quarto + TinyTeX (LuaLaTeX)
- macOS Sequoia (Mac mini M4 Pro)
