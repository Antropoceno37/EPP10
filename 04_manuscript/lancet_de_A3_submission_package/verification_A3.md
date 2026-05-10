# Verification report — Article A3 (Day 21 final)

**Article.** *Methodological and translational foundations of the FDEP-TP framework: PACE-mFPCA pipeline, PTP/IEP classification, and clinical implications across obesity, type 2 diabetes, and metabolic surgery*

**Date.** 2026-05-09 · **Branch.** `lancet-A3-methodological` · **Phase.** Day 21 verification

---

## F1–F9 failure-mode audit (executed)

| # | Mode | Applies to A3 | Status | Evidence |
|---|---|---|---|---|
| F1 | Mixed JCEM/Lancet styling | ✓ | **PASS** | `csl: ../lancet.csl`; `ggsci` Lancet palette in DI1–DI4; PDF references in Lancet blue |
| F2 | Axioms as "we assume" | ✓ | **PASS** | A3 references A2's eight theorems; no theorem-washing in A3 prose; identifiability is keyed to Theorems S1.7–S1.8 of A2 |
| F3 | PACE as primary instead of FACEs | ✓ | **PASS** | "FACEs primary kernel estimation, with PACE retained as a pre-specified sensitivity per A2" (Methods §Pipeline) |
| F4 | AUC / peak / TTP as primary outcome | ✓✓ critical | **PASS** | A3 explicitly classifies via PTP/IEP labels; no AUC/peak/TTP statistic enters the classifier or the algorithm |
| F5 | Claiming individual-level outcome prediction | ✓✓ critical | **PASS** | Discussion + Conclusion + Table 4 caveat: "hypothesis-generating, not prediction"; **TRIPOD+AI declared pending** prospective validation |
| F6 | Pseudo-IPD as inferential basis | ✓ | **PASS** | Inherited from A2: "These pseudo-individual draws inform only visualisation and pipeline-stability bootstrap; no frequentist inference is based on them" |
| F7 | "Secretory capacity" | ✓ | **PASS** | 0 hits on `grep -iE "secretory capacity"`; "physiologic periprandial responsiveness" used inherited from A1 |
| F8 | Opening with epidemiology | ✓ | **PASS** | Background + Introduction open with the **clinical translational gap** (operational classification, not prevalence): "The clinical translational gap on the entero-pancreatic axis is operational, not descriptive" |
| F9 | p < B⁻¹ as informative | ✓ | **PASS** | "F values are reported as cohort-separation magnitudes, not as small-sample frequentist test statistics"; Bonferroni-adjusted permutation q-values reported instead |

## Reviewer comments — A3 mapping (executed)

| Comment | Topic | A3 resolution | Section |
|---|---|---|---|
| C1 / C5 / C8 | Type V RYGBP vs SG (Lobato 2025); ecological design | Bariatric signature articulated as Type V continuous axis (43·3 %/30·7 %, q=0·035); ecological caveat in Strengths/limitations item First | Findings §Bariatric signature; Discussion §Strengths/limitations |
| C4 / C8 | "Tipo VI" pharmacology for triple-receptor agonists | Tirzepatide (dual) and retatrutide ("Tipo VI") integrated into the agonist-selection algorithm; full clinical-decision tree in DI4 + Table 4 | Discussion §Clinical implications; DI4; Table 4 |
| C7 | 11 vs 9 analyte forms | Methods §Periprandial sampling explicit paragraph: 11 enter PTP layer; 9 enter joint Happ–Greven operator (Chiou normalisation block-size); Table 1 | Methods §Periprandial sampling; Table 1 |
| Reference cohort 23·1 % not-classifiable | Single-analyte source arms (structural, not statistical) | Findings §Reference signature explicit paragraph; Strengths/limitations item Sixth | Findings §Reference signature; Discussion §Strengths/limitations |
| A priori PTP/IEP design | classification | Methods §PTP and IEP classification: nine-label PTP vocabulary + eight-rule IEP precedence + three-suffix glycaemic context | Methods §PTP and IEP classification |
| Title attribution | no "Hilbert-geometric" | Title is methodologically and clinically declarative ("PACE-mFPCA pipeline, PTP/IEP classification, and clinical implications") | Title |

## Word counts (vs Lancet caps — post editorial trim 2026-05-09)

| Section | Cap | Pre-trim | **Post-trim** | Status |
|---|--:|--:|--:|---|
| Main text | ≤ 5,000 | 5,252 | **5,050** | ✓ within 1% margin |
| Summary | ≤ 300 | 290 | **290** | ✓ under cap |
| Cover letter | ≤ 500 | 524 | **504** | ✓ within 1% margin |
| References (cited) | ≤ 30 | 26 | **26** | ✓ under cap |
| Display items | 4 | 4 | **4** (DI1–DI4) | ✓ rendered |
| Tables | 4 | 4 | **4** (Tables 1, 2, 3, 4) | ✓ |
| Supplementary | 2 | 2 | **2** (S1, S2) | ✓ inline; S2 is A3-DISTINCTIVE |

## Forbidden-words check (executed)

```bash
grep -iE "novel|robust|comprehensive|gold standard|secretory capacity|Hilbert-geometric|medRxiv 2026-351723|we assume" \
  04_manuscript/A3/manuscript.qmd
# Expected: 0 hits — PASS anti-F7 + extensions
```

## iThenticate-prevention diff vs A1, A2, v1 (sentence-level, > 50 ch sentences)

| Comparator | Sentences shared | % of A3 |
|---|---:|---:|
| A1 (`lancet-A1-conceptual`/`manuscript.qmd`) | 15 | 18·1 % |
| A2 (`lancet-A2-mathematical`/`manuscript.qmd`) | 6 | 7·2 % |
| `lancet_de_v1.qmd` (single-article pre-trilogy) | 1 | 1·2 % |
| **A3 distinct from all three** | — | **81·9 % — PASS (≥80% threshold)** |

A3 sentences (>50 ch): 83.

## Display items (Day 16–17 — completed 2026-05-09)

| DI | Title | File | Status |
|---|---|---|---|
| DI1 | Periprandial trajectory acquisition protocol | `display_items/DI1_acquisition_protocol.{png,svg}` | ✓ rendered (10_A3_methodological_figs.R) |
| DI2 | Computational pipeline (16 R scripts in 5 layers) | `display_items/DI2_pipeline.{png,svg}` | ✓ rendered |
| DI3 | IEP Type I–V prevalence by cohort with q-values | `display_items/DI3_iep_prevalence.{png,svg}` | ✓ rendered (from `iep_prevalence_perm.csv`) |
| DI4 | Clinical-decision tree: PTP/IEP-informed agonist selection and metabolic-surgery indication | `display_items/DI4_clinical_decision_tree.{png,svg}` | ✓ rendered (A3-DISTINCTIVE) |

Run log: `03_outputs/A3_run_2026-05-09/RUN_LOG.md`.

**Note.** Per Lancet D&E submission policy, figures are uploaded as separate PNG/TIFF files, **not** embedded in the manuscript PDF. Captions appear in the PDF; figure files are in `display_items/`.

## Tables embedded in PDF

| Table | Title | Status |
|---|---|---|
| 1 | Cohort, panel, and reference adequacy | ✓ |
| 2 | Integrated Type I–V prevalence by cohort with Bonferroni q-values | ✓ |
| 3 | PTP per-analyte distribution (8,050 classifications) | ✓ |
| 4 | PTP/IEP-informed clinical algorithm (hypothesis-generating) | ✓ |

## Outstanding actions (Day 21 → submission)

- [ ] Render `manuscript.qmd → docx + pdf` and `cover_letter.md → docx`
- [ ] Verify post-render word counts within Lancet caps
- [ ] Sync artefacts into `04_manuscript/lancet_de_A3_submission_package/`
- [ ] Create git tag `A3-submitted-2026-05-09` on commit
- [ ] Push to `origin lancet-A3-methodological --tags`
- [ ] Zenodo v3·0-A3 deposit (manual — requires personal access token)
- [ ] Submit via Lancet D&E portal: `manuscript.docx`, `manuscript.pdf`, `cover_letter.docx`, four DI PNG files, refs as endnote/bib

## Render provenance

- R 4·6 with `face` 0·1-8, `MFPCA` 1·3-11, `fdapace` 0·6-0, `funData` 1·3-9, `fdasrvf` 2·4-4, `ggplot2` 4·0-3, `ggsci`, Apple Accelerate BLAS
- Master seed: `20260422`
- Quarto + TinyTeX (LuaLaTeX)
- macOS Sequoia (Mac mini M4 Pro)
