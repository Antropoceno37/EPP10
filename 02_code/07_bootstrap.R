# 07_bootstrap.R
# Doc 2 §6/§7 — Bootstrap funcional de sujetos (B=2000) con quantile envelope.
# GATE Doc 1 §STATISTICAL RULES: si los sujetos independientes son insuficientes,
# NO se simulan pseudo-réplicas desde una sola media — se reporta inestimable.
# Output: 03_outputs/bootstrap_envelopes.rds

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here)
  library(fdapace); library(future); library(future.apply); library(cli)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))

n_subj <- uniqueN(dt$subject_id)
# Pipeline-stage bootstrap B=50 (manuscrito canónico §2.12); el B=2000 canónico
# corresponde al classification-stage bootstrap (07_bootstrap_classification.R).
B      <- 50L
n_min  <- 30L  # umbral mínimo para bootstrap defendible

if (n_subj < n_min) {
  cli_alert_danger("Sujetos = {n_subj} < {n_min}. Bootstrap NO se ejecuta.")
  cli_alert_info("Doc 1 §STATISTICAL RULES: 'inference not supportable'.")
  saveRDS(list(status = "skipped",
               reason = "insufficient_independent_units",
               n_subj = n_subj),
          here("03_outputs", "bootstrap_envelopes.rds"))
  quit(save = "no", status = 0L)
}

# 4 workers (Doc 2 §7: NO usar 8 en 24 GB)
plan(multisession, workers = 4L)

run_one_boot <- function(b, dt, h_name) {
  sub_h <- dt[hormone == h_name]
  subj_pool <- unique(sub_h$subject_id)
  resampled <- sample(subj_pool, length(subj_pool), replace = TRUE)
  # Usar tabla por sujeto reasignando IDs únicos para evitar duplicados de subject_id
  sub_b <- sub_h[subject_id %in% resampled]
  Ly <- split(sub_b$value_log, sub_b$subject_id)
  Lt <- split(sub_b$time_min,  sub_b$subject_id)
  fit <- tryCatch(
    FPCA(Ly, Lt, optns = list(methodSelectK = "FVE", FVEthreshold = 0.99,
                              kernel = "epan", nRegGrid = 51, verbose = FALSE)),
    error = function(e) NULL
  )
  if (is.null(fit) || ncol(fit$phi) < 1L) return(NULL)
  fit$phi[, 1]   # devuelve solo la primera eigenfunción
}

envelopes <- list()
for (h in unique(dt$hormone)) {
  cli_alert_info("Bootstrap {h} (B={B}, workers=4)...")
  tic <- Sys.time()
  boots <- future_lapply(seq_len(B), run_one_boot, dt = dt, h_name = h,
                         future.seed = 20260422L)
  boots <- do.call(cbind, boots[!sapply(boots, is.null)])
  if (is.null(boots) || ncol(boots) < B/2L) {
    cli_alert_warning("{h}: solo {ifelse(is.null(boots), 0, ncol(boots))} bootstraps válidos")
    next
  }
  # Quantile envelope 95% (Doc 2 §7)
  envelopes[[h]] <- list(
    lower = apply(boots, 1, quantile, 0.025, na.rm = TRUE),
    upper = apply(boots, 1, quantile, 0.975, na.rm = TRUE),
    median = apply(boots, 1, median, na.rm = TRUE)
  )
  cli_alert_info("{h}: {round(as.numeric(difftime(Sys.time(), tic, units='secs')))}s")
}

out <- here("03_outputs", "bootstrap_envelopes.rds")
saveRDS(envelopes, out)
cli_alert_success("Bootstrap envelopes: {.path {out}}")
