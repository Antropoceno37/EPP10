# Verification report — Article A1 (skeleton)

**Article.** *Multivariate functional principal component eigenfunctions of the entero-pancreatic system*
**Date.** 2026-05-09 · **Branch.** `lancet-A1-conceptual` · **Phase.** Day 8 init

---

## F1–F9 failure-mode audit (planned criteria)

| # | Mode | Applies to A1 | Action / status |
|---|---|---|---|
| F1 | Mixed JCEM/Lancet styling | ✓ | Lancet CSL configured (`csl: ../lancet.csl`); ggsci palette to be applied at Day 10 |
| F2 | Axioms as "we assume" | – (A2 focus) | n.a.; A1 references the axiomatic layer of A2 |
| F3 | PACE as primary instead of FACEs | – | A1 inherits FACEs primary from A2 |
| F4 | AUC / peak / TTP as primary outcome | ✓ | Verify in Discussion that no AUC/peak/TTP claim slips in; eigenfunction interpretation only |
| F5 | Claiming individual-level outcome prediction | ✓ | Conclusion must state hypothesis-generating, no individual prediction |
| F6 | Pseudo-IPD as inferential basis | – | Inherited statement from A2 Methods |
| F7 | Mention of "secretory capacity" | ✓✓ critical | Replace with "physiologic periprandial responsiveness" everywhere |
| F8 | Opening with epidemiology | ✓ | Introduction must open with the **physiological** gap |
| F9 | p < B⁻¹ as informative | ✓ | F as cohort-separation magnitudes; inherited language from A2 |

## Reviewer comments — A1 mapping

| Comment | Topic | Resolution to encode in A1 |
|---|---|---|
| C1 / C5 / C8 | Tipo V RYGBP vs SG (Lobato 2025) | Mention bariatric-dominant signature qualitatively; defer therapeutic detail to A3 |
| C4 / C8 | "Tipo VI" pharmacology | Conceptual mention only; A3 elaborates |
| C7 | 11 vs 9 analyte forms | Table 1 footnote (anti-F8 share) |

## Word counts (targets)

| Section | Cap (Lancet) | Day-X target |
|---|--:|--:|
| Main text | ≤ 5,000 | Day 14: 4,500–5,000 |
| Summary | ≤ 300 | Day 9: 280–300 |
| Cover letter | ≤ 500 | Day 13: 450–500 |
| References | ≤ 30 (≥ 80 % IF > 10) | Day 13 |
| Display items | 4 | Days 10–11 |

## Forbidden-words check (Days 13–14)

```bash
grep -i -E "novel|robust|comprehensive|gold standard|secretory capacity|Hilbert-geometric|medRxiv 2026-351723|we assume" \
  04_manuscript/A1/manuscript.qmd
# Expected: 0 hits
```

## iThenticate-prevention diff vs A2 and v1

```bash
diff -y --suppress-common-lines \
  ~/Research/PTP_JCEM/04_manuscript/A1/manuscript.qmd \
  ~/Research/PTP_JCEM/04_manuscript/A2/manuscript.qmd | wc -l
diff -y --suppress-common-lines \
  ~/Research/PTP_JCEM/04_manuscript/A1/manuscript.qmd \
  ~/Research/PTP_JCEM/04_manuscript/lancet_de_v1.qmd | wc -l
# Threshold: ≥ 80 % distinct from each comparator
```

## Display items (Day 10)

| DI | Title | Generator | Status |
|---|---|---|---|
| DI1 | H-product space architecture with Chiou weights | `02_code/10_A1_conceptual_figs.R` | TODO Day 10 |
| DI2 | Four mFPC eigenfunctions with physiological annotation | id. | TODO Day 10 |
| DI3 | Cohort mean trajectories with simultaneous bands | id. | TODO Day 11 (reuse bootstrap_envelopes.rds) |
| DI4 | Heatmap of PTP per-analyte labels by cohort | id. | TODO Day 11 (reuse ptp_classification.csv) |

## Outstanding actions

- [ ] Days 8–9: complete Summary, Research-in-context, Introduction.
- [ ] Days 9–11: complete Methods (cohort + four conceptual moves), Findings (4 eigenfunctions), tables.
- [ ] Day 10: produce `02_code/10_A1_conceptual_figs.R` and DI1–DI4.
- [ ] Days 12–13: complete Discussion + cover letter + verification report.
- [ ] Day 14: render `manuscript.qmd → docx + pdf`; package; tag `A1-submitted-YYYY-MM-DD`.
