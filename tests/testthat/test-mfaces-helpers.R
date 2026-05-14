# =============================================================================
# Tests for lightweight mFACEs helpers (R/mfaces_helpers.R)
# =============================================================================

# ---- zscore_vs_reference ----------------------------------------------------

test_that("zscore_vs_reference (mean_sd) centers the reference cohort to mean 0", {
  set.seed(42)
  scores <- matrix(rnorm(60, mean = 5, sd = 2), ncol = 3)
  cohort <- rep(c("ref", "test"), each = 10)
  z <- zscore_vs_reference(scores, cohort, reference = "ref", method = "mean_sd")
  ref_z <- z[cohort == "ref", ]
  expect_equal(colMeans(ref_z), rep(0, 3), tolerance = 1e-10)
  # And unit SD on the reference rows
  expect_equal(apply(ref_z, 2, sd), rep(1, 3), tolerance = 1e-10)
})

test_that("zscore_vs_reference handles zero-scale columns by substituting 1", {
  scores <- matrix(rep(5, 30), ncol = 3)  # zero variance on every column
  cohort <- rep(c("ref", "test"), each = 5)
  expect_silent(z <- zscore_vs_reference(scores, cohort, reference = "ref",
                                         method = "mean_sd"))
  expect_true(all(is.finite(z)))
})

test_that("zscore_vs_reference robust resists a single ref-cohort outlier", {
  set.seed(42)
  # 9 well-behaved reference values + 1 large outlier on column 1
  col1_ref <- c(rnorm(9, mean = 0, sd = 1), 100)
  col2_ref <- rnorm(10)
  col3_ref <- rnorm(10)
  col1_test <- rnorm(10); col2_test <- rnorm(10); col3_test <- rnorm(10)
  scores <- cbind(c(col1_ref, col1_test),
                  c(col2_ref, col2_test),
                  c(col3_ref, col3_test))
  cohort <- c(rep("ref", 10), rep("test", 10))
  z_robust <- zscore_vs_reference(scores, cohort, reference = "ref",
                                  method = "robust")
  z_mean   <- zscore_vs_reference(scores, cohort, reference = "ref",
                                  method = "mean_sd")
  # mean_sd is dragged by the outlier; robust shouldn't be
  expect_gt(abs(z_robust[1, 1] - z_mean[1, 1]), 0.1)
})

# ---- retain_by_fve ----------------------------------------------------------

mk_mfpca <- function(values = c(5, 3, 1.5, 0.4, 0.1)) {
  list(values = values, scores = matrix(rnorm(10 * length(values)), nrow = 10))
}

test_that("retain_by_fve K is monotone non-decreasing in threshold", {
  set.seed(1)
  mfpca <- mk_mfpca()
  r_80 <- retain_by_fve(mfpca, threshold = 0.80)
  r_90 <- retain_by_fve(mfpca, threshold = 0.90)
  r_95 <- retain_by_fve(mfpca, threshold = 0.95)
  expect_lte(r_80$diagnostics$K_retained, r_90$diagnostics$K_retained)
  expect_lte(r_90$diagnostics$K_retained, r_95$diagnostics$K_retained)
})

test_that("retain_by_fve fve_achieved is at least the requested threshold", {
  set.seed(1)
  mfpca <- mk_mfpca()
  for (thr in c(0.50, 0.80, 0.90, 0.99)) {
    r <- retain_by_fve(mfpca, threshold = thr)
    expect_gte(r$diagnostics$fve_achieved, thr)
  }
})

test_that("retain_by_fve passes_7_3 reflects N/K > 10", {
  set.seed(1)
  # 5 PCs; N=200 subjects => N/K_retained at threshold 0.80 should be 200/2 = 100 -> pass
  mfpca <- list(values = c(5, 3, 1.5, 0.4, 0.1),
                scores = matrix(rnorm(200 * 5), nrow = 200))
  r <- retain_by_fve(mfpca, threshold = 0.80)
  expect_true(r$diagnostics$passes_7_3)
  # N=15 with K_retained=2 => N/K = 7.5 -> fail
  mfpca2 <- list(values = c(5, 3, 1.5, 0.4, 0.1),
                 scores = matrix(rnorm(15 * 5), nrow = 15))
  r2 <- retain_by_fve(mfpca2, threshold = 0.80)
  expect_false(r2$diagnostics$passes_7_3)
})

test_that("retain_by_fve truncates scores and values to K_retained", {
  set.seed(1)
  mfpca <- mk_mfpca()
  r <- retain_by_fve(mfpca, threshold = 0.80)
  K <- r$diagnostics$K_retained
  expect_equal(length(r$mfpca$values), K)
  expect_equal(ncol(r$mfpca$scores), K)
})

# ---- classify_by_scores -----------------------------------------------------

test_that("classify_by_scores uses incretin_axis for Enhanced / Blunted", {
  z <- rbind(
    c(0,  2.5,  0),  # incretin axis (PC2) > 2  -> Enhanced
    c(0, -2.5,  0),  # incretin axis < -2       -> Blunted
    c(0,  1.2,  0),  # PC2 in (1.0, 1.5]        -> Impairment_limitrofe
    c(0,  0,    0)   # all zero                 -> Preservado
  )
  cls <- classify_by_scores(z, incretin_axis = 2L)
  expect_equal(as.character(cls),
               c("Enhanced", "Blunted", "Impairment_limitrofe", "Preservado"))
})

test_that("classify_by_scores returns Altered when 2+ axes have |z| > 2", {
  z <- rbind(c(2.5, 2.5, 0))
  cls <- classify_by_scores(z, incretin_axis = 2L)
  expect_equal(as.character(cls), "Altered")
})

test_that("classify_by_scores Altered priority beats Enhanced via incretin", {
  # Both PC1 and PC2 above |2|; even though PC2 (incretin) > 2 would suggest
  # Enhanced, two axes above 2 trigger Altered first
  z <- rbind(c(2.5, 2.5, 0))
  cls <- classify_by_scores(z, incretin_axis = 2L)
  expect_equal(as.character(cls), "Altered")
})

test_that("classify_by_scores Impaired triggers in (1.5, 2] window", {
  z <- rbind(c(1.7, 0, 0))
  cls <- classify_by_scores(z, incretin_axis = 2L)
  expect_equal(as.character(cls), "Impaired")
})

test_that("classify_by_scores returns the factor with canonical levels", {
  z <- rbind(c(0, 0, 0))
  cls <- classify_by_scores(z, incretin_axis = 2L)
  expect_equal(levels(cls), CLASS_LEVELS)
})

test_that("classify_by_scores tolerates NA in non-extreme positions", {
  z <- rbind(c(0, NA, 0))
  cls <- classify_by_scores(z, incretin_axis = 2L)
  expect_equal(as.character(cls), "Preservado")
})
