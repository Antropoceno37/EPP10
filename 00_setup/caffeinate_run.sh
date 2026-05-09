#!/usr/bin/env bash
# caffeinate_run.sh — Wrapper para corridas largas que NO deben interrumpirse por sleep.
# Uso:
#   bash 00_setup/caffeinate_run.sh Rscript 02_code/07_bootstrap.R
#   bash 00_setup/caffeinate_run.sh ./run_pipeline.sh
#
# Flags caffeinate:
#   -d  evita display sleep
#   -i  evita idle sleep
#   -m  evita disk sleep
#   -s  evita system sleep cuando hay AC power
#   -u  declara user activity (60s por default)

set -euo pipefail
exec caffeinate -dimsu "$@"
