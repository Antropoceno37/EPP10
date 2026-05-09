# SAP — Plan operativo y cómputo (síntesis Doc 2, alineado a FDEP-TP v2.0)

> **Jerarquía:** `framework.md` > `governance.md` > **`sap.md`** > scripts.
> Cualquier salida de este SAP debe pasar (a) los gates de `governance.md` y (b) la auditoría de `verification.md` antes de incluirse en el manuscrito.

## Pipeline de 5 capas (framework.md §4) — visión operativa

| Capa | Script | Operación | Output |
|---|---|---|---|
| 1 | `02_code/01_harmonize.R` | Digitalización + interpolación PCHIP a 1 min + harmonización unidades | `01_data/harmonized/ptp_long.parquet` |
| 2 | `02_code/01_harmonize.R` (extiende) | Baseline + AUC₃₀₋₁₈₀ + índices secreción/supresión | métricas escalares por analito × cohorte |
| 3 | `02_code/02_fpca_pace.R` + `03_mfpca_happgreven.R` | FPCA por analito (PC1, PC2, PC3) + z-estandarización a Lean-Healthy | `03_outputs/fpca_univariate.rds` |
| 4 | `02_code/05_classify_ptp.R` | Asignación PTP determinística (15 etiquetas v2.0) | `03_outputs/tables/ptp_classification.csv` |
| 5 | `02_code/05_classify_ptp.R` (continúa) | Integración Types I–V + subtipos a/b/c con jerarquía D2>D1>U2>U1>L2>L1>R | `03_outputs/tables/types_integration.csv` |

Adicionales: `04_cwt_morlet.R` (time-frequency), `06_lme4_scores.R` (subject-level — gated), `07_bootstrap.R` (gated), `08_figures.R` (publication-grade).

---

## 1. Hipótesis

**Primaria:** las trayectorias periprandiales multivariantes (vector funcional 7-dim sobre 0–180 min) discriminan entre cohortes metabólico-quirúrgicas con un patrón coherente entre las primeras 2–3 MFPCs; RYGBP es la cohorte que más se desvía del perfil Lean-Healthy en el subespacio dominado por GLP-1, PYY y grelina (efecto incretínico hipertrofiado).

**Secundarias:**
- ‖score‖ de la 1ª MFPC se asocia con remisión de T2DM a 12 meses post-cirugía.
- Fase (time-to-peak vía PCA-de-fase / warping) discrimina sleeve vs RYGBP mejor que las amplitudes brutas.
- La heterocedasticidad funcional aumenta en obesidad y T2DM y se reduce post-cirugía.

---

## 2. Diseño

Estudio observacional prospectivo de **5 cohortes** (≈ 50–100 sujetos por brazo, n total objetivo 250–500) con prueba mixta de comidas estandarizada (500 kcal: 50% CHO, 30% grasa, 20% proteína) tras 10–12 h de ayuno. Sangre en t = 0, 15, 30, 45, 60, 90, 120, 180 min.

Covariables: edad, sexo, IMC, duración T2DM, HbA1c basal, tiempo desde la cirugía (en cohortes quirúrgicas), medicación basal.

---

## 3. Preprocesamiento (`01_harmonize.R`)

- Unidades: hormonas en pmol/L; insulina en μUI/mL; glucosa de mg/dL → mmol/L (factor 0.0555).
- Imputación: faltantes ≤ 1 punto/sujeto → interpolación lineal; ≥ 2 → dejar al algoritmo PACE manejar la esparsidad.
- Normalización: log natural en hormonas con asimetría > 1; z-score post-FPCA opcional.
- Outliers: boxplot funcional (Sun & Genton 2011) + revisión clínica antes de descartar.
- Covariables ausentes: MICE m=20 si NA > 5%.

---

## 4. FPCA univariante PACE (`02_fpca_pace.R`)

`Y_i(t) = μ(t) + Σ_k ξ_{ik} φ_k(t) + ε_i(t)`, ξ_{ik} ~ N(0, λ_k), φ_k ortonormales en L²[0, 180].

- Estimación vía expectación condicional (PACE) — robusta a esparsidad.
- Retener Kp tal que FVE ≥ 99%.
- Kernel: Epanechnikov; ancho de banda h vía GCV bilineal.
- Diagnóstico: examen visual de φ̂_k, scree plot + FVE acumulada, residuos, split-half.

---

## 5. MFPCA Happ–Greven (`03_mfpca_happgreven.R`)

Procedimiento de tres pasos (Happ & Greven 2018):
1. FPCA univariante por cada hormona K=7 con Kp=4 retenidas.
2. Matriz N × K₊ de scores concatenados, K₊ = ΣKp = 28.
3. Descomposición de la covarianza pequeña K₊ × K₊ vía `irlba` (Lanczos para SVD parcial).

M global tal que FVE conjunta ≥ 95%. Eigenfunciones multivariantes φ_M(t) reconstruidas como combinación lineal ponderada de las univariantes. **No** se construye la covarianza conjunta (K·p)×(K·p) — el pico de RAM se mantiene en la mayor covarianza univariante.

---

## 6. Bootstrap funcional y bandas de confianza (`07_bootstrap.R`)

- B = 2000 réplicas no-paramétricas de sujetos.
- Control FWE por quantile envelope.
- `future::multisession`, **workers = 4** (no 8) para no duplicar la huella de R en 24 GB.
- Semilla maestra `set.seed(20260502)`.

**Gate `governance.md` §8:** si los sujetos independientes son insuficientes (POC con curvas digitalizadas), bootstrap **NO** se ejecuta — se reporta `inference not supportable`.

---

## 7. Modelos jerárquicos (`06_lme4_scores.R`)

`score_iM ~ cohort + age + sex + BMI + (1 | site) + ε`

- Bates et al. 2015 (`lme4`) + lmerTest con Satterthwaite.
- Tukey HSD para comparaciones múltiples; F aproximado para tests globales (REML).

**Gate `governance.md` §1:** solo se ejecuta si hay datos subject-level reales.

---

## 8. Análisis de sensibilidad (`08_figures.R` y supplement)

- Ancho de banda × 0.5, × 2.0 en GCV.
- Re-análisis con FACE en lugar de PACE.
- Kp ∈ {3, 4, 5} y M ∈ {3, 4, 5}.
- Estratificación por sexo, edad (<50 vs ≥50), duración T2DM.
- PACE vs Greven et al. (2010) mixed approach.
- Independencia de scores: correlación intra-sujeto post-hoc.

---

## 9. Plan de figuras

- **Fig 1** — CONSORT-like del reclutamiento (5 cohortes, n por etapa, exclusiones, completers).
- **Fig 2** — Trayectorias medias por hormona × cohorte con bandas IC 95% (panel 7×1).
- **Fig 3** — Eigenfunciones multivariantes M=1,2,3 (panel 3×7) con interpretación clínica anotada.
- **Fig 4** — Score plot bidimensional (MFPC₁ vs MFPC₂) con elipses de confianza por cohorte y centroides.
- **Fig 5** — Asociación score MFPC₁ ↔ remisión T2DM (forest plot OR ajustado).
- **Fig S1** — Comparación PACE vs FACE (validación sensibilidad).
- **Fig S2** — Bootstrap envelope 95% por eigenfunción.

---

## 10. Plan de tablas

- **Tabla 1** — Características basales por cohorte (Mean ± SD continuas, n(%) categóricas; ANOVA / χ² + Bonferroni post-hoc).
- **Tabla 2** — Resumen scores MFPC y FVE por cohorte (Median [IQR], Kruskal-Wallis).
- **Tabla S1** — Detalle metodológico (kernels, anchos, K₊, M, B, semilla, BLAS, versión R).
- **Tabla S2** — Sensibilidad: invariancia del rango de cohortes ante elección de Kp y M.

---

## 11. Perfil computacional (Mac mini M4 Pro 24 GB · 4 workers)

| Escenario | n | K | p | RAM pico | Tiempo bootstrap | Veredicto |
|---|---|---|---|---|---|---|
| Baseline | 500 | 7 | 8 | 3–5 GB | 20–60 min (B=2000) | **Cómodo** |
| A · Sujetos 20× | 10 000 | 7 | 8 | 5–8 GB | 2–4 h | **Cómodo** |
| B · Tiempos 20× | 500 | 7 | 160 | 6–10 GB (FACE) | 2–3 h con FACE | **Viable con FACE** |
| C · Hormonas 20× | 500 | 140 | 8 | 8–14 GB | 1–2 h por bloques | **Marginal en 24 GB** |
| D · Combinado mod | 1 850 | 26 | 30 | 3–5 GB | 30–90 min | **Cómodo · Recomendado** |

**Fórmulas de verificación** (en `PTP_FPCA_Scenarios.xlsx`):
- `cov_univariate (MB) = 8 · p² / 1024²`
- `scores_matrix (MB) = 8 · n · K · Kp / 1024²`
- `score_cov (MB) = 8 · (K · Kp)² / 1024²`
- `long_data (MB) = 8 · n · K · p / 1024²`

**Optimizaciones obligatorias** (preservadas en `00_setup/Renviron` y `Rprofile`):
- Vectorización Accelerate (BLAS = vecLib desde CRAN binario).
- `data.table` con `setDTthreads(4)`.
- Persistencia `arrow / parquet` para datasets harmonizados.
- `future::multisession(workers=4)` (no 8 — duplicaría la huella).

---

## 12. Cronograma

- **Mes 0–1:** cierre del SAP, pre-registro OSF.
- **Mes 1–3:** monitoreo del reclutamiento, análisis interino ciego al brazo.
- **Mes 4–5:** análisis confirmatorio con código congelado, redacción.
- **Mes 5–6:** revisión interna, STROBE checklist.
- **Mes 6:** envío a JCEM + preprint medRxiv (sin embargo).

---

## 13. Reproducibilidad

- Repo Git público (OSF + GitHub) con releases firmadas y DOI Zenodo.
- Datos individuales no se publican; dataset sintético acompaña el código.
- Quarto único `04_manuscript/PTP_pipeline_FPCA_MFPCA.qmd` regenera todas las figuras.
- STROBE checklist; FDA guidelines para datos longitudinales (Tian et al. 2014).
- Pre-registro OSF + log de cualquier desviación del SAP.
