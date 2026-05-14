# =============================================================================
# R/classifier.R — PTP / IEP deterministic classifier (pure functions)
# =============================================================================
# Canonical source for classify_ptp_primary, iep_group and assign_iep_type.
# classify_ptp_iep.R sources this file so the inline-vs-extracted versions
# cannot drift.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(purrr); library(tibble)
})

if (!exists("%||%", mode = "function")) {
  `%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a
}

UPPER_TAIL_ALTERED_ANALYTES <- c("GIP_total", "GIP_active", "insulin", "glucose",
                                 "ghrelin_total", "ghrelin_acyl")

ENHANCED_CANDIDATES <- c("GLP1_total", "GLP1_active", "PYY_total", "PYY_3_36",
                        "glucagon")

INCRETIN_SATIETY <- c("GLP1_total", "GLP1_active", "PYY_total", "PYY_3_36",
                     "GIP_total", "GIP_active")

classify_ptp_primary <- function(z_row, ref, analyte) {
  B <- z_row$basal; X1 <- z_row$xi1
  upper_triggers_altered <- analyte %in% UPPER_TAIL_ALTERED_ANALYTES

  if (upper_triggers_altered) {
    if (!is.na(B) && B >= ref$basal_p95) return("Altered")
    if (!is.na(X1) && X1 >= ref$pc1_p95) return("Altered")
    if (!is.na(B) && B >= ref$basal_p75 && B < ref$basal_p95) return("Borderline Altered")
    if (!is.na(X1) && X1 >= ref$pc1_p75 && X1 < ref$pc1_p95) return("Borderline Altered")
  }
  if (!is.na(B) && B < ref$basal_p5)  return("Blunted")
  if (!is.na(X1) && X1 < ref$pc1_p5)  return("Blunted")
  if (!is.na(B) && B < ref$basal_p10) return("Impaired")
  if (!is.na(X1) && X1 < ref$pc1_p10) return("Impaired")
  if (!is.na(B) && B < ref$basal_p25) return("Borderline Impaired")
  if (!is.na(X1) && X1 < ref$pc1_p25) return("Borderline Impaired")
  "Preserved"
}

classify_ptp_all <- function(Z_long, ref_percentiles, cohort_vec, post_cohorts) {
  Z_ptp <- Z_long %>% left_join(ref_percentiles, by = "hormone_name")
  Z_ptp$ptp_primary <- pmap_chr(Z_ptp, function(basal, xi1, hormone_name,
                                                 basal_p5, basal_p10,
                                                 basal_p25, basal_p75, basal_p95,
                                                 pc1_p5, pc1_p10, pc1_p25, pc1_p75,
                                                 pc1_p95, ...) {
    ref <- list(basal_p5 = basal_p5, basal_p10 = basal_p10, basal_p25 = basal_p25,
                basal_p75 = basal_p75, basal_p95 = basal_p95,
                pc1_p5 = pc1_p5, pc1_p10 = pc1_p10, pc1_p25 = pc1_p25,
                pc1_p75 = pc1_p75, pc1_p95 = pc1_p95)
    classify_ptp_primary(list(basal = basal, xi1 = xi1), ref, hormone_name)
  })
  Z_ptp
}

iep_group <- function(ptp) {
  case_when(
    ptp == "Preserved"            ~ "R",
    ptp == "Recovered"            ~ "R",
    ptp == "Borderline Impaired"  ~ "L1",
    ptp %in% c("Impaired","Blunted") ~ "L2",
    ptp == "Borderline Enhanced"  ~ "U1",
    ptp == "Enhanced"             ~ "U2",
    ptp == "Borderline Altered"   ~ "D1",
    ptp == "Altered"              ~ "D2",
    TRUE                          ~ NA_character_
  )
}

assign_iep_type <- function(df_subj) {
  non_glu <- df_subj %>% filter(hormone_name != "glucose")
  glu <- df_subj %>% filter(hormone_name == "glucose")
  if (nrow(non_glu) < 2) return(tibble(iep_type = "not_integrable",
                                        glucose_subtype = glu$glucose_subtype[1] %||% NA))
  has_pancr <- any(non_glu$hormone_name == "insulin")
  has_gut   <- any(non_glu$hormone_name %in% c("ghrelin_total","ghrelin_acyl",
                                                "GIP_total","GIP_active",
                                                "GLP1_total","GLP1_active",
                                                "PYY_total","PYY_3_36"))
  if (!has_pancr || !has_gut || nrow(glu) == 0)
    return(tibble(iep_type = "not_integrable",
                  glucose_subtype = glu$glucose_subtype[1] %||% NA))
  glu_subtype <- glu$glucose_subtype[1]
  groups <- non_glu$group
  has_L1_L2 <- any(groups %in% c("L1","L2"))
  if (any(groups == "D2")) return(tibble(iep_type = "IV.II", glucose_subtype = glu_subtype))
  if (any(groups == "D1")) return(tibble(iep_type = "IV.I",  glucose_subtype = glu_subtype))
  if (any(groups == "U2") && glu_subtype == "a" && !has_L1_L2)
    return(tibble(iep_type = "II.II", glucose_subtype = glu_subtype))
  if (any(groups == "U2"))
    return(tibble(iep_type = "V.II", glucose_subtype = glu_subtype))
  if (any(groups == "U1") && glu_subtype == "a" && !has_L1_L2)
    return(tibble(iep_type = "II.I", glucose_subtype = glu_subtype))
  if (any(groups == "U1"))
    return(tibble(iep_type = "V.I", glucose_subtype = glu_subtype))
  if (any(groups == "L2")) return(tibble(iep_type = "III.II", glucose_subtype = glu_subtype))
  if (any(groups == "L1")) return(tibble(iep_type = "III.I",  glucose_subtype = glu_subtype))
  if (all(groups == "R"))  return(tibble(iep_type = "I.I",    glucose_subtype = glu_subtype))
  tibble(iep_type = "I.II", glucose_subtype = glu_subtype)
}
