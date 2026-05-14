# =============================================================================
# R/simulate_helpers.R — GP simulation kernels (pure functions)
# =============================================================================
# Canonical source for ar1_kernel and sample_gp. simulate_pseudo_ipd.R sources
# this file.
# =============================================================================

ar1_kernel <- function(t, rho, delta_ref = 30) {
  d <- as.matrix(dist(t, diag = TRUE, upper = TRUE))
  rho ^ (d / delta_ref)
}

sample_gp <- function(mu, Sigma, M, seed = NULL,
                      clip_nonneg = TRUE, sigma_floor_frac = 0.01) {
  if (!is.null(seed)) set.seed(seed)
  n_t <- length(mu)
  if (any(!is.finite(mu)))     mu[!is.finite(mu)] <- 0
  if (any(!is.finite(Sigma)))  Sigma[!is.finite(Sigma)] <- 0
  content_scale <- max(abs(mu), 1, diag(Sigma), na.rm = TRUE)
  diag_floor <- max((sigma_floor_frac * content_scale) ^ 2, 1e-8)
  L <- NULL
  for (mult in c(1, 10, 100, 1000)) {
    L <- tryCatch(
      chol(Sigma + diag(diag_floor * mult, n_t)),
      error = function(e) NULL
    )
    if (!is.null(L)) break
  }
  if (is.null(L)) {
    L <- diag(sqrt(diag(Sigma) + diag_floor), n_t)
  }
  Z <- matrix(rnorm(M * n_t), nrow = n_t, ncol = M)
  Y <- mu + t(L) %*% Z
  if (clip_nonneg) Y[Y < 0] <- 0
  t(Y)
}
