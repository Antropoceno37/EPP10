# 01_harmonize.R — Doc 1 §HARMONIZATION + manuscrito canónico §2.4-2.6
# Modo (auto-detectado):
#   1. Si 01_data/raw/master_table.csv existe → harmoniza datos reales + pseudo-IPD GP AR(1).
#   2. Si solo hay PDFs en 01_data/raw/ → TODO parser específico (no implementado).
#   3. Si vacío → genera dataset sintético (Apéndice A) para validar pipeline.
#
# Pseudo-IPD GP AR(1) (manuscrito §2.6):
#   K_ρ(s,t) = ρ^(|s-t|/30 min); σ²_h(t) = (CV_h × μ_h(t))²
#   CV literatura: ghrelin 0.40 · GLP-1 0.35 · GIP 0.30 · insulin 0.20 · glucose 0.12 · glucagon 0.30
#   Primary: ρ=0.5, CV_mult=1.0, M=1000, deterministic subsample N=50/arm.

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(fs); library(cli)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

# CV literature priors (manuscrito §2.6) — upper-bound typical values
CV_PRIORS <- c(
  ghrelin_total = 0.40, ghrelin_acyl = 0.40,
  GIP = 0.30, GLP1 = 0.35, PYY = 0.35,
  insulin = 0.20, glucose = 0.12, glucagon = 0.30
)

# === Pseudo-IPD GP AR(1) draws (manuscrito §2.6) ===
generate_pseudo_ipd <- function(times, mu, hormone, M = 1000L, rho = 0.5, cv_mult = 1.0) {
  n_t <- length(times)
  # Kernel AR(1) continuo
  K  <- outer(times, times, function(s, t) rho^(abs(s - t) / 30))
  cv <- as.numeric(CV_PRIORS[hormone])
  if (is.na(cv)) cv <- 0.30  # default conservative
  cv <- cv * cv_mult
  sigma <- cv * abs(mu)
  Sigma <- diag(sigma) %*% K %*% diag(sigma) + diag(1e-8, n_t)  # ridge para stability
  L <- chol(Sigma)
  Z <- matrix(rnorm(M * n_t), nrow = M)
  matrix(mu, M, n_t, byrow = TRUE) + Z %*% t(L)
}

# === Templates de trayectoria media para dataset sintético (modo 3) ===
mean_traj_synthetic <- function(hormone, cohort, t) {
  cohort_lean <- cohort %in% c("Lean-Healthy", "Obesity")
  base <- switch(hormone,
    ghrelin_total = 800 - ifelse(cohort_lean, 250, 100) * exp(-t/30),
    ghrelin_acyl  = 80  - 25  * exp(-t/30),
    GIP           = 50 + 100 * dgamma(t, 2, scale = 20) * 60,
    GLP1          = if (cohort == "RYGBP")
                       5 + 60 * dgamma(t, 2, scale = 15) * 60
                    else if (cohort == "Sleeve")
                       5 + 35 * dgamma(t, 2, scale = 18) * 60
                    else
                       5 + 18 * dgamma(t, 2, scale = 25) * 60,
    PYY           = if (cohort %in% c("Sleeve", "RYGBP"))
                       20 + 80 * dgamma(t, 2, scale = 20) * 60
                    else
                       20 + 25 * dgamma(t, 2, scale = 30) * 60,
    insulin       = if (cohort == "Obesity+T2DM")
                       10 + 35 * dnorm(t, 60, 30) * 60
                    else
                       5  + 60 * dnorm(t, 30, 25) * 60,
    glucose       = 90 + ifelse(cohort == "Obesity+T2DM", 80, 40) * dnorm(t, 45, 30) * 60,
    NA_real_
  )
  pmax(base, 0.01)
}

# === Modo de operación: auto-detectar fuentes ===
raw_dir       <- here("01_data", "raw")
master_path   <- file.path(raw_dir, "master_table.csv")
times_canon   <- c(0, 15, 30, 45, 60, 90, 120, 180)
cohorts_synt  <- c("Lean-Healthy", "Obesity", "Obesity+T2DM", "Sleeve", "RYGBP")
hormones_synt <- c("ghrelin_total", "ghrelin_acyl", "GIP", "GLP1", "PYY", "insulin", "glucose")

# Modo 1: data real con master_table.csv
if (file.exists(master_path)) {
  cli_alert_info("Modo 1: master_table.csv detectado — harmonizando + pseudo-IPD GP AR(1)")
  master <- fread(master_path)

  # Espera cols: cohort, hormone, time_min, mean_value, sem (opcional), n (opcional)
  required <- c("cohort", "hormone", "time_min", "mean_value")
  if (!all(required %in% names(master))) {
    stop("master_table.csv falta columnas: ", paste(setdiff(required, names(master)), collapse=", "))
  }

  rho_primary <- 0.5
  cv_mult     <- 1.0
  M_per_arm   <- 1000L
  N_subsample <- 50L

  # PSEUDO-IPD POR ARM (manuscrito §2.6):
  # Cada arm = (source_study, cohort). Cada pseudo-subject tiene TODAS las hormonas
  # que el arm reporta, en una rejilla común de timepoints. subject_id es único por
  # arm × idx (1..N_subsample), independiente de hormona — esto permite MFPCA conjunta.
  arms <- if ("source_study" %in% names(master)) {
    unique(master[, .(source_study, cohort)])
  } else {
    master_local <- copy(master)[, source_study := "single"]
    unique(master_local[, .(source_study, cohort)])
  }

  rows <- list()
  global_uid <- 0L

  for (a_i in seq_len(nrow(arms))) {
    s_n <- arms$source_study[a_i]
    c_n <- arms$cohort[a_i]
    arm_data <- master[get("source_study") == s_n & cohort == c_n]
    if (nrow(arm_data) < 2L) next

    arm_hormones <- unique(arm_data$hormone)
    if (length(arm_hormones) == 0L) next

    # Asigna subject_ids únicos para este arm
    idx <- seq_len(N_subsample)
    sid_arm <- sprintf("U%07d", global_uid + idx)
    global_uid <- global_uid + length(idx)

    # Para cada hormona del arm, genera pseudo-IPD con esos sujetos
    for (h_n in arm_hormones) {
      sub <- arm_data[hormone == h_n][order(time_min)]
      if (nrow(sub) < 2L) next

      pseudo <- generate_pseudo_ipd(
        times = sub$time_min,
        mu    = sub$mean_value,
        hormone = h_n,
        M = M_per_arm, rho = rho_primary, cv_mult = cv_mult
      )
      pseudo_sub <- pseudo[idx, , drop = FALSE]   # N_subsample × T

      rows[[length(rows) + 1L]] <- data.table(
        subject_id = rep(sid_arm, each = length(sub$time_min)),
        cohort     = c_n,
        hormone    = h_n,
        time_min   = rep(sub$time_min, times = length(idx)),
        value      = pmax(as.vector(t(pseudo_sub)), 0.01),
        source_study = s_n
      )
    }
  }
  dt <- rbindlist(rows)
  unit_of_analysis <- sprintf("B_cohort_pseudo_IPD_GP_rho%.1f_M%d_N%d",
                              rho_primary, M_per_arm, N_subsample)

# Modo 3: dataset sintético (validación pipeline)
} else {
  cli_alert_info("Modo 3: sin master_table.csv — generando dataset sintético")
  n_per <- 50L
  cohort_codes <- c("Lean-Healthy" = "LEH", "Obesity" = "OBE", "Obesity+T2DM" = "OBT",
                    "Sleeve" = "SLG", "RYGBP" = "RYG")
  rows <- vector("list", length(cohorts_synt) * length(hormones_synt) * length(times_canon))
  i <- 0L
  for (cohort in cohorts_synt) for (h in hormones_synt) for (t in times_canon) {
    mu <- mean_traj_synthetic(h, cohort, t)
    i <- i + 1L
    rows[[i]] <- data.table(
      subject_id = paste0(cohort_codes[[cohort]], sprintf("%04d", seq_len(n_per))),
      cohort     = cohort,
      hormone    = h,
      time_min   = t,
      value      = pmax(rnorm(n_per, mu, mu * 0.15), 0.01)
    )
  }
  dt <- rbindlist(rows)
  unit_of_analysis <- "A_subject_synthetic"
}

# === Log-transform (Doc 2 §4: hormonas con asimetría > 1) ===
log_hormones <- c("GLP1", "GLP-1", "PYY", "insulin", "ghrelin_acyl", "GIP")
dt[, value_log := ifelse(hormone %in% log_hormones, log(value), value)]
dt[, unit_of_analysis := unit_of_analysis]

out <- here("01_data", "harmonized", "ptp_long.parquet")
dir_create(dirname(out), recurse = TRUE)
write_parquet(dt, out)
cli_alert_success("Harmonized: {.path {out}} ({nrow(dt)} filas, {uniqueN(dt$subject_id)} sujetos, mode={unit_of_analysis})")
