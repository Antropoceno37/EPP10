# 06_lme4_scores.R
# Doc 2 §8 — Modelos jerárquicos sobre los scores MFPC.
# GATE Doc 1 §1 (inference ladder): solo si la unidad de análisis es A (subject-level).
# Output: 03_outputs/tables/lme4_scores.csv

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here)
  library(lme4); library(lmerTest); library(emmeans); library(broom.mixed); library(cli)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))

# GATE: bloquea si los datos no son subject-level
unit <- unique(dt$unit_of_analysis)
if (!(any(grepl("^A_", unit)))) {
  cli_alert_warning("Unit of analysis = {unit}. lme4 NO aplica (solo subject-level).")
  cli_alert_info("Resultado: 'inference not supportable at this evidence tier'.")
  fwrite(data.table(message = "lme4 skipped — non-subject-level data"),
         here("03_outputs", "tables", "lme4_scores.csv"))
  quit(save = "no", status = 0L)
}

mfpca <- readRDS(here("03_outputs", "mfpca_happgreven.rds"))
M     <- mfpca$M

# Scores subject × MFPC (Doc 2 §8: score_iM ~ cohort + age + sex + BMI + (1|site))
# Aquí: solo cohort (sintético no tiene age/sex/BMI). En datos reales, completar.
sc <- as.data.table(mfpca$fit$scores[, seq_len(M), drop = FALSE])
setnames(sc, paste0("MFPC", seq_len(M)))

subjects <- unique(dt[, .(subject_id, cohort)])
sc[, subject_id := subjects$subject_id]
sc[, cohort := factor(subjects$cohort, levels = c("Lean-Healthy", "Obesity",
                                                  "Obesity+T2DM", "Sleeve", "RYGBP"))]

# Dataset sintético: site = primera letra del cohort (para demostrar (1|site))
sc[, site := substr(cohort, 1, 3)]

results <- rbindlist(lapply(seq_len(M), function(m) {
  formula <- as.formula(sprintf("MFPC%d ~ cohort + (1|site)", m))
  fit <- tryCatch(lmer(formula, data = sc, REML = TRUE),
                  error = function(e) NULL)
  if (is.null(fit)) return(NULL)
  tidied <- broom.mixed::tidy(fit, conf.int = TRUE)
  tidied$component <- paste0("MFPC", m)
  as.data.table(tidied)
}))

out <- here("03_outputs", "tables", "lme4_scores.csv")
fwrite(results, out)
cli_alert_success("lme4 scores: {.path {out}} ({nrow(results)} efectos)")

# Comparaciones múltiples Tukey HSD (Doc 2 §8)
emm_out <- here("03_outputs", "tables", "lme4_tukey.csv")
emm_results <- rbindlist(lapply(seq_len(M), function(m) {
  formula <- as.formula(sprintf("MFPC%d ~ cohort + (1|site)", m))
  fit <- lmer(formula, data = sc, REML = TRUE)
  emm <- emmeans(fit, ~ cohort)
  pairs_df <- as.data.table(pairs(emm, adjust = "tukey"))
  pairs_df[, component := paste0("MFPC", m)]
  pairs_df
}), fill = TRUE)
fwrite(emm_results, emm_out)
cli_alert_success("Tukey HSD: {.path {emm_out}}")
