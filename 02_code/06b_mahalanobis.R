# 06b_mahalanobis.R — Mahalanobis cross-cohort separability (Lancet D&E §L3.8a)
# Meta-prompt v1.1: distances between cohort centroids in (xi1, xi2, xi3, nu1..nu4) score space;
# permutation p-values with Bonferroni correction.
#
# Output:
#   03_outputs/tables/mahalanobis_cohort.csv

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(cli)
})
set.seed(20260422)

mfpca_path <- here("03_outputs", "mfpca_canonical.rds")
if (!file.exists(mfpca_path)) mfpca_path <- here("03_outputs", "mfpca_happgreven.rds")
mfpca <- readRDS(mfpca_path)
fit   <- mfpca$fit %||% mfpca
K     <- mfpca$K_primary %||% mfpca$M %||% min(7L, ncol(fit$scores))

# Use up to 7 components (xi1..xi3 univariate proxy + nu1..nu4 multivariate)
scores <- as.matrix(fit$scores[, seq_len(min(K, 7L)), drop = FALSE])
n_total <- nrow(scores)

dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))
subj_cohort <- unique(dt[, .(subject_id, cohort)])
if (nrow(subj_cohort) != n_total) {
  cli_alert_warning("n_subj harmonized={nrow(subj_cohort)} vs scores={n_total}; using first {n_total}")
  subj_cohort <- subj_cohort[seq_len(n_total)]
}
cohort <- factor(subj_cohort$cohort)
cohorts <- levels(cohort)

# Reference cohort
ref_cohort <- cohorts[grepl("Lean|reference|no_obese", cohorts, ignore.case = TRUE)]
if (!length(ref_cohort)) ref_cohort <- cohorts[1]
ref_cohort <- ref_cohort[1]
cli_alert_info("Reference: {ref_cohort}")

# Pooled within-cohort covariance
pooled_cov <- function(X, g) {
  groups <- levels(g)
  k <- length(groups); n <- nrow(X); p <- ncol(X)
  W <- matrix(0, p, p)
  for (gi in groups) {
    Xi <- X[g == gi, , drop = FALSE]
    if (nrow(Xi) < 2L) next
    W <- W + (nrow(Xi) - 1L) * cov(Xi)
  }
  W / max(n - k, 1L)
}

S <- pooled_cov(scores, cohort)
S_inv <- tryCatch(solve(S), error = function(e) MASS::ginv(S))

centroids <- t(sapply(cohorts, function(c_n) colMeans(scores[cohort == c_n, , drop = FALSE])))
rownames(centroids) <- cohorts

mahal <- function(a, b) sqrt(t(a - b) %*% S_inv %*% (a - b))

# Pairwise vs reference
ref_mu <- centroids[ref_cohort, ]
others <- setdiff(cohorts, ref_cohort)

# Permutation p (B=1000): permute cohort labels, recompute distance, count exceedances.
B <- 1000L
mahal_dt <- rbindlist(lapply(others, function(c_n) {
  obs_d <- as.numeric(mahal(ref_mu, centroids[c_n, ]))
  perm_d <- replicate(B, {
    perm_label <- sample(cohort)
    mu_ref_p <- colMeans(scores[perm_label == ref_cohort, , drop = FALSE])
    mu_oth_p <- colMeans(scores[perm_label == c_n, , drop = FALSE])
    as.numeric(mahal(mu_ref_p, mu_oth_p))
  })
  p_perm <- (sum(perm_d >= obs_d, na.rm = TRUE) + 1L) / (B + 1L)
  data.table(cohort = c_n, mahal_d = obs_d, p_perm = p_perm)
}))
mahal_dt[, p_bonf := pmin(p_perm * nrow(mahal_dt), 1)]
mahal_dt <- mahal_dt[order(-mahal_d)]

out_dir <- here("03_outputs", "tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
fwrite(mahal_dt, file.path(out_dir, "mahalanobis_cohort.csv"))

cli_alert_success("Mahalanobis vs {ref_cohort} (B={B}, Bonferroni):")
for (i in seq_len(nrow(mahal_dt))) {
  cli_alert("  {mahal_dt$cohort[i]}: D = {round(mahal_dt$mahal_d[i], 2)} | p_bonf = {signif(mahal_dt$p_bonf[i], 3)}")
}

`%||%` <- function(a, b) if (!is.null(a)) a else b
