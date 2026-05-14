# =============================================================================
# classify_ptp_iep.R — Per-analyte PTP + IEP Type I–V (framework v1.0, April 2026)
# =============================================================================
# Applies the deterministic PTP/IEP classification framework to the primary
# mFACEs fit + univariate PACE scores. Emits:
#   • per-analyte PTP class (primary 6-class, secondary 9-class where applicable)
#   • cohort-time-arm IEP Type (I.I, I.II, II.I, II.II, III.I, III.II, IV.I, IV.II,
#                                V.I, V.II) with glucose subtype a/b/c
#   • classifiability flag per arm
# =============================================================================

.libPaths(c("~/.R/library", .libPaths()))
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(purrr); library(tibble)
})

# Classifier pure functions live in R/classifier.R so they can be unit-tested
# without sourcing the full pipeline. UPPER_TAIL_ALTERED_ANALYTES,
# ENHANCED_CANDIDATES, INCRETIN_SATIETY, classify_ptp_primary, classify_ptp_all,
# iep_group and assign_iep_type are all defined there.
source("/Users/hmva/EPP10/R/classifier.R")

REF_COHORT <- "no_obese_without_T2DM"
POST_INTERV_COHORTS <- c("SG", "RYGBP")   # also applies to caloric_restriction_post

# -- 1. Load univariate PACE fits per analyte --------------------------------
# (We re-use the batch fits from the primary run; if these aren't saved, re-run
#  fit_all_analytes with the current seed and pseudo-IPD)
source("/Users/hmva/EPP10/mfaces_dryrun.R", echo = FALSE)
pipd_sub <- read_csv("/Users/hmva/EPP10/pseudo_ipd_subsample_N50_rho050_cv100.csv",
                     show_col_types = FALSE)

opts_pace <- list(dataType = "Sparse", methodSelectK = "FVE", FVEthreshold = 0.95,
                  methodBwMu = "GCV", methodBwCov = "GCV",
                  methodXi = "CE", methodMuCovEst = "smooth",
                  error = TRUE, verbose = FALSE, nRegGrid = 51, lean = FALSE)
cat("Fitting univariate PACE per analyte (cached via fit_all_analytes)…\n")
batch <- fit_all_analytes(pipd_sub, base_opts = opts_pace, min_obs = 3,
                          reference_cohort = REF_COHORT)
cat(sprintf("  %d analytes fit OK\n", length(batch$fits)))

# -- 2. Extract per-subject [basal, ξ1, ξ2, ξ3] per analyte ------------------
# basal: value at t == 0 (or nearest); from long data pre-baseline-subtraction
baselines <- pipd_sub %>%
  filter(timepoint_min == 0) %>%
  select(subject_id, hormone_name, basal = value)

# For each fit, scores matrix with rows = subject_ids, cols = PC1..3
score_tbl <- imap_dfr(batch$fits, function(fit, analyte) {
  sids <- fit$inputData$Lid %||% rownames(fit$xiEst) %||%
          unique(pipd_sub$subject_id[pipd_sub$hormone_name == analyte])
  scores <- fit$xiEst
  K_keep <- min(3, ncol(scores))
  tibble(subject_id = sids,
         hormone_name = analyte,
         xi1 = scores[, 1],
         xi2 = if (K_keep >= 2) scores[, 2] else NA_real_,
         xi3 = if (K_keep >= 3) scores[, 3] else NA_real_)
})

Z_long <- baselines %>%
  inner_join(score_tbl, by = c("subject_id", "hormone_name"))

# -- 3. Reference percentiles per analyte ------------------------------------
ref_sids <- unique(pipd_sub$subject_id[pipd_sub$cohort == REF_COHORT])
ref_Z <- Z_long %>% filter(subject_id %in% ref_sids)

ref_percentiles <- ref_Z %>%
  group_by(hormone_name) %>%
  summarise(
    basal_p5  = quantile(basal, 0.05, na.rm = TRUE),
    basal_p10 = quantile(basal, 0.10, na.rm = TRUE),
    basal_p25 = quantile(basal, 0.25, na.rm = TRUE),
    basal_p75 = quantile(basal, 0.75, na.rm = TRUE),
    basal_p95 = quantile(basal, 0.95, na.rm = TRUE),
    pc1_p5    = quantile(xi1,   0.05, na.rm = TRUE),
    pc1_p10   = quantile(xi1,   0.10, na.rm = TRUE),
    pc1_p25   = quantile(xi1,   0.25, na.rm = TRUE),
    pc1_p75   = quantile(xi1,   0.75, na.rm = TRUE),
    pc1_p95   = quantile(xi1,   0.95, na.rm = TRUE),
    pc2_p5    = quantile(xi2,   0.05, na.rm = TRUE),
    pc2_p95   = quantile(xi2,   0.95, na.rm = TRUE),
    pc3_p5    = quantile(xi3,   0.05, na.rm = TRUE),
    pc3_p95   = quantile(xi3,   0.95, na.rm = TRUE),
    .groups = "drop"
  )

# -- 4. PTP classifier per (subject × analyte) ------------------------------
# Pathophysiological-relevance filter per PTP framework §3.6, §3.7 is encoded
# in classify_ptp_primary / classify_ptp_all (see R/classifier.R).
cat("\nClassifying per-analyte PTPs…\n")
cohort_lookup <- distinct(pipd_sub, subject_id, cohort)
Z_ptp <- classify_ptp_all(Z_long, ref_percentiles, cohort_lookup$cohort,
                          POST_INTERV_COHORTS) %>%
  left_join(cohort_lookup, by = "subject_id")

# -- 5. Upgrade to secondary PTPs in post-intervention cohorts ---------------
# In post-bariatric cohorts, "Borderline Altered"/"Altered" labels that apply to
# GLP-1, PYY, incretin total — with glucose subtype a (preserved) — reclassify
# as "Borderline Enhanced"/"Enhanced" (physiologically coherent amplification).
# This requires knowing each subject's glucose class to condition the upgrade.
glucose_status <- Z_ptp %>%
  filter(hormone_name == "glucose") %>%
  select(subject_id, glucose_ptp = ptp_primary) %>%
  mutate(glucose_subtype = case_when(
    glucose_ptp %in% c("Preserved", "Recovered") ~ "a",
    glucose_ptp %in% c("Borderline Impaired", "Impaired", "Blunted") ~ "b",
    glucose_ptp %in% c("Borderline Altered", "Altered") ~ "c",
    TRUE ~ "unclassifiable"
  ))

incretin_satiety <- INCRETIN_SATIETY

Z_ptp <- Z_ptp %>%
  left_join(glucose_status, by = "subject_id")

# Direct-route to Enhanced for GLP-1/PYY/glucagon upper-tail in any cohort
# (per §3.7: upper-tail GLP-1 is NOT automatically pathological; in disease +
#  surgery contexts it can be physiologically coherent when glucose is preserved)
# ENHANCED_CANDIDATES sourced from R/classifier.R.

Z_ptp <- Z_ptp %>%
  left_join(Z_ptp %>% select(subject_id, hormone_name, basal, xi1,
                              basal_p75, basal_p95, pc1_p75, pc1_p95) %>%
             rename(b2 = basal, x2 = xi1, b75 = basal_p75, b95 = basal_p95,
                    p75 = pc1_p75, p95 = pc1_p95),
             by = c("subject_id", "hormone_name")) %>%
  mutate(
    is_upper_p95 = (!is.na(b2) & b2 >= b95) | (!is.na(x2) & x2 >= p95),
    is_upper_p75 = ((!is.na(b2) & b2 >= b75 & b2 < b95) |
                     (!is.na(x2) & x2 >= p75 & x2 < p95)) & !is_upper_p95,
    ptp_final = case_when(
      # Primary upgrade: Borderline Altered → Borderline Enhanced (gut/incretin, any cohort with glucose a)
      hormone_name %in% ENHANCED_CANDIDATES & is_upper_p95 & glucose_subtype == "a" ~ "Enhanced",
      hormone_name %in% ENHANCED_CANDIDATES & is_upper_p75 & glucose_subtype == "a" ~ "Borderline Enhanced",
      # Default: primary PTP as computed
      TRUE ~ ptp_primary
    )
  ) %>%
  select(-b2, -x2, -b75, -b95, -p75, -p95, -is_upper_p95, -is_upper_p75)

# -- 6. IEP Type assignment per subject (treating each pseudo-subject as a
#       cohort-time-arm draw; framework speaks of cohort-time-arm but for
#       pseudo-IPD we apply per pseudo-subject and aggregate to cohort).
#       iep_group and assign_iep_type live in R/classifier.R.
Z_ptp <- Z_ptp %>% mutate(group = iep_group(ptp_final))

cat("\nAssigning IEP Type I–V per pseudo-subject…\n")
iep_by_subj <- Z_ptp %>%
  nest(analytes = -c(subject_id, cohort)) %>%
  mutate(iep = map(analytes, assign_iep_type)) %>%
  unnest(iep) %>%
  select(subject_id, cohort, iep_type, glucose_subtype)

cat(sprintf("  Classifiable: %d / %d\n",
            sum(iep_by_subj$iep_type != "not_integrable"), nrow(iep_by_subj)))

# -- 7. Aggregate to cohort level --------------------------------------------
iep_freq <- iep_by_subj %>%
  count(cohort, iep_type, name = "n") %>%
  group_by(cohort) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  select(-n) %>%
  pivot_wider(names_from = iep_type, values_from = pct, values_fill = 0) %>%
  arrange(factor(cohort, levels = c("no_obese_without_T2DM","Obesity","T2DM",
                                     "Obesity_T2DM","SG","RYGBP")))

cat("\n=== IEP Type distribution per cohort (%) ===\n")
print(iep_freq, width = Inf)

# Glucose subtype × Type cross-tab
gxt <- iep_by_subj %>% filter(iep_type != "not_integrable") %>%
  count(cohort, iep_type, glucose_subtype, name = "n") %>%
  arrange(cohort, iep_type, glucose_subtype)

cat("\n=== IEP Type × glucose subtype (counts per cohort) ===\n")
print(gxt %>% slice_head(n = 30))

# Also: per-analyte PTP prevalence per cohort
analyte_ptp_freq <- Z_ptp %>%
  count(cohort, hormone_name, ptp_final, name = "n") %>%
  group_by(cohort, hormone_name) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  select(-n) %>%
  pivot_wider(names_from = ptp_final, values_from = pct, values_fill = 0)

# -- 8. Save artefacts -------------------------------------------------------
OUT_DIR <- "/Users/hmva/EPP10"
write_csv(Z_ptp, file.path(OUT_DIR, "ptp_per_subject_analyte.csv"))
write_csv(iep_by_subj, file.path(OUT_DIR, "iep_per_subject.csv"))
write_csv(iep_freq, file.path(OUT_DIR, "iep_frequency_by_cohort.csv"))
write_csv(analyte_ptp_freq, file.path(OUT_DIR, "ptp_frequency_by_cohort_analyte.csv"))

saveRDS(list(Z_ptp = Z_ptp, iep_by_subj = iep_by_subj,
             iep_freq = iep_freq, ref_percentiles = ref_percentiles,
             analyte_ptp_freq = analyte_ptp_freq),
        file.path(OUT_DIR, "ptp_iep_results.rds"))
cat("\nSaved: ptp_iep_results.rds, iep_frequency_by_cohort.csv,\n")
cat("       ptp_per_subject_analyte.csv, ptp_frequency_by_cohort_analyte.csv\n")
