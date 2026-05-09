#!/usr/bin/env bash
# 03_install_python_tfa.sh
# Crea un venv Python para CWT (PyWavelets) y HHT/EMD (EMD-signal).
# Doc 1 §TIME-FREQUENCY: complex Morlet wavelet + HHT/EMD exploratorio.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$ROOT/00_setup/.venv"

say() { printf "\n\033[1;36m==> %s\033[0m\n" "$*"; }

# Asegura python3 reciente vía brew (el del sistema es 3.9 — útil pero viejo)
if ! brew list python@3.12 >/dev/null 2>&1; then
  say "Instalando python@3.12 vía brew..."
  brew install --quiet python@3.12 || true
fi

PY=$(brew --prefix python@3.12 2>/dev/null)/bin/python3.12
[ -x "$PY" ] || PY=$(command -v python3)

say "Python base: $PY ($($PY --version))"

# Venv
if [ ! -d "$VENV" ]; then
  say "Creando venv en $VENV"
  "$PY" -m venv "$VENV"
fi

"$VENV/bin/pip" install --upgrade pip wheel setuptools

say "Instalando librerías time-frequency..."
"$VENV/bin/pip" install \
  numpy pandas scipy matplotlib seaborn \
  PyWavelets EMD-signal \
  jupyter ipykernel

# Symlink corto
ln -sf "$VENV/bin/python" "$ROOT/00_setup/python"

say "Python venv listo: $VENV"
say "Para activar: source $VENV/bin/activate"
say "Para usar en scripts: $ROOT/00_setup/python tu_script.py"
