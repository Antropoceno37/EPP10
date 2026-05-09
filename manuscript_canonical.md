# Manuscrito canónico — medRxiv 2026-351723v1 (en revisión)

> **Documento de mayor jerarquía operativa.** Cuando hay conflicto entre este manuscrito y los frameworks previos (Doc 1 optimized prompt, Doc 2 SAP roadmap, Doc 3 Informe Ejecutivo, Doc 4 Prompt Verificación), **prevalece el manuscrito canónico.**

## Dos versiones del manuscrito

| Versión | Páginas | Título | Uso |
|---|---|---|---|
| **medRxiv preprint v1** | **36** | *Dynamic Enteropancreatic Phenotyping via **Sparse mFACEs** and **PTP/IEP** Classification: An Ecological Meta-Analysis of Six Metabolic Cohorts* | **Versión definitiva con resultados completos** (en `~/Desktop/MEDRXIV-2026-351723v1-VirgenAyala.pdf`) |
| JCEM-formatted (corto) | 15 | *Dynamic Enteropancreatic Phenotyping via Multivariate Functional Principal Component Analysis: A Lean-Healthy–Referenced Proof-of-Concept Ecological Study* | Versión condensada para submission a JCEM (en `~/Desktop/Dynamic Enteropancreatic Phenotyping... .pdf`) |

**Cuando hay diferencia, prevalece la versión medRxiv preprint v1 (36 pp.).**

## Identificadores definitivos

- **medRxiv submission ID:** **2026-351723v1** (en revisión, abril 2026)
- **Pre-registro OSF:** **DOI [10.17605/OSF.IO/3CZRE](https://doi.org/10.17605/OSF.IO/3CZRE)** · proyecto [https://osf.io/tr469](https://osf.io/tr469) · frozen 2026-04-22
- **Zenodo concept DOI:** **[10.5281/zenodo.19743544](https://doi.org/10.5281/zenodo.19743544)**
- **Zenodo v1.3** (current, pre-journal-submission polish): [10.5281/zenodo.19758429](https://doi.org/10.5281/zenodo.19758429)
- **Zenodo v1.2** (manuscript conceptual revision): [10.5281/zenodo.19750294](https://doi.org/10.5281/zenodo.19750294)
- **Zenodo v1.0** (initial code snapshot): [10.5281/zenodo.19743545](https://doi.org/10.5281/zenodo.19743545)
- **GitHub:** `sv8wmxnbp8-hash/EPP10` v1.3
- **License:** CC-BY 4.0 (Plan-S compliant)

## Autor

- Héctor Manuel Virgen Ayala, MD · ORCID 0009-0006-2081-2286
- Departamento de Clínicas Quirúrgicas, Universidad de Guadalajara
- Hospital General de Zona No. 14, Departamento de Cirugía General, IMSS, Guadalajara, México
- Correo manuscrito: hectorvirgenmd@gmail.com (vs. académico: hector.virgen@academicos.udg.mx)
- **Sole author**, all CRediT roles

## AI/LLM disclosure (en el manuscrito)

> *"Analytic pipeline design, R code implementation, and manuscript drafting were supported by Claude (Anthropic, Opus 4.7, April 2026)."*

---

## Diseño definitivo (medRxiv v1)

| Parámetro | Valor |
|---|---|
| Tipo | **Ecological meta-analysis at cohort-time-arm level** (pre-registered v10.0) |
| SHA-256 input | `ce2e343d...` |
| **Source studies** | **23** publicaciones (refs 49–71) |
| **(Author × Cohort) tuples** | **71** |
| Cohort-time-arms productivos | **55** |
| Pseudo-IPD generation | M = 1000 sintéticos por arm (GP AR(1) ρ=0.5) |
| **Total pseudo-subjects** | **2,750** (deterministic subsample N=50 × 55 arms) |
| **6 cohortes canónicas** | no_obese_without_T2DM (reference) · Obesity · T2DM · Obesity_T2DM · SG · RYGBP |
| Analyte-forms | **11** (ghrelin total/acyl, GIP total/active, GLP-1 total/active, PYY total, insulin, glucagon, glucose) |
| Challenge classes | SMMT · LMMT · OGTT (analizadas separadas o pooled SMMT+LMMT con covariate) |
| Ventana | [0, 180] min · alineación PCHIP a rejilla 1 min |
| **Seed maestra** | **20260422** (NO 20260502) |

### Cobertura por cohorte (Tabla 1 del manuscrito)

| Cohorte v10.0 | Source labels | Arms | Obs (long) | Pseudo-subj N |
|---|---|---|---|---|
| no_obese_without_T2DM | 1 | 13 | 692 | 650 |
| Obesity | 17 | 14 | 777 | 700 |
| T2DM | 2 | 4 | 280 | 200 |
| Obesity_T2DM | 10 | 7 | 528 | 350 |
| SG | 7 | 7 | 264 | 350 |
| RYGBP | 10 | 10 | 376 | 500 |

---

## Métodos primarios canónicos

### 1. Sparse mFACEs (primary MFPCA)
- Implementación: `face::face.sparse` (Li, Wang, Liu, Greven 2021, ref 35)
- Cross-covariance pairwise via 2-D tensor-product penalized splines
- **Chiou normalization** (Chiou, Chen, Yang 2014, ref 36) — **operacionalmente indispensable**: sin Chiou, PC1 captura 84% varianza pero incretin loading colapsa a 0.000
- BLUP score recovery con measurement-error variance σ²
- Adaptive ridge regularization
- Sign alignment vía `flipFuns()` con Procrustes rotation

### 2. Selección de componentes
- FVE ≥ 0.90 primario · FVE ≥ 0.95 sensitivity
- **Identifiability:** N/K_eff > 10 (en el manuscrito: N/K = 196, criterio cleared con margin)
- **Resultado:** **K = 14** componentes retenidos · FVE top-5 = {0.16, 0.28, 0.38, 0.48, 0.55}

### 3. Pseudo-IPD via Gaussian Process
- Kernel AR(1) continuo: `K_ρ(s,t) = ρ^(|s-t|/30 min)`
- Marginal variance: `σ²_h(t) = (CV_h × μ_h(t))²`
- **CV literatura por hormona**: ghrelin 0.40 · GLP-1 total 0.35 · GIP total 0.30 · insulin 0.20 · glucose 0.12
- Primary: ρ=0.5, CV multiplier=1.0
- Sensitivity: ρ ∈ {0.3, 0.7, 0.9}; CV multipliers {0.75, 1.25}

### 4. Univariate FPCA (sensitivity)
- PACE (Yao, Müller, Wang 2005, ref 33) sobre componente dinámico `d_ih(t) = x_ih(t) - B_ih`
- B_ih definido como t=0 (reference) o nearest-to-zero (study cohorts)
- ≥3 obs per subject per hormone; FVE 0.95
- PC1 = global amplitude · PC2 = early-vs-late · PC3 = biphasic
- Componentes sin orientation física estable: retener numéricamente, withhold physiologic label

### 5. Inferencia
- **FANOVA permutation:** B = 5000 cohort-label permutations · BH-FDR α = 0.05
- **Pillai multivariate contrasts**
- Simultaneous 95% bands vía sup-t bootstrap (B=2000) — Goldsmith et al. 2013
- **Limitación:** pseudo-IPD inflation N=2750 satura permutation p-values en B⁻¹ ≈ 2×10⁻⁴; **F values reportados como cohort-separation magnitudes, NO test statistics formales**

### 6. Dual classification
- **Track A — Joint-mFPC 6-class** sobre (ξ₁, ξ₂, ξ₃) primeros 3 multivariate scores. Pseudo-subjects z-standardized vs. reference; precedence: Altered > Blunted/Enhanced > Impaired > Borderline Impaired > Preserved.
- **Track B — Per-analyte PTP → IEP Type I–V** (framework v1.0 de abril 2026): vector Z_ih de univariate PACE, 9 PTPs (6+3) con pathophysiological filter; cohort-time-arm IEP via 8-rule deterministic precedence.

### 7. Validación
- **Classification-stage bootstrap** (B=2000): scores fixed, reference cohort resampled. Target: ≥80% pseudo-subjects con stability ≥0.80.
- **Pipeline-stage bootstrap** (B=50 primary + B=300 extended Zenodo)
- **Sensibilidad pre-especificada:** (i) PTP ±0.5 SD displacement; (ii) leave-one-axis-out; (iii) ρ ∈ {0.3, 0.5, 0.7, 0.9}; (iv) challenge-class pooling

---

## PTP labels v1.0 (canónico) — 9 etiquetas (6+3)

### Primarias (6) por bandas percentílicas

| PTP | Banda operativa | Significado fisiológico |
|---|---|---|
| **Preserved** | P25–P75; ningún coord en cola | Reference-concordant *physiologic periprandial responsiveness* |
| **Borderline Impaired** | P10–P25 (mild lower-tail); ningún coord <P5 | Mild reduction |
| **Impaired** | P5–P10 (moderate lower-tail) | Moderately reduced |
| **Blunted** | <P5 (severe lower-tail) | Severely attenuated |
| **Borderline Altered** | P75–P95 (upper-tail con relevancia patofisiológica) | Mildly abnormal |
| **Altered** | ≥P95 (extreme upper-tail) | Marked dysregulation. **Reservado:** GIP excesivo, hyperinsulinemia, hyperglycemic excursion, context-specific ghrelin excess |

**Filtro patofisiológico crucial:** Upper-tail Altered/Borderline Altered solo cuando el exceso es patofisiológicamente significativo. **GLP-1/PYY/glucagon elevados → routed to Enhanced/Borderline Enhanced cuando glucose subtype = a** (no automáticamente Altered).

### Secundarias (3) post-intervención

| PTP | Cuándo se asigna |
|---|---|
| **Recovered** | Profile previously abnormal vuelve a banda Preserved; pre→post improvement explícito requerido |
| **Borderline Enhanced** | Mild physiologically coherent supra-reference + glucose Preserved/Recovered. Reservado: GLP-1, PYY, contextualmente insulin |
| **Enhanced** | Marked physiologically coherent supra-reference + glucose Preserved/Recovered. Reservado: GLP-1, PYY, selected insulin. **NO se asigna con glucosa Altered** (esos profiles → Altered) |

Pérdida de peso = modificador contextual (no hard gate).

---

## Mapeo grupos no-glucosa para integración Types

```
R  = {Preserved, Recovered}
L1 = {Borderline Impaired}
L2 = {Impaired, Blunted}
U1 = {Borderline Enhanced}
U2 = {Enhanced}
D1 = {Borderline Altered}
D2 = {Altered}
```

## Subtipos glucémicos a/b/c

```
a = {Preserved, Recovered}                                  # preservado
b = {Borderline Impaired, Impaired, Blunted}                # lower-tail
c = {Borderline Altered, Altered}                           # upper-tail / dysglycemia
```

## Clasificabilidad

Integrated pattern asignado solo si: **(1)** glucose PTP clasificable; **(2)** ≥2 non-glucose PTPs clasificables; **(3)** set incluye ≥1 pancreatic effector (insulin) + ≥1 gut hormone (ghrelin, GIP o GLP-1). Sin imputación.

## 8 reglas de precedencia determinística (canónicas)

```
1. ∃ non-glucose Altered                                          → Type IV.II
2. ∃ non-glucose Borderline Altered                               → Type IV.I
3. ∃ non-glucose Enhanced:
     a. glucose=a y sin L1/L2                                     → Type II.II
     b. otherwise                                                 → Type V.II
4. ∃ non-glucose Borderline Enhanced:
     a. glucose=a y sin L1/L2                                     → Type II.I
     b. otherwise                                                 → Type V.I
5. ∃ non-glucose Impaired/Blunted                                 → Type III.II
6. ∃ non-glucose Borderline Impaired                              → Type III.I
7. todos non-glucose Preserved                                    → Type I.I
8. ≥1 Recovered + resto Preserved/Recovered                       → Type I.II
```

Subtipos a/b/c **solo** en Types III, IV, V. Patterns I y II por definición = subtipo a (preserved glucose).

---

## Resultados clave (cifras canónicas medRxiv)

### Componentes y Pillai

| Métrica | Valor |
|---|---|
| K retained components (FVE 0.90) | **14** |
| PC1 incretin loading (squared, integrated) | **0.817** |
| PC2 / PC3 loadings | 0.699 / 0.608 |
| N/K | **196** (criterio §7.3 cleared) |
| Omnibus Pillai F | **47.6** |
| Off-diagonal cross-cov blocks estimados | **89%** |
| BLUP failures | **0/2750** |

### Pairwise Pillai F vs. reference

| Cohort | F | Rank |
|---|---|---|
| T2DM | **108.3** | 1 |
| RYGBP | 86.8 | 2 |
| Obesity_T2DM | 59.3 | 3 |
| SG | 34.1 | 4 |
| Obesity | 22.5 | 5 |

### IEP Type IV.II prevalence (sin glycemic subclass)

| Cohort | IV.II % |
|---|---|
| RYGBP | **76.4%** |
| Obesity_T2DM | 56.0% |
| SG | 55.0% |
| Obesity | 45.1% |
| T2DM | 28.5% |
| reference | 18.8% |

### IV.II.c con glycemic subclass

| Cohort | IV.II.c % |
|---|---|
| RYGBP | **62.8%** |
| Obesity_T2DM | 56.0% |
| SG | 47.0% |
| Obesity | 36.6% |
| T2DM | 28.5% |
| reference | 8.8% |

### Cross-framework concordance

- **Spearman ρ = 0.50** entre joint Pillai F y IEP Type IV.II prevalence — **moderada concordancia, frameworks complementarios** (no redundantes).

### Stability

- **Classification-stage bootstrap (B=2000): 81.6%** pseudo-subjects con modal-class stability ≥ 0.80 — **>80% target met**.
- **Pipeline-stage bootstrap (B=50): 50/50 reps converged** · K mediana = 14 (range 13–15) · incretin axis PC1 invariant · loading IQR 0.795–0.829.
- **Sensitivity:** ρ ∈ {0.3, 0.7, 0.9} preserva K ∈ [11, 14]; CV multipliers {0.75, 1.25} preservan K ∈ [12, 16] e incretin loadings 0.79–0.83.

### Trajectory differences (sup-t bands)

- 18/47 hormone × cohort-vs-reference comparisons significativas a 95% simultaneous coverage en grid 0–180 min.
- Top: ghrelin total **SG Δ = −143 pmol/L** (fundectomy signature) · insulin Obesity Δ = +975 pmol/L · insulin RYGBP Δ = +665 pmol/L · glucose Obesity_T2DM Δ = +8.3 mmol/L · ghrelin acyl SG Δ = −97 pmol/L · GLP-1 total T2DM Δ = −12.8 pmol/L (incretin deficiency).

---

## Reproducibilidad técnica canónica

### Computational environment del manuscrito
- **R 4.5.3 arm64** + Apple Accelerate
- `future::plan(multisession, workers = 8)` *(NB: el SAP roadmap del Doc 2 §11 recomienda 4 workers para 24 GB; el manuscrito usó 8 — requiere monitoring de RAM)*
- macOS Sequoia 15
- **Seed 20260422** en todos los procedimientos estocásticos

### Paquetes R exactos del manuscrito

| Paquete | Versión |
|---|---|
| `fdapace` | 0.6.0 |
| `face` | 0.1-7 |
| `MFPCA` | 1.3-11 |
| `funData` | 1.3-9 |
| `conformalInference.fd` | 1.1.1 |
| `roahd` | 1.4.3 |
| `mgcv` | 1.9 |
| `pointblank` | 0.12 |
| `irr` | 0.84 |

### Reporting
- **STROBE cohort** (von Elm 2007, ref 46) — completed checklist en Supplementary File S1
- **TRIPOD+AI declared NOT applicable** (descriptive-inferential, no clinical prediction model)
- Ecological meta-analysis → **no requiere ethics review** (publicly available aggregate data)
- Funding: **none**
- Competing interests: **none** (36 meses)

---

## Conceptual core: "physiologic periprandial responsiveness"

Reemplaza explícitamente la convención previa de **"secretory capacity"**:

- **Secretory capacity**: medida por maximal-stimulation tests; refleja biosynthetic pipeline (ER folding, hormone storage, granule biogenesis). NO describe la fase inhibitoria (e.g., ghrelin suppression bajo satiety, glucagon stabilization en fasting, periprandial insulin restraint between meals).
- **Physiologic periprandial responsiveness** (neologismo deliberado): captura stimulus-coupled dynamic behavior across **fasting + postprandial** phases del ciclo circadiano, incluyendo tanto secreción como inhibición. Mathematically tractable vía FPCA sobre multi-hormone trajectories anchored al baseline.

El framework evalúa fasting hormones (ghrelin, glucagon) en su fase dominante (fasting) y postprandial hormones (GIP, GLP-1, insulin, PYY) en la suya (postprandial), todas anchored al basal — captura el sistema responsive completo, no una proyección unidireccional.

---

## Multi-agonist landscape relevante

| Fármaco | Targets | Estado |
|---|---|---|
| Tirzepatide | GIP/GLP-1 dual | Aprobado (Jastreboff 2022, ref 21) |
| Semaglutide | GLP-1 | Aprobado (Wilding 2021, ref 22) |
| Retatrutide | GLP-1/GIP/glucagon triple | Phase 3 TRIUMPH-4 (ref 23, dic 2025) |
| CagriSema | Amylin/GLP-1 | NEJM REDEFINE 1 (Garvey 2025, ref 24) |
| Survodutide | GLP-1/glucagon (MASH) | Phase 2 (Sanyal 2024, ref 25) |

El framework FDEP-TP propone **Type IV + GIP altered → diana de agonistas duales GIP/GLP-1**, y **Type III GLP-1 blunted → beneficio de agonistas GLP-1R**.

---

## Mapeo del manuscrito al pipeline local

| Sección manuscrito | Script local | Estado |
|---|---|---|
| §2.1 Source inventory | `00_inventory.R` | ✅ |
| §2.4–2.6 Time alignment + decomp B+d(t) | `01_harmonize.R` | ✅ (sintético; data real pendiente) |
| §2.6 Pseudo-IPD GP AR(1) | `01_harmonize.R` ext. | ⚠️ TODO: añadir GP draws |
| §2.7 mFACEs primary | `03_mfpca_happgreven.R` | ⚠️ usa MFPCA Happ-Greven; cambiar a `face::face.sparse` + Chiou |
| §2.8 Univariate PACE | `02_fpca_pace.R` | ✅ |
| §2.9 FANOVA permutation + Pillai | falta `06_inference.R` | ⚠️ TODO |
| §2.10 PTP/IEP construction | `05_classify_ptp.R` | ✅ (ajustado a 9 etiquetas + 8 reglas) |
| §2.12 Validación (8 sensibilidad) | falta `09_sensitivity.R` | ⚠️ TODO |
| §2.13 Reproducibilidad | `00_setup/Renviron`, `Rprofile` | ✅ |

**Acciones pendientes para alinear con manuscrito canónico:**

1. ✅ Cambiar seed maestra de `20260502` → `20260422` en todos los scripts.
2. ⚠️ Añadir paquetes `pointblank` e `irr` a `02_install_r_packages.R`.
3. ⚠️ Reescribir `03_mfpca_happgreven.R` para usar `face::face.sparse` + Chiou normalization explícita.
4. ⚠️ Implementar pseudo-IPD GP AR(1) draws en `01_harmonize.R` (cuando llegue data real).
5. ⚠️ Crear `06_inference.R` con FANOVA permutation + Pillai contrasts.
6. ⚠️ Crear `09_sensitivity.R` con los 4 análisis pre-especificados.
