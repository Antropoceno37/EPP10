# Numerical ledger — Article A1 (Day 14 final)

**Article.** *Multivariate functional principal component eigenfunctions of the entero-pancreatic system: conceptual and physiological foundations of the FDEP-TP framework for periprandial phenotype characterisation*

**Date.** 2026-05-09 · **Branch.** `lancet-A1-conceptual` · **Phase.** Day 14 (final, post-render) · **Master corpus SHA-256.** `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`

**Provenance.** Inherits from the master ledger at `~/Research/PTP_JCEM/03_outputs/lancet_run_2026-05-08/numerical_ledger.md` and from the A2 ledger. ✶ flags cross-article anti-F8 figures.

---

## Anti-F8 figures (reconciled with A2 — 2026-05-09)

| Quantity | Value | Source | A1 location |
|---|---|---|---|
| ✶ N source studies | 23 | `lancet_run_2026-05-08/tables/source_inventory.csv` | Methods §Study design + Summary |
| ✶ N (Author × Cohort) tuples | 71 | id. | Summary + Methods |
| ✶ N productive cohort-time-arms | 55 | id. | Summary + Methods + Table 1 |
| ✶ N pseudo-subjects | 2,750 | `master_table.csv` | Methods + Findings + Table 1 |
| ✶ K (primary) | 12 | `mfpca_canonical.rds$K_primary` | Methods + Findings |
| ✶ Cumulative multivariate-FVE at K=12 | 0·92 (92 %) | `mfpca_canonical.rds$fve_cum[12]` | Methods + Findings |
| ✶ N/K ratio | 29·2 | derived | Methods §Statistical estimation |
| ✶ ‖ψ̂_1^{(PYY total)}‖² | 0·762 | `mfpca_canonical.rds$fit$values` | Findings §Eigenfunction 1 + Table 2 + DI2 caption |
| ✶ Integrated incretin loading on ψ̂_1 | 0·211 | id. | Findings §Eigenfunction 1 |
| ✶ Pillai omnibus F | 18·29 | `tables/pillai_omnibus.csv` | Findings §Cross-cohort separability |
| ✶ Pillai pairwise F vs reference: Post-CR | 52·09 | `tables/pillai_pairwise.csv` | id. |
| ✶ Bootstrap classification stability per cohort | ≥ 80 % | `tables/sensitivity_summary.csv` | Methods + Findings |

**Cross-check.** Permutation p-value floor B⁻¹ ≈ 2·10⁻⁴ at N=2,750 — anti-F9 declaration ("F values reported as cohort-separation magnitudes, not as small-sample frequentist test statistics"). Consistent with A2 §Statistical estimation.

## A1-specific eigenfunction loadings (Table 2 — from `mfpca_canonical.rds`)

Integrated squared L²-norms ‖ψ̂_m^{(j)}‖² normalised so Σ_j ‖ψ̂_m^{(j)}‖² = 1 per component.

| Analyte block | Ψ̂_1 | Ψ̂_2 | Ψ̂_3 | Ψ̂_4 |
|---|---:|---:|---:|---:|
| PYY total | **0·762** | 0·14 | 0·02 | 0·02 |
| GLP-1 active | 0·11 | 0·22 | 0·05 | 0·05 |
| GIP active | 0·05 | **0·31** | 0·08 | 0·05 |
| GIP total | 0·07 | 0·14 | 0·06 | 0·05 |
| GLP-1 total | 0·02 | 0·11 | 0·08 | 0·07 |
| PYY 3-36 | 0·02 | 0·06 | 0·07 | 0·08 |
| Ghrelin acyl | 0·01 | 0·01 | 0·02 | **0·31** |
| Ghrelin total | 0·01 | 0·01 | 0·02 | 0·30 |
| Glucagon | 0·01 | 0·01 | **0·60** | 0·07 |

**Cumulative multivariate-FVE captured by Ψ̂_1..Ψ̂_4** = 21·2 + 14·5 + 11·9 + 9·9 = **57·5 %** (subset of K=12 retained at FVE ≥ 0·90 threshold).

## Cohort-level qualitative signatures (Findings §Cohort signatures + DI3 + DI4)

| Cohort | Ψ̂_1 (PYY) | Ψ̂_2 (sequencing) | Ψ̂_3 (biphasic) | Ψ̂_4 (ghrelin) | A3 mapping |
|---|---|---|---|---|---|
| Non-obese w/o T2D (reference) | ≈ 0 | ≈ 0 | ≈ 0 | ≈ 0 | Type I (preserved) |
| Obesity | mild − | preserved | preserved | preserved | Type II (mild) |
| T2DM | per-analyte only (excl. block-size) | id. | id. | id. | Type II/III |
| Obesity + T2DM | graded − | preserved | mild − | preserved | Type III |
| Caloric restriction (Post-CR) | marked − | mild | marked − | mild | **Type III dominant** |
| Sleeve gastrectomy (SG) | + | + | preserved | **−** (fundic resection) | **Type V variant** |
| Roux-en-Y gastric bypass (RYGBP) | + (PYY-dom) | + | preserved | preserved | **Type V** |

## Reference physiological citations (Table 3)

| Eigenfunction | Physiological reading | Anchoring references |
|---|---|---|
| Ψ̂_1 distal L-cell dominance | PYY-dominant axis; secondary integrated incretin contribution | le Roux 2006²¹; Madsbad 2014¹⁰; Steinert 2017⁸; Svane 2019²² |
| Ψ̂_2 proximal-vs-distal sequencing | Early-peak GIP+insulin vs late-peak GLP-1+PYY along small-bowel anatomical gradient | Drucker 2018⁶; Holst 2007⁷; Steinert 2017⁸ |
| Ψ̂_3 biphasic glucose-insulin coupling | Phase-shifted glucose-insulin axis; symmetric brisk vs delayed | Drucker 2018⁶; Nauck 1986⁹ |
| Ψ̂_4 ghrelin tone | Fasting tone vs postprandial suppression; SG signature | Steinert 2017⁸; Camilleri 2024¹¹; le Roux 2006²¹; Svane 2019²² |

## Identifiers (shared with A2)

| Resource | Value |
|---|---|
| OSF | DOI 10.17605/OSF.IO/3CZRE · project tr469 |
| Zenodo concept | 10.5281/zenodo.19743544 |
| Zenodo v1·3 | 10.5281/zenodo.19758429 |
| Zenodo v3·0-A1 (forthcoming) | TBD on deposit |
| GitHub | sv8wmxnbp8-hash/EPP10 v1·3 (CC-BY 4·0) |
| Branch | `lancet-A1-conceptual` (HEAD `14f91bd`) |
| Tag (forthcoming) | `A1-submitted-2026-05-09` |
