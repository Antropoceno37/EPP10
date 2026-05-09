# Verification report — Article A3 (skeleton)

**Article.** *Methodological and translational foundations of the FDEP-TP framework*
**Date.** 2026-05-09 · **Branch.** `lancet-A3-methodological` · **Phase.** Day 15 init

---

## F1–F9 failure-mode audit (planned criteria)

| # | Mode | Applies to A3 | Action / status |
|---|---|---|---|
| F1 | Mixed JCEM/Lancet styling | ✓ | Lancet CSL + ggsci palette |
| F2 | Axioms as "we assume" | ✓ | A3 references A2's eight theorems; ensure no theorem-washing in A3 prose |
| F3 | PACE as primary instead of FACEs | ✓ | Inherited from A2; verify no slip in A3 Methods |
| F4 | AUC / peak / TTP as primary outcome | ✓✓ critical | A3 explicitly avoids AUC/peak/TTP — uses PTP/IEP labels |
| F5 | Claiming individual-level outcome prediction | ✓✓ critical | Discussion must state hypothesis-generating; clinical algorithm is decision support, not prediction; TRIPOD+AI declared **pending** prospective validation |
| F6 | Pseudo-IPD as inferential basis | ✓ | Inherited from A2 |
| F7 | "Secretory capacity" | ✓ | Replace with "physiologic periprandial responsiveness" |
| F8 | Opening with epidemiology | ✓ | Open with the **clinical translational** gap — operational classification, not prevalence |
| F9 | p < B⁻¹ as informative | ✓ | F as cohort-separation magnitudes; inherited language |

## Reviewer comments — A3 mapping (most reviewer comments converge on A3)

| Comment | Topic | Resolution to encode in A3 |
|---|---|---|
| C1 / C5 / C8 | Type V RYGBP vs SG (Lobato 2025); ecological design | §Findings §Bariatric signature + §Discussion §Mechanistic + §Clinical implications |
| C4 / C8 | "Tipo VI" for triple-receptor agonists | §Discussion §Clinical implications: agonist selection algorithm with retatrutide as Tipo VI extension |
| C7 | 11 vs 9 analyte forms | Methods §Periprandial sampling explicit paragraph + Table 1 footnote |
| Reference cohort 23·1 % not-classifiable | Single-analyte arms | §Findings §Reference signature + §Strengths/limitations item Sixth |
| A priori PTP/IEP design | classification | §Methods §PTP and IEP classification |
| Title attribution | no "Hilbert-geometric" | Title is methodologically and clinically declarative |

## Word counts (targets)

| Section | Cap (Lancet) | Day-X target |
|---|--:|--:|
| Main text | ≤ 5,000 | Day 21 |
| Summary | ≤ 300 | Day 16 |
| Cover letter | ≤ 500 | Day 20 |
| References | ≤ 30 (≥ 80 % IF > 10) | Day 19 |
| Display items | 4 | Days 16–17 |

## Forbidden-words check (Day 21)

```bash
grep -i -E "novel|robust|comprehensive|gold standard|secretory capacity|Hilbert-geometric|medRxiv 2026-351723|we assume" \
  04_manuscript/A3/manuscript.qmd
# Expected: 0 hits
```

## iThenticate-prevention diff vs A1 / A2 / v1

```bash
diff -y --suppress-common-lines \
  ~/Research/PTP_JCEM/04_manuscript/A3/manuscript.qmd \
  ~/Research/PTP_JCEM/04_manuscript/A2/manuscript.qmd | wc -l
diff -y --suppress-common-lines \
  ~/Research/PTP_JCEM/04_manuscript/A3/manuscript.qmd \
  ~/Research/PTP_JCEM/04_manuscript/A1/manuscript.qmd | wc -l
diff -y --suppress-common-lines \
  ~/Research/PTP_JCEM/04_manuscript/A3/manuscript.qmd \
  ~/Research/PTP_JCEM/04_manuscript/lancet_de_v1.qmd | wc -l
# Threshold: ≥ 80 % distinct from each comparator
```

## Display items (Days 16–17)

| DI | Title | Generator | Status |
|---|---|---|---|
| DI1 | Periprandial trajectory acquisition protocol | `02_code/10_A3_methodological_figs.R` | TODO Day 16 |
| DI2 | Computational pipeline (16 R scripts in 5 layers) | id. | TODO Day 16 |
| DI3 | IEP Type I–V prevalence by cohort with q-values | id. | TODO Day 17 (reuse `iep_prevalence_perm.csv`) |
| DI4 | Clinical-decision tree: PTP/IEP-informed agonist selection and metabolic-surgery indication | id. | TODO Day 17 (A3-DISTINCTIVE) |

## Outstanding actions

- [ ] Days 15–16: complete Summary, Research-in-context, Introduction, Methods §Study design, §Periprandial sampling, §Pipeline, §Classification.
- [ ] Days 16–17: produce `02_code/10_A3_methodological_figs.R`; DI1–DI4 generated; Tables 2–4.
- [ ] Days 17–18: complete Findings (PTP per-analyte + three IEP signatures).
- [ ] Days 19–20: complete Discussion (clinical implications + mechanistic + strengths/limitations); Supplementary S1 + S2 (operational protocol appendix).
- [ ] Day 21: render docx + pdf · package · tag `A3-submitted-2026-05-30` (or actual date) · Zenodo v2·0-A3 deposit.
