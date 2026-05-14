# =============================================================================
# R/mfaces_helpers.R — Lightweight mFACEs helpers (no heavy package deps)
# =============================================================================
# Canonical source for zscore_vs_reference, retain_by_fve, classify_by_scores
# and the CLASS_LEVELS factor levels. mfaces_dryrun.R sources this file so
# inline-vs-extracted versions cannot drift.
#
# Only functions that depend on base R / dplyr / tibble are extracted here —
# functions that pull in fdapace, face, mgcv, funData, MFPCA stay in
# mfaces_dryrun.R since installing those packages in a CI test environment is
# expensive and not required for unit tests of the helpers below.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tibble)
})

if (!exists("%||%", mode = "function")) {
  `%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a
}

CLASS_LEVELS <- c("Preservado", "Impairment_limitrofe", "Impaired",
                  "Blunted", "Enhanced", "Altered")

zscore_vs_reference <- function(scores, cohort,
                                reference = "no_obese_without_T2DM",
                                method = c("robust", "mean_sd")) {
  method <- match.arg(method)
  ref_idx <- cohort == reference
  ref_mat <- scores[ref_idx, , drop = FALSE]
  if (method == "robust") {
    center <- apply(ref_mat, 2, median, na.rm = TRUE)
    scale  <- apply(ref_mat, 2, mad, na.rm = TRUE)
  } else {
    center <- colMeans(ref_mat, na.rm = TRUE)
    scale  <- apply(ref_mat, 2, sd, na.rm = TRUE)
  }
  scale[scale == 0 | is.na(scale)] <- 1
  sweep(sweep(scores, 2, center, "-"), 2, scale, "/")
}

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
