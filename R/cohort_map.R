# =============================================================================
# R/cohort_map.R — Cohort string normalization (pure function)
# =============================================================================
# Canonical source for normalize_cohort. etl_master_csv.R sources this file.
# =============================================================================

suppressPackageStartupMessages({
  library(stringr); library(dplyr); library(tibble)
})

normalize_cohort <- function(s) {
  x <- str_to_lower(s)
  has_obesity <- str_detect(x, "obesity|overweight")
  has_t2dm    <- str_detect(x, "type 2 diabetes|t2dm|plus type 2|with type 2")
  explicit_no_t2dm <- str_detect(x, "no obesity-no t2dm|no t2dm|non-diabetic|non diabetic|without t2dm")
  has_rygb    <- str_detect(x, "roux|rygb|rox-en-y|gastric bypass|gastric bypas")
  has_sg      <- str_detect(x, "sleeve gastrectomy|sleeve")
  has_calr    <- str_detect(x, "caloric|calóric")
  is_pre      <- str_detect(x, " before ")
  is_post     <- str_detect(x, " after ") | str_detect(x, " at 1[- ]year| weeks|week 13")
  weeks <- case_when(
    str_detect(x, "6 weeks")                                 ~ "6w",
    str_detect(x, "12 weeks|week 13")                        ~ "12w",
    str_detect(x, "1[- ]year|at 1 year|1 year after|after 1 year") ~ "1y",
    TRUE                                                      ~ NA_character_
  )
  is_post_cr <- is_post & has_calr
  cohort_v10_primary <- case_when(
    str_detect(x, "no obesity-no t2dm")  ~ "no_obese_without_T2DM",
    is_post_cr                           ~ "Obesity",
    is_post & has_rygb                   ~ "RYGBP",
    is_post & has_sg                     ~ "SG",
    has_obesity & has_t2dm               ~ "Obesity_T2DM",
    has_obesity                          ~ "Obesity",
    has_t2dm                             ~ "T2DM",
    TRUE                                 ~ "UNCLASSIFIED"
  )
  cohort_v10_sensitivity <- if_else(is_post_cr, "caloric_restriction_post",
                                    cohort_v10_primary)
  modality <- case_when(is_post & has_rygb ~ "RYGB", is_post & has_sg ~ "SG",
                        is_post_cr ~ "caloric_restriction", TRUE ~ "none")
  surg_status <- case_when(is_pre ~ "pre_surgery", is_post ~ "post_surgery",
                           TRUE ~ "not_applicable")
  had_t2dm_pre_surgery <- case_when(has_t2dm ~ "TRUE",
                                    explicit_no_t2dm ~ "FALSE",
                                    TRUE ~ "unknown")
  tibble(cohort_v10_primary     = cohort_v10_primary,
         cohort_v10_sensitivity = cohort_v10_sensitivity,
         surgery_status         = surg_status,
         weeks_post_surgery     = weeks,
         weight_loss_modality   = modality,
         had_t2dm_pre_surgery   = had_t2dm_pre_surgery)
}
