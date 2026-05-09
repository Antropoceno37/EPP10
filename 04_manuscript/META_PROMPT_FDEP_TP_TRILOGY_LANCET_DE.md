# META-PROMPT v1.0 — Trilogía FDEP-TP para *The Lancet Diabetes & Endocrinology*

**Objetivo.** Optimizar el flujo completo (programas, herramientas, repositorios, métricas, workflows y hardware) en el Mac mini M4 Pro 24 GB para producir tres artículos hermanos (M1 — *Original Research* o *Article*) en *The Lancet Diabetes & Endocrinology*, derivados de *Periprandial Transition Profiles and Integrated Enteropancreatic Patterns I–V* (manuscrito ya empaquetado en `~/Research/PTP_JCEM/04_manuscript/lancet_de_submission_package/`), incorporando y referenciando los comentarios de revisión consolidados (Jenni AI rounds 1–4, sesión 2026-05-08/09).

**Autor único.** Dr. Héctor M. Virgen-Ayala · ORCID 0009-0006-2081-2286 · Universidad de Guadalajara / IMSS · `hectorvirgenmd@gmail.com`.

**Fecha de emisión.** 2026-05-09. **Idioma del meta-prompt.** Español académico. **Idioma de los artículos resultantes.** Inglés británico Lancet style.

---

## 0 · Estado actual del sistema (línea base verificada 2026-05-09)

| Componente | Versión | Estado |
|---|---|---|
| Hardware | Apple M4 Pro · 12 cores · 24 GB | ✓ |
| macOS | Sequoia 26.4.1 | ✓ |
| R | 4.6.0 (2026-04-24) arm64 + Apple Accelerate | ✓ |
| Quarto | 1.9.37 | ✓ |
| Pandoc | 3.9.0.2 | ✓ |
| xelatex / pdflatex | NO instalado | ✗ — requerirá MacTeX o equivalente para PDF nativo |
| Python venv | PyWavelets, EMD-signal | ✓ |
| Workspace | `~/Research/PTP_JCEM/` (00_setup → 04_manuscript) | ✓ |
| Master corpus | `master_table.csv` SHA-256 `2829cd78…` | ✓ congelado |
| Run output | `03_outputs/lancet_run_2026-05-08/` | ✓ |
| Submission package | `04_manuscript/lancet_de_submission_package/` | ✓ |
| OSF pre-registration | DOI 10.17605/OSF.IO/3CZRE · proyecto `tr469` · frozen 2026-04-22 | ✓ |
| Zenodo | concept DOI 10.5281/zenodo.19743544 · v1.3 DOI 10.5281/zenodo.19758429 | ✓ |
| GitHub | `sv8wmxnbp8-hash/EPP10` v1·3 · CC-BY 4·0 | ✓ |

---

## 1 · Definición de la trilogía FDEP-TP

Las tres piezas comparten datos (`master_table.csv`), pre-registro OSF, depósito Zenodo y GitHub, y framework taxonómico FDEP-TP (renombrado de PTP/IEP en este corpus para reforzar la marca arquitectónica). Cada artículo enfatiza **una de las tres capas jerárquicas L1 → L2 → L3** del marco.

| # | Capa | Título de trabajo | Foco | Audiencia primaria | Display items |
|---|---|---|---|---|---|
| **A1** | **L1 ontológica/fisiológica** | *Multivariate functional principal component eigenfunctions of the entero-pancreatic system: conceptual and physiological foundations of the FDEP-TP framework for periprandial phenotype characterisation* | Marco conceptual; los 4 ejes de covariación inter-hormonal con interpretación fisiológica directa; oscilador secreción↔inhibición; "physiologic periprandial responsiveness" reemplaza "secretory capacity" | Endocrinólogos clínicos, fisiólogos, internistas | DI1: arquitectura H-product · DI2: 4 eigenfunctions con anotación fisiológica · DI3: trayectorias media ± banda · DI4: heatmap PTP labels |
| **A2** | **L2 axiomática + L3 estadística** | *Mathematical and statistical foundations of the FDEP-TP framework: covariance operators, spectral decomposition, and BLUP estimation in sparse periprandial data* | 8 axiomas como teoremas; descomposición Karhunen-Loève multivariada; estimación FACEs/PACE no paramétrica del kernel; BLUP scores; Chiou normalisation; Happ-Greven PSD-by-construction; Golovkine 2025 K selection | Bioestadísticos, metodólogos FDA | DI1: schema KL multivariado · DI2: kernel estimation pipeline · DI3: eigenvalue spectrum + FVE · DI4: BLUP score recovery + simultaneous bands |
| **A3** | **L3 procedural + traslacional** | *Methodological and translational foundations of the FDEP-TP framework: PACE-mFPCA pipeline, PTP/IEP classification, and clinical implications across obesity, type 2 diabetes, and metabolic surgery* | Protocolo estandarizado de adquisición; pipeline computacional 16 scripts R; criterios diagnósticos cuantitativos PTP/IEP Tipos I–V; implicaciones terapéuticas (selección de agonistas, indicación de cirugía metabólica) | Clínicos, cirujanos metabólicos, investigadores traslacionales | DI1: protocolo de adquisición · DI2: pipeline computacional · DI3: prevalencia IEP por cohorte · DI4: árbol decisional terapéutico |

**Diferenciación inequívoca.** Los tres artículos NO duplican findings; cada uno es una pieza autocontenida con **sus propios resultados primarios** anclados en su capa:
- **A1**: descomposición de varianza inter-hormonal (4 ejes), PC1 incretínico=0·211, dominancia PYY 0·76 — interpretación fisiológica
- **A2**: teoremas L2·1–L2·8 con prueba citada, K=12 por criterio Golovkine, N/K=29·2, eigenvalues, kernel FACEs vs PACE
- **A3**: prevalencia Tipos I–V por cohorte, RYGBP V=43·3%, SG V=30·7%, T2DM III·I=29·5%, árbol decisional clínico

---

## 2 · Optimización del Mac mini M4 Pro 24 GB

### 2·1 BLAS y paralelismo R

Verificar que R 4.6 use Apple Accelerate (no OpenBLAS genérico):

```r
sessionInfo()$BLAS
# Esperado: /System/Library/Frameworks/Accelerate.framework/Versions/A/...
```

Para mFPCA con n=2,750 sujetos × 9 hormonas × 9 puntos temporales, la diagonalización del operador conjunto es el cuello de botella. Apple Accelerate provee ~150× speed-up sobre Reference BLAS; verificar con benchmark `bench::system_time(eigen(matrix(rnorm(2000^2), 2000)))` < 1 s.

```r
future::plan(future::multisession, workers = 8)  # 8 de 12 cores; reserva 4 para SO + render
options(future.globals.maxSize = 8 * 1024^3)     # 8 GB cap por worker
```

### 2·2 Memoria

Los archivos `mfpca_canonical.rds` (~2·5 MB) y `bootstrap_envelopes.rds` (~10 KB) son ligeros, pero el bootstrap de clasificación B=2000 con N=2,750 puede picar 6–8 GB transitoriamente. **Política de RAM**:

- Cerrar Chrome/Safari durante runs MFPCA y bootstrap
- Monitor RAM con `vm_stat` cada 30 s durante ejecución larga
- `data.table::setDTthreads(8)` para I/O de parquet
- `arrow::set_cpu_count(8)` para lectura columnar

### 2·3 Almacenamiento y caching

```bash
# Cache de Quarto: limitar a 2 GB para evitar disk pressure
quarto cache clear
defaults write com.quarto.QuartoApp CacheSizeMB -int 2048
```

Workspace en SSD interno (no iCloud sync para el directorio `01_data/` ni `03_outputs/`).

### 2·4 Instalación pendiente: TeX para PDF nativo

```bash
# Opción A: BasicTeX (~80 MB, suficiente para Lancet)
brew install --cask basictex
sudo tlmgr update --self
sudo tlmgr install collection-fontsrecommended xetex unicode-math fontspec mathtools tabularx booktabs caption

# Opción B: MacTeX completo (~5 GB)
brew install --cask mactex-no-gui
```

Después de BasicTeX, restaurar `format: pdf` en YAML del .qmd.

### 2·5 Word/Pages para verificación visual final

Lancet acepta `.docx` como formato canónico. Para verificación pre-submission:

```bash
brew install --cask libreoffice
# o
brew install --cask microsoft-word  # si licencia disponible
```

---

## 3 · Optimización del stack de software

### 3·1 R packages canónicos (ya instalados — verificar versiones)

```r
required <- c(
  "fdapace"  = "0.6.0",   # PACE FPCA (sensitivity)
  "face"     = "0.1-7",   # FACEs sparse covariance (primary)
  "MFPCA"    = "1.3-11",  # Happ-Greven multivariate
  "funData"  = "1.3-9",   # Functional data containers
  "fdasrvf"  = "*",       # SRSF registration (L3·6)
  "mgcv"     = "1.9",     # GAM smoothing
  "pointblank" = "0.12",  # Data validation
  "irr"      = "0.84",    # Cohen kappa
  "data.table" = "*",     # Fast I/O
  "arrow"    = "*",       # Parquet
  "future"   = "*",       # Parallelism
  "bench"    = "*",       # Benchmarking
  "ggplot2"  = "*",       # Plotting
  "patchwork" = "*",      # Multi-panel layout
  "ggsci"    = "*",       # Lancet color palette
  "officer"  = "*",       # Word table customisation
  "flextable" = "*",      # Lancet-style tables
  "WebPlotDigitizer" = "*" # Verification only
)
# Verificar con:
# installed.packages()[,c("Package","Version")] %>% as.data.frame() %>% filter(Package %in% names(required))
```

**Paquete nuevo a añadir para A1/A2/A3:** `ggsci::scale_color_lancet()` provee la paleta oficial de The Lancet (rojos, naranjas, azules) compatible con daltonismo.

### 3·2 Python venv (ya configurado)

```bash
cd ~/Research/PTP_JCEM
source .venv/bin/activate
pip install --upgrade pywavelets emd-signal numpy scipy scikit-learn matplotlib seaborn
# Para A2 (cualquier diagnóstico espectral adicional)
pip install pyts tslearn  # time-series feature extraction
```

### 3·3 Quarto + Lancet template

```bash
# Descargar plantilla Lancet (CSL + reference-doc)
curl -L https://raw.githubusercontent.com/citation-style-language/styles/master/the-lancet.csl \
  -o ~/Research/PTP_JCEM/04_manuscript/lancet.csl

# Para reference-doc.docx con estilos Lancet — descargar de:
# https://www.thelancet.com/pb-assets/Lancet/authors/ldelancet-information-for-authors.pdf
# (template no público; usar default Quarto + ajuste manual en Word)
```

Restaurar en YAML de cada `.qmd`:

```yaml
format:
  docx:
    reference-doc: lancet_template.docx
    toc: false
  pdf:
    documentclass: article
    geometry: margin=2.2cm
csl: lancet.csl
bibliography: refs.bib
```

### 3·4 Git/GitHub configuración

```bash
# Branches por artículo (para no contaminar el v1·3 del PTP/IEP master)
cd ~/Research/PTP_JCEM
git checkout -b lancet-A1-conceptual
git checkout -b lancet-A2-mathematical
git checkout -b lancet-A3-methodological
```

GitHub remote: crear releases por artículo (`A1-v1.0`, `A2-v1.0`, `A3-v1.0`) tras revisión.

---

## 4 · Arquitectura de identificadores y repositorios

### 4·1 Estrategia OSF

**Decisión recomendada.** Mantener `OSF.IO/3CZRE` como pre-registro **paraguas** del marco FDEP-TP. Crear tres sub-componentes (`/A1`, `/A2`, `/A3`) que apunten al pre-registro maestro y declaren el foco específico de cada artículo. Esto evita la fragmentación y mantiene la trazabilidad metodológica.

Alternativa (sólo si OSF policy lo exige): tres pre-registros independientes con cross-reference.

### 4·2 Estrategia Zenodo

Estructura propuesta:

| Versión | DOI esperado | Contenido |
|---|---|---|
| concept | 10.5281/zenodo.19743544 | Master concept (sin cambios) |
| v1·3 | 10.5281/zenodo.19758429 | Snapshot del run lancet 2026-05-08 (ya depositado) |
| v2·0-A1 | (nuevo) | Snapshot tras A1 submission (mismo data, sólo manuscript A1 + DI A1) |
| v2·0-A2 | (nuevo) | Snapshot tras A2 submission (mismo data, manuscript A2 + DI A2) |
| v2·0-A3 | (nuevo) | Snapshot tras A3 submission (mismo data, manuscript A3 + DI A3 + protocol) |

### 4·3 GitHub repository

- `main` branch: estado actual v1·3 (PTP/IEP Lancet manuscript empaquetado)
- `lancet-A1-conceptual` branch: A1 desarrollo (con `04_manuscript/A1/`)
- `lancet-A2-mathematical` branch: A2 desarrollo (con `04_manuscript/A2/`)
- `lancet-A3-methodological` branch: A3 desarrollo (con `04_manuscript/A3/`)
- Tags: `A1-submitted-YYYY-MM-DD`, `A2-submitted-YYYY-MM-DD`, `A3-submitted-YYYY-MM-DD`

---

## 5 · Estructura de workspace propuesta

```
~/Research/PTP_JCEM/
├── 00_setup/                              # Scripts de inicialización
├── 01_data/
│   ├── raw/master_table.csv              # SHA-256 2829cd78… (frozen)
│   └── processed/                        # Outputs de 01_harmonize.R
├── 02_code/                              # 16 scripts R (sin cambios)
│   ├── 01_harmonize.R                    # ingest + GP AR(1)
│   ├── 02_fpca_pace.R                    # PACE univariate (sensitivity)
│   ├── 03_mfpca_happgreven.R             # FACEs + Happ-Greven (primary)
│   ├── 04b_srsf_registration.R           # SRSF L3·6
│   ├── 05_classify_ptp.R                 # 9-label PTP
│   ├── 05b_iep_perm.R                    # 8-rule IEP types
│   ├── 06_inference.R                    # Pillai + FANOVA
│   ├── 06b_mahalanobis.R                 # Mahalanobis distances
│   ├── 07_bootstrap.R                    # B=50 pipeline + B=2000 classification
│   ├── 08_figures.R                      # Generic figures
│   ├── 08b_lancet_figs.R                 # Lancet-aesthetic
│   └── 09_sensitivity.R                  # 4 pre-specified
├── 03_outputs/
│   ├── lancet_run_2026-05-08/            # PTP/IEP master run (frozen)
│   ├── A1_run_YYYY-MM-DD/                # A1-specific outputs (subset of master)
│   ├── A2_run_YYYY-MM-DD/                # A2-specific outputs
│   └── A3_run_YYYY-MM-DD/                # A3-specific outputs
├── 04_manuscript/
│   ├── lancet_de_v1.qmd                  # PTP/IEP master (frozen post-revision)
│   ├── lancet_de_submission_package/     # PTP/IEP submission (frozen)
│   ├── A1/                               # NEW
│   │   ├── manuscript.qmd
│   │   ├── refs_A1.bib
│   │   ├── display_items/
│   │   ├── cover_letter.md
│   │   ├── numerical_ledger_A1.md
│   │   └── verification_A1.md
│   ├── A2/                               # NEW
│   │   ├── manuscript.qmd
│   │   ├── refs_A2.bib
│   │   ├── display_items/
│   │   ├── cover_letter.md
│   │   ├── numerical_ledger_A2.md
│   │   └── verification_A2.md
│   └── A3/                               # NEW
│       ├── manuscript.qmd
│       ├── refs_A3.bib
│       ├── display_items/
│       ├── cover_letter.md
│       ├── protocol_appendix.md          # Specific to A3
│       ├── numerical_ledger_A3.md
│       └── verification_A3.md
├── governance.md                         # Rules; updated with A1/A2/A3 gates
├── verification.md                       # 10-module audit; per article
├── framework.md                          # Frozen v2·0
├── manuscript_canonical.md               # Frozen
├── sap.md                                # SAP roadmap
└── README.md                             # Updated index
```

---

## 6 · Optimización de pipelines (reuso + extensiones por artículo)

### 6·1 Pipeline base reutilizado (sin cambios)

Los 16 scripts del pipeline canónico operan sobre `master_table.csv` y producen los outputs en `03_outputs/lancet_run_2026-05-08/`. **Ningún script se modifica para los tres artículos hermanos**; todos reutilizan los mismos `.rds` y `.csv` master.

### 6·2 Scripts específicos por artículo

Cada artículo añade un único script de extracción de su subset de figuras/tablas:

| Artículo | Script nuevo | Función |
|---|---|---|
| A1 | `10_A1_conceptual_figs.R` | Genera 4 eigenfunction panels con anotación fisiológica |
| A2 | `10_A2_mathematical_figs.R` | Genera schema KL, kernel pipeline, eigenvalue spectrum, BLUP scores |
| A3 | `10_A3_methodological_figs.R` | Genera protocolo, pipeline computacional, decision tree |

Todos los scripts leen de `03_outputs/lancet_run_2026-05-08/*.rds` y escriben a `03_outputs/A{1,2,3}_run_YYYY-MM-DD/`.

### 6·3 Métricas comunes reportadas en los tres artículos

Para anti-F8 (cifras coherentes entre artículos):

- N_studies = 23, N_tuples = 71, N_arms = 55, N_pseudo = 2,750
- K = 12, FVE = 92%, N/K = 29·2
- PC1 incretin loading = 0·211 · PYY total dominance = 0·762
- Pillai omnibus F = 18·29; Post-CR F = 52·09 (rank 1)
- Type V RYGBP = 43·3% · SG = 30·7% · ref = 18·8%
- Type III·I T2DM = 29·5% · Type III obesity_T2DM = 40·0% · Post-CR = 36·8%
- Type I·I non-obese without T2D = 32·2% · 23·1% not-classifiable
- Bootstrap classification stability ≥ 80%

**Cada cifra remite a `numerical_ledger.md` (master) y al ledger específico del artículo.**

---

## 7 · Validación, QA y framework anti-F1–F9

### 7·1 Modos de fallo a verificar en cada artículo

| Modo | Descripción | Aplica A1 | A2 | A3 |
|---|---|---|---|---|
| F1 | Mezclar JCEM/Lancet styling | ✓ | ✓ | ✓ |
| F2 | Axiomas como "we assume" en lugar de teoremas | – | ✓✓ (crítico) | ✓ |
| F3 | PACE como primary en lugar de FACEs | – | ✓✓ | ✓ |
| F4 | AUC/peak/TTP como outcome primario | ✓ | – | ✓✓ |
| F5 | Reclamar predicción de outcomes individuales | ✓ | – | ✓✓ |
| F6 | Tratar pseudo-IPD AR(1) como base inferencial | – | ✓✓ | ✓ |
| F7 | Mencionar "secretory capacity" | ✓✓ | – | ✓ |
| F8 | Apertura con epidemiología en lugar de gap metodológico | ✓ | ✓ | ✓ |
| F9 | Reportar p-values < B⁻¹ como informativos | – | ✓✓ | ✓ |

✓✓ = revisión crítica obligatoria; ✓ = revisión estándar; – = no aplica directamente.

### 7·2 Checklist STROBE / TRIPOD por artículo

- A1: STROBE cohort; TRIPOD+AI N/A (sin modelo predictivo individual)
- A2: STROBE; TRIPOD+AI N/A (estadística metodológica)
- A3: STROBE + protocol appendix; TRIPOD+AI **declarar pendiente** (extension del marco a uso clínico individual será TRIPOD+AI cuando se valide prospectivamente — A3 abre esta línea pero no la cierra)

### 7·3 Forbidden words check (todos los artículos)

```bash
# En cada manuscrito final, verificar:
grep -i "novel\|robust\|comprehensive\|gold standard\|secretory capacity\|Hilbert-geometric\|medRxiv 2026-351723" manuscript.qmd
# Esperado: 0 hits en los tres
```

### 7·4 Métricas de calidad por artículo

| Métrica | A1 | A2 | A3 |
|---|---|---|---|
| Word count main text | ≤ 5,000 | ≤ 5,000 | ≤ 5,000 |
| Summary | ≤ 300 | ≤ 300 | ≤ 300 |
| Cover letter | ≤ 500 | ≤ 500 | ≤ 500 |
| References | ≤ 30 | ≤ 30 | ≤ 30 |
| IF coverage clínicas | ≥ 80% IF > 10 | N/A (mostly methodological) | ≥ 80% IF > 10 |
| Display items | 4 | 4 | 4 |

---

## 8 · Matriz de incorporación de comentarios de revisión

Cada uno de los 11 comentarios de revisión consolidados en la sesión 2026-05-08/09 debe quedar incorporado a uno o más de los tres artículos. La matriz garantiza no-duplicación y trazabilidad.

| # | Comentario | Resolución en MS PTP/IEP | A1 | A2 | A3 |
|---|---|---|---|---|---|
| C1/C5/C8 | Tipo V RYGBP vs SG (Lobato 2025); diseño ecológico | Párrafo §Mechanistic interpretation; sufijos a/b/c clarificados | – | – | ✓✓ (foco traslacional) |
| C2 | mFPCA vs PARAFAC (Shi 2024) | L3·3 párrafo extendido | ✓ (mención) | ✓✓ (sustento matemático) | – |
| C3 | Métricas L3·9/anti-F9 sin contexto | Tabla 3 → Suplementario S1 | – | ✓ | – |
| C4/C8 | "Tipo VI" para agonistas triple-receptor | §Implications párrafo farmacológico | ✓ (mención conceptual) | – | ✓✓ (selección de agonistas) |
| C5 | K selection Golovkine 2025 | L3·5 + Findings + Strengths | – | ✓✓ (criterio formal) | – |
| C6 | Sensibilidad ρ del kernel AR(1) / suavizado picos | L3·1 (μ_h(t) = digitised mean) + L3·10 (ρ=0·3 specifically probes rapid peaks) + L3·6 (SRSF safeguard) | – | ✓✓ (justificación estadística completa) | ✓ |
| C7 | 11 vs 9 analitos | Summary + Table 1 footnote | ✓ | ✓ | ✓ |
| Reference cohort 23·1% not-classifiable | Triple sentence specifying single-analyte source arms | ✓ | ✓ | ✓ |
| A priori PTP/IEP design | §Classification párrafo a priori; §Strengths bullet | ✓ (foco fisiológico) | ✓ | ✓ |
| Title attribution to author (no "Hilbert-geometric") | Título PTP/IEP-centred adoptado | ✓ | ✓ | ✓ |
| Three-tier reviewer responses (Jenni AI rounds 1-4) | 11 cambios aplicados al .qmd v1 | – | – | – |

---

## 9 · Preparación de submission por artículo

### 9·1 Submission package estructura (idéntica para A1/A2/A3)

```
A{1,2,3}/
├── manuscript.docx              # Lancet primary submission format
├── manuscript_preview.html      # Self-contained preview
├── manuscript_source.qmd        # Quarto source
├── cover_letter.docx
├── cover_letter.md
├── display_items/
│   ├── DI1.{svg,png}            # 300 dpi
│   ├── DI2.{svg,png}
│   ├── DI3.{svg,png}
│   └── DI4.{svg,png}
├── outputs/tables/              # CSV de cifras
├── numerical_ledger.md          # Single source of truth
├── verification_report.md       # 10-module audit M1-M10 + F1-F9
└── README.md                    # Package index
```

### 9·2 Checklist pre-submission Lancet D&E (por artículo)

- [ ] Title ≤ 25 palabras, declarativo, sin atribución implícita a constructo matemático
- [ ] Summary ≤ 300 palabras, estructura Background/Methods/Findings/Interpretation/Funding
- [ ] Research-in-context box (3 bloques)
- [ ] Methods ≤ 1,500 palabras
- [ ] Findings ≤ 2,000 palabras con cifras coherentes con `numerical_ledger.md`
- [ ] Discussion ≤ 1,500 palabras con limitaciones declaradas
- [ ] References ≤ 30, ≥ 80% IF > 10 (excepto A2)
- [ ] 4 display items con captions de longitud Lancet
- [ ] AI/LLM disclosure verbatim
- [ ] Funding statement: "None. The author had full access to all data and final responsibility for the decision to submit for publication."
- [ ] Suggested reviewers: Wagner, Frøslie, Bojsen-Møller, Greven, Müller (más reviewers específicos por artículo)
- [ ] Excluded reviewers: ninguno; declaración explícita de no competing interests
- [ ] STROBE checklist en Suppl. S1
- [ ] Cover letter ≤ 500 palabras: gap → journal precedent → contribution → reproducibility → reviewers
- [ ] Verification report con 0 hits a F1–F9 y forbidden words
- [ ] Submission package empaquetado y deposited en Zenodo v2·0-A{1,2,3}

### 9·3 Reviewers sugeridos por artículo

| Artículo | Reviewers sugeridos primarios |
|---|---|
| **A1** (conceptual/fisiológico) | Drucker DJ (Toronto, *Cell Metab*) · Holst JJ (Copenhagen, *Physiol Rev*) · Steinert RE (Adelaide/Zurich, *Physiol Rev*) · Madsbad S (Hvidovre, *Lancet D&E*) · Nauck MA (Bochum, *Diabetologia*) |
| **A2** (matemático/estadístico) | Greven S (HU Berlin, *JASA*) · Müller HG (UC Davis, *JASA*) · Crainiceanu CM (JHU, *Stat Comput*) · Hsing T (Michigan, *Ann Stat*) · Goldsmith J (Columbia, *Biometrics*) |
| **A3** (metodológico/traslacional) | Wagner R (Tübingen, *Nat Med*) · Bojsen-Møller KN (Hvidovre, *Diabetes*) · Frías JP (Velocity Clinical, *NEJM*) · Rubino F (King's College, *Lancet D&E*) · Cummings DE (Washington, *Diabetes Care*) |

---

## 10 · Workflow de ejecución secuencial

### 10·1 Fase 0 — Pre-flight (1 día)

```bash
# 1. Verificar línea base
cd ~/Research/PTP_JCEM
git status
git checkout main
git pull

# 2. Crear branches
git checkout -b lancet-A1-conceptual
git checkout -b lancet-A2-mathematical
git checkout -b lancet-A3-methodological

# 3. Crear directorios
mkdir -p 04_manuscript/{A1,A2,A3}/{display_items,outputs/tables}

# 4. Instalar TeX (opcional, mejora PDF)
brew install --cask basictex
sudo tlmgr update --self
sudo tlmgr install collection-fontsrecommended xetex unicode-math fontspec mathtools tabularx booktabs caption ifsym

# 5. Descargar Lancet CSL
curl -L https://raw.githubusercontent.com/citation-style-language/styles/master/the-lancet.csl \
  -o 04_manuscript/lancet.csl

# 6. Verificar paquetes R
Rscript -e 'pkgs <- c("face","MFPCA","fdapace","funData","fdasrvf","ggsci","officer","flextable"); invisible(sapply(pkgs, require, character.only=TRUE, quietly=TRUE)); cat("OK\n")'
```

### 10·2 Fase 1 — Ejecución por artículo (orden recomendado: A2 → A1 → A3)

**Justificación del orden.** A2 establece el sustento matemático/estadístico; A1 lo traduce a fisiología; A3 lo opera clínicamente. Empezar por A2 garantiza que los teoremas y métodos estén bien fundados antes de aplicarse en A1 y A3.

#### Ejecución A2 (matemático/estadístico) — 7 días

1. Día 1–2: borrador `04_manuscript/A2/manuscript.qmd` desde la capa L2 + L3 del meta-prompt PTP/IEP
2. Día 3: ejecutar `02_code/10_A2_mathematical_figs.R` → `03_outputs/A2_run_*/`
3. Día 4: redacción Methods + Findings con énfasis en teoremas con prueba citada
4. Día 5: Discussion focalizada en sustento matemático
5. Día 6: cover letter + verification report A2
6. Día 7: render `.docx` + `.html` + Zenodo deposit + GitHub tag

#### Ejecución A1 (conceptual/fisiológico) — 7 días

1. Día 8–9: borrador `04_manuscript/A1/manuscript.qmd` desde la capa L1 ontológica
2. Día 10: figuras conceptuales (`10_A1_conceptual_figs.R`)
3. Día 11–12: redacción con énfasis en interpretación fisiológica de los 4 ejes mFPCA
4. Día 13: cover letter + verification A1
5. Día 14: render + Zenodo + GitHub

#### Ejecución A3 (metodológico/traslacional) — 7 días

1. Día 15–16: borrador `04_manuscript/A3/manuscript.qmd` con énfasis en pipeline + protocolo + criterios diagnósticos
2. Día 17: árbol decisional terapéutico + figura de selección de agonistas
3. Día 18–19: redacción con foco clínico (obesidad, T2DM, indicación quirúrgica)
4. Día 20: cover letter + verification A3
5. Día 21: render + Zenodo + GitHub

### 10·3 Fase 2 — Submission (3 días)

1. Día 22: submission portal Lancet D&E para A2 (primer envío; el más maduro metodológicamente)
2. Día 23: submission A1
3. Día 24: submission A3

**Estrategia de espaciado.** Lancet D&E permite múltiples submissions del mismo autor pero el editor preferirá ver el portafolio coherente. Considerar enviar A2 primero, esperar 2 semanas, luego A1 y A3 con cover letters que crucen-citen explícitamente A2 como ya en revisión.

---

## 11 · Métricas de éxito y criterios de cierre

### 11·1 Por artículo

- ✓ Render `.docx` exitoso sin warnings
- ✓ `verification_report.md` con 0 hits a F1–F9
- ✓ `numerical_ledger.md` consistente con master ledger
- ✓ ≥ 80% referencias clínicas IF > 10 (A1, A3)
- ✓ Word count en límite Lancet
- ✓ 4 display items 300 dpi
- ✓ Zenodo v2·0-A{i} depositado con DOI mintado
- ✓ GitHub tag `A{i}-submitted-YYYY-MM-DD` creado

### 11·2 Trilogía completa

- ✓ Tres `.docx` submission-ready en `04_manuscript/A{1,2,3}/`
- ✓ Cifras coherentes entre los tres artículos (anti-F8 cross-article)
- ✓ Zero overlap de findings primarios entre artículos
- ✓ OSF sub-componentes /A1, /A2, /A3 enlazados al master
- ✓ Reviewers sugeridos diferenciados (mínimo 3 únicos por artículo)
- ✓ Cross-citation policy: A1/A3 pueden citar A2 cuando esté en revisión (acknowledged como sister manuscript); A2 NO cita A1/A3 (independencia metodológica)

### 11·3 Métricas de hardware (post-runs)

- ✓ Tiempo de render por `.docx`: < 30 s
- ✓ Pipeline completo (16 scripts) end-to-end: < 30 min con paralelismo 8 cores
- ✓ Memoria pico durante MFPCA + bootstrap: < 16 GB
- ✓ Disk usage del workspace completo (incluyendo 03_outputs A1/A2/A3): < 5 GB

---

## 12 · Riesgos y contingencias

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Editor de Lancet considera los 3 artículos como "salami slicing" | Media | Alto | Cover letters explican capas L1/L2/L3 como diferenciación legítima; A2 puede dirigirse a *Statistics in Medicine* o *Biometrics* como alternativa |
| Solapamiento detectado por iThenticate | Baja | Alto | Cada artículo redactado de novo desde el meta-prompt; cifras compartidas son inevitables pero la prosa es independiente |
| TeX no instalado bloquea PDF nativo | Alta | Bajo | `.docx` es el formato canónico Lancet; PDF se genera desde Word/Pages externamente |
| OSF no permite sub-componentes anidados | Baja | Medio | Plan B: tres pre-registros independientes con cross-reference |
| Reviewers solicitan datos individuales | Alta | Medio | Pre-registrado como ecological proof-of-concept; declarado en Methods + Limitations + Discussion |
| Los 4 ejes mFPCA del A1 no admiten interpretación fisiológica clean | Media | Alto | A1 dependiente del mismo run del PTP/IEP master; los 4 ejes ya tienen anotación preliminar (PC1=PYY/incretin; PC2=early/late; PC3=biphasic; PC4=ghrelin); A1 las desarrolla con literatura IF > 10 |

---

## 13 · Cláusulas finales

### 13·1 Disclosure verbatim (obligatoria en los tres artículos)

> "Analytic pipeline design, R code implementation, and manuscript drafting were supported by Claude (Anthropic, Opus 4.7 / Sonnet 4.6, May 2026). All statistical outputs, pre-registration decisions, and scientific claims were validated by the author against the v10·0 master analysis plan (OSF DOI 10.17605/OSF.IO/3CZRE) and the FDEP-TP framework v2·0 reference document."

### 13·2 Funding statement verbatim

> "None. The author had full access to all data and final responsibility for the decision to submit for publication."

### 13·3 Competing interests

> "The author declares no competing interests, no industry support, and no funding for this work."

### 13·4 Data sharing verbatim

> "All digitised periprandial trajectories, the harmonised cohort corpus (`master_table.csv`, SHA-256 `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`), the 16-script analytic pipeline, the article-specific outputs, and the reproducibility scripts are deposited at Zenodo (concept DOI 10.5281/zenodo.19743544; article-specific version DOIs cited in each manuscript) and GitHub (`sv8wmxnbp8-hash/EPP10` v1·3 and subsequent branches) under CC-BY 4·0. The repository permits full reproduction of every numerical claim and follows FAIR data principles. Pre-registration is at the Open Science Framework (DOI 10.17605/OSF.IO/3CZRE; project at https://osf.io/tr469, frozen 2026-04-22)."

---

**Fin del meta-prompt.**

**Para iniciar la ejecución:** abrir nueva sesión Claude con este documento adjunto + los tres documentos fuente referenciados + `master_table.csv` + `lancet_de_v1.qmd`, y ordenar: *"Ejecuta la Fase 0 del meta-prompt y produce el borrador inicial de A2 manuscript.qmd."*
