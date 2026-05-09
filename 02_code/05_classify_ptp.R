# 05_classify_ptp.R — FDEP-TP v2.0
# framework.md §2 (15 etiquetas PTP) + §3 (Types I-V con jerarquía D2>D1>U2>U1>L2>L1>R)
# Vector primario de 4 coordenadas: Z_ih = [z(B), z(xi1), z(xi2), z(xi3)].
# El escalar corroborativo C es métrica de validación convergente (NO coordenada primaria).
#
# Outputs:
#   03_outputs/tables/ptp_classification.csv      — etiquetas PTP por sujeto/cohorte × analito
#   03_outputs/tables/types_integration.csv       — Types I-V + subtipo glucémico
#   03_outputs/tables/reference_adequacy.csv      — gate de framework v2.0

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(cli)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

uni <- readRDS(here("03_outputs", "fpca_univariate.rds"))
dt  <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))

# ============================================================
# 1) Construcción del vector Z_ih de 4 coordenadas (framework v2.0)
# ============================================================
basal <- dt[time_min == 0L, .(subject_id, cohort, hormone, basal = value_log)]

scores_long <- rbindlist(lapply(names(uni), function(h) {
  fit <- uni[[h]]$fit
  K   <- min(3L, length(fit$lambda))
  data.table(
    subject_id = names(fit$inputData$Ly),
    hormone    = h,
    xi1 = if (K >= 1L) fit$xiEst[, 1] else NA_real_,
    xi2 = if (K >= 2L) fit$xiEst[, 2] else NA_real_,
    xi3 = if (K >= 3L) fit$xiEst[, 3] else NA_real_
  )
}))

# Escalar corroborativo C: AUC30-180 (capa 2 del pipeline) — para validación convergente
auc <- dt[time_min >= 30L,
          .(C = sum(diff(time_min) * (head(value, -1L) + tail(value, -1L)) / 2)),
          by = .(subject_id, cohort, hormone)]

features <- merge(scores_long, basal[, .(subject_id, hormone, basal)],
                  by = c("subject_id", "hormone"))
features <- merge(features, auc[, .(subject_id, hormone, C)],
                  by = c("subject_id", "hormone"))
features <- merge(features, unique(dt[, .(subject_id, cohort)]), by = "subject_id")

# ============================================================
# 2) Reference adequacy v2.0 (framework.md §5)
# ============================================================
# Reference cohort: nombre canónico es 'no_obese_without_T2DM' (Lean-Healthy semánticamente).
ref_label <- if ("no_obese_without_T2DM" %in% features$cohort) "no_obese_without_T2DM" else "Lean-Healthy"
ref_n <- features[cohort == ref_label, .(N_ref = .N), by = hormone]
ref_n[, status := fcase(
  N_ref >= 8L, "full",
  N_ref >= 5L, "limited",
  N_ref >= 3L, "marginal",
  default      = "excluded"
)]
ref_n[, eligible := status %in% c("full", "limited", "marginal")]
fwrite(ref_n, here("03_outputs", "tables", "reference_adequacy.csv"))

ok_hormones <- ref_n[eligible == TRUE, hormone]

# Estandariza vs. Lean-Healthy
z_hormones <- features[hormone %in% ok_hormones]
ref <- z_hormones[cohort == ref_label,
                  .(mu_b = mean(basal, na.rm=TRUE), sd_b = sd(basal, na.rm=TRUE),
                    mu_1 = mean(xi1,   na.rm=TRUE), sd_1 = sd(xi1,   na.rm=TRUE),
                    mu_2 = mean(xi2,   na.rm=TRUE), sd_2 = sd(xi2,   na.rm=TRUE),
                    mu_3 = mean(xi3,   na.rm=TRUE), sd_3 = sd(xi3,   na.rm=TRUE),
                    mu_C = mean(C,     na.rm=TRUE), sd_C = sd(C,     na.rm=TRUE)),
                  by = hormone]

z <- merge(z_hormones, ref, by = "hormone")
z[, `:=`(
  z_basal = (basal - mu_b) / sd_b,
  z_xi1   = (xi1   - mu_1) / sd_1,
  z_xi2   = (xi2   - mu_2) / sd_2,
  z_xi3   = (xi3   - mu_3) / sd_3,
  z_C     = (C     - mu_C) / sd_C   # validación convergente, no coordenada primaria
)]

# ============================================================
# 3) Etiquetas PTP primarias (6) — framework.md §2.1
# ============================================================
# Clasifica por z_xi1 (PC1 = amplitud global) y coherencia basal-PC1
classify_primary <- function(zb, z1, z2, z3) {
  if (any(is.na(c(zb, z1)))) return(NA_character_)
  # NA en z2/z3 (componentes superiores no retenidos) -> tratar como dentro de banda
  z2 <- ifelse(is.na(z2), 0, z2)
  z3 <- ifelse(is.na(z3), 0, z3)

  # Discordancia basal vs PC1 (R4: bloquea Type I/II)
  if (abs(zb) <= 1 && z1 < -1.5)      return("Discordant_Low")
  if (abs(zb) <= 1 && z1 >  1.5)      return("Discordant_High")
  if (abs(zb) >  1.5 && abs(z1) <= 1) return("Discordant_Basal")

  # Bandas primarias por z_xi1
  if (z1 >  1.5)                      return("Altered")
  if (z1 >  1.0)                      return("Borderline_Altered")
  if (abs(z1) <= 1.0 &&
      abs(zb) <= 1.0 &&
      abs(z2) <= 1.5 &&
      abs(z3) <= 1.5)                 return("Preserved")
  if (z1 < -1.5)                      return("Impaired")
  if (z1 < -1.0)                      return("Borderline_Impaired")
  return("Preserved")
}

# "Blunted" requiere contexto adicional: z_xi1 muy bajo + amplitud relativa baja
# (heurística: z_xi1 < -1.5 + |z_basal| <= 1 + analito secretion-dominant)
secretion_dominant <- c("GIP", "GLP1", "PYY", "insulin")

z[, ptp_primary := mapply(classify_primary, z_basal, z_xi1, z_xi2, z_xi3)]
z[hormone %in% secretion_dominant & ptp_primary == "Impaired" & abs(z_basal) <= 1,
  ptp_primary := "Blunted"]

# ============================================================
# 4) Etiquetas PTP secundarias (9) — framework.md §2.2
# ============================================================
# +Recovered / +Borderline_Enhanced / +Enhanced
# Aplica solo si hay datos pre/post (TODO: requiere link pre-post de cohorte)
# En POC sintético no hay pareo pre/post; se deja como NA.
z[, ptp_secondary := NA_character_]

z[, ptp_full := ifelse(is.na(ptp_secondary), ptp_primary,
                       paste(ptp_primary, ptp_secondary, sep = " + "))]

fwrite(z[, .(subject_id, cohort, hormone,
             z_basal, z_xi1, z_xi2, z_xi3, z_C,
             ptp_primary, ptp_secondary, ptp_full)],
       here("03_outputs", "tables", "ptp_classification.csv"))

# ============================================================
# 5) Integración Types I-V con jerarquía D2>D1>U2>U1>L2>L1>R
#    framework.md §3
# ============================================================
ptp_w <- dcast(z[, .(subject_id, cohort, hormone, ptp_primary)],
               subject_id + cohort ~ hormone, value.var = "ptp_primary")

# Mapeo PTP analito -> grupo no-glucosa (R/L1/L2/U1/U2/D1/D2)
map_to_group <- function(label) {
  fcase(
    label == "Preserved",            "R",
    label == "Borderline_Impaired",  "L1",
    label %in% c("Impaired","Blunted"), "L2",
    label == "Borderline_Altered",   "U1",
    label == "Altered",              "U2",
    label %in% c("Discordant_High","Discordant_Low","Discordant_Basal"), "D1",
    default                          = NA_character_
  )
}

# Subtipo glucémico a/b/c
glucose_subtype <- function(zb_g, z1_g) {
  if (any(is.na(c(zb_g, z1_g)))) return(NA_character_)
  if (zb_g >  1.5 || z1_g >  1.5) return("c")  # hiperglucemia
  if (zb_g < -1.0 || z1_g < -1.5) return("b")  # hipoglucemia
  return("a")                                   # preservada
}

# Construye Type integrado por cohorte
glucose_z <- z[hormone == "glucose", .(subject_id, z_basal_g = z_basal, z_xi1_g = z_xi1)]
ptp_long <- z[hormone != "glucose", .(subject_id, cohort, hormone, ptp_primary,
                                       group = sapply(ptp_primary, map_to_group))]
ptp_long <- merge(ptp_long, glucose_z, by = "subject_id", all.x = TRUE)

types_dt <- ptp_long[, {
  groups <- na.omit(group)
  if (length(groups) < 2L) {
    list(type = "not_classifiable", subtype = NA_character_,
         reason = "less_than_2_non-glucose_axes")
  } else {
    has_D2 <- any(groups == "D1") && any(groups %in% c("U2", "L2"))  # heurística D2
    has_D1 <- any(groups == "D1")
    has_U2 <- any(groups == "U2")
    has_U1 <- any(groups == "U1")
    has_L2 <- any(groups == "L2")
    has_L1 <- any(groups == "L1")
    all_R  <- all(groups == "R")

    sub <- glucose_subtype(unique(z_basal_g)[1], unique(z_xi1_g)[1])

    type_label <- if (all_R && (is.na(sub) || sub == "a")) {
      "Type I"
    } else if (has_U2 || has_U1) {
      # framework R4: Discordant_High/Low blocks Type II
      if (has_D1 || is.na(sub) || sub != "a") "Type V" else "Type II"
    } else if (has_L2 || has_L1) {
      if ((has_U2 || has_U1) || sub %in% c("b","c")) "Type V" else "Type III"
    } else if (has_D2 || (has_D1 && (has_U2 || has_U1 || has_L2))) {
      "Type IV"
    } else {
      "Type IV"
    }

    list(type = type_label,
         subtype = if (type_label %in% c("Type III", "Type IV", "Type V")) sub else NA_character_,
         reason = paste(groups, collapse = ","))
  }
}, by = .(subject_id, cohort)]

fwrite(types_dt, here("03_outputs", "tables", "types_integration.csv"))

cli_alert_success("PTP classification (15 etiquetas v2.0): {.path 03_outputs/tables/ptp_classification.csv}")
cli_alert_success("Types I-V integration: {.path 03_outputs/tables/types_integration.csv}")
cli_alert_success("Reference adequacy v2.0: {.path 03_outputs/tables/reference_adequacy.csv}")

# Resumen distribución Types por cohorte
summary_types <- types_dt[, .N, by = .(cohort, type)]
print(dcast(summary_types, cohort ~ type, value.var = "N", fill = 0L))
