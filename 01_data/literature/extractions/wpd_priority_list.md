# Lista priorizada para WebPlotDigitizer manual

> Generada por `parse_literature.py` tras PRISMA 2020 + dedup.
> 15 papers únicos · 2,359 sujetos acumulados · cobertura completa (7 cohortes × 11 hormonas).

## Workflow recomendado

1. **Verifica si el paper ya está en `master_table.csv` actual** (los 23 estudios originales). Si está, salta a evitar duplicación.
2. Abre el PDF en WebPlotDigitizer v4.7 ([https://automeris.io/wpd/](https://automeris.io/wpd/)).
3. **Double-extraction protocol** (ICC ≥ 0.95, manuscrito §2.5): extrae 2 veces en sesiones separadas, computa ICC, conserva si ≥ 0.95.
4. Exporta como CSV: cols `time_min, value`, una por hormona × cohort.
5. Append a `01_data/literature/extractions/trajectories.csv` con cols esperadas:
   `cohort, hormone, time_min, mean_value, n, source_study, challenge_class`
6. Re-corre `python 02_code/parse_literature.py merge` para integrar al master_table.

## Top 10 papers priorizados (por cobertura analítica)

| # | Paper | n | Hormonas | Cohortes | Tables auto | Prioridad |
|---|---|---|---|---|---|---|
| 1 | NEJM_style_PTP_enteropancreatic_manuscript_v5.pdf (**TU manuscrito v5**) | 14 | 7 | 7 | 20 | 🟢 ya en master |
| 2 | Olivan 2009 — Effect of Weight Loss by Diet or RYGB on PYY3-36 | 30 | 7 | 6 | 0 | 🔴 ALTA — NUEVO |
| 3 | Aukan 2022 — Differences in GI hormones among obesity classes | 45 | 8 | 5 | 0 | 🟡 ya en master (verificar) |
| 4 | Vilsbøll — Secretion of GIP in T2DM | 688 | 5 | 5 | 1 | 🔴 ALTA — n grande |
| 5 | Madsbad/Holst — Mechanisms of surgical control of T2DM (review) | 85 | 4 | 6 | 0 | 🟡 review (mecanístico, no IPD) |
| 6 | Appetite-related Gut Hormone Responses (Across the Life Course) | 20 | 6 | 4 | 0 | 🔴 ALTA — NUEVO |
| 7 | Comparison of Bariatric Surgical Procedures for Diabetes Remission | 250 | 3 | 6 | 4 | 🔴 ALTA — n grande |
| 8 | Enteroendocrine Patterns Meta-Analysis (¿companion?) | 847 | 3 | 6 | 18 | 🟡 verificar — quizás citing your work |
| 9 | Di Giuseppe 2025 — Altered GIP/GLP-1 Ratio + Impaired β-Cell | 23 | 6 | 3 | 0 | 🔴 ALTA — NUEVO 2025 |
| 10 | Theodorakis — Elevated GIP Associates With Hyperinsulinemia | 34 | 5 | 3 | 0 | 🔴 ALTA — incretinopathy classic |

## Papers excluidos (105) — desglose

| Razón | n |
|---|---|
| n=0 detectado < 5 (heurística no detectó N) | 83 |
| Sin challenge SMMT/LMMT/OGTT detectado | 10 |
| Sin glucose reportado | 8 |
| Sin pancreatic effector ni gut hormone | 3 |
| n explícito = 4 | 1 |

**Recomendación:** los 83 con `n=0` probablemente reportan N en formato no-estándar (ej. tabla en página 2, OCR pobre). Si quieres recuperarlos, ejecuta:

```bash
# Refinar a mano: edita 02_code/parse_literature.py PRISMA_CRITERIA,
# baja min_subjects a 1 (o quita el gate), re-corre prisma:
python 02_code/parse_literature.py prisma
```

## Integración con el manuscrito principal

Los 15 papers únicos cubren las 7 cohortes y las 11 analyte-forms canónicas. Su **valor primario** es:

1. **Para Discussion** (manuscrito §4): triangulación con literatura externa para los hallazgos canónicos:
   - GLP-1 RYGB 6.6× dynamic → corroborable en Olivan 2009 + Madsbad 2014
   - Ghrelin SG 30% LH → Vertical Banded Gastroplasty 2002 + Yousseif 2014
   - Insulin static-dynamic discordance → Theodorakis 2004 + Di Giuseppe 2025

2. **Para Introduction** (§1): justificar el gap "no MFPCA aplicado a multi-hormone" — los 15 papers usan FPCA univariada en mejor caso (Frøslie 2013, Renier 2024) pero ninguno multivariada conjunta.

3. **Para Limitations** (§4.4): el gap del 41.9% Type IV.II en cohorte Lean-Healthy se contextualiza con la heterogeneidad de protocolos en estos 15 papers.

## Comandos para próximos pasos

```bash
# Ver lista completa de papers incluidos
cat ~/Research/PTP_JCEM/01_data/literature/extractions/wpd_candidates_dedup.csv

# Render PRISMA synthesis a HTML para revisar
cd ~/Research/PTP_JCEM/04_manuscript/prisma
quarto render prisma_synthesis.qmd --to html
open prisma_synthesis.html

# Cuando termines digitización WPD de N papers, re-corre:
python ~/Research/PTP_JCEM/02_code/parse_literature.py merge
cat ~/Research/PTP_JCEM/01_data/raw/master_table.csv \
    <(tail -n +2 ~/Research/PTP_JCEM/01_data/literature/extractions/trajectories.csv) \
    > ~/Research/PTP_JCEM/01_data/raw/master_table_expanded.csv
mv ~/Research/PTP_JCEM/01_data/raw/master_table_expanded.csv ~/Research/PTP_JCEM/01_data/raw/master_table.csv
bash ~/Research/PTP_JCEM/run_pipeline.sh   # re-genera con master expandido
```
