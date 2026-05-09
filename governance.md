# Governance — Capa de calidad e inferencia (síntesis Doc 1, alineada a FDEP-TP v2.0)

> **Jerarquía:** `framework.md` (FDEP-TP v2.0) > `governance.md` (este documento) > `sap.md` > scripts.
> Si una instrucción del SAP entra en conflicto con governance, **prevalece governance**.
> Si una instrucción de governance entra en conflicto con `framework.md`, **prevalece framework**.
> Si un resultado no es estimable, decirlo explícitamente; preferir conservadurismo y reporte transparente sobre precisión inventada.

**Cambios v2.0 que afectan esta capa:**
- Vector primario de **4 coordenadas** `Z_ih = [z(B), z(ξ₁), z(ξ₂), z(ξ₃)]` (sin `z(C)`); el escalar corroborativo C pasa a métrica de validación convergente.
- Terminología "responsividad periprandial fisiológica" reemplaza "capacidad secretora".
- Etiquetas PTP: 6 primarias + 9 secundarias = 15 (ver `framework.md` §2).
- Pérdida de peso = modificador contextual, no hard gate.

---

## 1. Inference ladder (declarar para cada análisis)

| Nivel | Cuándo aplica | Inferencia permitida |
|---|---|---|
| **A · Participant-level** | Datos crudos o tabulados subject-level realmente adjuntos | lme4, bootstrap de sujetos, scores MFPCA subject-level, paired tests si hay matching explícito |
| **B · Cohort-time-arm** | Trayectorias digitalizadas o medias de brazo extraídas | Descripción ecológica; FPCA/CWT sobre la media; **no** paired language; no inferencia subject-level implícita |
| **C · Scalar-summary** | Solo AUC/peak/time-to-peak publicados | Síntesis descriptiva textual; no FPCA |

**Prohibido:** implicar inferencia A desde datos B. Usar paired/within-subject sólo si pairing está explícito.

---

## 2. Pipeline obligatorio (no saltar pasos)

1. **Source inventory + provenance map** → `02_code/00_inventory.R`
2. **Definir unidad de análisis para cada resultado** → tagging en inventario
3. **Determinar evidence tier + límites inferenciales** → reference adequacy table
4. **Harmonizar trayectorias y escalares** → `01_harmonize.R`
5. **Ajustar modelos funcionales/time-frequency solo donde haya soporte** → `02_fpca_pace.R`, `04_cwt_morlet.R`
6. **Clasificación PTP/Type I-V/glycemic subtype solo donde se cumplan criterios** → `05_classify_ptp.R`
7. **Manuscrito + supplement** → `04_manuscript/`

Output no soportado → omitir del análisis principal y enviar al **"Residual Quantitative Gaps Ledger"** con explicación de por qué no fue estimable.

---

## 3. Reglas funcionales (FPCA)

- Decomposición: `x_ih(t) = B_ih + d_ih(t)`. FPCA primaria sobre el componente dinámico `d_ih(t)` dentro de estratos analyte-form.
- PACE-style cuando los tiempos son sparse/irregular (Yao, Müller & Wang 2005).
- Retener componentes superiores **solo si son estables y reproducibles**.
- Nomenclatura fija (orientación de signo según interpretabilidad fisiológica):
  - **PC1** = global amplitude component
  - **PC2** = early-versus-late temporal redistribution component
  - **PC3** = biphasic or higher-order temporal shape component
- Si una eigenfunción no se alinea al template fisiológico tras orientación → retener el score numéricamente, retirar la etiqueta fisiológica.
- **ξ₂ y ξ₃ son coordenadas ortogonales distintas.** El descriptor circular shape-balance derivado de (ξ₂, ξ₃) es **suplementario** y no reemplaza ξ₂/ξ₃ en la regla de clasificación primaria.
- Si el radio en (ξ₂, ξ₃) estandarizado es muy chico para interpretación angular estable → flag `unstable angular descriptor`.

---

## 4. Estandarización y clasificación

**Vector estandarizado primario por hormona (v2.0):** `Z_ih = [z(B_ih), z(ξ_ih1), z(ξ_ih2), z(ξ_ih3)]` — **4 coordenadas**, sin C.
El escalar corroborativo `C_ih` (AUC₃₀₋₁₈₀, peak, etc.) es **métrica de validación convergente**, no coordenada primaria. Su correlación de Spearman con ξ₁ debe ser ρ > 0.7 para señales secretoras como sanity check.

**Clases de señal:**
- *Secretion-dominant*: GIP, GLP-1, PYY, insulin
- *Suppression-dominant*: ghrelin
- *Context-dependent regulatory*: glucagon
- *Glycemic regulation*: glucose

**Referencia:** Lean-Healthy define la distribución de referencia. Preferir región bivariada / elipse en (ξ₂, ξ₃); fallback a percentiles separados si no hay soporte.

**Regla de clasificación correcta (v2.0):** `Basal + PC1 + ξ₂ + ξ₃` (4 coordenadas).
**NO usar:** `Basal + PC1 + secondary balance descriptor` (el descriptor circular es suplementario).
El escalar corroborativo C entra como métrica de **validación convergente**, no como coordenada de clasificación.

**Tres capas de salida:**
1. analyte-level PTP
2. Integrated Enteropancreatic Pattern Type I–V
3. Glucose subtype a/b/c

**Etiquetas de no-clasificación:** `not integrable`, `isolated glycemic discordance`, `indeterminate mixed axis`, `not classifiable`.

---

## 5. Reference adequacy gates

Por cada estrato analyte-form × challenge-class, evaluar soporte de Lean-Healthy:

- **robust** → estandarización y clasificación habilitadas
- **cautious** → reportar con ancho extra de IC y caveat
- **withheld** → no estandarizar; descriptor crudo + explicación

Tabla obligatoria: `03_outputs/tables/reference_adequacy.csv`.

---

## 6. Harmonization

- Alinear tiempo a meal onset (t = 0); ventana periprandial común prespecificada (0–180 min).
- Harmonizar unidades **dentro** del analyte form. **No mezclar** isoformas o assay forms incompatibles silenciosamente.
- Trackear meal challenge class (mixed-meal vs OGTT), texture (líquido vs sólido), caloric load, macronutriente.
- Comparaciones cross-cohort **dentro** de challenge class cuando sea posible; si no → residualización conservadora o estratificación + caveat explícito.
- Interpolación solo dentro del soporte observado, regla prespecificada. **No extrapolar** salvo que un escalar corroborativo lo exija — y entonces flag.

---

## 7. Time-frequency (CWT + HHT/EMD)

- CWT con complex Morlet sobre representaciones densas comunes.
- Descriptores admitidos: dominant period/scale, time to maximal local power, integrated local power en ventanas, phase angle, mean phase lag vs glucose, phase concentration, wavelet coherence vs glucose (sólo si paired analysis es soportable).
- **Restringir interpretación formal a regiones fuera del cone of influence (COI).**
- Extraer descriptores solo de regiones tiempo-escala clínicamente interpretables prespecificadas.
- HHT/EMD: solo visualización exploratoria de casos representativos. **No inferencia confirmatoria.**

---

## 8. Reglas estadísticas

- Declarar análisis como descriptive / ecological / participant-level / mixed según los datos disponibles.
- Cross-grupos: no-paramétrico o permutación **solo cuando** el número de unidades independientes y exchangeability sean soportables.
- Paired: requiere pairing explícito.
- Effect sizes e ICs: solo cuando estimables desde las unidades disponibles.
- Multiplicidad: control dentro de familias prespecificadas.
- Si n es muy chico para inferencia → contrastes descriptivos sólo + declaración explícita de "inference not supportable".

**No inventar:** p-values, q-values, ICs, varianzas explicadas, bootstrap stability, eigengaps, conteos categóricos.
**Si bootstrap no es posible** (unidades independientes insuficientes) → decirlo y **NO simular pseudo-réplicas desde una sola trayectoria media.**

---

## 9. Plausibilidad fisiológica (sanity checks, no priors forzados)

1. Ghrelin es suppression-dominant; meal-related suppression es central.
2. GLP-1 y PYY son secretion-dominant distal-gut; pueden mostrar enhancement supra-fisiológico post-cirugía (especialmente RYGB).
3. Insulin se interpreta junto con glucose context.
4. Glucagon es context-dependent; persistencia postprandial anormal es potencialmente disfisiológica.
5. SG ≠ RYGB: SG remueve fundus (fuente principal de ghrelin); RYGB reroutea nutrientes a íleon distal con efecto incretínico exagerado.

Usar estos anchors para detectar errores de digitización, fallas de orientación de signo, o sobreinterpretación implausible.

---

## 10. Formato JCEM

- Clinical Research Article: Title page · Structured abstract · Keywords · Introduction · Materials and Methods · Results · Discussion · Acknowledgments · **Data Availability** · References · Figure legends · Tables.
- Abstract estructurado dentro del límite de palabras de JCEM.
- Referencias **numeradas en orden de primera aparición**.
- Manuscrito principal conciso; tablas extensas (provenance, QC logs, hyperparameters, sensibilidad) → Supplement.
- **Figuras originales redibujadas** desde datos extraídos. **No reproducir** ni adaptar figuras de fuente.

---

## 11. Outputs requeridos en el reporte final

1. Revised Main Manuscript
2. Revised Appendix / Supplementary Material
3. Revised Main Tables
4. Revised Supplementary Tables
5. Revised Main Figures
6. Revised Supplementary Figures
7. Revised Table Titles and Footnotes
8. Revised Figure Titles and Legends
9. References (orden de primera aparición)
10. **Residual Quantitative Gaps or Unverified Fields ledger**

---

## 12. Estrategia de ejecución en 3 pases

- **Pase 1:** source inventory, analyte-form × challenge matrix, reference-support table, lista estricta estimable vs no-estimable.
- **Pase 2:** objetos analíticos — tablas harmonizadas, decisiones FPCA (retención + orientación), definiciones CWT, exports de clasificación determinística, gap ledger.
- **Pase 3:** solo después de congelar las tablas analíticas → manuscrito y supplement JCEM completos.
