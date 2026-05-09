# Documentos de Referencia — Trilogía FDEP-TP para Lancet D&E

**Ubicación centralizada:** `~/Research/PTP_JCEM/00_reference_documents/`

**Propósito:** Ubicación única y canónica para todos los documentos de referencia (D1–D4) citados en `META_PROMPT_FDEP_TP_TRILOGY_LANCET_DE.md`. Esta estructura evita referencias dispersas a Desktop y asegura reproducibilidad.

---

## Documentos de Referencia Primarios (D1–D4)

### D1: Framework de Clasificación PTP/IEP

**Ubicación:** `D1_classification_framework/***** 13-04-2026 PTP_IEP_Classification_Framework 2.pdf`

**Autor:** Dr. Héctor M. Virgen-Ayala  
**Propósito:** Taxonomía operativa para los 9 tipos de PTP y 5 tipos de IEP con 8 reglas de precedencia y criterios de clasificabilidad.

**Referencias cruzadas en manuscritos:**
- A1: Sección Methods (definición de los 5 tipos IEP)
- A2: Sección Supplementary (criterios de clasificación)
- A3: Sección Methods (protocolo de clasificación)

---

### D2: Geometría del BLUP de PACE y Operador de Covarianza en mFPCA

**Ubicación:** `D2_D3_mathematical_proofs/Geometría del BLUP de PACE y del operador de covarianza en mFPCA.pdf`

**Propósito:** Desarrollo matemático de los axiomas L2.2 (BLUP optimality) y L2.3 (PACE = simple kriging).

**Citado como prueba para:**
- Teorema L2.2: Estimación óptima BLUP vía Yao-Müller-Wang 2005
- Teorema L2.3: Equivalencia PACE = kriging simple

**Audiencia:** Bioestadísticos, metodólogos FDA (primario para A2).

---

### D3: Estimación del Kernel de Covarianza en Datos Funcionales Sparse

**Ubicación:** `D2_D3_mathematical_proofs/Estimación del kernel de covarianza en datos funcionales sparse- marco metodológico para FPCA y mFPCA de hormonas entero-pancreáticas periprandiales.pdf`

**Propósito:** Análisis comparativo de métodos de estimación del kernel (PACE, FACEs, parametric, penalized). Justificación de FACEs (face::face.sparse) como estimador primario.

**Citado para:**
- Axioma L2.5: Normalización Chiou (w_j = 1/√tr(C^(jj)))
- L3.3: Justificación FACEs vs PACE (balanced-sparse n=50, m=8)
- Anti-F3: FACEs es primario; PACE es sensibilidad

**Audiencia:** Metodólogos FDA, estadísticos computacionales.

---

### D4: Master Table (Datos Armonizados)

**Ubicación:** `../01_data/raw/master_table.csv` (relativa a 00_reference_documents/)

**SHA-256 (run 2026-05-08):** `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`

**Contenido:**
- 1,843 filas (encabezado + datos)
- 23 estudios fuente
- 58 brazos productivos
- 2,750 pseudo-sujetos (tras subsampling 50/brazo)

**Generación de pseudo-IPD:**
- Motor: GP AR(1) con ρ=0.5
- CV por hormona: ghrelin 0.40, GLP-1 0.35, GIP 0.30, insulin 0.20, glucose 0.12, glucagon 0.30
- M=1,000 draws/brazo; subsample determinístico N=50/brazo
- Seed: `20260422`

**Forma:** long-format (92,150 filas post-pseudo-IPD, 2,900 IDs únicos)

---

## Evidencia Clínica Comparativa

### Estudios de Cohortes

**Directorio:** `clinical_evidence_cohorts/`

#### E1: Precision Subclassification of Type 2 Diabetes

**Archivo:** `Precision subclassification of type 2 diabetes: a systematic review.pdf`

**Cita:** Misra et al., Communications Medicine 2023.

**Relevancia:** Precedente de subfenotipificación de T2DM mediante análisis multivariado; precedente Lancet D&E para taxonomía clínica.

---

#### E2: Phenotype-Based Clusters, Inflammation and Cardiometabolic Complications

**Archivo:** `Phenotype-based clusters, inflammation and cardiometabolic complications in older people before the diagnosis of type 2 diabetes: KORA F4:FF4 cohort study.pdf`

**Cita:** Huemer et al., Cardiovascular Diabetology 2025.

**Relevancia:** Análisis cluster de panel hormonal con asociación a marcadores inflamatorios; precedente multi-hormonal.

---

#### E3: Characterizing Human Postprandial Metabolic Response Using Multiway Data Analysis

**Archivo:** `Characterizing human postprandial metabolic response using multiway data analysis.pdf`

**Cita:** Shi et al., Metabolomics 2024.

**Relevancia:** Aplicación de análisis PARAFAC a datos periprandiales; precedente para descomposición multi-hormonal.

---

## Documentación del Autor

### Artículos y Respuestas de Revisión

**Directorio:** `author_documentation/`

#### A1 Draft: Eigenfunciones Multivariadas en el Sistema Entero-Pancreático

**Archivo:** `Artículo 1 Eigenfunciones Multivariadas (mFPCA) en el Sistema Entero-Pancreático_ Fundamentos Conceptuales y Fisiológicos del Marco FDEP-TP para la Caracterización del Fenotipo Periprandial.pdf`

**Propósito:** Borrador A1 previo (capa L1 ontológica). Referencia para flujo de trabajo y estructura de argumentación.

---

#### Respuesta Consolidada a Revisores

**Archivo:** `Carta Consolidada de Respuesta al Reviewer.pdf`

**Fuente:** Feedback medRxiv v1 (rounds 1–4, Jenni AI).

**Propósito:** Documentación de cambios metodológicos en respuesta a revisión previa.

---

#### Resolución de Observación del Revisor 4

**Archivo:** `Resolución de la Observación 4 del Reviewer.pdf`

**Propósito:** Clarificación específica sobre estadística multivariada y saturación de p-valores en permutación.

---

## Verificación de Integridad

Para confirmar que todos los documentos están presentes:

```bash
find ~/Research/PTP_JCEM/00_reference_documents/ -type f \( -name "*.pdf" -o -name "*.csv" \) | wc -l
# Debe retornar: 10 (9 PDFs + 1 CSV)
```

Para listar específicamente:

```bash
find ~/Research/PTP_JCEM/00_reference_documents/ -type f -name "*.pdf" | sort
```

---

## Integración en el META-PROMPT

Todas las referencias en `META_PROMPT_FDEP_TP_TRILOGY_LANCET_DE.md` ahora resuelven localmente:

```markdown
## Documentos de Soporte (D1–D4)

Ubicación central: `~/Research/PTP_JCEM/00_reference_documents/`

- **D1:** Framework de clasificación → `D1_classification_framework/`
- **D2–D3:** Pruebas matemáticas → `D2_D3_mathematical_proofs/`
- **D4:** Datos maestros → `../01_data/raw/master_table.csv`
- **E1–E3:** Evidencia clínica → `clinical_evidence_cohorts/`
- **A1:** Documentación del autor → `author_documentation/`
```

No se requieren referencias externas a `~/Desktop/` ni vinculi a URLs de Google Drive.

---

**Último actualizado:** 2026-05-09  
**Validado con:** `find` + `wc -l` (10 documentos presentes)
