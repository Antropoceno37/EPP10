#!/usr/bin/env bash
# 04_enable_accelerate_blas.sh
# Activa la BLAS optimizada para Apple Silicon (vecLib/Accelerate) en R.
# R 4.6 para macOS ya incluye libRblas.vecLib.dylib pre-compilado por CRAN
# contra Accelerate. Solo hay que cambiar el symlink libRblas.dylib.
#
# Ganancia esperada en FPCA/MFPCA: 3-10x en algebra lineal densa.
# Pide tu password de macOS porque modifica /Library/Frameworks/R.framework.
# Idempotente y reversible.

set -euo pipefail
say()  { printf "\n\033[1;36m==> %s\033[0m\n" "$*"; }
fail() { printf "\n\033[1;31mx %s\033[0m\n" "$*"; exit 1; }

R_LIB="/Library/Frameworks/R.framework/Resources/lib"
TARGET_VECLIB="$R_LIB/libRblas.vecLib.dylib"
TARGET_DEFAULT="$R_LIB/libRblas.0.dylib"
SYMLINK="$R_LIB/libRblas.dylib"

[ -d "$R_LIB" ]              || fail "R.framework no encontrado en $R_LIB"
[ -f "$TARGET_VECLIB" ]      || fail "libRblas.vecLib.dylib no encontrado. R 4.6+ debe incluirlo."

# Estado actual
current=$(readlink "$SYMLINK" 2>/dev/null || echo "?")
say "BLAS actual: $current"

if [ "$current" = "libRblas.vecLib.dylib" ]; then
  say "Accelerate (vecLib) ya esta activo. Nada que hacer."
  R --no-save --quiet -e 'cat("BLAS:", extSoftVersion()["BLAS"], "\n")'
  exit 0
fi

say "Cambiando symlink a libRblas.vecLib.dylib (vecLib/Accelerate)..."
sudo ln -sf libRblas.vecLib.dylib "$SYMLINK"

say "Verificacion del symlink:"
ls -la "$SYMLINK"

say "Verificacion en R:"
R --no-save --quiet -e 'cat("BLAS:  ", extSoftVersion()["BLAS"], "\nLAPACK:", extSoftVersion()["LAPACK"], "\n")'

# Microbench para validar que es realmente mas rapido
say "Microbench (matriz 2000x2000, crossprod) - corre 3 veces, reporta el mejor:"
R --no-save --quiet -e '
set.seed(20260502)
A <- matrix(rnorm(2000*2000), 2000)
times <- replicate(3, system.time(crossprod(A))[3])
cat("  Tiempos (s):", paste(round(times, 2), collapse=", "), "\n")
cat("  Mejor:", round(min(times), 2), "s (con vecLib esperaras < 0.4 s)\n")
'

say "Listo. Reinicia cualquier sesion R abierta para que tome efecto."
say "Para revertir: sudo ln -sf libRblas.0.dylib $SYMLINK"
