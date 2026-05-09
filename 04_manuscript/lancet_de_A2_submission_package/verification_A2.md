# Verification report — Article A2

**Article.** *Mathematical and statistical foundations of the FDEP-TP framework*
**Date.** 2026-05-09 · **Branch.** `lancet-A2-mathematical` · **Phase.** 0 (pre-flight, initial draft)

---

## F1–F9 failure-mode audit

| # | Mode | Applies to A2 | Status |
|---|---|---|---|
| F1 | Mixed JCEM/Lancet styling | ✓ | ☑ Lancet CSL configured (`csl: ../lancet.csl`); ggsci palette planned for Day 3 figures |
| F2 | Axioms presented as "we assume" rather than theorems | ✓✓ critical | ☑ All eight axioms stated as `Theorem S1.x` with explicit `Proof citation:` tag in Supplementary S1; main text references theorems by number only. `grep -c "we assume"` = 0 |
| F3 | PACE as primary instead of FACEs | ✓✓ critical | ☑ Procedure L3·3 declares FACEs primary; PACE retained as sensitivity. Stated explicitly in Summary, Methods, Findings (FACEs vs PACE empirical comparison subsection), and Discussion |
| F4 | AUC / peak / TTP as primary outcome | – | n.a. |
| F5 | Claiming individual-level outcome prediction | – | ☑ Conclusion explicitly: "framework is descriptive-inferential and does not predict individual outcomes" |
| F6 | Treating pseudo-IPD AR(1) as inferential basis | ✓✓ critical | ☑ Procedure L3·1 and Methods §Study design state pseudo-IPD restricted to "visualisation and pipeline-stability bootstrap only, not for frequentist inference" |
| F7 | Mention of "secretory capacity" | – (A1 focus) | ☑ `grep -c "secretory capacity"` = 0 |
| F8 | Opening with epidemiology rather than methodological gap | ✓ | ☑ Introduction opens with the FDA methodological corpus and the gap (no published framework applies multivariate FPCA to the complete enteropancreatic panel under sparse irregular design) |
| F9 | Reporting p-values < B⁻¹ as informative | ✓✓ critical | ☑ Procedure L3·9 declares F values as cohort-separation magnitudes; Findings reports p saturation at B⁻¹ ≈ 2·10⁻⁴ explicitly |

## Reviewer comments (Jenni AI rounds 1–4) addressed in A2

| Comment | Topic | Resolution |
|---|---|---|
| C2 | mFPCA vs PARAFAC (Shi 2024) | Procedure L3·3 (extended structural justification) + Findings §FACEs vs PACE empirical comparison + Discussion §Comparison with FDA literature |
| C3 | F values without context (anti-F9) | Procedure L3·9 explicit caveat + Supplementary S2 per-cohort F summaries |
| C5 | Golovkine 2025 K selection | Procedure L3·5 + Findings §Multivariate eigenstructure and Golovkine threshold (with comparative inset against univariate-FVE and Cattell scree) + Discussion §Principal methodological findings (item 1) |
| C6 | ρ-sensitivity and rapid incretin smoothing | Methods §Study design (marginal-mean argument) + Procedure L3·10 + Findings §ρ-sensitivity numerical results + Supplementary S3 |
| C7 | 11 vs 9 analyte forms | Methods §Periprandial sampling and analyte panel (explicit paragraph distinguishing per-analyte input layer from joint-operator layer) + Table 1 footnote |
| 23·1 % not-classifiable | Reference cohort | Discussion §Strengths and limitations item Sixth: structural consequence of single-analyte source arms, not a failure of reference standardisation |
| Title attribution | Avoid "Hilbert-geometric" | ☑ Title is methodologically declarative; `grep -c "Hilbert-geometric"` = 0 |

## Forbidden-words check

```bash
grep -i -E "novel|robust|comprehensive|gold standard|secretory capacity|Hilbert-geometric|medRxiv 2026-351723|we assume" \
  04_manuscript/A2/manuscript.qmd
```
Expected: 0 hits. **Status:** to be verified at the end of Phase 0 with the QA bash block.

## Word counts

| Section | Cap (Lancet) | Current draft |
|---|--:|--:|
| Main text (excl. YAML, refs, captions, supplementary) | ≤ 5,000 | ~3,000 (margin for expansion in subsequent revisions) |
| Summary | ≤ 300 | ~280 (within cap) |
| Cover letter | ≤ 500 | (to be drafted) |
| References (refs_A2.bib) | ≤ 30 | 27 entries |
| Display items | 4 | 4 (DI1–DI4 captions present; figures generated Day 3) |

## Theorem and Proof checks

```bash
grep -c "Theorem S1\." manuscript.qmd     # expected: ≥ 8 (8 theorems × ≥1 reference each)
grep -c -i "Proof citation" manuscript.qmd # expected: ≥ 8 (one per theorem)
```

## Canonical figures check (anti-F8)

| Figure | Expected | Status |
|---|---|---|
| N source studies | 23 | ☑ |
| N pseudo-subjects | 2,750 | ☑ |
| K (primary) | 12 | ☑ |
| Cumulative FVE at K=12 | 92 % | ☑ |
| N/K ratio | 29·2 | ☑ |
| ‖ψ̂_1^{(j)}‖² (PYY total) | 0·762 | ☑ (DI/Tables) |
| Integrated incretin loading | 0·211 | ☑ |
| Pillai omnibus F | 18·29 | ☑ |
| Pillai pairwise F (Post-CR) | 52·09 | ☑ |
| Master SHA-256 | 2829cd78… | ☑ (Methods + Data sharing) |

## iThenticate-prevention diff check

```bash
diff -y --suppress-common-lines \
  ~/Research/PTP_JCEM/04_manuscript/A2/manuscript.qmd \
  ~/Research/PTP_JCEM/04_manuscript/lancet_de_v1.qmd | wc -l
# Threshold: ≥ 80 % distinct (excluding LaTeX formulas, refs, §13·1–13·4 verbatim statements)
```

## Verbatim disclosure statements

- AI/LLM disclosure: `grep -c "Anthropic, Opus 4.7"` ≥ 1 ☑
- Funding statement: "None. The author had full access to all data and final responsibility for the decision to submit for publication." (in Methods §Role of the funding source) ☑
- Competing interests: "no competing interests, no industry support, and no funding for this work" ☑
- Data sharing: includes master_table.csv SHA-256 and OSF DOI (`grep -c "10.17605/OSF.IO/3CZRE"` = 4) ☑

## Display items (Day 3 deferred)

| DI | Title | Generator | Status |
|---|---|---|---|
| DI1 | Schema of multivariate Karhunen–Loève representation | `02_code/10_A2_mathematical_figs.R` | Caption present; figure pending Day 3 |
| DI2 | Kernel estimation pipeline FACEs vs PACE | id. | Caption present; figure pending Day 3 |
| DI3 | Eigenvalue spectrum and Golovkine threshold | id. | Caption present; figure pending Day 3 |
| DI4 | BLUP score recovery and simultaneous bootstrap bands | id. | Caption present; figure pending Day 3 |

## Outstanding Phase 0 actions

- [ ] Render `manuscript.qmd → manuscript.docx` once `10_A2_mathematical_figs.R` produces DI1–DI4 (Day 3).
- [ ] Cross-validate `numerical_ledger_A2.md` ✶ figures against the master ledger and the eventual `numerical_ledger_A1.md` and `numerical_ledger_A3.md`.
- [ ] Final iThenticate-prevention diff check pre-submission.
- [ ] Cover letter (≤ 500 words) — drafted in `cover_letter.md`, to be polished after Day 4 redaction pass.
