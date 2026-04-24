# medRxiv Submission Checklist — Final Package

**Manuscrito**: *Dynamic enteropancreatic phenotyping via sparse mFACEs with Chiou normalization + PTP/IEP Type I-V classification: an ecological meta-analysis of six metabolic cohorts*

## Manuscript core

- [x] **Abstract structured** (250 words) — `manuscript/abstract.md`
- [x] **Introducción** — `manuscript/introduction.md`
- [x] **Methods (3G unificado)** — `manuscript/methods.md` (incluye PTP/IEP v1.0)
- [x] **Results (3F empírico)** — `manuscript/results.md`
- [x] **Discusión** — `manuscript/discussion.md`
- [x] **Tablas 1–3** — `manuscript/tables.md` (Cohort composition, Classification prevalence B=50, FANOVA + Pillai)
- [ ] **Tabla 4** — IEP Type I-V distribution per cohort (pendiente: copiar desde `iep_frequency_by_cohort.csv`)
- [x] **Figuras 1–3** — [figures/Figure{1,2,3}*.pdf + PNG](figures/)

## Suplementarios

- [ ] **S1. STROBE cohort checklist** — llenar plantilla EQUATOR Network con referencias a secciones del manuscrito
- [x] **S2. Compliance tick-sheet** — [verification/compliance_tick_sheet.md](verification/compliance_tick_sheet.md) (25 pass, 0 fail, 1 warning documentado)
- [x] **S3. Verification Appendix** — [verification/Verification_Appendix_S3.md](verification/Verification_Appendix_S3.md) (9 secciones)
- [x] **S4. PTP/IEP classification framework integration** — [ptp_iep_results.rds](ptp_iep_results.rds) + [iep_frequency_by_cohort.csv](iep_frequency_by_cohort.csv)

## Reproducibility artefacts (Zenodo deposit)

### Data artifacts (SHA-256 archivados)
- [x] `hormones_long_tidy.csv` → `93eba357565db8278452f6b16d2ec1e5f0d18f83af9d851a1254123b03c49f70`
- [x] `cohort_normalization_map.csv` → `fd133fb5bab90c1cc2b3e9873a9990cce88f316b0f90261350391c46923e944d`
- [x] `pseudo_ipd_primary_M1000_rho050_cv100.csv` → `c5d398b3a47d5a33430f1889a5b2d8dcba64020ff75b183a7bcf1c2393f1e4ca`
- [x] `pseudo_ipd_subsample_N50_rho050_cv100.csv` → `2e0f066fe51143d7f6ffb3d842cae01831e1c7fa9be8c7c1c368eb3016189cdc`
- [x] `fanova_results.csv` → `a099aa3f6771176325e764a57b2e5645043a6aefeef11d7f48518788d4aa102a`
- [x] `bands_simultaneous.csv` → `9aaa04140bf7c690386807bbf424a1560437a2d7ddde244cf5e2322270b67de6`
- [x] `stability_classification_stage.csv` — B=2000 clasificación
- [x] `bootstrap_stability_results.rds` — B=50 pipeline
- [ ] `bootstrap_B2000_results.rds` — pendiente completion (ETA mañana 05:00-08:00)

### Code (R scripts)
- [x] `etl_master_csv.R` — ETL CSV → long tidy con fill-down
- [x] `simulate_pseudo_ipd.R` — GP kernel AR(1) con CV priors
- [x] `mfaces_dryrun.R` — fit_mfaces_joint, retain_by_fve, clasificador joint 6-clase, health_check
- [x] `fit_mfaces_realdata.R` — orquestación primario
- [x] `classify_ptp_iep.R` — marco PTP v1.0 + IEP Type I-V
- [x] `fanova_permutation.R`, `sensitivity_rho.R`, `sensitivity_cv.R`
- [x] `conformal_bands.R` — sup-t simultáneas
- [x] `bootstrap_stability.R` — clasif-stage B=2000 + pipeline B=50
- [x] `bootstrap_B2000_zenodo.R` — B=2000 full pipeline (overnight)
- [x] `recover_B2000_results.R` — agregación post-completion
- [x] `generate_figures.R`, `generate_compliance_and_appendix.R`

### Registro pre-análisis (OSF)
- [x] `preregistration_cohort_map.yaml` — v10.0 + D1-D4 + CV priors + classifier spec
- [ ] OSF DOI: `10.17605/OSF.IO/XXXXX` (pendiente de registrar)

### Environment
- [ ] `renv.lock` — generar con `renv::snapshot()` en el proyecto
- [ ] `sessionInfo.txt` — capturar por figura y por artefacto crítico
- [ ] Apple M4 Pro + macOS Sequoia 15 + R 4.5.3 arm64 + BLAS Accelerate documentado en Methods

## Licencias y declaraciones

- [x] **Licencia CC-BY 4.0** para medRxiv deposit (Plan-S compliant)
- [ ] **Declaración de ética** — no aplica por naturaleza ecológica de datos publicados
- [ ] **Declaración de consentimiento** — no aplica
- [ ] **Declaración de financiamiento** — por llenar
- [ ] **Competing interests** (36-month window) — por llenar
- [ ] **Contribuciones por autor** (CRediT taxonomy) — por llenar
- [ ] **Data availability statement** — "De-identified cohort-level trajectories archived at Zenodo DOI 10.5281/zenodo.XXXXXXX under CC-BY 4.0"
- [ ] **Code availability statement** — "Analysis code archived at Zenodo DOI XXXXX; development at github.com/[org]/EPP10 (release v1.0)"
- [ ] **Clinical trial registration** — "Not applicable (ecological meta-analysis)"
- [ ] **AI/LLM use** — declarar asistencia analítica (code generation, statistical pipeline design)
- [ ] **Preprint notice** — "Preprint deposited on medRxiv DOI 10.1101/2026.MM.DD.XXXXXX"

## Pipeline operacional para submit

1. **Esperar B=2000 completion** (ETA mañana 05:00-08:00 CST)
2. `Rscript recover_B2000_results.R` → actualizar Apéndice S3 §6.3
3. Actualizar **Tabla 4** con IEP distribution desde `iep_frequency_by_cohort.csv`
4. Generar **STROBE S1** usando plantilla EQUATOR cross-referencing a secciones del manuscrito
5. `renv::snapshot()` en el proyecto → `renv.lock`
6. Compilar manuscrito final a PDF (Word/Quarto)
7. Tag GitHub release `v1.0` → Zenodo auto-archive → DOI asignado
8. Registrar YAML preregistro en OSF → DOI asignado
9. medRxiv submit:
   - Manuscrito PDF
   - Figures 1-3 PDF separados (high-res)
   - Suplementarios S1-S4
   - Declaraciones completas
   - Selección de licencia: CC-BY 4.0
10. Screening estimate 2-4 días laborables medRxiv → DOI público
