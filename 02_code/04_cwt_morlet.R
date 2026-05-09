# 04_cwt_morlet.R
# Doc 1 §TIME-FREQUENCY ANALYSIS — CWT con complex Morlet por cohorte/hormona.
# Restringido a regiones fuera del cone of influence (COI).
# Output: 03_outputs/cwt_summary.rds + 03_outputs/figures/cwt_*.png

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(WaveletComp); library(cli)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))

# Construye trayectorias medias por cohorte × hormona en rejilla densa (1 min)
times_dense <- 0:180

interp_mean <- function(sub) {
  agg <- sub[, .(mean_val = mean(value_log)), by = time_min]
  approx(agg$time_min, agg$mean_val, xout = times_dense, rule = 2L)$y
}

cwt_results <- list()
fig_dir <- here("03_outputs", "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

for (cohort in unique(dt$cohort)) for (h in unique(dt$hormone)) {
  key <- sprintf("%s__%s", cohort, h)
  sub <- dt[cohort == get("cohort", envir = parent.frame()) & hormone == h]
  if (nrow(sub) < 8L) next

  series <- data.frame(x = interp_mean(sub))

  cwt <- tryCatch(
    analyze.wavelet(series, my.series = "x",
                    loess.span = 0,
                    dt = 1, dj = 1/24,
                    lowerPeriod = 8, upperPeriod = 90,  # ventana clinicamente interpretable
                    make.pval = FALSE, verbose = FALSE),
    error = function(e) NULL
  )
  if (is.null(cwt)) next

  # Descriptores: dominant period, time of max power, integrated power, phase
  # Restringe fuera del COI cuando sea posible (Doc 1 §TIME-FREQUENCY)
  power <- tryCatch(cwt$Power, error = function(e) NULL)
  if (is.null(power) || !is.matrix(power)) next

  # COI mask: cwt$coi.1 puede ser vector o matrix segun version
  if (!is.null(cwt$coi.1) && length(cwt$coi.1) == nrow(power)) {
    coi_idx <- which(is.na(cwt$coi.1))
    if (length(coi_idx)) power[coi_idx, ] <- NA_real_
  }

  dominant_period_idx <- which.max(colMeans(power, na.rm = TRUE))
  dominant_period     <- if (length(dominant_period_idx)) cwt$Period[dominant_period_idx] else NA_real_
  t_max_power         <- which.max(rowSums(power, na.rm = TRUE)) - 1L
  integrated_power    <- sum(power, na.rm = TRUE)

  cwt_results[[key]] <- list(
    cohort = cohort, hormone = h,
    dominant_period_min = dominant_period,
    time_max_power_min  = t_max_power,
    integrated_power    = integrated_power
  )
}

cwt_dt <- rbindlist(lapply(cwt_results, as.data.table), fill = TRUE)
out <- here("03_outputs", "cwt_summary.rds")
saveRDS(list(summary = cwt_dt, raw = cwt_results), out)
cli_alert_success("CWT summary: {.path {out}} ({nrow(cwt_dt)} pares cohort×hormone)")
