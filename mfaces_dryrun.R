# =============================================================================
# DRY-RUN v10.0: pipeline completo sobre datos sintéticos
# =============================================================================
.libPaths(c("~/.R/library", .libPaths()))
suppressPackageStartupMessages({
  library(fdapace); library(face); library(mgcv); library(funData); library(MFPCA)
  library(dplyr); library(tidyr); library(purrr); library(tibble)
})
set.seed(20260422)

`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
approx2d <- function(x, y, z, xi, yi) {
  ix <- max(1, min(length(x) - 1, findInterval(xi, x)))
  iy <- max(1, min(length(y) - 1, findInterval(yi, y)))
  tx <- max(0, min(1, (xi - x[ix]) / (x[ix + 1] - x[ix])))
  ty <- max(0, min(1, (yi - y[iy]) / (y[iy + 1] - y[iy])))
  (1-tx)*(1-ty)*z[ix,iy]   + tx*(1-ty)*z[ix+1,iy] +
  (1-tx)*    ty *z[ix,iy+1]+ tx*    ty *z[ix+1,iy+1]
}

# ---------------------------------------------------------------------------
# fit_all_analytes (univariate sensitivity path, §6.2)
# ---------------------------------------------------------------------------
fit_all_analytes <- function(data, base_opts, analytes = NULL,
                             min_obs = 3, min_subjects = 5,
                             reference_cohort = "no_obese_without_T2DM",
                             exclude_censored = TRUE) {
  if (is.null(analytes)) analytes <- sort(unique(data$hormone_name))

  prep_and_fit <- function(a) {
    d0 <- filter(data, hormone_name == a)
    n_start <- n_distinct(d0$subject_id)
    d1 <- filter(d0, !is.na(value))
    if (exclude_censored) d1 <- filter(d1, !is_censored)
    n_after_value <- n_distinct(d1$subject_id)
    d2 <- d1 %>% group_by(subject_id) %>%
      mutate(baseline = if (first(cohort) == reference_cohort) {
               v0 <- value[timepoint_min == 0]   # nominal, strict
               if (length(v0) == 1) v0 else NA_real_
             } else value[which.min(abs(timepoint_min))],  # nominal nearest-to-zero
             d_value = value - baseline) %>% ungroup() %>%
      filter(!is.na(d_value))
    n_after_baseline <- n_distinct(d2$subject_id)
    d3 <- d2 %>% group_by(subject_id) %>%
      arrange(actual_time_min, .by_group = TRUE) %>%
      mutate(n_obs = n()) %>% ungroup() %>%
      filter(n_obs >= min_obs)
    n_final <- n_distinct(d3$subject_id)
    flow <- tibble(analyte=a, n_start=n_start, n_after_value=n_after_value,
                   n_after_baseline=n_after_baseline, n_final=n_final,
                   n_dropped=n_start-n_final)
    if (n_final < min_subjects)
      return(list(fit=NULL, flow=flow, status="insufficient_subjects",
                  reason=sprintf("n_final=%d < %d", n_final, min_subjects)))
    # Defensive per-subject sort before MakeFPCAInputs
    d3 <- d3 %>% arrange(subject_id, actual_time_min)
    inputs <- fdapace::MakeFPCAInputs(IDs=d3$subject_id, tVec=d3$actual_time_min, yVec=d3$d_value)
    inputs$Ly <- lapply(seq_along(inputs$Lt), function(i) inputs$Ly[[i]][order(inputs$Lt[[i]])])
    inputs$Lt <- lapply(inputs$Lt, sort)
    fit <- tryCatch(fdapace::FPCA(inputs$Ly, inputs$Lt, optns=base_opts),
                    error=function(e) e)
    if (inherits(fit, "error"))
      return(list(fit=NULL, flow=flow, status="fit_error", reason=conditionMessage(fit)))
    attr(fit, "analyte") <- a
    attr(fit, "n_subjects") <- n_final
    list(fit=fit, flow=flow, status="ok", reason=NA_character_)
  }
  results <- map(analytes, prep_and_fit) %>% set_names(analytes)
  fits <- compact(map(results, "fit"))
  diagnostics <- imap_dfr(results, function(r, a) mutate(r$flow, status=r$status, reason=r$reason))
  structure(list(fits=fits, diagnostics=diagnostics, call=match.call()),
            class=c("fpca_batch_fit", "list"))
}

print.fpca_batch_fit <- function(x, ...) {
  d <- x$diagnostics
  n_ok <- sum(d$status == "ok")
  cat(sprintf("<fpca_batch_fit>  %d analytes requested  |  ok: %d  |  failed: %d\n",
              nrow(d), n_ok, nrow(d)-n_ok))
  print(d, n=Inf)
  invisible(x)
}

# ---------------------------------------------------------------------------
# fit_mfaces_joint (primary, §7.4) with three defensive patches
# ---------------------------------------------------------------------------
fit_mfaces_joint <- function(long,
                             analytes,
                             nGrid = 51, knots = 10,
                             min_obs = 3,
                             reference_cohort = "no_obese_without_T2DM",
                             min_paired_obs = 50,
                             ridge = 0, ridge_max_mult = 10,
                             chiou_normalize = TRUE) {

  long_d <- long %>%
    filter(hormone_name %in% analytes, !is.na(value), !is_censored) %>%
    group_by(subject_id, hormone_name) %>%
    mutate(baseline = if (first(cohort) == reference_cohort) {
             v0 <- value[timepoint_min == 0]
             if (length(v0) == 1) v0 else NA_real_
           } else value[which.min(abs(timepoint_min))],
           d_value = value - baseline, n_obs_subject = n()) %>%
    ungroup() %>%
    filter(!is.na(d_value), n_obs_subject >= min_obs) %>%
    arrange(subject_id, hormone_name, actual_time_min)

  workGrid <- seq(min(long_d$actual_time_min),
                  max(long_d$actual_time_min), length.out = nGrid)

  face_fits <- map(analytes, function(a) {
    d_a <- filter(long_d, hormone_name == a)
    if (n_distinct(d_a$subject_id) < 5) return(NULL)
    face_df <- tibble(y = d_a$d_value,
                      argvals = d_a$actual_time_min,
                      subj = as.integer(factor(d_a$subject_id)))
    tryCatch(face::face.sparse(face_df, argvals.new = workGrid,
                               knots = knots, pve = 0.99, center = TRUE),
             error = function(e) NULL)
  }) %>% set_names(analytes) %>% compact()

  H <- length(face_fits); stopifnot(H >= 2)
  analytes_kept <- names(face_fits)

  # --- Chiou, Chen & Yang 2014 normalization weights --------------------
  # v_h = ∫ diag(Chat_h)(t) dt — integrated marginal variance per hormone.
  # Normalized features enter the joint decomposition with unit integrated variance.
  integrated_var <- vapply(face_fits, function(fit) {
    dt_h <- mean(diff(fit$argvals.new))
    max(sum(diag(fit$Chat.new)) * dt_h, 1e-12)
  }, numeric(1))
  names(integrated_var) <- analytes_kept
  sqrt_v <- sqrt(integrated_var)
  if (!chiou_normalize) sqrt_v[] <- 1   # no-op for testing / comparison

  centered_obs <- imap_dfr(face_fits, function(fit, a) {
    d_a <- filter(long_d, hormone_name == a)
    mu_obs <- approx(fit$argvals.new, fit$mu.new,
                     xout = d_a$actual_time_min, rule = 2)$y
    tibble(subject_id = d_a$subject_id, analyte = a,
           t = d_a$actual_time_min, y_centered = d_a$d_value - mu_obs)
  })

  # --- Parche 1: diagnóstico de cobertura de pares ---
  pair_counts <- matrix(0L, H, H,
                        dimnames = list(analytes_kept, analytes_kept))
  gam_status <- matrix("ok", H, H,
                       dimnames = list(analytes_kept, analytes_kept))

  cross_cov <- array(0, dim = c(H, H, nGrid, nGrid),
                     dimnames = list(analytes_kept, analytes_kept, NULL, NULL))
  for (i in seq_len(H)) for (j in seq_len(H)) {
    if (i == j) {
      cross_cov[i, j, , ] <- face_fits[[i]]$Chat.new
      pair_counts[i, j] <- nrow(filter(centered_obs, analyte == analytes_kept[i]))
      next
    }
    pairs <- inner_join(
      filter(centered_obs, analyte == analytes_kept[i]),
      filter(centered_obs, analyte == analytes_kept[j]),
      by = "subject_id", suffix = c("_i","_j"),
      relationship = "many-to-many"
    )
    pair_counts[i, j] <- nrow(pairs)
    if (nrow(pairs) < min_paired_obs) {
      gam_status[i, j] <- sprintf("insufficient(%d<%d)", nrow(pairs), min_paired_obs)
      next
    }
    pairs$prod <- pairs$y_centered_i * pairs$y_centered_j
    gam_fit <- tryCatch(
      mgcv::gam(prod ~ te(t_i, t_j, k = c(min(knots, 8), min(knots, 8))),
                data = pairs, method = "REML"),
      error = function(e) { gam_status[i, j] <<- paste0("gam_error:", conditionMessage(e)); NULL }
    )
    if (is.null(gam_fit)) next
    pred_grid <- expand.grid(t_i = workGrid, t_j = workGrid)
    cross_cov[i, j, , ] <- matrix(predict(gam_fit, newdata = pred_grid),
                                  nGrid, nGrid)
  }
  off_diag <- row(gam_status) != col(gam_status)
  pct_zero <- mean(gam_status[off_diag] != "ok")
  if (pct_zero > 0.50)
    warning(sprintf("[mfaces] %.0f%% off-diagonal cross-cov blocks fell to 0",
                    100 * pct_zero))

  for (i in seq_len(H)) for (j in seq_len(H)) if (i < j) {
    sym <- 0.5 * (cross_cov[i, j, , ] + t(cross_cov[j, i, , ]))
    cross_cov[i, j, , ] <- sym
    cross_cov[j, i, , ] <- t(sym)
  }

  # --- Apply Chiou normalization to each block ---------------------------
  # C̃_{h,h'}(s,t) = C_{h,h'}(s,t) / (sqrt_v[h] × sqrt_v[h'])
  # After this step, diag(C̃_{h,h}) integrates to 1 for every hormone.
  for (i in seq_len(H)) for (j in seq_len(H)) {
    cross_cov[i, j, , ] <- cross_cov[i, j, , ] / (sqrt_v[i] * sqrt_v[j])
  }

  C_joint <- matrix(0, H * nGrid, H * nGrid)
  for (i in seq_len(H)) for (j in seq_len(H)) {
    rows <- ((i-1)*nGrid + 1):(i*nGrid)
    cols <- ((j-1)*nGrid + 1):(j*nGrid)
    C_joint[rows, cols] <- cross_cov[i, j, , ]
  }
  C_joint <- 0.5 * (C_joint + t(C_joint))

  # --- Parche 3: verificación de rango numérico antes de eigen ---
  joint_diag <- list(
    dim = nrow(C_joint), frobenius = norm(C_joint, type = "F"),
    max_abs_val = max(abs(C_joint)),
    diag_mean = mean(diag(C_joint)), diag_min = min(diag(C_joint)))
  if (joint_diag$frobenius < .Machine$double.eps * joint_diag$dim)
    stop(sprintf("[mfaces] joint covariance numerically zero (Frobenius=%.2e)",
                 joint_diag$frobenius))

  eig <- eigen(C_joint, symmetric = TRUE)
  abs_floor <- max(abs(eig$values)) * 1e-10
  pos <- eig$values > abs_floor
  if (sum(pos) == 0)
    stop(sprintf("[mfaces] no positive eigenvalues above floor %.2e", abs_floor))

  values <- eig$values[pos]
  vectors <- eig$vectors[, pos, drop = FALSE]
  dt <- mean(diff(workGrid))
  vectors <- vectors / sqrt(dt)
  values <- values * dt

  K_total <- length(values)
  efs <- map(seq_along(analytes_kept), function(h) {
    rows <- ((h-1)*nGrid + 1):(h*nGrid)
    vectors[rows, , drop = FALSE]
  }) %>% set_names(analytes_kept)

  functions_mfd <- funData::multiFunData(
    map(efs, \(m) funData::funData(argvals = list(workGrid), X = t(m)))
  )

  # --- Parche 2: BLUP con ridge adaptativo ---
  sigma2_by <- map_dbl(face_fits, "sigma2") %>% set_names(analytes_kept)
  subj_ids <- unique(long_d$subject_id)
  scores <- matrix(NA_real_, length(subj_ids), K_total,
                   dimnames = list(subj_ids, paste0("xi", seq_len(K_total))))
  blup_na <- character(0)
  blup_ridge_used <- numeric(length(subj_ids)); names(blup_ridge_used) <- subj_ids

  # σ² in normalized space: σ̃²_h = σ²_h / v_h
  sigma2_normalized <- sigma2_by / integrated_var

  for (si in seq_along(subj_ids)) {
    d_i <- filter(long_d, subject_id == subj_ids[si])
    n_i <- nrow(d_i); if (n_i < 2) { blup_na <- c(blup_na, subj_ids[si]); next }
    a_idx <- match(d_i$hormone_name, analytes_kept)
    t_i <- d_i$actual_time_min
    mu_obs <- map_dbl(seq_len(n_i), \(k)
      approx(face_fits[[a_idx[k]]]$argvals.new, face_fits[[a_idx[k]]]$mu.new,
             xout = t_i[k], rule = 2)$y)
    # Normalize observations and eigenfunctions to same space as cross_cov
    sqrt_v_obs <- sqrt_v[a_idx]
    y_centered <- (d_i$d_value - mu_obs) / sqrt_v_obs
    Phi_i <- matrix(NA_real_, n_i, K_total)
    for (k in seq_len(n_i)) for (kk in seq_len(K_total))
      Phi_i[k, kk] <- approx(workGrid, efs[[a_idx[k]]][, kk],
                             xout = t_i[k], rule = 2)$y
    C_i <- matrix(NA_real_, n_i, n_i)
    for (r in seq_len(n_i)) for (c in seq_len(n_i))
      C_i[r, c] <- approx2d(workGrid, workGrid,
                            cross_cov[a_idx[r], a_idx[c], , ], t_i[r], t_i[c])
    sigma2_diag <- sigma2_normalized[a_idx]

    Sinv_y <- NULL; mult <- max(ridge, .Machine$double.eps)
    while (is.null(Sinv_y) && mult <= max(ridge_max_mult, ridge + 1)) {
      Sigma_i <- C_i + diag(sigma2_diag + mult * mean(sigma2_diag), n_i)
      Sinv_y <- tryCatch(solve(Sigma_i, y_centered), error = function(e) NULL)
      if (is.null(Sinv_y)) mult <- mult * 10
    }
    if (is.null(Sinv_y)) { blup_na <- c(blup_na, subj_ids[si]); next }
    blup_ridge_used[subj_ids[si]] <- mult
    scores[si, ] <- as.numeric(diag(values, K_total) %*% t(Phi_i) %*% Sinv_y)
  }

  diagnostics <- list(
    pair_counts = pair_counts, gam_status = gam_status,
    pct_offdiag_zero = pct_zero, joint_diag = joint_diag,
    blup_na_subjects = blup_na, blup_n_na = length(blup_na),
    blup_ridge_used = blup_ridge_used,
    blup_any_ridged = any(blup_ridge_used > 0, na.rm = TRUE),
    eigenvalue_floor = abs_floor, n_positive_eigs = sum(pos)
  )

  structure(list(
    values = values, functions = functions_mfd, scores = scores,
    face_fits = face_fits, cross_cov = cross_cov, workGrid = workGrid,
    analytes = analytes_kept, sigma2 = sigma2_by, H = H,
    integrated_var = integrated_var, sqrt_v = sqrt_v,
    chiou_normalized = chiou_normalize,
    diagnostics = diagnostics
  ), class = c("mfaces_fit", "list"))
}

print.mfaces_fit <- function(x, ...) {
  d <- x$diagnostics
  cat(sprintf("<mfaces_fit>  H = %d  |  K_total = %d\n", x$H, length(x$values)))
  cat(sprintf("  Cross-cov: %.0f%% off-diag blocks estimated (%.0f%% fell to 0)\n",
              100 * (1 - d$pct_offdiag_zero), 100 * d$pct_offdiag_zero))
  cat(sprintf("  BLUP: %d/%d subjects NA%s\n",
              d$blup_n_na, nrow(x$scores),
              if (d$blup_any_ridged) "; ridge triggered" else ""))
  cat(sprintf("  Joint eig: %d positive eigenvalues above %.2e\n",
              d$n_positive_eigs, d$eigenvalue_floor))
  top5 <- cumsum(x$values[seq_len(min(5, length(x$values)))]) / sum(x$values)
  cat(sprintf("  FVE top-5: %s\n",
              paste(sprintf("%.3f", top5), collapse = ", ")))
  invisible(x)
}

# ---------------------------------------------------------------------------
# retain_by_fve + sensitivity
# ---------------------------------------------------------------------------
retain_by_fve <- function(mfpca, threshold = 0.90, n_subjects = NULL) {
  vals <- mfpca$values
  fve_cum <- cumsum(vals) / sum(vals)
  K_sel <- min(which(fve_cum >= threshold))
  eigengap <- c(-diff(vals), NA_real_)
  N <- n_subjects %||% nrow(mfpca$scores)
  decision <- tibble(pc = seq_along(vals), eigenvalue = vals,
                     fve_cum = fve_cum, eigengap = eigengap,
                     retained = seq_along(vals) <= K_sel)
  diagnostics <- tibble(
    threshold = threshold, K_retained = K_sel,
    N_subjects = N, N_over_K = N / K_sel,
    passes_7_3 = (N / K_sel) > 10,
    fve_achieved = fve_cum[K_sel],
    min_eigengap_within = min(eigengap[seq_len(K_sel)], na.rm = TRUE),
    lambda_1 = vals[1], lambda_K_retained = vals[K_sel])
  mfpca_trunc <- mfpca
  mfpca_trunc$values <- vals[seq_len(K_sel)]
  mfpca_trunc$scores <- mfpca$scores[, seq_len(K_sel), drop = FALSE]
  structure(list(mfpca = mfpca_trunc, decision = decision,
                 diagnostics = diagnostics, full_values = vals),
            class = c("mfpca_retained", "list"))
}

retain_by_fve_sensitivity <- function(mfpca, thresholds = c(0.90, 0.95), ...) {
  res <- lapply(thresholds, \(t) retain_by_fve(mfpca, threshold = t, ...))
  names(res) <- sprintf("fve_%.2f", thresholds)
  comparison <- imap_dfr(res, \(r, tag) mutate(r$diagnostics, tag = tag, .before = 1))
  structure(list(by_threshold = res, comparison = comparison),
            class = c("mfpca_fve_sensitivity", "list"))
}

print.mfpca_retained <- function(x, ...) {
  d <- x$diagnostics
  cat(sprintf("<mfpca_retained>  FVE=%.2f  K=%d  FVE_ach=%.3f  N/K=%.1f  §7.3=%s\n",
              d$threshold, d$K_retained, d$fve_achieved, d$N_over_K,
              if (d$passes_7_3) "pass" else "FAIL"))
  invisible(x)
}
print.mfpca_fve_sensitivity <- function(x, ...) { print(x$comparison); invisible(x) }

# ---------------------------------------------------------------------------
# Clasificación
# ---------------------------------------------------------------------------
zscore_vs_reference <- function(scores, cohort,
                                reference = "no_obese_without_T2DM",
                                method = c("robust","mean_sd")) {
  method <- match.arg(method)
  ref_idx <- cohort == reference
  ref_mat <- scores[ref_idx, , drop = FALSE]
  if (method == "robust") {
    center <- apply(ref_mat, 2, median, na.rm = TRUE)
    scale  <- apply(ref_mat, 2, mad, na.rm = TRUE)  # MAD × 1.4826 by default
  } else {
    center <- colMeans(ref_mat, na.rm = TRUE)
    scale  <- apply(ref_mat, 2, sd, na.rm = TRUE)
  }
  scale[scale == 0 | is.na(scale)] <- 1
  sweep(sweep(scores, 2, center, "-"), 2, scale, "/")
}

identify_incretin_axis <- function(retained,
                                   incretin = c("GIP_total","GLP1_total","PYY_total")) {
  # Pre-registered rule (v10.0, OSF YAML): argmax relative —
  # always returns the PC with maximum squared incretin loading.
  # The loading value is attached as an attribute for downstream audit:
  # compliance check flags loading < 0.50 as a warning (not a fail).
  fns <- retained$mfpca$functions
  nms <- names(fns); K <- length(retained$mfpca$values)
  w <- vapply(seq_len(K), function(k) {
    sq_by_a <- vapply(nms, function(a) {
      x <- fns[[a]]@X[k, ]; dt <- mean(diff(fns[[a]]@argvals[[1]]))
      sum(x^2) * dt
    }, numeric(1))
    sum(sq_by_a[incretin], na.rm = TRUE) / sum(sq_by_a)
  }, numeric(1))
  k <- which.max(w)
  structure(as.integer(k),
            rule         = "argmax relative (pre-registered)",
            loading      = w[k],
            all_loadings = setNames(w, paste0("PC", seq_len(K))),
            warn_low     = w[k] < 0.50)
}

CLASS_LEVELS <- c("Preservado","Impairment_limitrofe","Impaired",
                  "Blunted","Enhanced","Altered")

classify_by_scores <- function(z, incretin_axis = NA_integer_) {
  apply(z, 1, function(zi) {
    zi_abs <- abs(zi)
    if (sum(zi_abs > 2, na.rm = TRUE) >= 2) return("Altered")
    if (!is.na(incretin_axis) && !is.na(zi[incretin_axis])) {
      if (zi[incretin_axis] >  2) return("Enhanced")
      if (zi[incretin_axis] < -2) return("Blunted")
    }
    if (any(zi_abs > 1.5 & zi_abs <= 2, na.rm = TRUE)) return("Impaired")
    if (any(zi_abs > 1.0 & zi_abs <= 1.5, na.rm = TRUE)) return("Impairment_limitrofe")
    "Preservado"
  }) |> factor(levels = CLASS_LEVELS)
}

mfaces_health_check <- function(fit, max_offdiag_zero = 0.30,
                                max_blup_na = 0.10, min_positive_eigs = 3) {
  d <- fit$diagnostics
  checks <- tibble(
    test = c("off-diagonal coverage", "BLUP NA fraction",
             "joint eigendecomp rank", "Σ_i ridge regularization"),
    observed = c(sprintf("%.1f%% blocks zeroed", 100 * d$pct_offdiag_zero),
                 sprintf("%d / %d (%.1f%%)", d$blup_n_na, nrow(fit$scores),
                         100 * d$blup_n_na / nrow(fit$scores)),
                 sprintf("%d positive eigenvalues", d$n_positive_eigs),
                 if (d$blup_any_ridged) "triggered" else "not triggered"),
    threshold = c(sprintf("≤ %.0f%%", 100 * max_offdiag_zero),
                  sprintf("≤ %.0f%%", 100 * max_blup_na),
                  sprintf("≥ %d", min_positive_eigs),
                  "informational"),
    status = c(
      if (d$pct_offdiag_zero <= max_offdiag_zero) "pass" else "fail",
      if (d$blup_n_na / nrow(fit$scores) <= max_blup_na) "pass" else "fail",
      if (d$n_positive_eigs >= min_positive_eigs) "pass" else "fail",
      if (d$blup_any_ridged) "warning" else "pass"
    )
  )
  checks
}

# ---------------------------------------------------------------------------
# Generador sintético
# ---------------------------------------------------------------------------
simulate_hormone_long <- function(n_per_cohort = 30,
                                  cohorts = c("no_obese_without_T2DM","Obesity","T2DM",
                                              "Obesity_T2DM","SG","RYGBP"),
                                  hormones = c("ghrelin_total","ghrelin_acyl",
                                               "GIP_total","GLP1_total","PYY_total",
                                               "insulin","glucose"),
                                  nominal_tp = c(-15, 0, 30, 60, 90, 120, 180),
                                  jitter_sd = 2) {
  cohort_amp <- tribble(
    ~cohort,                  ~ghrelin_total,~ghrelin_acyl,~GIP_total,~GLP1_total,~PYY_total,~insulin,~glucose,
    "no_obese_without_T2DM",          1.00,          1.00,      1.00,       1.00,       1.00,    1.00,   1.00,
    "Obesity",                        0.85,          0.80,      1.30,       0.70,       0.80,    2.30,   1.25,
    "T2DM",                           0.90,          0.90,      1.50,       0.55,       0.70,    0.60,   2.00,
    "Obesity_T2DM",                   0.75,          0.70,      1.60,       0.45,       0.60,    2.00,   2.40,
    "SG",                             0.30,          0.25,      0.90,       2.20,       2.50,    1.20,   0.95,
    "RYGBP",                          0.55,          0.50,      0.70,       3.00,       3.20,    1.30,   0.90
  )
  base_level <- c(ghrelin_total=500, ghrelin_acyl=80, GIP_total=15,
                  GLP1_total=10, PYY_total=30, insulin=60, glucose=5.0)

  subj_id <- 1L; rows <- list()
  for (co in cohorts) {
    amps <- cohort_amp[cohort_amp$cohort == co, -1, drop = FALSE]
    for (s in seq_len(n_per_cohort)) {
      sid <- sprintf("S%04d", subj_id); subj_id <- subj_id + 1L
      tp_sub <- sort(sample(nominal_tp, size = sample(5:7, 1)))
      # Ensure t=0 present for reference cohort to satisfy strict baseline rule
      if (co == "no_obese_without_T2DM" && !(0 %in% tp_sub)) tp_sub <- sort(c(0, tp_sub[-1]))
      for (h in hormones) {
        a <- as.numeric(amps[[h]]); b <- base_level[h]
        shape <- if (grepl("ghrelin", h)) -0.5 * exp(-((tp_sub-75)/60)^2)
                 else if (h == "glucose") 0.6 * exp(-((tp_sub-30)/35)^2)
                 else                     0.8 * exp(-((tp_sub-45)/40)^2)
        subj_effect <- rnorm(1, 0, 0.15)  # subject-level random intercept (log scale)
        value <- b * exp(subj_effect) * (a + a * shape + rnorm(length(tp_sub), 0, 0.05 * a))
        value <- pmax(value, 0.01)
        is_cens <- value < b * 0.05 & runif(length(tp_sub)) < 0.3
        value[is_cens] <- b * 0.05
        rows[[length(rows) + 1L]] <- tibble(
          subject_id = sid, cohort = co, hormone_name = h,
          timepoint_min = tp_sub,
          actual_time_min = tp_sub + rnorm(length(tp_sub), 0, jitter_sd),
          value = value, is_censored = is_cens
        )
      }
    }
  }
  bind_rows(rows)
}

# ===========================================================================
# EJECUCIÓN DEL DRY-RUN — solo corre cuando se invoca directamente con Rscript;
# sourcing desde otro script NO ejecuta este bloque.
# ===========================================================================
if (sys.nframe() == 0L) {
cat("\n=== 1. Generando datos sintéticos ===\n")
long <- simulate_hormone_long(n_per_cohort = 30)
cat(sprintf("rows=%d  subjects=%d  cohorts=%d  hormones=%d\n",
            nrow(long), n_distinct(long$subject_id),
            n_distinct(long$cohort), n_distinct(long$hormone_name)))

cat("\n=== 2. fit_all_analytes (PACE sensitivity) ===\n")
opts_pace <- list(dataType="Sparse", methodSelectK="FVE", FVEthreshold=0.95,
                  methodBwMu="GCV", methodBwCov="GCV",
                  methodXi="CE", methodMuCovEst="smooth",
                  error=TRUE, verbose=FALSE, nRegGrid=51, lean=TRUE)
batch <- fit_all_analytes(long, base_opts=opts_pace, min_obs=3,
                          reference_cohort="no_obese_without_T2DM")
print(batch)

cat("\n=== 3. fit_mfaces_joint (primary §7.4) ===\n")
mfaces <- fit_mfaces_joint(
  long,
  analytes = c("ghrelin_total","ghrelin_acyl","GIP_total","GLP1_total",
               "PYY_total","insulin","glucose"),
  reference_cohort = "no_obese_without_T2DM"
)
print(mfaces)

cat("\n=== 4. mfaces_health_check ===\n")
print(mfaces_health_check(mfaces))

cat("\n=== 5. retain_by_fve_sensitivity (0.90, 0.95) ===\n")
sens <- retain_by_fve_sensitivity(mfaces, thresholds=c(0.90, 0.95),
                                  n_subjects=nrow(mfaces$scores))
print(sens)

cat("\n=== 6. Clasificación por scores ===\n")
retained_primary <- sens$by_threshold$fve_0.90
cohort_vec <- tibble(subject_id = rownames(retained_primary$mfpca$scores)) |>
  left_join(distinct(long, subject_id, cohort), by="subject_id") |>
  pull(cohort)
z <- zscore_vs_reference(retained_primary$mfpca$scores, cohort_vec,
                         reference="no_obese_without_T2DM")
inc_axis <- identify_incretin_axis(retained_primary,
                                   incretin=c("GIP_total","GLP1_total","PYY_total"))
cat(sprintf("Incretin axis: PC%d  [rule: %s; loading = %.3f]%s\n",
            as.integer(inc_axis), attr(inc_axis, "rule"), attr(inc_axis, "loading"),
            if (isTRUE(attr(inc_axis, "warn_low"))) "  [WARN: loading < 0.50]" else ""))
cat(sprintf("All incretin loadings by PC: %s\n",
            paste(sprintf("%.3f", attr(inc_axis, "all_loadings")), collapse = ", ")))
cls <- classify_by_scores(z, incretin_axis = as.integer(inc_axis))
prevalence <- tibble(cohort=cohort_vec, cls_scores=cls) |>
  count(cohort, cls_scores) |>
  pivot_wider(names_from=cls_scores, values_from=n, values_fill=0L)
cat("\nPrevalence by cohort:\n")
print(prevalence)

cat("\n=== 7. Structural sanity ===\n")
cat(sprintf("mfaces_fit class ok: %s\n", inherits(mfaces, "mfaces_fit")))
cat(sprintf("retained_primary class ok: %s\n", inherits(retained_primary, "mfpca_retained")))
cat(sprintf("cls factor levels match: %s\n",
            identical(levels(cls), CLASS_LEVELS)))
cat(sprintf("K_retained @0.90: %d\n", retained_primary$diagnostics$K_retained))
cat(sprintf("NA scores on PC1: %d / %d\n",
            sum(is.na(mfaces$scores[, 1])), nrow(mfaces$scores)))

cat("\n=== DRY-RUN COMPLETE ===\n")
} # end if (sys.nframe() == 0L)
