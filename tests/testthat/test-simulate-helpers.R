# =============================================================================
# Tests for ar1_kernel and sample_gp (R/simulate_helpers.R)
# =============================================================================

# ---- ar1_kernel -------------------------------------------------------------

test_that("ar1_kernel is symmetric with unit diagonal", {
  t <- c(0, 30, 60, 90, 120)
  K <- ar1_kernel(t, rho = 0.5)
  expect_equal(diag(K), rep(1, length(t)))
  expect_true(isSymmetric(K))
})

test_that("ar1_kernel obeys K[i,j] = rho^(|t_i - t_j| / delta_ref)", {
  t <- c(0, 30, 60)
  rho <- 0.5
  K <- ar1_kernel(t, rho = rho, delta_ref = 30)
  expect_equal(K[1, 2], rho^(30 / 30))
  expect_equal(K[1, 3], rho^(60 / 30))
  expect_equal(K[2, 3], rho^(30 / 30))
})

test_that("ar1_kernel decays monotonically with distance", {
  t <- seq(0, 180, by = 30)
  K <- ar1_kernel(t, rho = 0.5)
  expect_true(all(diff(K[1, ]) <= 0))
})

test_that("ar1_kernel rho near 1 produces near-perfect correlation", {
  t <- c(0, 30, 60, 90)
  K <- ar1_kernel(t, rho = 0.999)
  expect_true(all(K > 0.99))
})

test_that("ar1_kernel rho near 0 produces near-zero off-diagonal", {
  t <- c(0, 30, 60, 90)
  K <- ar1_kernel(t, rho = 0.001)
  off_diag <- K[lower.tri(K)]
  expect_true(all(off_diag < 0.01))
})

# ---- sample_gp --------------------------------------------------------------

test_that("sample_gp produces M trajectories of length n_t", {
  mu <- c(1, 2, 3, 4, 5)
  Sigma <- diag(0.1, 5)
  out <- sample_gp(mu, Sigma, M = 10, seed = 42)
  expect_equal(dim(out), c(10, 5))
})

test_that("sample_gp clip_nonneg=TRUE eliminates negative values", {
  mu <- rep(0, 5)
  Sigma <- diag(1, 5)
  out <- sample_gp(mu, Sigma, M = 200, seed = 42, clip_nonneg = TRUE)
  expect_true(all(out >= 0))
})

test_that("sample_gp clip_nonneg=FALSE allows negative values", {
  mu <- rep(0, 5)
  Sigma <- diag(1, 5)
  out <- sample_gp(mu, Sigma, M = 200, seed = 42, clip_nonneg = FALSE)
  expect_true(any(out < 0))
})

test_that("sample_gp is deterministic for a fixed seed", {
  mu <- c(1, 2, 3)
  Sigma <- diag(0.5, 3)
  out1 <- sample_gp(mu, Sigma, M = 5, seed = 123, clip_nonneg = FALSE)
  out2 <- sample_gp(mu, Sigma, M = 5, seed = 123, clip_nonneg = FALSE)
  expect_equal(out1, out2)
})

test_that("sample_gp ridge fallback handles a singular Sigma without erroring", {
  mu <- c(1, 2, 3)
  Sigma <- matrix(0, 3, 3)  # rank 0
  expect_silent(out <- sample_gp(mu, Sigma, M = 5, seed = 42,
                                 clip_nonneg = FALSE))
  expect_equal(dim(out), c(5, 3))
  expect_true(all(is.finite(out)))
})

test_that("sample_gp sanitises non-finite inputs in mu and Sigma", {
  mu <- c(1, NA, Inf)
  Sigma <- diag(c(1, NaN, 1), 3)
  expect_silent(out <- sample_gp(mu, Sigma, M = 5, seed = 42,
                                 clip_nonneg = FALSE))
  expect_true(all(is.finite(out)))
})

test_that("sample_gp recovers mean across many draws", {
  mu <- c(10, 20, 30)
  Sigma <- diag(1, 3)
  out <- sample_gp(mu, Sigma, M = 5000, seed = 42, clip_nonneg = FALSE)
  empirical_mean <- colMeans(out)
  expect_equal(empirical_mean, mu, tolerance = 0.1)
})
