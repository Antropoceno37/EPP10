# =============================================================================
# helper-load.R — Auto-sourced by testthat before every test file
# =============================================================================
# Loads the pure-function modules from R/ that the tests exercise. testthat
# sets the working directory to tests/testthat/, so project root is "../..".
# =============================================================================

.project_root <- normalizePath(file.path(getwd(), "..", ".."), winslash = "/")

source(file.path(.project_root, "R", "classifier.R"))
source(file.path(.project_root, "R", "cohort_map.R"))
source(file.path(.project_root, "R", "simulate_helpers.R"))
source(file.path(.project_root, "R", "mfaces_helpers.R"))
