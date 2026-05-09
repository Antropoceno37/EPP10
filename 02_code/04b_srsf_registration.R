# 04b_srsf_registration.R — Phase-amplitude registration diagnostic (Lancet D&E §L3.5)
# Meta-prompt v1.1: SD of peak times per hormone across subjects.
#   - SD ≤ 15 min  → no registration needed; report negative diagnostic.
#   - SD >  15 min → SRSF registration via fdasrvf::time_warping (Tucker-Wu-Srivastava 2013).
#
# Outputs:
#   03_outputs/tables/peak_time_sd.csv      — SD of peak times per hormone (always)
#   03_outputs/srsf_warpings.rds            — warpings (only if SRSF triggered)

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(cli)
})
set.seed(20260422)

dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))

# === Diagnose phase variability via SD of peak times ===
# For each subject × hormone: time of maximum value within (0, 180].
peak_times <- dt[time_min > 0L,
                 .(t_peak = time_min[which.max(value_log)]),
                 by = .(subject_id, cohort, hormone)]

sd_dt <- peak_times[, .(
  n_subjects = .N,
  mean_t_peak = mean(t_peak),
  sd_t_peak = sd(t_peak)
), by = hormone][order(-sd_t_peak)]

sd_dt[, srsf_recommended := sd_t_peak > 15]

out_dir <- here("03_outputs", "tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
fwrite(sd_dt, file.path(out_dir, "peak_time_sd.csv"))

cli_alert_info("Peak-time SD by hormone:")
for (i in seq_len(nrow(sd_dt))) {
  flag <- ifelse(sd_dt$srsf_recommended[i], "** SRSF recommended **", "no SRSF")
  cli_alert("  {sd_dt$hormone[i]}: SD = {round(sd_dt$sd_t_peak[i], 1)} min ({flag})")
}

# === If any hormone exceeds 15 min threshold, run SRSF on those ===
need_srsf <- sd_dt[srsf_recommended == TRUE, hormone]
if (length(need_srsf) > 0L) {
  if (!requireNamespace("fdasrvf", quietly = TRUE)) {
    cli_alert_warning("Package fdasrvf not installed; skipping SRSF registration.")
    cli_alert_info("Diagnostic still saved. Install with: install.packages('fdasrvf')")
  } else {
    library(fdasrvf)
    times_dense <- seq(0, 180, by = 1)
    warpings <- list()
    for (h in need_srsf) {
      cli_alert("Registering {h} via SRSF...")
      sub <- dt[hormone == h]
      subjects <- unique(sub$subject_id)
      # Build n_t × n_subj matrix
      mat <- sapply(subjects, function(sid) {
        x <- sub[subject_id == sid]
        if (nrow(x) < 4L) return(rep(NA_real_, length(times_dense)))
        approx(x$time_min, x$value_log, xout = times_dense, rule = 2L)$y
      })
      keep <- colSums(is.na(mat)) == 0L
      if (sum(keep) < 5L) next
      mat <- mat[, keep, drop = FALSE]
      tw <- tryCatch(
        time_warping(f = mat, time = times_dense, showplot = FALSE,
                     parallel = FALSE, lambda = 0),
        error = function(e) { cli_alert_warning("SRSF failed for {h}: {e$message}"); NULL })
      if (!is.null(tw)) {
        warpings[[h]] <- list(
          subjects = subjects[keep],
          gam = tw$gam, fn = tw$fn, fmean = tw$fmean,
          mqn = tw$mqn, qn = tw$qn
        )
      }
    }
    if (length(warpings)) {
      saveRDS(warpings, here("03_outputs", "srsf_warpings.rds"))
      cli_alert_success("SRSF warpings saved: {.path 03_outputs/srsf_warpings.rds} ({length(warpings)} hormones)")
    }
  }
} else {
  cli_alert_success("No hormone exceeds 15-min phase-variability threshold; SRSF not required.")
}
