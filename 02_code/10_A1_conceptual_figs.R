#!/usr/bin/env Rscript
# =============================================================================
# 10_A1_conceptual_figs.R — Display Items DI1-DI4 for Article A1
# Conceptual / physiological foundations of the FDEP-TP framework
# Lancet Diabetes & Endocrinology — A1 (2026-05-09)
#
# Reads:  03_outputs/lancet_run_2026-05-08/mfpca_canonical.rds
#         03_outputs/lancet_run_2026-05-08/bootstrap_envelopes.rds
#         03_outputs/lancet_run_2026-05-08/fpca_univariate.rds
#         03_outputs/lancet_run_2026-05-08/tables/ptp_classification.csv
# Writes: 03_outputs/A1_run_2026-05-09/DI{1,2,3,4}.{png,svg}
#         and copies to 04_manuscript/A1/display_items/
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
  library(dplyr)
  library(tidyr)
  library(scales)
  library(ggsci)   # Lancet palette
  library(funData)
})

# ----------------------------- paths ----------------------------------------
RUN_IN  <- "~/Research/PTP_JCEM/03_outputs/lancet_run_2026-05-08"
RUN_OUT <- "~/Research/PTP_JCEM/03_outputs/A1_run_2026-05-09"
DI_OUT  <- "~/Research/PTP_JCEM/04_manuscript/A1/display_items"
TBL_OUT <- "~/Research/PTP_JCEM/04_manuscript/A1/outputs/tables"
dir.create(RUN_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(DI_OUT,  recursive = TRUE, showWarnings = FALSE)
dir.create(TBL_OUT, recursive = TRUE, showWarnings = FALSE)

# Lancet aesthetic
theme_lancet_a1 <- function() {
  theme_minimal(base_family = "Helvetica", base_size = 10) +
    theme(
      plot.title    = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 9, colour = "grey30"),
      axis.title    = element_text(size = 10),
      strip.text    = element_text(face = "bold", size = 9),
      legend.position = "bottom",
      legend.title    = element_text(size = 9),
      panel.grid.minor = element_blank()
    )
}

# ----------------------------- load run --------------------------------------
mfpca   <- readRDS(file.path(RUN_IN, "mfpca_canonical.rds"))
benv    <- readRDS(file.path(RUN_IN, "bootstrap_envelopes.rds"))
fpca_u  <- readRDS(file.path(RUN_IN, "fpca_univariate.rds"))
ptp     <- read.csv(file.path(RUN_IN, "tables/ptp_classification.csv"),
                    stringsAsFactors = FALSE)

K_primary <- mfpca$K_primary
fve_cum   <- as.numeric(mfpca$fve_cum)
ev        <- as.numeric(mfpca$fit$values)
hormones  <- mfpca$hormones
argvals   <- mfpca$fit$functions@.Data[[1]]@argvals[[1]]

cat(sprintf("Loaded mfpca_canonical.rds: K_primary=%d, FVE_K=%.3f\n",
            K_primary, fve_cum[K_primary]))
cat(sprintf("hormones (%d): %s\n", length(hormones), paste(hormones, collapse = ", ")))

# Pretty hormone labels for display
hormone_pretty <- c(
  "ghrelin_acyl"  = "Ghrelin acyl",
  "ghrelin_total" = "Ghrelin total",
  "GIP_active"    = "GIP active",
  "GIP_total"     = "GIP total",
  "GLP1_active"   = "GLP-1 active",
  "GLP1_total"    = "GLP-1 total",
  "glucagon"      = "Glucagon",
  "PYY_3_36"      = "PYY 3-36",
  "PYY_total"     = "PYY total"
)

# ============================================================================
# DI1 — Architecture of the Hilbert product space H = product L^2(T_j)
# ============================================================================
mk_di1 <- function() {
  # Top: schematic of the four conceptual moves laid out as panels
  t   <- seq(0, 180, length.out = 200)
  oscillator_df <- data.frame(
    t,
    secretion = sin(pi * t / 90)^2,
    inhibition = -0.6 * cos(pi * t / 90)
  ) |> pivot_longer(-t, names_to = "process", values_to = "amplitude")
  oscillator_df$process <- factor(
    oscillator_df$process,
    levels = c("secretion", "inhibition"),
    labels = c("Secretion (incretins, PYY, insulin)",
               "Inhibition (ghrelin)")
  )

  p_osc <- ggplot(oscillator_df, aes(t, amplitude, colour = process)) +
    geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
    geom_line(linewidth = 1) +
    scale_colour_lancet() +
    labs(
      title    = "Periprandial transition as a coupled oscillator",
      subtitle = "Conceptual move (i): the unit of analysis",
      x = "Periprandial time (min)", y = "Responsiveness", colour = NULL
    ) +
    theme_lancet_a1()

  # Chiou block-share bars (DI1 right panel)
  cw     <- as.numeric(mfpca$chiou_weights)
  block_df <- data.frame(
    hormone = factor(hormone_pretty[hormones], levels = hormone_pretty[hormones]),
    chiou_share = cw / sum(cw)
  )
  p_chiou <- ggplot(block_df, aes(hormone, chiou_share, fill = hormone)) +
    geom_col(colour = "grey25", linewidth = 0.2) +
    geom_text(aes(label = sprintf("%.1f%%", 100 * chiou_share)),
              vjust = -0.4, size = 2.6) +
    scale_y_continuous(labels = percent_format(1),
                       expand = expansion(mult = c(0, 0.12))) +
    scale_fill_lancet() +
    labs(
      title    = "Chiou weights w_j across the joint operator",
      subtitle = "Conceptual move (iv): equalising integrated variance per analyte block",
      x = NULL, y = "Block share"
    ) +
    theme_lancet_a1() +
    theme(axis.text.x = element_text(angle = 35, hjust = 1),
          legend.position = "none")

  p_osc / p_chiou +
    plot_layout(heights = c(1, 1)) +
    plot_annotation(
      title    = "DI1 - Architecture of the Hilbert product space H = product L^2(T_j)",
      subtitle = "Four conceptual moves of the FDEP-TP framework"
    )
}
di1 <- mk_di1()
ggsave(file.path(DI_OUT, "DI1_H_space_architecture.png"), di1, width = 9, height = 9, dpi = 300)
ggsave(file.path(DI_OUT, "DI1_H_space_architecture.svg"), di1, width = 9, height = 9)
cat("DI1 written.\n")

# ============================================================================
# DI2 — Four leading mFPC eigenfunctions with physiological annotation
# ============================================================================
mk_di2 <- function() {
  # Extract eigenfunctions psi_m^{(j)}(t) for m = 1..4 from mfpca$fit$functions
  fns <- mfpca$fit$functions
  M_show <- 4
  ef_list <- list()
  for (j in seq_along(hormones)) {
    fd <- fns@.Data[[j]]
    Xmat <- fd@X[seq_len(M_show), , drop = FALSE]
    for (m in seq_len(M_show)) {
      ef_list[[length(ef_list) + 1L]] <- data.frame(
        component = paste0("Psi[", m, "]"),
        hormone   = hormone_pretty[hormones[j]],
        t         = fd@argvals[[1]],
        psi       = Xmat[m, ]
      )
    }
  }
  ef_df <- do.call(rbind, ef_list)
  ef_df$component <- factor(ef_df$component,
                            levels = paste0("Psi[", 1:M_show, "]"),
                            labels = c(
                              "Psi[1] - distal L-cell dominance (PYY)",
                              "Psi[2] - proximal-vs-distal sequencing",
                              "Psi[3] - biphasic glucose-insulin coupling",
                              "Psi[4] - ghrelin tone"
                            ))
  ef_df$hormone <- factor(ef_df$hormone, levels = hormone_pretty[hormones])

  ggplot(ef_df, aes(t, psi, colour = hormone)) +
    geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
    geom_line(linewidth = 0.7) +
    facet_wrap(~ component, ncol = 2, scales = "free_y") +
    scale_colour_lancet() +
    labs(
      title    = "DI2 - Four leading mFPC eigenfunctions with physiological annotation",
      subtitle = "Joint Happ-Greven operator on H = product L^2(T_j); n=350 panel",
      x = "Periprandial time (min)", y = expression(hat(psi)[m]^{(j)}(t)),
      colour = NULL
    ) +
    theme_lancet_a1() +
    theme(legend.position = "bottom")
}
di2 <- mk_di2()
ggsave(file.path(DI_OUT, "DI2_four_eigenfunctions.png"), di2, width = 11, height = 9, dpi = 300)
ggsave(file.path(DI_OUT, "DI2_four_eigenfunctions.svg"), di2, width = 11, height = 9)
cat("DI2 written.\n")

# ============================================================================
# DI3 - Cohort-level mean trajectories with simultaneous bootstrap bands
# ============================================================================
mk_di3 <- function() {
  pick <- c("PYY_total", "GLP1_active", "ghrelin_total", "GIP_active")
  band_df <- do.call(rbind, lapply(pick, function(h) {
    e <- benv[[h]]
    data.frame(
      hormone = factor(hormone_pretty[h], levels = hormone_pretty[pick]),
      t = argvals[seq_along(e$median)],
      lower = e$lower, upper = e$upper, median = e$median
    )
  }))

  ggplot(band_df, aes(t)) +
    geom_ribbon(aes(ymin = lower, ymax = upper, fill = hormone),
                alpha = 0.40, colour = NA) +
    geom_line(aes(y = median, colour = hormone), linewidth = 0.9) +
    facet_wrap(~ hormone, scales = "free_y", ncol = 2) +
    scale_fill_lancet() + scale_colour_lancet() +
    labs(
      title    = "DI3 - Cohort-level mean trajectories with simultaneous bootstrap bands",
      subtitle = "Goldsmith 2013 / Degras 2011 sup-t; bands derived from bootstrap_envelopes (B = 50 pipeline-stage)",
      x = "Periprandial time (min)", y = "z-standardised trajectory"
    ) +
    theme_lancet_a1() +
    theme(legend.position = "none")
}
di3 <- mk_di3()
ggsave(file.path(DI_OUT, "DI3_cohort_trajectories_bands.png"), di3, width = 10, height = 8, dpi = 300)
ggsave(file.path(DI_OUT, "DI3_cohort_trajectories_bands.svg"), di3, width = 10, height = 8)
cat("DI3 written.\n")

# ============================================================================
# DI4 - Heatmap of per-analyte PTP labels by cohort
# ============================================================================
mk_di4 <- function() {
  # ptp$ptp_full has nine labels; aggregate proportions by cohort x hormone
  ptp$cohort <- ifelse(ptp$cohort == "no_obese_without_T2DM",
                       "Reference\n(non-obese without T2D)", ptp$cohort)
  ptp$cohort <- ifelse(ptp$cohort == "Obesity_T2DM", "Obesity + T2DM", ptp$cohort)

  ptp_count <- ptp |>
    mutate(label = ifelse(is.na(ptp_full) | ptp_full == "",
                          "Not classifiable", ptp_full)) |>
    group_by(cohort, hormone, label) |>
    summarise(n = n(), .groups = "drop") |>
    group_by(cohort, hormone) |>
    mutate(prop = n / sum(n)) |>
    ungroup()

  # Order labels physiologically (preserved -> impaired -> altered -> enhanced)
  label_order <- c("Preserved", "Borderline Impaired", "Impaired", "Blunted",
                   "Borderline Altered", "Altered", "Recovered",
                   "Borderline Enhanced", "Enhanced",
                   "Discordant_Basal", "Discordant_High", "Discordant_Low",
                   "Not classifiable")
  ptp_count$label <- factor(ptp_count$label, levels = label_order)

  # Hormone ordering (proximal -> distal -> ghrelin -> pancreatic effectors)
  horm_order <- c("GIP_active", "GIP_total", "GLP1_active", "GLP1_total",
                  "PYY_total", "PYY_3_36", "ghrelin_total", "ghrelin_acyl",
                  "glucagon", "insulin", "glucose")
  horm_present <- intersect(horm_order, unique(ptp_count$hormone))
  ptp_count$hormone_pretty <- factor(
    hormone_pretty[as.character(ptp_count$hormone)] %||%
      as.character(ptp_count$hormone),
    levels = c(unname(hormone_pretty[horm_present]),
               "Insulin", "Glucose")
  )
  # Build a robust hormone label vector
  pretty_lookup <- c(hormone_pretty,
                     "insulin" = "Insulin",
                     "glucose" = "Glucose")
  ptp_count$hormone_pretty <- factor(
    pretty_lookup[ptp_count$hormone],
    levels = unname(pretty_lookup[horm_present])
  )

  ptp_count$cohort <- factor(
    ptp_count$cohort,
    levels = c("Reference\n(non-obese without T2D)",
               "Obesity", "T2DM", "Obesity + T2DM",
               "Post-CR", "SG", "RYGBP")
  )

  ggplot(ptp_count, aes(hormone_pretty, prop, fill = label)) +
    geom_col(position = "stack", colour = "grey25", linewidth = 0.15) +
    facet_wrap(~ cohort, ncol = 4) +
    scale_y_continuous(labels = percent_format(1),
                       expand = expansion(mult = c(0, 0.02))) +
    scale_fill_manual(values = c(
      "Preserved"            = "#00468B",
      "Borderline Impaired"  = "#42B540",
      "Impaired"             = "#FDAF91",
      "Blunted"              = "#AD002A",
      "Borderline Altered"   = "#0099B4",
      "Altered"              = "#925E9F",
      "Recovered"            = "#1B1919",
      "Borderline Enhanced"  = "#FDAF91",
      "Enhanced"             = "#ED0000",
      "Discordant_Basal"     = "grey70",
      "Discordant_High"      = "grey50",
      "Discordant_Low"       = "grey30",
      "Not classifiable"     = "grey85"
    ), drop = FALSE) +
    labs(
      title    = "DI4 - Per-analyte PTP labels by cohort",
      subtitle = "Stacked-bar heatmap of the nine PTP labels and discordance flags; integrated IEP Types I-V are reported in companion paper A3",
      x = NULL, y = "Proportion of subject-analyte classifications", fill = "PTP label"
    ) +
    theme_lancet_a1() +
    theme(
      axis.text.x = element_text(angle = 35, hjust = 1, size = 7),
      legend.position = "bottom",
      legend.text = element_text(size = 8),
      legend.key.size = unit(0.45, "cm"),
      strip.text = element_text(size = 9, face = "bold")
    ) +
    guides(fill = guide_legend(nrow = 2))
}
`%||%` <- function(a, b) if (!is.null(a)) a else b
di4 <- mk_di4()
ggsave(file.path(DI_OUT, "DI4_PTP_heatmap.png"), di4, width = 13, height = 10, dpi = 300)
ggsave(file.path(DI_OUT, "DI4_PTP_heatmap.svg"), di4, width = 13, height = 10)
cat("DI4 written.\n")

# Save tabular ledgers
write.csv(data.frame(
  hormone = unname(hormone_pretty[hormones]),
  chiou_weight = as.numeric(mfpca$chiou_weights),
  pc1_norm = as.numeric(mfpca$pc1_norms_per_block)
), file.path(TBL_OUT, "DI1_chiou_weights.csv"), row.names = FALSE)

# Mirror to RUN_OUT
file.copy(file.path(DI_OUT, list.files(DI_OUT, pattern = "^DI[0-9].*")),
          RUN_OUT, overwrite = TRUE)

# RUN_LOG
log_path <- file.path(RUN_OUT, "RUN_LOG.md")
writeLines(c(
  "# A1 Display Items run log",
  "",
  sprintf("**Date.** %s · **Run.** %s", Sys.Date(), basename(RUN_OUT)),
  "",
  sprintf("- K_primary = %d  ·  cumulative FVE at K_primary = %.3f",
          K_primary, fve_cum[K_primary]),
  sprintf("- Joint operator hormones (%d): %s", length(hormones),
          paste(unname(hormone_pretty[hormones]), collapse = ", ")),
  sprintf("- Argvals: %d points on [0, 180] min", length(argvals)),
  "",
  "Outputs:",
  paste0("- ", list.files(DI_OUT, pattern = "^DI"))
), log_path)
cat(sprintf("Run log: %s\n", log_path))
cat("Done.\n")
