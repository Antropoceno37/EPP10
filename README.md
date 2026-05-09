# PTP_JCEM — Periprandial Transition Profiles & Enteropancreatic Patterns

**Workspace de investigación reproducible para el manuscrito JCEM**
Dr. Héctor M. Virgen Ayala · Cirugía general e investigación clínica · Guadalajara, México
Versión 1.0 · Mac mini M4 Pro 24 GB · Semilla maestra `20260502`

---

## Estructura

```
~/Research/PTP_JCEM/
├── 00_setup/        Instaladores, .Renviron, .Rprofile, wrappers
├── 01_data/         raw · digitized · harmonized · synthetic
├── 02_code/         9 scripts numerados (00_inventory → 08_figures)
├── 03_outputs/      figures · tables · logs
├── 04_manuscript/   Quarto reproducible + supplement + refs.bib
├── framework.md     ★ FDEP-TP v2.0 (PRIMARY — prevalece sobre todo)
├── verification.md  10 módulos de auditoría (M1–M10)
├── governance.md    Capa de calidad (gates anti-alucinación, alineada a v2.0)
├── sap.md           SAP operativo y plan de cómputo (pipeline 5 capas)
├── run_pipeline.sh  Orquesta 00 → 08 secuencial
└── README.md        Este archivo
```

## Setup (una vez)

```bash
cd ~/Research/PTP_JCEM
bash 00_setup/01_install_macos_toolchain.sh    # Homebrew + R + Quarto + gfortran
Rscript 00_setup/02_install_r_packages.R       # ~15-30 min, en background
bash 00_setup/03_install_python_tfa.sh         # Python venv para CWT/HHT
```

## Correr el pipeline completo

```bash
bash run_pipeline.sh                           # corrida normal
bash 00_setup/caffeinate_run.sh ./run_pipeline.sh   # corridas largas (no duerme)
```

Cada script en `02_code/` puede correrse aislado; lee del paso anterior y escribe al siguiente vía Parquet en `01_data/harmonized/` y RDS en `03_outputs/`.

## Capas de gobernanza (jerarquía estricta — lee antes de modificar nada)

1. **`manuscript_canonical.md`** ⟵ **PRIMARY** · El manuscrito real submeteado a medRxiv (id **2026-351723v1**, en revisión, OSF [x4gzt](https://osf.io/x4gzt/)). Cualquier conflicto con otros documentos se resuelve a favor del manuscrito canónico.
2. **`framework.md`** · FDEP-TP v2.0 (Abril 2026, Informe Ejecutivo). Vector primario 4 coordenadas, 15 etiquetas PTP, Types I–V, jerarquía D2>D1>U2>U1>L2>L1>R, pipeline 5 capas. **Nota:** algunas decisiones operativas (e.g., 15 vs 9 etiquetas PTP) fueron actualizadas en el manuscrito canónico — ver discrepancias en `manuscript_canonical.md`.
3. **`verification.md`** · Auditoría exhaustiva en 10 módulos (M1–M10) auto-aplicable a cualquier output del pipeline. Severidad CR/MA/ME.
4. **`governance.md`** · Capa de calidad e inferencia (Doc 1 alineado a v2.0): inference ladder, gates de soporte, reglas FPCA/CWT, formato JCEM.
5. **`sap.md`** · Plan operativo y cómputo (Doc 2): pipeline de 5 capas, escenarios A–D con perfil RAM M4 Pro.

**Regla de prevalencia:** `manuscript_canonical.md` > `framework.md` > `verification.md` > `governance.md` > `sap.md` > scripts.

## Régimen dual

- **POC actual** (proof-of-concept con trayectorias digitalizadas): solo nivel ecológico cohort-time-arm. Prohibido bootstrap de pseudo-réplicas, lme4 subject-level, p-values con n insuficiente.
- **Confirmatorio futuro** (n=250–500 sujetos prospectivos): habilita lme4, MFPCA con scores subject-level, bootstrap real.

Los gates de `governance.md` se aplican automáticamente — si un script no encuentra soporte adecuado, marca el output como `not classifiable / not integrable / indeterminate mixed axis` en lugar de fabricar resultados.

## Reproducibilidad

- `renv` bloquea versiones de paquetes R (`renv::snapshot()` después de cada cambio).
- Semilla maestra `20260502` en todos los scripts.
- `sessioninfo::session_info()` se loguea en `03_outputs/logs/` cada corrida.
- Pre-registro en OSF antes del análisis confirmatorio.
- Releases firmadas en GitHub + DOI Zenodo.

## Hardware tuning

`Renviron` y `Rprofile` están simlinkados desde `00_setup/` a `$HOME`. Mantienen R en 4 workers / 4 threads BLAS, dejando 4 perf cores + 4 eff para macOS y Quarto. **No subir a 8 workers** — duplicaría la huella y rompería en escenarios B/C del SAP.
