# =============================================================================
# Tests for PTP / IEP classifier (R/classifier.R)
# =============================================================================

ref_default <- list(
  basal_p5  = 1, basal_p10 = 2, basal_p25 = 3,
  basal_p75 = 8, basal_p95 = 10,
  pc1_p5    = -2, pc1_p10  = -1, pc1_p25  = -0.5,
  pc1_p75   = 0.5, pc1_p95 = 2
)

# ---- classify_ptp_primary --------------------------------------------------

test_that("classify_ptp_primary returns Preserved for in-range values", {
  z <- list(basal = 5, xi1 = 0)
  expect_equal(classify_ptp_primary(z, ref_default, "insulin"), "Preserved")
  expect_equal(classify_ptp_primary(z, ref_default, "GLP1_total"), "Preserved")
})

test_that("classify_ptp_primary upper-tail-allowed analytes hit Altered at ≥P95", {
  expect_equal(
    classify_ptp_primary(list(basal = 11, xi1 = 0), ref_default, "insulin"),
    "Altered")
  expect_equal(
    classify_ptp_primary(list(basal = 5, xi1 = 2.5), ref_default, "glucose"),
    "Altered")
  # Boundary: exactly at P95 counts as Altered
  expect_equal(
    classify_ptp_primary(list(basal = 10, xi1 = 0), ref_default, "GIP_total"),
    "Altered")
})

test_that("classify_ptp_primary upper-tail-NOT-allowed analytes do NOT flag Altered", {
  # GLP1_total, PYY_total, glucagon are excluded from upper-tail-Altered
  expect_equal(
    classify_ptp_primary(list(basal = 11, xi1 = 3), ref_default, "GLP1_total"),
    "Preserved")
  expect_equal(
    classify_ptp_primary(list(basal = 9, xi1 = 1.5), ref_default, "PYY_total"),
    "Preserved")
  expect_equal(
    classify_ptp_primary(list(basal = 11, xi1 = 3), ref_default, "glucagon"),
    "Preserved")
})

test_that("classify_ptp_primary Borderline Altered in P75-P95 window", {
  expect_equal(
    classify_ptp_primary(list(basal = 9, xi1 = 0), ref_default, "insulin"),
    "Borderline Altered")
  expect_equal(
    classify_ptp_primary(list(basal = 5, xi1 = 1.5), ref_default, "ghrelin_total"),
    "Borderline Altered")
})

test_that("classify_ptp_primary lower-tail tiers apply for any analyte", {
  # Blunted: below P5
  expect_equal(
    classify_ptp_primary(list(basal = 0.5, xi1 = 0), ref_default, "GLP1_total"),
    "Blunted")
  expect_equal(
    classify_ptp_primary(list(basal = 5, xi1 = -3), ref_default, "PYY_total"),
    "Blunted")
  # Impaired: P5..P10
  expect_equal(
    classify_ptp_primary(list(basal = 1.5, xi1 = 0), ref_default, "GLP1_total"),
    "Impaired")
  # Borderline Impaired: P10..P25
  expect_equal(
    classify_ptp_primary(list(basal = 2.5, xi1 = 0), ref_default, "GLP1_total"),
    "Borderline Impaired")
})

test_that("classify_ptp_primary tolerates NA inputs without erroring", {
  expect_equal(
    classify_ptp_primary(list(basal = NA_real_, xi1 = NA_real_),
                         ref_default, "insulin"),
    "Preserved")
  expect_equal(
    classify_ptp_primary(list(basal = NA_real_, xi1 = -3),
                         ref_default, "insulin"),
    "Blunted")
})

test_that("classify_ptp_primary upper-tail beats lower-tail when both could trigger", {
  # An upper-tail-allowed analyte at the high extreme should return Altered,
  # not fall through to lower-tail logic
  expect_equal(
    classify_ptp_primary(list(basal = 11, xi1 = -3), ref_default, "insulin"),
    "Altered")
})

# ---- iep_group --------------------------------------------------------------

test_that("iep_group maps PTP labels to deterministic groups", {
  expect_equal(iep_group("Preserved"), "R")
  expect_equal(iep_group("Recovered"), "R")
  expect_equal(iep_group("Borderline Impaired"), "L1")
  expect_equal(iep_group("Impaired"), "L2")
  expect_equal(iep_group("Blunted"), "L2")
  expect_equal(iep_group("Borderline Enhanced"), "U1")
  expect_equal(iep_group("Enhanced"), "U2")
  expect_equal(iep_group("Borderline Altered"), "D1")
  expect_equal(iep_group("Altered"), "D2")
  expect_true(is.na(iep_group("not_a_real_label")))
})

# ---- assign_iep_type --------------------------------------------------------

# Build a 4-row tibble (insulin + 2 gut hormones + glucose) for a single
# pseudo-subject. Caller supplies the 3 non-glucose group labels.
mk_subject <- function(groups, glucose_subtype = "a") {
  stopifnot(length(groups) == 3)
  tibble::tibble(
    hormone_name    = c("insulin", "GLP1_total", "PYY_total", "glucose"),
    group           = c(groups, "R"),  # glucose group is unused by assign_iep_type
    glucose_subtype = rep(glucose_subtype, 4)
  )
}

test_that("assign_iep_type returns not_integrable without a pancreatic effector", {
  df <- tibble::tibble(
    hormone_name    = c("GLP1_total", "PYY_total", "glucose"),
    group           = c("R", "R", "R"),
    glucose_subtype = rep("a", 3)
  )
  expect_equal(assign_iep_type(df)$iep_type, "not_integrable")
})

test_that("assign_iep_type returns not_integrable without a gut hormone", {
  df <- tibble::tibble(
    hormone_name    = c("insulin", "glucagon", "glucose"),
    group           = c("R", "R", "R"),
    glucose_subtype = rep("a", 3)
  )
  expect_equal(assign_iep_type(df)$iep_type, "not_integrable")
})

test_that("assign_iep_type returns not_integrable without glucose", {
  df <- tibble::tibble(
    hormone_name    = c("insulin", "GLP1_total"),
    group           = c("R", "R"),
    glucose_subtype = c(NA_character_, NA_character_)
  )
  expect_equal(assign_iep_type(df)$iep_type, "not_integrable")
})

test_that("assign_iep_type precedence: D2 > D1 > U2 > U1 > L2 > L1 > R", {
  expect_equal(assign_iep_type(mk_subject(c("D2", "U2", "L2")))$iep_type, "IV.II")
  expect_equal(assign_iep_type(mk_subject(c("D1", "U1", "L1")))$iep_type, "IV.I")
  expect_equal(assign_iep_type(mk_subject(c("L2", "R", "R")))$iep_type, "III.II")
  expect_equal(assign_iep_type(mk_subject(c("L1", "R", "R")))$iep_type, "III.I")
  expect_equal(assign_iep_type(mk_subject(c("R",  "R", "R")))$iep_type, "I.I")
})

test_that("assign_iep_type U2 routes to II.II only when glucose=a and no L co-occurs", {
  # Pure U2, glucose preserved -> II.II
  expect_equal(
    assign_iep_type(mk_subject(c("U2", "R", "R"), glucose_subtype = "a"))$iep_type,
    "II.II")
  # U2 + glucose dysregulated -> V.II
  expect_equal(
    assign_iep_type(mk_subject(c("U2", "R", "R"), glucose_subtype = "b"))$iep_type,
    "V.II")
  expect_equal(
    assign_iep_type(mk_subject(c("U2", "R", "R"), glucose_subtype = "c"))$iep_type,
    "V.II")
  # U2 + L1 co-occurring (glucose=a) -> V.II (the L breaks the II route)
  expect_equal(
    assign_iep_type(mk_subject(c("U2", "L1", "R"), glucose_subtype = "a"))$iep_type,
    "V.II")
})

test_that("assign_iep_type U1 routes parallel U2 (II.I vs V.I)", {
  expect_equal(
    assign_iep_type(mk_subject(c("U1", "R", "R"), glucose_subtype = "a"))$iep_type,
    "II.I")
  expect_equal(
    assign_iep_type(mk_subject(c("U1", "R", "R"), glucose_subtype = "b"))$iep_type,
    "V.I")
  expect_equal(
    assign_iep_type(mk_subject(c("U1", "L2", "R"), glucose_subtype = "a"))$iep_type,
    "V.I")
})

test_that("assign_iep_type returns the glucose_subtype unchanged", {
  res <- assign_iep_type(mk_subject(c("D2", "R", "R"), glucose_subtype = "c"))
  expect_equal(res$glucose_subtype, "c")
})
