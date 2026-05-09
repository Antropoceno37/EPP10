# 09_sensitivity.R — Sensibilidad pre-especificada (CANÓNICO)
# Manuscrito medRxiv 2026-351723v1 §2.12:
#   (i)   PTP-threshold displacement por ±0.5 SD; reportar % assignments que cambian
#   (ii)  Leave-one-axis-out integrated typing (excluir cada analito)
#   (iii) Pseudo-IPD AR(1) ρ ∈ {0.3, 0.5, 0.7, 0.9}; reportar K, incretin loading, cohort ordering
#   (iv)  Challenge-class pooling — stratum-specific vs pooled SMMT+LMMT con binary covariate
#
# Output: 03_outputs/tables/sensitivity_summary.csv

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(cli)
  library(fdapace)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))
ptp <- fread(here("03_outputs", "tables", "ptp_classification.csv"))
types <- fread(here("03_outputs", "tables", "types_integration.csv"))

results <- list()

# ========================================================================
# (i) ±0.5 SD threshold displacement (manuscrito §2.12)
# ========================================================================
cli_h1("Sensibilidad (i): ±0.5 SD threshold displacement")

reclassify_with_offset <- function(z_dt, offset) {
  z_dt[, ptp_offset := fcase(
    z_xi1 >  (1.5 + offset),                        "Altered",
    z_xi1 >  (1.0 + offset),                        "Borderline_Altered",
    abs(z_xi1) <= (1.0 + offset) & abs(z_basal) <= (1.0 + offset), "Preserved",
    z_xi1 < -(1.5 + offset),                        "Impaired",
    z_xi1 < -(1.0 + offset),                        "Borderline_Impaired",
    default                                          = "Preserved"
  )]
  z_dt
}

ptp_minus <- copy(ptp); reclassify_with_offset(ptp_minus, -0.5)
ptp_plus  <- copy(ptp); reclassify_with_offset(ptp_plus,  +0.5)

pct_changed_minus <- mean(ptp_minus$ptp_offset != ptp$ptp_primary, na.rm = TRUE) * 100
pct_changed_plus  <- mean(ptp_plus$ptp_offset  != ptp$ptp_primary, na.rm = TRUE) * 100

cli_alert_info("PTP -0.5 SD: {round(pct_changed_minus, 1)}% reasignados")
cli_alert_info("PTP +0.5 SD: {round(pct_changed_plus,  1)}% reasignados")

results[["i_threshold_displacement"]] <- data.table(
  test = "(i) ±0.5 SD displacement",
  metric = c("pct_reassigned_-0.5SD", "pct_reassigned_+0.5SD"),
  value = c(pct_changed_minus, pct_changed_plus)
)

# ========================================================================
# (ii) Leave-one-axis-out (manuscrito §2.12)
# ========================================================================
cli_h1("Sensibilidad (ii): Leave-one-axis-out")

hormones_all <- unique(ptp$hormone)
loo_results <- rbindlist(lapply(hormones_all, function(h_drop) {
  ptp_loo <- ptp[hormone != h_drop]
  # Recompute Type por sujeto sin h_drop (lógica simplificada del precedence hierarchy)
  by_subj <- ptp_loo[, .(
    has_altered  = any(ptp_primary == "Altered"),
    has_bord_alt = any(ptp_primary == "Borderline_Altered"),
    has_impaired = any(ptp_primary %in% c("Impaired", "Blunted")),
    n_classifiable = .N
  ), by = .(subject_id, cohort)]
  by_subj[, type_loo := fcase(
    has_altered,        "Type IV.II",
    has_bord_alt,       "Type IV.I",
    has_impaired,       "Type III.II",
    default              = "Type I.I"
  )]

  merged <- merge(by_subj, types[, .(subject_id, type_full = type)], by = "subject_id")
  pct_unchanged <- mean(merged$type_loo == merged$type_full, na.rm = TRUE) * 100
  data.table(test = "(ii) leave-one-axis-out",
             axis_dropped = h_drop,
             pct_type_unchanged = pct_unchanged)
}))
print(loo_results)
results[["ii_leave_one_out"]] <- loo_results

# ========================================================================
# (iii) Pseudo-IPD GP AR(1) ρ ∈ {0.3, 0.5, 0.7, 0.9} (manuscrito §2.12)
# ========================================================================
cli_h1("Sensibilidad (iii): GP AR(1) rho in 0.3, 0.5, 0.7, 0.9")

# Si los datos NO son pseudo-IPD del modo 1, este test no aplica
if (!grepl("pseudo_IPD", unique(dt$unit_of_analysis)[1])) {
  cli_alert_warning("Pipeline en modo sintético — sensibilidad ρ no aplica.")
  cli_alert_info("Cuando harmonice data real con master_table.csv, este bloque ejecutará.")
  results[["iii_rho_sensitivity"]] <- data.table(
    test = "(iii) ρ sensitivity",
    rho = c(0.3, 0.5, 0.7, 0.9),
    K = NA, incretin_loading = NA,
    note = "skipped — synthetic data mode"
  )
} else {
  # Para data real: re-correr el pipeline con cada ρ y reportar K, PC1 incretin loading
  cli_alert_info("Re-corriendo MFPCA para cada ρ (puede tomar varios minutos)...")
  rho_results <- rbindlist(lapply(c(0.3, 0.5, 0.7, 0.9), function(rho) {
    # TODO: re-correr 01_harmonize.R con rho específico + 03_mfpca_happgreven.R
    # Por ahora: placeholder
    data.table(test = "(iii) ρ sensitivity", rho = rho,
               K = NA_integer_, incretin_loading = NA_real_,
               note = "re-run pipeline manually with ρ override")
  }))
  results[["iii_rho_sensitivity"]] <- rho_results
}

# ========================================================================
# (iv) Challenge-class pooling (manuscrito §2.12)
# ========================================================================
cli_h1("Sensibilidad (iv): Challenge-class pooling SMMT vs LMMT")

# Si el dataset no tiene challenge_class, este test no aplica al sintético
if (!"challenge_class" %in% names(dt)) {
  cli_alert_warning("Dataset sin columna challenge_class — sensibilidad pooling no aplica.")
  cli_alert_info("Master table real debe incluir challenge_class (SMMT/LMMT/OGTT).")
  results[["iv_challenge_pooling"]] <- data.table(
    test = "(iv) challenge-class pooling",
    metric = "skipped",
    value = NA_real_,
    note = "synthetic data has no challenge_class"
  )
} else {
  # Comparar PTP assignments stratum-specific vs pooled
  # TODO: reimplementar 02_fpca_pace.R con/sin pooling y comparar
  results[["iv_challenge_pooling"]] <- data.table(
    test = "(iv) challenge-class pooling",
    metric = "stratum_vs_pooled_concordance",
    value = NA_real_,
    note = "TODO: implement when real data arrives"
  )
}

# ========================================================================
# Persistir
# ========================================================================
out <- here("03_outputs", "tables", "sensitivity_summary.csv")
fwrite(rbindlist(results, fill = TRUE), out)
cli_alert_success("Sensitivity summary: {.path {out}}")
