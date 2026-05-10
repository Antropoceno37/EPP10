# Numerical ledger — Article A2

**Article.** *Mathematical and statistical foundations of the FDEP-TP framework: covariance operators, spectral decomposition, and BLUP estimation in sparse periprandial data*

**Date.** 2026-05-09 · **Master corpus SHA-256.** `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`

**Provenance.** This A2-specific ledger inherits all canonical figures from the master ledger at `~/Research/PTP_JCEM/03_outputs/lancet_run_2026-05-08/numerical_ledger.md`, restricted to the methodological-statistical layer relevant to A2. Cross-article anti-F8 figures are flagged ✶.

---

## Cohort and panel composition (anti-F8 — shared across A1/A2/A3)

| Quantity | Value | Source |
|---|---|---|
| ✶ N source studies | 23 | `03_outputs/lancet_run_2026-05-08/source_inventory.csv` |
| ✶ N (Author × Cohort) tuples | 71 | `03_outputs/lancet_run_2026-05-08/source_inventory.csv` |
| ✶ N productive cohort-time-arms | 55 | `03_outputs/lancet_run_2026-05-08/source_inventory.csv` |
| ✶ N canonical cohorts | 7 | non-obese without T2D (ref), Obesity, T2DM, Obesity+T2DM, Post-CR, SG, RYGBP |
| ✶ N analyte forms (per-analyte PTP layer) | 11 | GLP-1 a/t, GIP a/t, PYY t/3-36, ghrelin t/a, glucagon, insulin, glucose |
| ✶ N analyte forms (joint operator) | 9 | GIP a/t, GLP-1 a/t, PYY t/3-36, ghrelin t/a, glucagon |
| ✶ N pseudo-subjects (M=1000 per arm × N=50/arm subsample × 55 arms) | 2,750 | `01_data/harmonized/ptp_long.parquet` |
| ✶ Smallest joint block n | 350 | `03_outputs/lancet_run_2026-05-08/reference_adequacy.csv` |
| Reference adequacy (n_ref ≥ 8 per analyte) | 9/9 complete | `03_outputs/lancet_run_2026-05-08/reference_adequacy.csv` |

## Multivariate eigenstructure (A2-specific)

| Quantity | Value | Source |
|---|---|---|
| ✶ K (primary, multivariate-FVE ≥ 0·90, Golovkine 2025) | 12 | `03_outputs/lancet_run_2026-05-08/mfpca_canonical.rds` |
| K (sensitivity, multivariate-FVE ≥ 0·95) | 15 | `03_outputs/lancet_run_2026-05-08/mfpca_canonical.rds` |
| ✶ Cumulative multivariate-FVE at K=12 | 0·92 | `03_outputs/lancet_run_2026-05-08/mfpca_canonical.rds` |
| ✶ N/K ratio | 29·2 | derived |
| ν̂_1 | 1·73 | `03_outputs/lancet_run_2026-05-08/mfpca_canonical.rds` |
| ν̂_2 | 1·19 | id. |
| ν̂_3 | 0·97 | id. |
| ν̂_4 | 0·81 | id. |
| ν̂_5 | 0·61 | id. |
| ν̂_6 | 0·50 | id. |
| ν̂_7 | 0·45 | id. |
| ν̂_8 | 0·35 | id. |
| Cumulative multivariate-FVE at K=5 | 0·650 | id. |
| ✶ ‖ψ̂_1^{(j)}‖² (PYY total) | 0·762 | id. (anti-F8 share with A1/A3) |
| ✶ Integrated incretin loading on ψ̂_1 (sum over GIP a/t + GLP-1 a/t) | 0·211 | id. (anti-F8 share with A1/A3) |

## Univariate eigenstructure

| Quantity | Range | Source |
|---|---|---|
| Components per analyte | 3 | `03_outputs/lancet_run_2026-05-08/fpca_univariate.rds` |
| Cumulative univariate-FVE at 3 components | > 0·999 | id. (post over-parametrisation per L3·5) |
| PC1 variance per analyte | 71 % – 84 % | id. |
| PC2 variance per analyte | 9·8 % – 17·3 % | id. |
| PC3 variance per analyte | 3·1 % – 6·9 % | id. |

## Cross-cohort separability

| Quantity | Value | Source |
|---|---|---|
| ✶ Pillai omnibus F (joint score panel, n=350) | 18·29 | `03_outputs/lancet_run_2026-05-08/pillai_omnibus.csv` |
| ✶ Pillai pairwise F vs reference: Post-CR | 52·09 | `03_outputs/lancet_run_2026-05-08/pillai_pairwise.csv` |
| Pillai pairwise F vs reference: Obesity+T2DM | 9·63 | id. |
| Pillai pairwise F vs reference: Obesity | 7·78 | id. |
| Permutation B | 5,000 | id. |
| Permutation p saturation | B⁻¹ ≈ 2·10⁻⁴ | derived |
| Mahalanobis vs ref: Post-CR | 2·89 | `03_outputs/lancet_run_2026-05-08/mahalanobis_cohort.csv` |
| Mahalanobis vs ref: Obesity+T2DM | 1·67 | id. |
| Mahalanobis vs ref: Obesity | 0·78 | id. |
| Bonferroni q (all three) | 0·003 | id. |

## Phase variability and registration

| Quantity | Value | Source |
|---|---|---|
| Min SD(t_peak) (GIP active) | 23·8 min | `03_outputs/lancet_run_2026-05-08/peak_time_sd.csv` |
| Max SD(t_peak) (ghrelin total) | 63·8 min | id. |
| All analytes SD(t_peak) > 15 min ⇒ SRSF applied | True | id. |

## Sensitivity (ρ ∈ {0·3, 0·5, 0·7, 0·9})

| ρ | K (FVE ≥ 0·90) | Cumulative FVE at K=12 | Rank-correlation vs ρ=0·5 |
|---|---|---|---|
| 0·3 | 13 | 0·89 | 0·92 |
| 0·5 | 12 | 0·92 | 1·00 |
| 0·7 | 12 | 0·93 | 0·97 |
| 0·9 | 11 | 0·94 | 0·94 |

Source: `03_outputs/lancet_run_2026-05-08/tables/sensitivity_summary.csv`.

## Bootstrap stability

| Quantity | Value |
|---|---|
| Subject-level bootstrap B (classification stage) | 2,000 |
| Pre-specified stability target | ≥ 80 % |
| ✶ Modal-Type assignment stability per cohort | ≥ 80 % (target met) |
| Pipeline-stage bootstrap B (eigenfunction envelopes) | 50 |
| Simultaneous-bands method | Goldsmith 2013 / Degras 2011 sup-t |

## Identifiers

| Resource | Value |
|---|---|
| OSF pre-registration | DOI 10.17605/OSF.IO/3CZRE · project tr469 · frozen 2026-04-22 |
| Zenodo concept DOI | 10.5281/zenodo.19743544 |
| Zenodo v2·0-A2 (deposited 2026-05-09) | 10.5281/zenodo.20102959 |
| GitHub | sv8wmxnbp8-hash/EPP10 v1·4 (CC-BY 4·0) |
| Branch (this article) | `lancet-A2-mathematical` |

---

**Anti-F8 cross-article reconciliation.** All ✶-flagged figures must appear identically in `numerical_ledger_A1.md` and `numerical_ledger_A3.md`. Discrepancies block submission of any article in the trilogy until reconciled.
