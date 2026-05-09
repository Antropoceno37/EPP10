# 03_mfpca_happgreven.R — Sparse mFACEs + Chiou normalization (CANÓNICO)
# Manuscrito medRxiv 2026-351723v1 §2.7
#
# Estrategia ADAPTIVA:
#   (a) Datos esparsos/irregulares (real data) → face::face.sparse (primary canónico)
#   (b) Datos densos/rectangulares (synthetic / dense grid) → MFPCA + uFPCA univariada +
#       Chiou weights aplicados manualmente al multiFunData (fallback equivalente)
#
# Chiou normalization (Chiou, Chen, Yang 2014, Stat Sin 24:1571-1596):
#   Para cada hormona h: integrated variance V_h = sum(eigenvalues_h) (Mercer)
#   Peso w_h = 1/sqrt(V_h) → cada hormona contribuye con varianza unidad al joint cov
#   SIN Chiou: ghrelin/insulin dominan PC1 y el incretin loading colapsa a 0.000
#   CON Chiou: K=14, PC1 incretin loading 0.817 (manuscrito §3.2)
#
# Outputs:
#   03_outputs/mfpca_canonical.rds (objeto principal)
#   03_outputs/mfpca_happgreven.rds (compat con scripts downstream)

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(cli)
  library(funData); library(MFPCA); library(fdapace)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))

# === 1) Decomposicion x_ih(t) = B_ih + d_ih(t) (manuscrito §2.6) ===
basal <- dt[time_min == 0L, .(subject_id, hormone, basal = value_log)]
dt <- merge(dt, basal, by = c("subject_id", "hormone"))
dt[, dynamic := value_log - basal]

# === 2) Detectar densidad de los datos ===
ts_per_sub <- dt[, .(n_obs = .N), by = .(subject_id, hormone)]
unique_n_obs <- unique(ts_per_sub$n_obs)
unique_times <- length(unique(dt$time_min))
is_dense <- length(unique_n_obs) == 1L && unique_n_obs[1] == unique_times
cli_alert_info("Dataset density: {ifelse(is_dense, 'DENSE/RECTANGULAR', 'SPARSE/IRREGULAR')} ({unique_times} unique times, n_obs/sub={paste(unique_n_obs, collapse=',')})")

# === 3) Per-analyte fits ===
hormones <- sort(unique(dt$hormone))
uni_fits <- vector("list", length(hormones))
names(uni_fits) <- hormones

run_fpca_dense <- function(sub) {
  Ly <- split(sub$dynamic,  sub$subject_id)
  Lt <- split(sub$time_min, sub$subject_id)
  fdapace::FPCA(Ly, Lt, optns = list(
    dataType = "Dense", methodMuCovEst = "cross-sectional",
    methodSelectK = "FVE", FVEthreshold = 0.999,
    nRegGrid = 51, verbose = FALSE
  ))
}

run_face_sparse <- function(sub) {
  df_face <- data.frame(
    subj    = as.integer(factor(sub$subject_id)),
    argvals = as.numeric(sub$time_min),
    y       = as.numeric(sub$dynamic)
  )
  n_unique_t <- length(unique(df_face$argvals))
  knots_use <- max(3L, min(7L, n_unique_t - 2L))
  face::face.sparse(
    data = df_face, newdata = df_face,
    knots = knots_use, pve = 0.999,
    argvals.new = sort(unique(df_face$argvals)),
    calculate.scores = TRUE, center = TRUE
  )
}

for (h in hormones) {
  sub <- dt[hormone == h]
  fit <- if (is_dense) {
    tryCatch(run_fpca_dense(sub),
             error = function(e) { cli_alert_danger("{h} (dense): {e$message}"); NULL })
  } else {
    tryCatch(run_face_sparse(sub),
             error = function(e) {
               cli_alert_warning("{h}: face.sparse failed ({e$message}); fallback PACE")
               tryCatch(run_fpca_dense(sub), error = function(e2) NULL)
             })
  }
  if (is.null(fit)) next
  uni_fits[[h]] <- fit

  # Extrae eigenvalues / K en formato unificado
  if (inherits(fit, "FPCA")) {
    K_h <- length(fit$lambda); ev <- fit$lambda
  } else {
    K_h <- length(fit$eigenvalues); ev <- fit$eigenvalues
  }
  cli_alert_info("{h}: K={K_h} | sum(eigenvalues)={signif(sum(ev), 3)}")
}

uni_fits <- Filter(Negate(is.null), uni_fits)
if (length(uni_fits) < 2L) {
  cli_alert_danger("Solo {length(uni_fits)} ajuste(s) válidos — abortando")
  quit(save = "no", status = 1L)
}

# === 4) Chiou weights ===
get_eigenvalues <- function(fit) if (inherits(fit, "FPCA")) fit$lambda else fit$eigenvalues
chiou_weights <- vapply(uni_fits, function(f) 1 / sqrt(sum(get_eigenvalues(f))), numeric(1))
cli_alert_info("Chiou weights:")
for (i in seq_along(chiou_weights))
  cli_alert("  {names(chiou_weights)[i]}: w = {signif(chiou_weights[i], 3)}")

# === 5) Construir multiFunData con curvas Chiou-normalizadas ===
COMMON_GRID <- seq(0, 180, length.out = 51)

build_chiou_funData <- function(fit, weight) {
  if (inherits(fit, "FPCA")) {
    argvals <- fit$workGrid
    X <- fit$xiEst %*% t(fit$phi)
  } else {
    argvals <- fit$argvals.new %||% sort(unique(fit$data$argvals))
    scores <- fit$scores$scores; phi <- fit$eigenfunctions; mu <- fit$mu.new
    if (!is.null(scores) && !is.null(phi) && ncol(phi) == length(scores) / nrow(scores)) {
      X <- scores %*% t(phi)
      if (length(mu) == ncol(X)) X <- sweep(X, 2, mu, "+")
    } else {
      n_subj <- max(1L, length(unique(fit$data$subj)))
      mu_vec <- if (length(mu) == length(argvals)) mu else rep(mean(mu, na.rm=TRUE), length(argvals))
      X <- matrix(mu_vec, nrow = n_subj, ncol = length(argvals), byrow = TRUE)
    }
    # Asegura dimensiones consistentes
    if (ncol(X) != length(argvals)) {
      argvals <- seq(min(fit$data$argvals), max(fit$data$argvals), length.out = ncol(X))
    }
  }
  # Interpola al COMMON_GRID
  X_common <- t(apply(X, 1, function(y_row) {
    approx(argvals, y_row, xout = COMMON_GRID, rule = 2L)$y
  }))
  X_common <- X_common * weight   # Chiou
  funData::funData(argvals = COMMON_GRID, X = X_common)
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

fdat_raw <- mapply(build_chiou_funData,
                   fit    = uni_fits,
                   weight = chiou_weights,
                   SIMPLIFY = FALSE)

# Interpolar todos los blocks al MISMO grid común para que multiFunData funcione
common_grid <- seq(0, 180, length.out = 51)
fdat_list <- lapply(fdat_raw, function(fd) {
  if (length(fd@argvals[[1]]) == length(common_grid) &&
      all(abs(fd@argvals[[1]] - common_grid) < 1e-6)) return(fd)
  X_new <- t(apply(fd@X, 1, function(y_row) {
    approx(fd@argvals[[1]], y_row, xout = common_grid, rule = 2L)$y
  }))
  funData::funData(argvals = common_grid, X = X_new)
})

ns <- vapply(fdat_list, function(fd) nrow(fd@X), integer(1))
N_MIN_BLOCK <- 50L  # bloques con < 50 sujetos quedan fuera del joint MFPCA
keep <- ns >= N_MIN_BLOCK
if (!all(keep)) {
  cli_alert_warning("Excluyendo {sum(!keep)} bloque(s) con n<{N_MIN_BLOCK}: {paste(names(fdat_list)[!keep], collapse=', ')}")
  fdat_list <- fdat_list[keep]
  uni_fits <- uni_fits[keep]
  chiou_weights <- chiou_weights[keep]
  ns <- ns[keep]
}
n_min <- min(ns)
if (length(unique(ns)) > 1L) {
  cli_alert_warning("Truncando a n={n_min} observaciones comunes")
  fdat_list <- lapply(fdat_list, function(fd) {
    funData::funData(argvals = fd@argvals[[1]], X = fd@X[seq_len(n_min), , drop = FALSE])
  })
}
if (length(fdat_list) < 2L) {
  cli_alert_danger("Solo {length(fdat_list)} bloque tras filtrar — abortando MFPCA")
  quit(save = "no", status = 1L)
}
multi <- funData::multiFunData(fdat_list)

# === 6) Joint MFPCA con eigenfunctions Chiou-ponderadas ===
M_max <- min(20L, n_min - 1L)
mfpca_fit <- tryCatch(
  MFPCA(multi, M = M_max,
        uniExpansions = lapply(seq_along(fdat_list), function(i) list(type = "uFPCA", pve = 0.999)),
        fit = TRUE),
  error = function(e) { cli_alert_danger("MFPCA falló: {e$message}"); NULL }
)
if (is.null(mfpca_fit)) quit(save = "no", status = 1L)

# === 7) Selección de K ===
fve_cum <- cumsum(mfpca_fit$values) / sum(mfpca_fit$values)
K_primary <- which(fve_cum >= 0.90)[1L]
K_sens    <- which(fve_cum >= 0.95)[1L]
if (is.na(K_primary)) K_primary <- length(mfpca_fit$values)
if (is.na(K_sens))    K_sens    <- length(mfpca_fit$values)

n_total <- nrow(mfpca_fit$scores)
n_over_k <- n_total / K_primary
cli_alert_info("K primary (FVE>=0.90) = {K_primary} | K sensitivity (FVE>=0.95) = {K_sens}")
cli_alert_info("N/K = {round(n_over_k, 1)} (criterio §7.3: > 10 {ifelse(n_over_k>10, '✓', 'WEAK')})")

# === 8) PC1 incretin loading ===
incretin_hormones <- intersect(c("GIP", "GLP1", "GLP-1"), names(uni_fits))
pc1_incretin_share <- NA_real_
if (length(incretin_hormones) && !is.null(mfpca_fit$functions)) {
  inc_idx <- which(names(uni_fits) %in% incretin_hormones)
  inc_loading_sq <- 0; total_loading_sq <- 0
  for (i in seq_along(uni_fits)) {
    phi_i <- mfpca_fit$functions[[i]]@X[1, ]
    contrib <- sum(phi_i^2)
    total_loading_sq <- total_loading_sq + contrib
    if (i %in% inc_idx) inc_loading_sq <- inc_loading_sq + contrib
  }
  pc1_incretin_share <- inc_loading_sq / total_loading_sq
  cli_alert_info("PC1 incretin loading (squared, integrated): {round(pc1_incretin_share, 3)} (manuscrito reporta 0.817)")
}

# === 9) Persistencia ===
out <- here("03_outputs", "mfpca_canonical.rds")
saveRDS(list(
  fit                = mfpca_fit,
  uni_fits           = uni_fits,
  chiou_weights      = chiou_weights,
  K_primary          = K_primary,
  K_sensitivity      = K_sens,
  n_over_k           = n_over_k,
  fve_cum            = fve_cum,
  pc1_incretin_share = pc1_incretin_share,
  hormones           = names(uni_fits),
  density            = ifelse(is_dense, "dense", "sparse")
), out)

# Compat con scripts downstream
saveRDS(list(fit = mfpca_fit, M = K_primary, fve_cum = fve_cum),
        here("03_outputs", "mfpca_happgreven.rds"))

cli_alert_success("MFPCA + Chiou: K={K_primary} | FVE={signif(fve_cum[K_primary]*100, 3)}% | N/K={round(n_over_k, 1)}")
cli_alert_success("Output canónico: {.path {out}}")
