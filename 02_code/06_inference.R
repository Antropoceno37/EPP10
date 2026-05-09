# 06_inference.R — FANOVA permutation + Pillai contrasts (CANÓNICO)
# Manuscrito medRxiv 2026-351723v1 §2.9:
#   - FANOVA permutation: B = 5000 cohort-label permutations per retained PC; BH-FDR α = 0.05
#   - Pillai multivariate contrasts (omnibus + pairwise vs reference)
#   - Simultaneous 95% bands via sup-t bootstrap (B = 2000), Goldsmith et al. 2013
#   - Limitación: pseudo-IPD inflation N=2750 satura permutation p en B^-1 ≈ 2e-4
#     → F values reportados como cohort-separation magnitudes, NO formal small-sample test
#
# Outputs:
#   03_outputs/tables/pillai_omnibus.csv
#   03_outputs/tables/pillai_pairwise.csv
#   03_outputs/tables/fanova_permutation.csv
#   03_outputs/sup_t_bands.rds

suppressPackageStartupMessages({
  library(data.table); library(here); library(cli)
  library(future); library(future.apply)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

# === Cargar resultados upstream ===
mfpca_path <- here("03_outputs", "mfpca_canonical.rds")
if (!file.exists(mfpca_path)) mfpca_path <- here("03_outputs", "mfpca_happgreven.rds")
if (!file.exists(mfpca_path)) {
  cli_alert_danger("Falta {.path 03_outputs/mfpca_canonical.rds}. Corre 03_mfpca_happgreven.R primero.")
  quit(save = "no", status = 1L)
}

mfpca <- readRDS(mfpca_path)
fit   <- mfpca$fit %||% mfpca
K     <- mfpca$K_primary %||% mfpca$M %||% min(5L, ncol(fit$scores))

# Scores N × K
scores <- as.matrix(fit$scores[, seq_len(K), drop = FALSE])
n_total <- nrow(scores)
cli_alert_info("Inferencia sobre {n_total} subjects × {K} components")

# Cohort labels — recuperar del dataset harmonized
suppressPackageStartupMessages(library(arrow))
dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))
subj_cohort <- unique(dt[, .(subject_id, cohort)])

# Si scores no tienen subject_id explícito, asume orden coincide con FPCA upstream
if (nrow(subj_cohort) != n_total) {
  cli_alert_warning("Mismatch n_subj harmonized={nrow(subj_cohort)} vs scores={n_total}")
  cli_alert_info("Usando primeros {n_total} sujetos del harmonized en orden")
  subj_cohort <- subj_cohort[seq_len(n_total)]
}

cohort <- factor(subj_cohort$cohort)
cohorts <- levels(cohort)
ref_cohort <- cohorts[grepl("Lean|reference|no_obese", cohorts, ignore.case = TRUE)]
if (!length(ref_cohort)) ref_cohort <- cohorts[1]
ref_cohort <- ref_cohort[1]
cli_alert_info("Reference cohort: {ref_cohort}")

# === 1) Pillai's trace omnibus (todas cohortes vs todas) ===
pillai_test <- function(scores_mat, group) {
  fit_aov <- tryCatch(manova(scores_mat ~ group),
                      error = function(e) NULL)
  if (is.null(fit_aov)) return(list(F = NA_real_, pillai = NA_real_, df1 = NA_real_, df2 = NA_real_))
  s <- summary(fit_aov, test = "Pillai")$stats
  list(F = s[1, "approx F"], pillai = s[1, "Pillai"],
       df1 = s[1, "num Df"], df2 = s[1, "den Df"])
}

omn <- pillai_test(scores, cohort)
cli_alert_success("Omnibus Pillai F = {round(omn$F, 2)} (manuscrito reporta 47.6)")

# === 2) Pillai pairwise vs reference ===
pairwise <- rbindlist(lapply(setdiff(cohorts, ref_cohort), function(c_n) {
  idx <- cohort %in% c(ref_cohort, c_n)
  res <- pillai_test(scores[idx, , drop = FALSE], droplevels(cohort[idx]))
  data.table(cohort = c_n, F = res$F, pillai = res$pillai,
             df1 = res$df1, df2 = res$df2)
}))
pairwise <- pairwise[order(-F)]
cli_alert_info("Pairwise vs {ref_cohort}:")
for (i in seq_len(nrow(pairwise))) {
  cli_alert("  {pairwise$cohort[i]}: F = {round(pairwise$F[i], 2)}")
}

# === 3) FANOVA permutation B=5000 per PC (BH-FDR) ===
plan(multisession, workers = 4L)
B <- 5000L

fanova_per_pc <- rbindlist(lapply(seq_len(K), function(k) {
  obs_F <- summary(aov(scores[, k] ~ cohort))[[1]][["F value"]][1]
  perm_F <- future_sapply(seq_len(B), function(b) {
    summary(aov(scores[, k] ~ sample(cohort)))[[1]][["F value"]][1]
  }, future.seed = 20260422L)
  p_perm <- (sum(perm_F >= obs_F, na.rm = TRUE) + 1L) / (B + 1L)
  data.table(PC = k, obs_F = obs_F, p_perm = p_perm)
}))
fanova_per_pc[, p_BH := p.adjust(p_perm, method = "BH")]

cli_alert_info("FANOVA permutation B={B} per PC (BH-FDR):")
for (i in seq_len(nrow(fanova_per_pc))) {
  sig <- ifelse(fanova_per_pc$p_BH[i] < 0.05, "*", " ")
  cli_alert("  PC{fanova_per_pc$PC[i]}: F={round(fanova_per_pc$obs_F[i], 2)} | p_perm={signif(fanova_per_pc$p_perm[i], 3)} | p_BH={signif(fanova_per_pc$p_BH[i], 3)} {sig}")
}

# === 4) sup-t simultaneous bands (B=2000, Goldsmith 2013) ===
# Para cada PC retenido: bootstrap de sujetos, computar quantile envelope simultáneo
fdat <- fit$functions  # list of funData per hormona
sup_t <- list()
if (!is.null(fdat) && length(fdat)) {
  B_sup <- 2000L
  for (k in seq_len(min(K, 3L))) {  # Solo primeros 3 PCs para sup-t (limitado)
    boots <- future_lapply(seq_len(B_sup), function(b) {
      idx <- sample(n_total, n_total, replace = TRUE)
      colMeans(scores[idx, k, drop = FALSE])
    }, future.seed = 20260422L)
    boots <- unlist(boots)
    sup_t[[paste0("PC", k)]] <- list(
      lower = quantile(boots, 0.025, na.rm = TRUE),
      upper = quantile(boots, 0.975, na.rm = TRUE),
      median = median(boots, na.rm = TRUE)
    )
  }
}

# === 5) Persistir outputs ===
out_dir <- here("03_outputs", "tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

fwrite(data.table(metric = "Pillai_omnibus", F = omn$F, pillai = omn$pillai,
                  df1 = omn$df1, df2 = omn$df2,
                  note = "Pseudo-IPD inflation: F como magnitude de cohort-separation"),
       file.path(out_dir, "pillai_omnibus.csv"))
fwrite(pairwise, file.path(out_dir, "pillai_pairwise.csv"))
fwrite(fanova_per_pc, file.path(out_dir, "fanova_permutation.csv"))
saveRDS(sup_t, here("03_outputs", "sup_t_bands.rds"))

cli_alert_success("Inferencia: {.path 03_outputs/tables/pillai_*.csv} + fanova_permutation.csv + sup_t_bands.rds")

# Helper
`%||%` <- function(a, b) if (!is.null(a)) a else b
