# FDEP-TP v2.0 — Framework maestro

> **Capa de máxima jerarquía.** Si algo en `governance.md`, `sap.md` o cualquier script entra en conflicto con este documento, **prevalece `framework.md`**. Refleja los refinamientos consolidados de Abril 2026 (Informe Ejecutivo v2.0 + Prompt Final de Verificación).

**Nombre completo:** Fenotipificación Dinámica Enteropancreática durante la Transición Periprandial — versión 2.0.
**Autor:** Héctor M. Virgen-Ayala, MD, PhD · Universidad de Guadalajara / IMSS · Guadalajara, México.
**Producto:** Manuscrito tipo **JCEM Original Investigation** (proof-of-concept ecológico sobre 131 cohortes digitalizadas).

---

## 1. Refinamientos terminológicos v2.0 (críticos)

| # | Cambio | Aplicación |
|---|---|---|
| 1 | "Capacidad secretora" → **"Responsividad periprandial fisiológica"** | Aplica coherentemente a señales secretion-dominant (GIP, GLP-1, insulin), suppression-dominant (ghrelin), regulación glucémica (glucose). Cero instancias residuales de la denominación antigua. |
| 2 | **Vector primario de 4 coordenadas:** `Z_ih = [z(B_ih), z(ξ_ih1), z(ξ_ih2), z(ξ_ih3)]` | El descriptor secundario de balance forma-temporal derivado de (ξ₂, ξ₃) es **suplementario**, nunca primario, nunca sustituto de ξ₂/ξ₃. El escalar corroborativo C pasa de coordenada primaria a métrica de validación convergente. |
| 3 | **Pérdida de peso = modificador contextual** (no hard gate) | Criterios post-intervención: (a) posición vs. Lean-Healthy; (b) dirección de cambio vs. pre-intervención. |

---

## 2. Etiquetas PTP v2.0 — 15 etiquetas (6 primarias + 9 secundarias)

### 2.1. Primarias (6) — derivadas de (B, ξ₁, ξ₂, ξ₃) vs. distribución Lean-Healthy

| Etiqueta | Criterio operativo | Nota fisiológica |
|---|---|---|
| **Preserved** | `|z|` ≤ 1 en todas las coordenadas; dentro de banda Lean-Healthy | Estado fisiológico de referencia |
| **Borderline Impaired** | -1.5 ≤ z_ξ₁ < -1; resto sin Altered | Reducción leve de responsividad |
| **Impaired** | z_ξ₁ < -1.5 | Reducción franca de responsividad (cualquier señal) |
| **Blunted** | z_ξ₁ < -1.5 + amplitud relativa baja vs. basal preservado | Específico para secretion-dominant (GIP, GLP-1, PYY, insulin) cuando la amplitud postprandial está cualitativamente comprometida |
| **Borderline Altered** | 1 < z_ξ₁ ≤ 1.5 con significancia patofisiológica | Upper-tail solo si exceso es patofisiológicamente significativo (ej. glucosa) — **NO** automático para GLP-1 elevado en datos transversales |
| **Altered** | z_ξ₁ > 1.5 + significancia patofisiológica | Disrupción franca del eje |

**Discordant_High / Discordant_Low:** desacuerdo entre B y ξ₁ (e.g., basal Preserved pero PC1 muy alterado). **No equivalen a Preserved.** Bloquean Type I/II.

### 2.2. Secundarias (9) — modificadores post-intervención (combinables con primarias)

| Modificador | Cuándo se asigna |
|---|---|
| **+Recovered** | Post-intervención: posición vuelve a banda Lean-Healthy + dirección de cambio acerca al referente. Requiere estado previo anormal (Impaired/Blunted/Altered). |
| **+Borderline Enhanced** | Post-intervención: 1 < z_ξ₁ ≤ 1.5 + glucosa Preserved/Recovered. **No** se asigna con glucosa Altered. |
| **+Enhanced** | Post-intervención: z_ξ₁ > 1.5 + glucosa Preserved/Recovered. **Co-requisito glucosa explícito.** |

Las 9 etiquetas secundarias resultan de aplicar {+Recovered, +Borderline Enhanced, +Enhanced} a los 3 escenarios pre→post (de Impaired, de Blunted, de Altered).

### 2.3. Reglas críticas (R1–R7)

| Regla | Enunciado | Notas |
|---|---|---|
| **R1** | Glucosa opcional para clasificabilidad de PTP analito-individual | **Conflicto con M3 (Types):** la integración requiere glucosa. Resolución: la PTP analito puede asignarse sin glucosa, pero el Type integrado requiere glucosa + ≥2 no-glucosa. |
| **R2** | Enhanced es glucosa-independiente a nivel analito; glucosa determina Type II vs V a nivel integrado | |
| **R3** | Subtipos glucémicos a/b/c **solo** en Types III, IV, V. Types I y II no llevan sufijo (requieren glucosa subtipo a). | |
| **R4** | Discordant_High/Low ≠ Preserved. Bloquean Type I/II. Ghrelin blunted post-SG → Type V; GIP blunted post-RYGBP → Type V. | |
| **R5** | Pérdida de peso = modificador contextual (no hard gate) | Consistencia con §1.3 |
| **R6** | ξ₂ y ξ₃ son coordenadas primarias distintas; el descriptor circular (ξ₂, ξ₃) es **suplementario** | Consistencia con §1.2 |
| **R7** | Ausencia de Types I/II en una cohorte = hallazgo genuino de heterogeneidad, **no** fallo del framework | |

---

## 3. Patrones Enteropancreáticos Integrados — Types I–V

### 3.1. Clasificabilidad

Requiere: **glucosa + ≥2 no-glucosa** (insulina + ≥1 hormona intestinal). Sin imputación.

### 3.2. Grupos de estado no-glucosa (7)

`R` (Reference) · `L1` (mild low) · `L2` (severe low) · `U1` (mild high, condicional) · `U2` (severe high) · `D1` (mild discordant) · `D2` (severe discordant).

### 3.3. Jerarquía de precedencia (10 reglas)

```
D2 > D1 > U2 > U1 [condicional] > L2 > L1 > R
```

Y: **Enhanced + glucosa b/c** (o presencia de L1/L2 con Enhanced) → **Type V**.

### 3.4. Definiciones operativas

| Type | Denominación | Definición operativa | Cohortes predominantes | Subtipo glucémico dominante |
|---|---|---|---|---|
| **I** | Fisiológico / Recuperado | Todos los PTPs no-glucosa Preserved o Recovered | Lean-Healthy | a (preservado) |
| **II** | Supra-fisiológico | ≥1 PTP Enhanced + glucosa Preserved/Recovered; sin Altered | Post-RYGBP (algunos); obesos hiperinsulinémicos compensados | a |
| **III** | Infra-fisiológico | ≥1 PTP Impaired/Blunted; sin Enhanced ni Altered | Obesidad; restricción calórica post-intervención | a → c (variable) |
| **IV** | Disfisiológico | Combinación Altered/Enhanced + Preserved + Impaired/Blunted | T2DM; Obesidad+T2DM | c (altered/hiperglucemia) |
| **V** | Enhanced-mixto | ≥1 PTP Enhanced coexistente con ≥1 PTP Impaired/Blunted + disglucemia | Post-SG; Post-RYGBP | b (hipoglucemia) o c (residual) |

### 3.5. Subtipos glucémicos

- **a** = preservado (basal y ξ₁ glucosa dentro de banda Lean-Healthy)
- **b** = hipoglucemia (ξ₁ glucosa muy bajo; nadir < 70 mg/dL si hay datos)
- **c** = hiperglucemia (basal y/o ξ₁ glucosa Altered)

---

## 4. Pipeline analítico de 5 capas

| Capa | Denominación | Operación | Output | Validación |
|---|---|---|---|---|
| **1** | Digitalización + armonización | Extracción curvas medias 0–180 min; interpolación PCHIP a rejilla 1 min; armonización unidades y formas analíticas | 131 cohortes con curvas interpoladas | QC visual; concordancia tablas publicadas |
| **2** | Métricas derivadas | Baseline; AUC₃₀₋₁₈₀ (trapezoidal); Índices secreción/supresión = (AUC₃₀₋₁₈₀ − Baseline×150)/Baseline×150 | Métricas escalares por analito × cohorte | Comparación valores publicados |
| **3** | FPCA por analito | Decomposición ponderada por n: PC1 (amplitud), PC2 (early/late), PC3 (biphasicidad); z-estandarización a Lean-Healthy | z(B), z(ξ₁), z(ξ₂), z(ξ₃) por analito | Bootstrap stability; % varianza explicada |
| **4** | Asignación PTP determinística | Mapeo z → bandas percentílicas (<P5, P5–10, P10–25, P25–75, P75–95, ≥P95); reglas analito-específicas | PTP por analito × cohorte (machine-readable) | Leave-one-axis-out; sensibilidad ±0.5 SD |
| **5** | Integración Types I–V + subtipos | Agregación determinística por jerarquía D2>D1>U2>U1>L2>L1>R; subtipos a/b/c por glucosa; GCI | Patrón integrado + subtipo glucémico por cohorte | Cohen's κ inter-evaluador; concordancia clínica |

---

## 5. Reference adequacy actualizada (status archivado)

| Analito | Series Lean-Healthy | Status | Elegible framework primario |
|---|---|---|---|
| Glucose | 8 | **full** | Sí |
| Insulin | 8 | **full** | Sí |
| GIP | 6 | **full** | Sí |
| GLP-1 | 4 | **limited / marginal** | Sí (con caveat) |
| PYY | 5 | **limited** | Sí (con caveat) |
| Acyl-Ghrelin | 2 | **excluded** | No |
| Glucagon | 2 | **excluded** | No |

---

## 6. Estado de gaps (Abril 2026)

| Gap | Descripción breve | Estado |
|---|---|---|
| G1 | Distribución Lean-Healthy completa para 4 coordenadas | **cerrado** |
| G2 | Bandas percentílicas P5/P10/P25/P75/P90/P95 | **cerrado** |
| G3 | Reglas analito-específicas v2.0 | **cerrado** |
| G4 | Sensibilidad ±0.5 SD | **confirmado** |
| G5 | Leave-one-axis-out | **confirmado** |
| G6 | Bootstrap stability bandas | **atenuado** |
| G7 | Coherencia jerarquía Types | **resuelto** |
| **G8** | Región bivariada (ξ₂,ξ₃): elipse vs. fallback percentil | **pendiente** |

---

## 7. Hallazgos centrales para el manuscrito

| # | Hallazgo | Cifra clave |
|---|---|---|
| 1 | Discordancia estática-dinámica cuantificada | **41.9%** general; GIP 58.7%, GLP-1 47.9%, glucosa 38.9% |
| 2 | Separabilidad fenotípica por FPCA y CWT | glucose early_delta BH q = 5.1×10⁻⁴; glucose CWT HF/LF ratio BH q = 0.005 |
| 3 | Taxonomía Types I–V con validez ecológica | 5 patrones determinísticos; subtipos a/b/c en III/IV/V |
| 4 | Re-patternización post-quirúrgica ≠ normalización | Post-SG/RYGBP transitan a Type V o II; PC3 (biphasicidad) elevado post-SG en GLP-1 |

Validación convergente FPCA-PTP: Spearman ρ = 0.77–0.83 (señales secretoras); ρ = −0.33 (ghrelin).

---

## 8. Estructura del manuscrito JCEM Original Investigation

| Sección | Palabras | Contenido |
|---|---|---|
| Title | ≤ 25 palabras | "Dynamic Enteropancreatic Phenotyping via Periprandial Transition Profiles: Integrated Types I–V Quantify Static–Dynamic Discordance Across Obesity, Type 2 Diabetes, and Bariatric Interventions" |
| Structured Abstract | 250 | Background → Methods (5-layer pipeline) → Results (3–4 hallazgos cuantitativos) → Conclusions (proof-of-concept; requiere validación IPD) |
| Key Points box | 4 ítems | Problema · Evidencia · Mejora · Implicación clínica |
| Introduction | 800 | (1) heterogeneidad mecánica + límites métricas estáticas; (2) precedentes (PREDICT, glucotypes, Ahlqvist) + gap enteropancreático; (3) objetivo + contribución |
| Methods | 2 500 | Fuentes + QC → métricas derivadas → FPCA → CWT/HHT → PTP assignment → Types I–V integration → sensibilidad. Tabla de decisión PTP completa en Supplementary. |
| Results | 2 000 | Características cohortes → diferenciación FPCA/CWT → discordancia → distribución Types I–V por condición → re-patternización post-intervención |
| Discussion | 2 000 | Hallazgos → interpretación fisiológica Types I–V → comparación frameworks → aplicaciones clínicas → 3 limitaciones consolidadas → futuras direcciones |
| Acknowledgments / Data Availability / References / Figure legends / Tables | — | JCEM standard. Referencias **numeradas en orden de primera aparición**. |

**Total ≈ 7 500 palabras** del cuerpo principal.

### 8.1. Tres limitaciones consolidadas (declarar explícitamente)

1. **Nivel de análisis:** medias de cohorte digitalizadas, no datos individuales. Variabilidad intra-cohorte y predicción a nivel paciente no son inferibles.
2. **Heterogeneidad de protocolos:** energía calórica, composición de macronutrientes, textura del meal test, plataformas de ensayo y schedules de muestreo varían entre estudios. Sin ajuste por energía de la comida.
3. **Cobertura analítica incompleta:** pocos estudios miden simultáneamente los 7 analitos, reduciendo cohortes elegibles para tipificación integrada.

---

## 9. Posicionamiento vs. frameworks contemporáneos

| Framework | Variables | Diferencia con FDEP-TP v2.0 |
|---|---|---|
| **PREDICT** (Berry 2020) | glucosa, triglicéridos, insulina | No integra GLP-1/GIP/PYY/ghrelin; FDEP-TP cubre 7 analitos |
| **Glucotypes** (Hall 2018) | CGM intra-individual | Patrones glucémicos solo; FDEP-TP es multi-eje |
| **Ahlqvist clusters** (2018) | 6 variables → 5 subgrupos diabetes | Estáticas; FDEP-TP usa coordenadas funcionales (FPCA) sobre la transición periprandial |
| **Subphenotypes** (Wagner 2021) | OGTT-based clustering | FDEP-TP integra time-frequency (CWT) además de FPCA |
| **Tirzepatida agonistas duales GIP/GLP-1** (Frías 2021) | Farmacología | FDEP-TP propone Type IV + GIP altered como diana terapéutica |
| **Hipoglucemia post-bariátrica** (Salehi 2014) | Fenómeno clínico | FDEP-TP la captura en Type V subtipo b |

Búsqueda 2024–2026: agonistas triples (retatrutida), nuevas cohortes con panel completo, avances FPCA clínica → ver `verification.md` Módulo 7.

---

## 10. Aplicación práctica en este workspace

- `governance.md` y `sap.md` se mantienen como capas operativas, **alineados a este framework**. En cualquier discrepancia, este documento prevalece.
- `verification.md` provee la auditoría de 10 módulos que valida cualquier output del pipeline contra este framework.
- `02_code/05_classify_ptp.R` implementa las 6 etiquetas primarias + jerarquía Types I–V con la jerarquía de precedencia D2>D1>U2>U1>L2>L1>R.
- `04_manuscript/PTP_pipeline_FPCA_MFPCA.qmd` usa la estructura JCEM de §8.
