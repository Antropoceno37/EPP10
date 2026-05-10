# Numerical ledger — Article A3 (Day 21 final)

**Article.** *Methodological and translational foundations of the FDEP-TP framework: PACE-mFPCA pipeline, PTP/IEP classification, and clinical implications across obesity, type 2 diabetes, and metabolic surgery*

**Date.** 2026-05-09 · **Branch.** `lancet-A3-methodological` · **Phase.** Day 21 (final, post-render) · **Master corpus SHA-256.** `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`

**Provenance.** Inherits from the master ledger and from the A1 + A2 ledgers. ✶ flags cross-article anti-F8 figures.

---

## Anti-F8 figures (reconciled with A1 and A2 — 2026-05-09)

| Quantity | Value | Source | A3 location |
|---|---|---|---|
| ✶ N source studies | 23 | `lancet_run_2026-05-08/tables/source_inventory.csv` | Methods §Study design + Table 1 |
| ✶ N (Author × Cohort) tuples | 71 | id. | Methods + Table 1 |
| ✶ N productive cohort-time-arms | 55 | id. | Methods + Table 1 |
| ✶ N pseudo-subjects | 2,750 | `master_table.csv` | Methods + Findings + Table 1 |
| ✶ K (primary) | 12 | `mfpca_canonical.rds$K_primary` | inherited from A2 |
| ✶ Cumulative multivariate-FVE at K=12 | 0·92 (92 %) | `mfpca_canonical.rds$fve_cum[12]` | inherited from A2 |
| ✶ N/K ratio | 29·2 | derived | inherited from A2 |
| ✶ ‖ψ̂_1^{(PYY total)}‖² | 0·762 | inherited from A1 | inherited from A1 |
| ✶ Integrated incretin loading on ψ̂_1 | 0·211 | inherited from A1 | inherited from A1 |
| ✶ Pillai omnibus F | 18·29 | `tables/pillai_omnibus.csv` | Findings §Cross-cohort separability |
| ✶ Pillai pairwise F vs reference: Post-CR | 52·09 | `tables/pillai_pairwise.csv` | id. |
| ✶ Bootstrap classification stability per cohort | ≥ 80 % | `tables/sensitivity_summary.csv` | Methods + Findings |

## A3-specific Type prevalences (from `tables/iep_prevalence_perm.csv`)

### Type V (enhanced–mixed) — bariatric-dominant signature

| Cohort | Prevalence | n | Bonferroni q |
|---|---:|--:|---:|
| **RYGBP** | **43·3 %** | 195 / 450 | **0·035** |
| **SG** | **30·7 %** | 92 / 300 | **0·035** |
| Non-obese without T2D (reference) | 18·8 % | — | n.s. |
| Obesity + T2DM | 17·7 % | 53 / 300 | n.s. |
| T2DM | 17·9 % | per-analyte only | n.s. |
| Obesity | 16·3 % | 98 / 600 | n.s. |
| Post-CR | 7·6 % | 19 / 250 | n.s. |

### Type III (infra-physiological) — disease + restriction signature

| Cohort | Prevalence | n | Bonferroni q |
|---|---:|--:|---:|
| **Obesity + T2DM** | **40·0 %** | 120 / 300 | **0·035** |
| **Post-CR** | **36·8 %** | 92 / 250 | **0·035** |
| T2DM (per-analyte only) | 29·5 % | — | n.s. |
| Non-obese without T2D | 18·0 % | — | n.s. |
| Obesity | 18·3 % | 110 / 600 | n.s. |
| RYGBP | 11·3 % | 51 / 450 | n.s. |
| SG | 9·3 % | 28 / 300 | n.s. |

### Type I·I (preserved) and not-classifiable

| Cohort | Type I·I | Not-classifiable |
|---|---:|---:|
| **Non-obese without T2D (reference)** | **32·2 %** (q=0·035) | **23·1 %** (structural — single-analyte source arms) |
| Obesity | 32·2 % | 16·7 % |
| Obesity + T2DM | 31·7 % | 0 % |
| SG | 27·3 % | 16·7 % |
| Post-CR | 26·4 % | 20·0 % |
| T2DM | 16·8 % | 14·5 % |
| RYGBP | 6·4 % | 22·2 % |

## PTP per-analyte distribution (8,050 classifications)

| Label | Count | Proportion |
|---|--:|--:|
| Preserved | 5,402 | 67·1 % |
| Borderline Impaired | 692 | 8·6 % |
| Discordant_Basal | 507 | 6·3 % |
| Borderline Altered | 467 | 5·8 % |
| Discordant_High | 386 | 4·8 % |
| Altered | 298 | 3·7 % |
| Impaired | 177 | 2·2 % |
| Discordant_Low | 121 | 1·5 % |
| Blunted | 0 | 0 % (conjunctive criterion not met) |

## PTP/IEP threshold sensitivity (`tables/sensitivity_summary.csv`)

| Sensitivity | Outcome |
|---|---|
| ±0·5 SD threshold displacement | ≤ 6·8 % of per-analyte PTP labels reassigned |
| Leave-one-axis-out | ≥ 90 % integrated Type assignments preserved (except glucagon: +3·1 pp not-classifiable) |

## Identifiers (shared with A1, A2)

| Resource | Value |
|---|---|
| OSF | DOI 10.17605/OSF.IO/3CZRE · project tr469 |
| Zenodo concept | 10.5281/zenodo.19743544 |
| Zenodo v1·4 (deposited 2026-04-28) | 10.5281/zenodo.19758429 |
| Zenodo v3·0-A3 (deposited 2026-05-09) | 10.5281/zenodo.20102987 |
| GitHub | sv8wmxnbp8-hash/EPP10 v1·4 (CC-BY 4·0); branch `lancet-A3-methodological` |
| Tag (forthcoming) | `A3-submitted-2026-05-09` |
