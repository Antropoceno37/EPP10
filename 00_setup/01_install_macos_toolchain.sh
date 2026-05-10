#!/usr/bin/env bash
# 01_install_macos_toolchain.sh
# Instala Homebrew (si falta), R desde CRAN (vinculado a Accelerate),
# Quarto, gfortran, pandoc y dependencias de compilación para FPCA/MFPCA.
# Idempotente: se puede correr varias veces sin daño.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT/03_outputs/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

say() { printf "\n\033[1;36m==> %s\033[0m\n" "$*"; }

say "Instalación toolchain Mac mini M4 Pro :: $(date)"
say "Log: $LOG"

# --- 1. Homebrew (arm64 nativo en /opt/homebrew) ---
if ! command -v brew >/dev/null 2>&1; then
  say "Instalando Homebrew (te pedirá tu password de macOS — escríbelo cuando aparezca)..."
  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Asegura que brew esté en PATH para esta sesión
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Persistir brew en ~/.zprofile si no está
if ! grep -q "brew shellenv" "$HOME/.zprofile" 2>/dev/null; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  say "Añadido brew shellenv a ~/.zprofile"
fi

say "brew: $(brew --version | head -1)"

# --- 2. Compilación + utilidades ---
say "Instalando dependencias de compilación + poppler (PDF rendering)..."
brew update --quiet || true
brew install --quiet pkg-config gcc cmake pandoc imagemagick libxml2 libgit2 openssl@3 poppler || true

# --- 3. Quarto ---
say "Instalando Quarto..."
brew install --quiet --cask quarto || true

# --- 4. R desde CRAN (vinculado a Accelerate / vecLib) ---
say "Instalando R (cask oficial CRAN)..."
brew install --quiet --cask r || true

# --- 5. Symlinks de configuración ---
say "Symlinks .Renviron y .Rprofile..."
[ -f "$HOME/.Renviron" ] && [ ! -L "$HOME/.Renviron" ] && \
  cp "$HOME/.Renviron" "$HOME/.Renviron.bak.$(date +%s)" && \
  say "Backup de .Renviron previo guardado"
[ -f "$HOME/.Rprofile" ] && [ ! -L "$HOME/.Rprofile" ] && \
  cp "$HOME/.Rprofile" "$HOME/.Rprofile.bak.$(date +%s)" && \
  say "Backup de .Rprofile previo guardado"
ln -sf "$ROOT/00_setup/Renviron" "$HOME/.Renviron"
ln -sf "$ROOT/00_setup/Rprofile" "$HOME/.Rprofile"

# --- 6. Verificación BLAS ---
say "Verificando R + BLAS..."
R --no-save --quiet <<'RS' || true
cat("\nR version:", R.version.string, "\n")
cat("Platform: ", R.version$platform, "\n")
cat("BLAS:     ", extSoftVersion()["BLAS"], "\n")
cat("LAPACK:   ", extSoftVersion()["LAPACK"], "\n")
RS

# --- 7. Optimizaciones macOS no invasivas ---
say "Configurando energía (no permanente)..."
# Desactiva App Nap para R durante esta sesión de usuario
defaults write -app R NSAppSleepDisabled -bool true 2>/dev/null || true
defaults write -app RStudio NSAppSleepDisabled -bool true 2>/dev/null || true

say "Toolchain listo."
say "Siguiente paso:"
say "  Rscript $ROOT/00_setup/02_install_r_packages.R"
say "  bash    $ROOT/00_setup/03_install_python_tfa.sh"
