# Pipeline de literatura — Estrategias A + C combinadas

> **Objetivo combinado:**
> **(A)** Expandir `master_table.csv` con cohort-time-arms de literatura nueva.
> **(C)** Síntesis sistemática PRISMA 2020 para Introducción/Discusión del manuscrito.

## Estructura

```
01_data/literature/
├── pdfs/                       <-- COLOCA AQUÍ los PDFs a procesar
├── extractions/
│   ├── per_paper/              JSON estructurado por paper (paper_id.json)
│   ├── prisma_log.csv          decisiones inclusión/exclusión
│   └── trajectories.csv        trayectorias extraídas, append-able a master_table.csv
└── prisma/                     (mirror local — el output principal está en 04_manuscript/prisma/)
```

## Workflow operativo (4 comandos)

```bash
cd ~/Research/PTP_JCEM

# 1. Coloca los PDFs en 01_data/literature/pdfs/
# 2. Extrae texto, tablas, metadata, hormonas, cohortes detectadas:
python 02_code/parse_literature.py extract

# 3. Aplica PRISMA 2020 (inclusion/exclusion automáticos):
python 02_code/parse_literature.py prisma

# 4. Extrae trayectorias de papers incluidos:
python 02_code/parse_literature.py merge

# 5. Genera PRISMA flow + summary table:
python 02_code/parse_literature.py report

# 6. Re-corre el pipeline principal con master_table expandido:
cat 01_data/raw/master_table.csv \
    <(tail -n +2 01_data/literature/extractions/trajectories.csv) \
    > 01_data/raw/master_table_expanded.csv
mv 01_data/raw/master_table.csv 01_data/raw/master_table_v1.csv  # backup
mv 01_data/raw/master_table_expanded.csv 01_data/raw/master_table.csv
bash run_pipeline.sh
```

## Criterios PRISMA aplicados (refinables en `parse_literature.py`)

| Inclusión | Exclusión |
|---|---|
| n ≥ 5 sujetos por cohort | n < 5 |
| ≥4 timepoints periprandiales | < 4 timepoints |
| Glucose reportado + ≥1 (GLP-1/GIP/insulin) | Sin gut hormone ni effector pancreático |
| Challenge ∈ {SMMT, LMMT, OGTT} | Otros challenges (IV glucose, etc.) |
| Cohort canónica detectada | Sin cohort identificable |

## Calidad de extracción

- **Auto** (✅): tablas con timepoints + valores numéricos extraídas directamente.
- **Manual_required** (⚠️): solo tiene figuras → usa **WebPlotDigitizer v4.7** con double-extraction (ICC ≥0.95) según manuscrito §2.5.
- **Failed** (❌): PDF corrupto/protegido — extracción manual completa.

## Output downstream

- `01_data/literature/extractions/trajectories.csv` → integra a `master_table.csv` (estrategia A)
- `04_manuscript/prisma/flow_diagram.mmd` → PRISMA 2020 flow diagram (estrategia C)
- `04_manuscript/prisma/summary_table.md` → tabla incluidos para Discussion (estrategia C)
- `04_manuscript/prisma/prisma_synthesis.qmd` → render Quarto a HTML/DOCX
