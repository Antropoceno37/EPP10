library(testthat)

# Resolve the directory of this file, robust to interactive source(), Rscript,
# and being run with cwd anywhere.
.resolve_self <- function() {
  # 1. sys.frame(1)$ofile — set when source()d
  ofile <- try(sys.frame(1)$ofile, silent = TRUE)
  if (!inherits(ofile, "try-error") && !is.null(ofile)) {
    return(dirname(normalizePath(ofile)))
  }
  # 2. --file= argument from Rscript
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) == 1) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg))))
  }
  # 3. fallback
  getwd()
}

testthat::test_dir(file.path(.resolve_self(), "testthat"),
                   reporter = "progress",
                   stop_on_failure = TRUE)
