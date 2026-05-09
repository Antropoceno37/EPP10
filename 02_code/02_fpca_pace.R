# 02_fpca_pace.R
# Doc 2 §5 · Doc 1 §FUNCTIONAL RULES
# FPCA-PACE univariante por hormona. Decomposición B + d(t), FPCA sobre d(t).
# Retiene Kp tal que FVE >= 99%. Output: 03_outputs/fpca_univariate.rds

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(fdapace); library(cli)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))

# Decomposición basal-dinámico (Doc 1 §FUNCTIONAL RULES)
# B_ih = valor en t=0; d_ih(t) = valor - B_ih
basal <- dt[time_min == 0L, .(subject_id, hormone, basal = value_log)]
dt <- merge(dt, basal, by = c("subject_id", "hormone"))
dt[, dynamic := value_log - basal]

results <- list()

for (h in unique(dt$hormone)) {
  sub <- dt[hormone == h]
  Ly <- split(sub$dynamic,  sub$subject_id)
  Lt <- split(sub$time_min, sub$subject_id)

  # Detecta si los datos son densos (todos los sujetos en la misma rejilla)
  ts_per_sub <- lengths(Lt)
  is_dense <- length(unique(ts_per_sub)) == 1L && all(ts_per_sub == length(unique(unlist(Lt))))

  # Intenta FPCA con varias estrategias en cascada
  try_fpca <- function(Ly, Lt, dataType, methodMuCovEst, ...) {
    optns <- list(dataType = dataType, methodMuCovEst = methodMuCovEst,
                  methodSelectK = "FVE", FVEthreshold = 0.99,
                  nRegGrid = 51, verbose = FALSE, ...)
    if (dataType == "Sparse") optns$kernel <- "epan"
    tryCatch(FPCA(Ly, Lt, optns = optns), error = function(e) NULL)
  }

  fit <- if (is_dense) {
    try_fpca(Ly, Lt, "Dense", "cross-sectional")
  } else {
    # Cascade: Sparse → Dense (interpolando) → Dense (cross-sectional)
    f <- try_fpca(Ly, Lt, "Sparse", "smooth", userBwMu = 0, userBwCov = 0)
    if (is.null(f)) f <- try_fpca(Ly, Lt, "Sparse", "smooth", userBwMu = 30, userBwCov = 30)
    if (is.null(f)) f <- try_fpca(Ly, Lt, "DenseWithMV", "cross-sectional")
    f
  }
  if (is.null(fit)) cli_alert_danger("{h}: ningún método FPCA convergió")

  if (is.null(fit)) next

  # Orientación de signo (Doc 1 §FUNCTIONAL RULES):
  # PC1 = global amplitude → forzar phi_1 con integral positiva
  # PC2 = early-vs-late redistribution → forzar phi_2 con primer cuartil > segundo
  # PC3 = biphasic / higher-order → no forzar (numérico)
  if (length(fit$lambda) >= 1L && sum(fit$phi[, 1]) < 0) {
    fit$phi[, 1] <- -fit$phi[, 1]
    fit$xiEst[, 1] <- -fit$xiEst[, 1]
  }
  if (length(fit$lambda) >= 2L) {
    grid_n <- length(fit$workGrid)
    early <- mean(fit$phi[seq_len(grid_n %/% 2L), 2])
    late  <- mean(fit$phi[(grid_n %/% 2L + 1L):grid_n, 2])
    if (early < late) {
      fit$phi[, 2] <- -fit$phi[, 2]
      fit$xiEst[, 2] <- -fit$xiEst[, 2]
    }
  }

  results[[h]] <- list(
    fit  = fit,
    K    = length(fit$lambda),
    FVE  = fit$cumFVE
  )
  cli_alert_info("{h}: K = {length(fit$lambda)} | FVE_total = {sprintf('%.1f%%', tail(fit$cumFVE, 1)*100)}")
}

out <- here("03_outputs", "fpca_univariate.rds")
saveRDS(results, out)
cli_alert_success("FPCA univariante: {.path {out}}")
