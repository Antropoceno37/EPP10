# Numerical ledger — Article A3 (skeleton)

**Article.** *Methodological and translational foundations of the FDEP-TP framework: PACE-mFPCA pipeline, PTP/IEP classification, and clinical implications across obesity, type 2 diabetes, and metabolic surgery*

**Date.** 2026-05-09 · **Master corpus SHA-256.** `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`

**Provenance.** Inherits from the master ledger and from the A2 ledger. ✶ flags cross-article anti-F8 figures.

---

## Anti-F8 figures (must reconcile with A1 and A2)

| Quantity | Value |
|---|---|
| ✶ N source studies | 23 |
| ✶ N (Author × Cohort) tuples | 71 |
| ✶ N productive cohort-time-arms | 55 |
| ✶ N pseudo-subjects | 2,750 |
| ✶ K (primary) | 12 |
| ✶ Cumulative multivariate-FVE at K=12 | 0·92 |
| ✶ N/K ratio | 29·2 |
| ✶ ‖ψ̂_1^{(PYY total)}‖² | 0·762 |
| ✶ Integrated incretin loading on ψ̂_1 | 0·211 |
| ✶ Pillai omnibus F | 18·29 |
| ✶ Pillai pairwise F vs reference: Post-CR | 52·09 |
| ✶ Bootstrap classification stability per cohort | ≥ 80 % |

## A3-specific quantities

### Type V (enhanced–mixed with residual dysglycaemia)

| Cohort | Prevalence | q (Bonferroni) |
|---|---|---|
| RYGBP | 43·3 % | 0·035 |
| SG | 30·7 % | 0·035 |
| Reference (non-obese without T2D) | 18·8 % | — |

### Type III (infra-physiological)

| Cohort | Prevalence | q (Bonferroni) |
|---|---|---|
| Obesity+T2DM | 40·0 % | 0·035 |
| Post-CR (caloric restriction) | 36·8 % | 0·035 |
| T2DM | 29·5 % | — (excluded from joint panel by smallest-block constraint) |

### Type I·I and not-classifiable

| Cohort | Prevalence | q |
|---|---|---|
| Non-obese without T2D — Type I·I | 32·2 % | 0·035 |
| Non-obese without T2D — not classifiable | 23·1 % | structural (single-analyte source arms) |
| Obesity — Type I·I | 32·2 % | — |

### PTP per-analyte distribution (8,050 classifications)

| Label | Proportion |
|---|---|
| Preserved | 67·1 % |
| Borderline Impaired | 8·6 % |
| Discordant_Basal | 6·3 % |
| Borderline Altered | 5·8 % |
| Discordant_High | 4·8 % |
| Altered | 3·7 % |
| Impaired | 2·2 % |
| Discordant_Low | 1·5 % |
| Blunted | 0 % (conjunctive criterion not met by any subject in this run) |

### PTP/IEP threshold sensitivity

| Sensitivity | Outcome |
|---|---|
| ±0·5 SD threshold displacement | ≤ 6·8 % of per-analyte PTP labels reassigned |
| Leave-one-axis-out | ≥ 90 % integrated Type assignments preserved (except glucagon) |

## Identifiers (shared with A1, A2)

| Resource | Value |
|---|---|
| OSF | DOI 10.17605/OSF.IO/3CZRE · project tr469 |
| Zenodo concept | 10.5281/zenodo.19743544 |
| Zenodo v1·3 | 10.5281/zenodo.19758429 |
| GitHub | sv8wmxnbp8-hash/EPP10 v1·3 (CC-BY 4·0) |
| Branch | `lancet-A3-methodological` |
| Tag (forthcoming) | `A3-submitted-YYYY-MM-DD` |
