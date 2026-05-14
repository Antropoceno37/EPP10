# =============================================================================
# Tests for cohort string normalization (R/cohort_map.R)
# =============================================================================

test_that("normalize_cohort recognises the reference cohort string", {
  res <- normalize_cohort("No obesity-no T2DM")
  expect_equal(res$cohort_v10_primary, "no_obese_without_T2DM")
  expect_equal(res$cohort_v10_sensitivity, "no_obese_without_T2DM")
  expect_equal(res$weight_loss_modality, "none")
})

test_that("normalize_cohort splits Obesity vs T2DM vs Obesity_T2DM", {
  expect_equal(normalize_cohort("Obesity")$cohort_v10_primary, "Obesity")
  expect_equal(normalize_cohort("Type 2 Diabetes")$cohort_v10_primary, "T2DM")
  expect_equal(normalize_cohort("Obesity plus type 2 diabetes")$cohort_v10_primary,
               "Obesity_T2DM")
  expect_equal(normalize_cohort("Obesity with type 2 diabetes")$cohort_v10_primary,
               "Obesity_T2DM")
})

test_that("normalize_cohort identifies post-RYGB cohorts and weeks bucket", {
  res <- normalize_cohort("Patients after Roux-en-Y gastric bypass at 1 year")
  expect_equal(res$cohort_v10_primary, "RYGBP")
  expect_equal(res$weight_loss_modality, "RYGB")
  expect_equal(res$surgery_status, "post_surgery")
  expect_equal(res$weeks_post_surgery, "1y")
})

test_that("normalize_cohort identifies post-SG cohorts and weeks bucket", {
  res_12w <- normalize_cohort("Patients after sleeve gastrectomy at 12 weeks")
  expect_equal(res_12w$cohort_v10_primary, "SG")
  expect_equal(res_12w$weight_loss_modality, "SG")
  expect_equal(res_12w$weeks_post_surgery, "12w")

  res_6w <- normalize_cohort("Patients after sleeve gastrectomy at 6 weeks")
  expect_equal(res_6w$weeks_post_surgery, "6w")

  # "week 13" still buckets to 12w (per the YAML-frozen rule)
  res_w13 <- normalize_cohort("Patients after sleeve gastrectomy at week 13")
  expect_equal(res_w13$weeks_post_surgery, "12w")
})

test_that("normalize_cohort routes post-caloric-restriction to Obesity primary with caloric_restriction_post sensitivity", {
  res <- normalize_cohort("Obesity patients after caloric restriction at 12 weeks")
  expect_equal(res$cohort_v10_primary, "Obesity")
  expect_equal(res$cohort_v10_sensitivity, "caloric_restriction_post")
  expect_equal(res$weight_loss_modality, "caloric_restriction")
  expect_equal(res$surgery_status, "post_surgery")
})

test_that("normalize_cohort surgery_status is_pre overrides is_post for 'before'", {
  res <- normalize_cohort("Obesity before sleeve gastrectomy")
  expect_equal(res$surgery_status, "pre_surgery")
})

test_that("normalize_cohort had_t2dm_pre_surgery is tri-state", {
  expect_equal(normalize_cohort("Obesity with type 2 diabetes")$had_t2dm_pre_surgery,
               "TRUE")
  expect_equal(normalize_cohort("Non-diabetic obesity")$had_t2dm_pre_surgery,
               "FALSE")
  expect_equal(normalize_cohort("Obesity")$had_t2dm_pre_surgery, "unknown")
})

test_that("normalize_cohort weeks_post_surgery is NA when no marker present", {
  expect_true(is.na(normalize_cohort("Obesity")$weeks_post_surgery))
  expect_true(is.na(normalize_cohort("Type 2 Diabetes")$weeks_post_surgery))
})

test_that("normalize_cohort returns UNCLASSIFIED for unrecognised strings", {
  res <- normalize_cohort("some unrelated description")
  expect_equal(res$cohort_v10_primary, "UNCLASSIFIED")
})
