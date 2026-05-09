# Verification — Auditoría exhaustiva en 10 módulos (síntesis del Prompt Final v2.0)

> Auditoría auto-aplicable de cualquier output del pipeline FDEP-TP contra el framework v2.0.
> Cada módulo se ejecuta secuencialmente; un módulo se aprueba sólo si todos sus checks aprueban.
> Severidad: **CR** = Crítica (bloquea manuscrito) · **MA** = Mayor (resolver pre-publicación) · **ME** = Menor (deseable).

---

## Tabla de síntesis (a llenar al final de cada auditoría)

| Mód. | Dominio | Estado | Checks | Sev. | Acciones requeridas |
|---|---|---|---|---|---|
| M1 | Terminología v2.0 | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M2 | Etiquetas PTP (6+9) | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M3 | Reglas Types I–V | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M4 | Alineación framework ↔ datos | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M5 | Reglas R1–R7 | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M6 | Coherencia fisiológica | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M7 | Estado de la investigación | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M8 | Rigor estadístico | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M9 | Conformidad JCEM | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |
| M10 | Validación cruzada global | ✅ / ❌ | N/N | CR/MA/ME | *[documentar]* |

---

## M1 — Coherencia terminológica v2.0

1. Sustitución completa de "capacidad secretora" → **"responsividad periprandial fisiológica"**. Buscar instancias residuales (`grep -ri "capacidad secretora"` debe devolver vacío). Aplicación coherente a:
   - secretion-dominant: GIP, GLP-1, PYY, insulin
   - suppression-dominant: ghrelin
   - glycemic regulation: glucose
2. **Vector primario de 4 coordenadas:** `Z_ih = [z(B), z(ξ₁), z(ξ₂), z(ξ₃)]`. Descriptor secundario de balance forma-temporal explícitamente suplementario, **nunca primario, nunca sustituto de ξ₂/ξ₃**.
3. **Pérdida de peso = modificador contextual**, no hard gate. Criterios post-intervención: (a) posición vs. Lean-Healthy; (b) dirección de cambio vs. pre-intervención.

**Aprobación:** cero instancias residuales; consistencia 100%.

---

## M2 — Integridad de etiquetas PTP (6 primarias + 9 secundarias)

4. **Primarias (6):** Preserved · Borderline Impaired · Impaired · Blunted · Borderline Altered · Altered. Cada una con: definición operativa, criterios estadísticos (cortes z), fallback percentil, nota fisiológica por tipo de señal.
5. **Secundarias (9):** {+Recovered, +Borderline Enhanced, +Enhanced} aplicadas a los 3 escenarios pre→post (Impaired/Blunted/Altered). Verificar:
   - Recovered requiere estado previo anormal.
   - Enhanced requiere glucosa Preserved/Recovered.
   - Enhanced **NO** se asigna con glucosa Altered.
6. **Upper-tail primarias** (Borderline Altered / Altered) sólo cuando el exceso es patofisiológicamente significativo. **GLP-1 elevado no es automáticamente Altered en datos transversales.**

**Aprobación:** 15 etiquetas sin solapamiento; co-requisitos Enhanced explícitos; bandas percentil coherentes.

---

## M3 — Reglas de integración Types I–V

7. **Clasificabilidad:** glucosa + ≥2 no-glucosa (insulina + ≥1 hormona intestinal). Sin imputación.
8. **Grupos de estado no-glucosa (7):** R, L1, L2, U1, U2, D1, D2. Mapeo exhaustivo y excluyente.
9. **Subtipos glucémicos a/b/c:** sólo Types III, IV, V. Types I/II sin sufijo (requieren glucosa subtipo a).
10. **Jerarquía de precedencia (10 reglas):** `D2 > D1 > U2 > U1 [condicional] > L2 > L1 > R`. Probar ≥3 casos hipotéticos. Enhanced + glucosa b/c (o L1/L2 con Enhanced) → Type V.
11. Definiciones Type I.I a V.II: condiciones, interpretación, coherencia con jerarquía.

**Aprobación:** 0 contradicciones lógicas; cobertura exhaustiva de combinaciones.

---

## M4 — Alineación framework ↔ datos archivados

12. Percentiles Lean-Healthy para las 4 coordenadas. Gaps **G1–G3 cerrados** (Pasos 1–2). **G8 pendiente.**
13. Cobertura de referencia: Glucose(8) full · Insulin(8) full · GIP(6) full · GLP-1(4) marginal · PYY(5) limited · Acyl-Ghrelin(2) excluido · Glucagon(2) excluido.
14. Varianza FPCA: cruce Tabla 2 vs. informe v2.0. Justificación de ξ₂ para GLP-1 (21%), GIP (16%), Glucose (11%).
15. Distribución PTP v5: cruce Parte C de Pasos 1–2. Altered T2D 43.8%; Discordant_High SG 30.8%; Enhanced 0%.
16. Distribución Types I–V: cruce Parte E vs. Guía Estratégica §6.2. Documentar discrepancias entre fuentes.
17. Estado de los 8 gaps: G1–G3 cerrados; G4–G5 confirmados; G6 atenuado; G7 resuelto; **G8 pendiente**.

**Aprobación:** cifras rastreables; gaps actualizados.

---

## M5 — Reglas operacionales R1–R7

18. **R1:** glucosa opcional para clasificabilidad analito-individual. **ALERTA:** verificar inconsistencia con regla de clasificabilidad (M3) que requiere glucosa para integración. Documentar versión prevaleciente.
19. **R2:** Enhanced glucosa-independiente a nivel analito; glucosa determina Type II vs V a nivel integrado.
20. **R3:** Subtipos a/b/c sólo Types III, IV, V. Sin sufijos en Types I/II.
21. **R4:** Discordant_High/Low ≠ Preserved. Bloquean Type I/II. Ghrelin blunted post-SG → Type V; GIP blunted post-RYGBP → Type V.
22. **R5:** Pérdida peso = modificador contextual. Consistencia con M1.
23. **R6:** ξ₂/ξ₃ en regla primaria; descriptor secundario suplementario. Consistencia con M1.
24. **R7:** Ausencia de Types I/II = hallazgo genuino de heterogeneidad, no fallo del framework.

**Aprobación:** 7 reglas sin contradicción; inconsistencia R1 documentada si existe.

---

## M6 — Coherencia fisiológica

25. Discordancia 41.9%: tasas analito-específicas coherentes con fisiopatología (GIP 58.7%, GLP-1 47.9%). Soporte: Nauck 1986; Toft-Nielsen 2001; Holst 2019.
26. Re-patternización bariátrica: SG suprime ghrelin / potencia GLP-1; RYGBP atenúa GIP. Soporte: le Roux 2006/7; Peterli 2012; Svane 2019.
27. Biphasicidad post-SG en PC3 GLP-1: soporte en datos y fisiología células L distales (Svendsen & Holst 2016).
28. Agrupación señales: ¿ghrelin puramente supresión-dominante? ¿Por qué PYY no aparece en agrupación explícita?
29. Type IV en Lean-Healthy (42–50%): discutir como **limitación del diseño ecológico**, no hallazgo fisiológico.

**Aprobación:** interpretaciones respaldadas por ≥1 referencia verificable; anomalías transparentes.

---

## M7 — Pertinencia respecto al estado actual de la investigación

30. PREDICT (Berry 2020): glucosa/triglicéridos/insulina pero **no** GLP-1/GIP/PYY/ghrelin.
31. Glucotypes (Hall 2018): patrones CGM intra-individuales vs. ejes hormonales ecológicos.
32. Clusters Ahlqvist (2018): 6 variables / 5 subgrupos diabetes vs. coordenadas funcionales / Types I–V.
33. Subphenotypes Wagner (2021): mención y diferenciación.
34. Agonistas duales GIP/GLP-1 (tirzepatida): Type IV + GIP altered → diana terapéutica. Soporte: Frías 2021.
35. Hipoglucemia post-bariátrica: Type V subtipo b. Soporte: Salehi 2014.
36. **Búsqueda web actualizada 2024–2026:** agonistas triples (retatrutida), nuevas cohortes con panel completo, avances en FPCA clínica. Identificar omisiones críticas.

**Aprobación:** posicionamiento correcto vs. ≥5 frameworks; sin omisiones de literatura 2024–2026.

---

## M8 — Rigor estadístico y metodológico

37. Pipeline de 5 capas: inputs, operaciones, outputs, validación documentados para cada capa.
38. FPCA Karhunen-Loève: justificación Ramsay & Silverman 2005; PC1/PC2/PC3 coherentes con varianza.
39. Univariada vs. multivariada: justificada por cobertura simultánea incompleta de los 7 analitos.
40. Región bivariada (ξ₂, ξ₃): elipse preferida; fallback percentil autorizado; **G8 pendiente**.
41. Multiplicidad: Benjamini-Hochberg FDR; BH q < 0.05.
42. Sensibilidad: leave-one-axis-out, ±0.5 SD, bootstrap stability.
43. Validez convergente: Spearman ρ = 0.77–0.83 (secretores); ρ = −0.33 (ghrelin).

**Aprobación:** pipeline completo; justificaciones correctas; controles documentados.

---

## M9 — Conformidad JCEM Original Investigation

44. **Título** incluye PTP, Types I–V, Static–Dynamic Discordance, condiciones clínicas.
45. **Estructura:** Abstract 250 + Intro 800 + Methods 2500 + Results 2000 + Discussion 2000 ≈ 7500 palabras.
46. **Key Points box:** 4 elementos (Problema, Evidencia, Mejora, Implicación). Específicos y cuantitativos.
47. **Limitaciones:** 3 consolidadas (cohort means, protocol heterogeneity, analyte coverage); evaluar adicionales: restricción 0–180 min, formas activas vs. totales, PYY sin agrupación explícita.
48. **Encuadre proof-of-concept** consistente; sin afirmaciones de validación clínica definitiva.

**Aprobación:** conformidad completa; limitaciones exhaustivas; encuadre consistente.

---

## M10 — Validación cruzada global

49. **Consistencia numérica:** cruzar cifras con fuentes primarias. Documentar discrepancias.
50. **Trazabilidad:** cada afirmación soportada por ≥1 documento archivado.
51. **Coherencia PTP ↔ Types:** distribuciones PTP compatibles con Types (e.g., Altered T2D → Type IV domina).
52. **Coherencia jerarquía ↔ definiciones:** mismos resultados al aplicar a datos.
53. **Cero datos fabricados:** nada ausente de materiales archivados.

**Aprobación:** cero discrepancias no explicadas; trazabilidad 100%; cero datos sin fuente.

---

## Mapeo módulos → documentos fuente

| Mód. | Dominio | Documentos fuente |
|---|---|---|
| M1 | Terminología v2.0 | Informe Ejecutivo v2.0 §II; PTP label set; `framework.md` §1 |
| M2 | Etiquetas PTP | Input investigador §7.1–7.2; `framework.md` §2 |
| M3 | Types I–V | Construction of Integrated Patterns; `framework.md` §3 |
| M4 | Datos archivados | Pasos 1–2 Consolidados; CSV maestro; `framework.md` §5 |
| M5 | Reglas R1–R7 | Informe v2.0 §VIII; `framework.md` §2.3 |
| M6 | Fisiología | Literature Review; 29 PDFs; Informe v1 §IV |
| M7 | Estado investigación | Literature Review §10; búsqueda web 2024–2026 |
| M8 | Estadística | Informe v1 §III–IV; `sap.md`; `framework.md` §4 |
| M9 | JCEM | Informe v2.0 §X; `framework.md` §8 |
| M10 | Cruzada | Todos los documentos (cruce sistemático) |

---

## Instrucciones de ejecución

1. Ejecutar secuencialmente M1 → M10. Completar cada módulo antes de avanzar.
2. Registrar APROBADO / FALLO / PARCIAL por check con justificación y referencia.
3. Severidad: CRÍTICA (bloquea manuscrito), MAYOR (resolver pre-publicación), MENOR (deseable).
4. Discrepancias numéricas: documentar ambas versiones y recomendar prevaleciente.
5. M7 requiere búsqueda web actualizada 2024–2026.
6. Producto final: `03_outputs/tables/verification_audit.csv` + reporte legible (`.md` o `.docx`).
