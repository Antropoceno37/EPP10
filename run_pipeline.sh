#!/usr/bin/env bash
# run_pipeline.sh — Orquesta el pipeline 00 → 08.
# Cada script lee el output del anterior; falla rápido si algo falta.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT/03_outputs/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/pipeline_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

say() { printf "\n\033[1;32m==> %s\033[0m\n" "$*"; }
fail() { printf "\n\033[1;31m✗ %s\033[0m\n" "$*"; exit 1; }

cd "$ROOT"

# Verifica R disponible
command -v Rscript >/dev/null 2>&1 || fail "Rscript no encontrado. Corre 00_setup/01_install_macos_toolchain.sh primero."

scripts=(
  "00_inventory.R"
  "01_harmonize.R"
  "02_fpca_pace.R"
  "03_mfpca_happgreven.R"   # mFACEs + Chiou normalization (canónico)
  "04_cwt_morlet.R"
  "05_classify_ptp.R"
  "06_inference.R"          # FANOVA permutation + Pillai (canónico §2.9)
  "06_lme4_scores.R"
  "07_bootstrap.R"
  "08_figures.R"
  "09_sensitivity.R"        # 4 análisis pre-especificados (canónico §2.12)
)

for s in "${scripts[@]}"; do
  say "[$(date +%H:%M:%S)] $s"
  Rscript "02_code/$s" || fail "Falló $s — revisar $LOG"
done

say "Pipeline completo. Log: $LOG"
say "Outputs en: $ROOT/03_outputs/"
say "Para regenerar el manuscrito: cd 04_manuscript && quarto render PTP_pipeline_FPCA_MFPCA.qmd"
