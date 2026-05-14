# A4 empirical validation — Lancet D&E pre-submission

Branch: `lancet-A4-empirical`. Self-contained subpackage adding to the EPP10
FDEP-TP framework (A1/A2/A3 trilogy on `main`) the **empirical cohort-level
validation paper (A4)** submitted to *The Lancet Diabetes & Endocrinology*.

Contents:
- `scripts/01-02` — master table parser (shared with A3 pipeline)
- `scripts/14-18` — FDEP-TP A4 pipeline (pseudo-IPD, PACE, Happ-Greven mFPCA,
  cross-covariance kernels, ρ descriptors, PTP/IEP classification)
- `scripts/19` — Leave-One-Study-Out sensitivity (mean |corr|=0·938)
- `data/` — master_table + intermediate RDS + final CSVs
- `figures/` — DI1-DI4 main + DI_S3_* supplementary (LOSO)
- `lancet_package/main/` — manuscript (300-word abstract), cover letter, refs,
  ICMJE disclosure, CRediT statement
- `lancet_package/supplementary/` — S1 STROBE, S2 acquisition protocol, S3 LOSO

Reproducibility: master seed 20260514, R 4.6.0 + fdapace 0.6.0 + MFPCA 1.3-11.
Pre-registration: OSF DOI 10.17605/OSF.IO/3CZRE (v10·0, frozen 2026-04-22).
