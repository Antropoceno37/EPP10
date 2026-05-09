# 02_install_r_packages.R
# Instala el stack R para el manuscrito canónico FDEP-TP / MFPCA
# (medRxiv 2026-351723v1 — JCEM Original Investigation, Virgen-Ayala).
# Idempotente: omite paquetes ya instalados.
# Tiempo aproximado: 25–45 min en M4 Pro 24 GB (brms/rstan compilan).

repos <- c(CRAN = "https://cloud.r-project.org")
options(repos = repos, Ncpus = 4L)
options(install.packages.compile.from.source = "never")  # prefiere binarios

cran_pkgs <- c(
  # === Funcional univariante / multivariante (manuscrito §2.7-2.8) ===
  "fdapace",      # FPCA-PACE (Yao, Müller & Wang 2005, ref 45)
  "MFPCA",        # MFPCA Happ-Greven 2018 (ref 31), v1.3-11
  "funData",      # contenedor unificado
  "refund",       # functional regression
  "face",         # FACE Xiao et al. 2016 (rejilla densa, sensitivity)
  "fda",          # Ramsay & Silverman base
  "mgcv",         # smoothing spline backend

  # === Distribution-free uncertainty (manuscrito §2.10 — primary) ===
  "conformalInference.fd",  # conformal prediction bands (Diquigiovanni 2022, ref 49)
  # "fdWasserstein" — puede no estar en CRAN; intentar desde GitHub si falla
  "transport",              # backend de Wasserstein

  # === Outlier detection (manuscrito §2.10 MBD) ===
  "roahd",                  # robust analysis FDA, MBD nativo
  "fdaPOIFD",               # outliers funcionales

  # === Reproducibilidad y QC (manuscrito §2.13) ===
  "pointblank",             # data quality assertions
  "irr",                    # inter-rater reliability (Cohen's kappa, ICC)

  # === Bayesian hierarchical (manuscrito §2.9) ===
  "brms",                   # Stan-based, regularized horseshoe priors
  "rstan",
  "loo",                    # LOO-PIT calibration (Vehtari 2017, ref 48)
  "bayesplot",
  "tidybayes",
  "posterior",

  # === Modelos mixtos clásicos (sensibilidad univariada) ===
  "lme4", "lmerTest", "emmeans", "broom.mixed", "performance",

  # === Time-frequency (CWT en R; HHT/EMD en Python venv) ===
  "WaveletComp", "wavelets", "biwavelet",

  # === Imputación, manipulación, IO ===
  "mice", "data.table", "arrow", "tibble", "tidyr", "dplyr",
  "purrr", "stringr", "readxl", "writexl", "readr",

  # === Paralelización y reproducibilidad ===
  "future", "future.apply", "furrr", "irlba", "renv", "here",
  "fs", "digest", "sessioninfo", "cli",

  # === Visualización ===
  "ggplot2", "patchwork", "ggdist", "ggrepel", "ggsci",
  "scales", "viridis", "cowplot",

  # === Quarto / reportes ===
  "quarto", "knitr", "rmarkdown", "kableExtra", "gt", "flextable", "officer"
)

installed <- rownames(installed.packages())
to_install <- setdiff(cran_pkgs, installed)

if (length(to_install)) {
  message(sprintf("Instalando %d/%d paquetes nuevos...",
                  length(to_install), length(cran_pkgs)))
  message("Pendientes: ", paste(to_install, collapse = ", "))
  install.packages(to_install)
} else {
  message("Todos los paquetes CRAN ya están instalados.")
}

# === Paquetes potencialmente no-CRAN: intentar GitHub ===
github_pkgs <- list(
  fdWasserstein = "vmasarot/fdWasserstein"   # Masarotto et al. 2019 (ref 50)
)

if (!"remotes" %in% rownames(installed.packages())) {
  install.packages("remotes")
}

for (p in names(github_pkgs)) {
  if (!p %in% rownames(installed.packages())) {
    message(sprintf("Intentando instalar %s desde GitHub (%s)...", p, github_pkgs[[p]]))
    tryCatch(remotes::install_github(github_pkgs[[p]], upgrade = "never"),
             error = function(e) message(sprintf("  Falló %s: %s", p, e$message)))
  }
}

# === Verificación ===
loaded <- vapply(cran_pkgs,
                 function(p) requireNamespace(p, quietly = TRUE),
                 logical(1))
if (any(!loaded)) {
  warning("No cargaron: ", paste(cran_pkgs[!loaded], collapse = ", "))
} else {
  message("OK: ", length(cran_pkgs), " paquetes CRAN disponibles.")
}

# === Snapshot session info al log ===
log_dir <- file.path(Sys.getenv("HOME"), "Research", "PTP_JCEM", "03_outputs", "logs")
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
log_file <- file.path(log_dir, sprintf("session_info_%s.txt",
                                       format(Sys.time(), "%Y%m%d_%H%M%S")))
sink(log_file)
print(sessioninfo::session_info(pkgs = "loaded"))
sink()
message("Session info guardado en: ", log_file)
