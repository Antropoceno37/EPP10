#!/usr/bin/env Rscript
# =============================================================================
# 10_A3_methodological_figs.R — Display Items DI1-DI4 for Article A3
# Procedural / translational layer of the FDEP-TP framework
# Lancet Diabetes & Endocrinology — A3 (2026-05-09)
#
# Reads:  03_outputs/lancet_run_2026-05-08/tables/iep_prevalence_perm.csv
#         03_outputs/lancet_run_2026-05-08/tables/ptp_classification.csv
#         03_outputs/lancet_run_2026-05-08/tables/sensitivity_summary.csv
# Writes: 03_outputs/A3_run_2026-05-09/DI{1,2,3,4}.{png,svg}
#         and copies to 04_manuscript/A3/display_items/
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
  library(dplyr)
  library(tidyr)
  library(scales)
  library(ggsci)
})

# ----------------------------- paths ----------------------------------------
RUN_IN  <- "~/Research/PTP_JCEM/03_outputs/lancet_run_2026-05-08"
RUN_OUT <- "~/Research/PTP_JCEM/03_outputs/A3_run_2026-05-09"
DI_OUT  <- "~/Research/PTP_JCEM/04_manuscript/A3/display_items"
TBL_OUT <- "~/Research/PTP_JCEM/04_manuscript/A3/outputs/tables"
dir.create(RUN_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(DI_OUT,  recursive = TRUE, showWarnings = FALSE)
dir.create(TBL_OUT, recursive = TRUE, showWarnings = FALSE)

# Lancet aesthetic
theme_lancet_a3 <- function() {
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

# ----------------------------- load tables -----------------------------------
iep <- read.csv(file.path(RUN_IN, "tables/iep_prevalence_perm.csv"),
                stringsAsFactors = FALSE)
ptp <- read.csv(file.path(RUN_IN, "tables/ptp_classification.csv"),
                stringsAsFactors = FALSE)

cat(sprintf("Loaded iep_prevalence_perm.csv: %d cohort-type rows\n", nrow(iep)))
cat(sprintf("Loaded ptp_classification.csv: %d analyte-subject rows\n", nrow(ptp)))

# ============================================================================
# DI1 — Periprandial trajectory acquisition protocol (schematic)
# ============================================================================
mk_di1 <- function() {
  # Top: timeline of meal and sampling timepoints
  t <- c(-30, 0, 15, 30, 60, 90, 120, 130, 150, 180)
  events <- data.frame(
    t = t,
    label = c("Fasting\nbaseline", "Meal\nstart", "15", "30", "60",
              "90", "120", "130", "150", "180"),
    is_meal = c(FALSE, TRUE, rep(FALSE, 8))
  )

  # Generic trajectory shapes for 4 representative analytes
  ts <- seq(-30, 180, length.out = 200)
  resp <- function(amp, tpeak, width, baseline = 0) {
    baseline + amp * exp(-((ts - tpeak)/width)^2)
  }
  trajectories <- bind_rows(
    data.frame(t = ts, y = resp(1.0, 30, 30),  analyte = "GIP active (proximal K-cell)"),
    data.frame(t = ts, y = resp(0.85, 75, 45), analyte = "GLP-1 active (distal L-cell)"),
    data.frame(t = ts, y = resp(0.95, 90, 50), analyte = "PYY total (distal L-cell)"),
    data.frame(t = ts, y = -0.7 * exp(-((ts - 60)/55)^2), analyte = "Ghrelin total (gastric)")
  )

  p_top <- ggplot(trajectories, aes(t, y, colour = analyte)) +
    annotate("rect", xmin = 0, xmax = 180, ymin = -Inf, ymax = Inf,
             alpha = 0.05, fill = "grey50") +
    geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
    geom_vline(xintercept = events$t, colour = "grey80", linewidth = 0.2) +
    geom_vline(xintercept = 0, colour = "grey25", linewidth = 0.6, linetype = 2) +
    geom_line(linewidth = 0.9) +
    annotate("text", x = -15, y = 0.95, label = "Fasting", size = 3.2, colour = "grey25") +
    annotate("text", x = 90, y = 1.15, label = "Periprandial window (0-180 min)",
             size = 3.2, colour = "grey25") +
    scale_colour_lancet() +
    scale_x_continuous(breaks = t,
                       labels = c("−30", "0", "15", "30", "60", "90", "120", "130", "150", "180")) +
    scale_y_continuous(limits = c(-1.0, 1.3)) +
    labs(
      title = "Standardised periprandial sampling protocol",
      subtitle = "Mixed-meal tolerance test, liquid mixed-meal test, or 75 g OGTT",
      x = "Time relative to meal start (min)", y = "Stylised analyte response", colour = NULL
    ) +
    theme_lancet_a3() +
    theme(legend.position = "bottom",
          axis.text.x = element_text(size = 8))

  # Bottom: panel composition table (11 analyte forms; 9 enter joint operator)
  panel_df <- data.frame(
    analyte = c("GIP active", "GIP total", "GLP-1 active", "GLP-1 total",
                "PYY total", "PYY 3-36", "Glucagon", "Ghrelin total", "Ghrelin acyl",
                "Glucose", "Insulin"),
    layer = c(rep("Joint Happ-Greven operator (n=9)", 9),
              rep("Per-analyte PTP layer only", 2))
  )
  panel_df$analyte <- factor(panel_df$analyte, levels = panel_df$analyte)
  panel_df$layer   <- factor(panel_df$layer,
                             levels = c("Joint Happ-Greven operator (n=9)",
                                        "Per-analyte PTP layer only"))

  p_bot <- ggplot(panel_df, aes(x = analyte, y = 1, fill = layer)) +
    geom_tile(colour = "grey25", linewidth = 0.4, height = 0.5) +
    geom_text(aes(label = analyte), size = 2.7, colour = "white", fontface = "bold") +
    scale_fill_lancet() +
    labs(
      title = "Analyte panel: per-analyte PTP layer (11 forms) and joint operator (9 forms)",
      subtitle = "Glucose and insulin enter PTP at the per-analyte level only; the joint operator excludes them",
      x = NULL, y = NULL, fill = NULL
    ) +
    theme_lancet_a3() +
    theme(axis.text  = element_blank(),
          axis.ticks = element_blank(),
          panel.grid = element_blank(),
          legend.position = "bottom")

  p_top / p_bot + plot_layout(heights = c(2.4, 1)) +
    plot_annotation(
      title = "DI1 - Periprandial trajectory acquisition protocol",
      subtitle = "Sampling grid {0, 15, 30, 60, 90, 120, 130, 150, 180} min after standardised oral nutrient stimulus"
    )
}
di1 <- mk_di1()
ggsave(file.path(DI_OUT, "DI1_acquisition_protocol.png"), di1, width = 11, height = 9, dpi = 300)
ggsave(file.path(DI_OUT, "DI1_acquisition_protocol.svg"), di1, width = 11, height = 9)
cat("DI1 written.\n")

# ============================================================================
# DI2 — Computational pipeline (16 R scripts in 5 layers)
# ============================================================================
mk_di2 <- function() {
  layers <- data.frame(
    layer = factor(rep(paste0("L", 1:5, " - ",
                              c("Ingest & harmonisation",
                                "Pseudo-IPD generation",
                                "Estimation",
                                "Classification",
                                "Inference, sensitivity & figures")),
                       c(3, 1, 3, 2, 7)),
                   levels = paste0("L", 1:5, " - ",
                                   c("Ingest & harmonisation",
                                     "Pseudo-IPD generation",
                                     "Estimation",
                                     "Classification",
                                     "Inference, sensitivity & figures"))),
    script = c("00_inventory.R", "parse_master_table.R", "01_harmonize.R",
               "01_harmonize.R (pseudo-IPD section)",
               "02_fpca_pace.R", "03_mfpca_happgreven.R", "04b_srsf_registration.R",
               "05_classify_ptp.R", "05b_iep_perm.R",
               "06_inference.R", "06_lme4_scores.R", "06b_mahalanobis.R",
               "07_bootstrap.R", "08_figures.R", "08b_lancet_figs.R", "09_sensitivity.R"),
    role = c("Inventory + ingestion of source studies",
             "Parse master_table.csv (SHA-256 anchored)",
             "Harmonise units, time grid, analyte forms",
             "Gaussian-process AR(1) draws (rho=0.5; B=50 / B=300)",
             "FACEs primary (PACE sensitivity) univariate kernel estimation",
             "Happ-Greven joint operator with Chiou normalisation",
             "Square-root-velocity-function phase-amplitude registration",
             "PTP nine-label per-analyte classification",
             "IEP Type I-V integration with permutation q-values",
             "Pillai trace, FANOVA permutation, omnibus + pairwise F",
             "Linear-mixed-effects scores (lme4, Tukey HSD)",
             "Mahalanobis distances per cohort",
             "Simultaneous bootstrap bands (Goldsmith / Degras sup-t)",
             "Generic figures (per-analyte trajectories, score plots)",
             "Lancet-formatted figures (ggsci palette)",
             "Four pre-specified sensitivities")
  )
  layers$script <- factor(layers$script, levels = rev(layers$script))

  ggplot(layers, aes(x = 1, y = script, fill = layer)) +
    geom_tile(colour = "grey25", linewidth = 0.3, width = 0.9, height = 0.85) +
    geom_text(aes(label = script), size = 2.8, colour = "white", fontface = "bold", hjust = 0,
              x = 0.6) +
    geom_text(aes(label = role), x = 1.45, hjust = 0, size = 2.5, colour = "grey15") +
    scale_fill_lancet() +
    scale_x_continuous(limits = c(0.55, 4.2), expand = c(0, 0)) +
    labs(
      title = "DI2 - Computational pipeline (16 R scripts in 5 layers)",
      subtitle = "FACEs primary; PACE / rho-AR(1) / leave-one-axis-out as pre-specified sensitivities (companion paper A2)",
      x = NULL, y = NULL, fill = NULL
    ) +
    theme_lancet_a3() +
    theme(
      axis.text.x = element_blank(),
      axis.ticks  = element_blank(),
      axis.text.y = element_blank(),
      panel.grid  = element_blank(),
      legend.position = "right",
      legend.title    = element_blank(),
      legend.text     = element_text(size = 7)
    )
}
di2 <- mk_di2()
ggsave(file.path(DI_OUT, "DI2_pipeline.png"), di2, width = 12, height = 8, dpi = 300)
ggsave(file.path(DI_OUT, "DI2_pipeline.svg"), di2, width = 12, height = 8)
cat("DI2 written.\n")

# ============================================================================
# DI3 — IEP Type I-V prevalence by cohort with q-values
# ============================================================================
mk_di3 <- function() {
  iep$cohort_pretty <- factor(
    recode(iep$cohort,
           "Obesity"               = "Obesity",
           "Obesity_T2DM"          = "Obesity + T2DM",
           "T2DM"                  = "T2DM",
           "no_obese_without_T2DM" = "Non-obese\nwithout T2D",
           "Post-CR"               = "Post-CR",
           "RYGBP"                 = "RYGBP",
           "SG"                    = "SG"),
    levels = c("Non-obese\nwithout T2D", "Obesity", "T2DM", "Obesity + T2DM",
               "Post-CR", "SG", "RYGBP")
  )
  iep$type_pretty <- factor(
    recode(iep$type_lancet,
           "I.I"                   = "Type I.I (preserved)",
           "III.I"                 = "Type III (infra-physio)",
           "IV.I"                  = "Type IV (altered)",
           "V.I"                   = "Type V (enhanced-mixed)",
           "not_classifiable.I"    = "Not classifiable"),
    levels = c("Type I.I (preserved)", "Type III (infra-physio)",
               "Type IV (altered)", "Type V (enhanced-mixed)",
               "Not classifiable")
  )

  iep$sig_label <- ifelse(iep$p_bonf <= 0.05,
                          sprintf("%.1f%%*", 100 * iep$prevalence),
                          sprintf("%.1f%%", 100 * iep$prevalence))

  ggplot(iep, aes(cohort_pretty, prevalence, fill = type_pretty)) +
    geom_col(position = "stack", colour = "grey25", linewidth = 0.2) +
    geom_text(aes(label = sig_label), position = position_stack(vjust = 0.5),
              size = 2.4, colour = "white", fontface = "bold") +
    scale_y_continuous(labels = percent_format(1),
                       expand = expansion(mult = c(0, 0.02))) +
    scale_fill_manual(values = c(
      "Type I.I (preserved)"      = "#00468B",
      "Type III (infra-physio)"   = "#AD002A",
      "Type IV (altered)"         = "#925E9F",
      "Type V (enhanced-mixed)"   = "#ED0000",
      "Not classifiable"          = "grey70"
    )) +
    labs(
      title = "DI3 - Integrated Enteropancreatic Pattern Type prevalence by cohort",
      subtitle = "* indicates Bonferroni-adjusted permutation q <= 0.05 (lancet_run_2026-05-08)",
      x = NULL, y = "Within-cohort prevalence", fill = "Integrated Type"
    ) +
    theme_lancet_a3() +
    theme(
      axis.text.x = element_text(size = 9),
      legend.position = "bottom",
      legend.text = element_text(size = 8)
    )
}
di3 <- mk_di3()
ggsave(file.path(DI_OUT, "DI3_iep_prevalence.png"), di3, width = 11, height = 8, dpi = 300)
ggsave(file.path(DI_OUT, "DI3_iep_prevalence.svg"), di3, width = 11, height = 8)
cat("DI3 written.\n")

# ============================================================================
# DI4 — Clinical-decision tree: PTP/IEP-informed agonist + surgery indication
# ============================================================================
mk_di4 <- function() {
  # Programmatic decision-tree layout
  nodes <- data.frame(
    id = 1:12,
    x = c(5.0,
          2.5, 5.0, 7.5,
          1.0, 4.0, 5.0, 6.0, 8.5,
          0.5, 6.0, 8.5),
    y = c(8.5,
          7.0, 7.0, 7.0,
          5.5, 5.5, 5.5, 5.5, 5.5,
          3.5, 3.5, 3.5),
    label = c(
      "Compute PTP\nnine-label vector\n(per-analyte)",
      "Aggregate to IEP Type\n(eight-rule precedence)",
      "Glycaemic context\nsuffix a / b / c",
      "Type V flag\n(enhanced-mixed)",
      "Type I.I or II\n(preserved)",
      "Type III\n(infra-physio)",
      "Type IV\n(altered)",
      "Type V (enhanced-mixed)\nwith glucose dysglycaemia",
      "Type V without\nglucose dysglycaemia",
      "Lifestyle support;\nno pharmacology",
      "Single - GLP-1 RA;\ndual - GIP/GLP-1;\ntriple - retatrutide (Tipo VI)",
      "Metabolic surgery\ncandidate: RYGBP / SG\n(Lobato 2025; Rubino 2025)"
    ),
    fill = c("#00468B",
             "#00468B", "#00468B", "#00468B",
             "#42B540", "#AD002A", "#925E9F", "#ED0000", "#FDAF91",
             "#42B540", "#ED0000", "#FDAF91")
  )
  edges <- data.frame(
    x = c(5.0, 5.0, 5.0,    2.5, 2.5,    5.0, 5.0,    7.5, 7.5,    4.0, 6.0, 8.5),
    y = c(8.5, 8.5, 8.5,    7.0, 7.0,    7.0, 7.0,    7.0, 7.0,    5.5, 5.5, 5.5),
    xend = c(2.5, 5.0, 7.5,   1.0, 4.0,   5.0, 6.0,   6.0, 8.5,    0.5, 6.0, 8.5),
    yend = c(7.0, 7.0, 7.0,   5.5, 5.5,   5.5, 5.5,   5.5, 5.5,    3.5, 3.5, 3.5)
  )

  ggplot() +
    geom_segment(data = edges, aes(x, y, xend = xend, yend = yend),
                 colour = "grey45", linewidth = 0.45,
                 arrow = arrow(length = unit(0.18, "cm"), type = "closed")) +
    geom_label(data = nodes, aes(x, y, label = label, fill = fill),
               colour = "white", fontface = "bold", size = 2.6,
               label.r = unit(0.12, "lines"),
               label.padding = unit(0.32, "lines")) +
    scale_fill_identity() +
    scale_x_continuous(limits = c(-0.5, 9.5), expand = c(0, 0)) +
    scale_y_continuous(limits = c(2.8, 9.2), expand = c(0, 0)) +
    annotate("text", x = -0.5, y = 8.5, label = "Step 1.",  hjust = 0, fontface = "italic", size = 3, colour = "grey25") +
    annotate("text", x = -0.5, y = 7.0, label = "Step 2.",  hjust = 0, fontface = "italic", size = 3, colour = "grey25") +
    annotate("text", x = -0.5, y = 5.5, label = "Step 3.",  hjust = 0, fontface = "italic", size = 3, colour = "grey25") +
    annotate("text", x = -0.5, y = 3.5, label = "Action.",  hjust = 0, fontface = "italic", size = 3, colour = "grey25") +
    labs(
      title = "DI4 - PTP/IEP-informed clinical-decision tree (hypothesis-generating)",
      subtitle = "Agonist selection and metabolic-surgery indication keyed on Integrated Type and glycaemic-context suffix; awaits prospective TRIPOD+AI individual-participant validation",
      x = NULL, y = NULL
    ) +
    theme_void(base_family = "Helvetica") +
    theme(
      plot.title    = element_text(face = "bold", size = 11, hjust = 0),
      plot.subtitle = element_text(size = 9, colour = "grey30", hjust = 0),
      plot.margin   = margin(10, 10, 10, 10)
    )
}
di4 <- mk_di4()
ggsave(file.path(DI_OUT, "DI4_clinical_decision_tree.png"), di4, width = 13, height = 8, dpi = 300)
ggsave(file.path(DI_OUT, "DI4_clinical_decision_tree.svg"), di4, width = 13, height = 8)
cat("DI4 written.\n")

# Save A3-specific tabular ledger
type_summary <- iep |>
  group_by(cohort) |>
  summarise(n_subjects = sum(n), .groups = "drop")
write.csv(type_summary,
          file.path(TBL_OUT, "DI3_cohort_subject_counts.csv"),
          row.names = FALSE)

# Mirror to RUN_OUT
file.copy(file.path(DI_OUT, list.files(DI_OUT, pattern = "^DI[0-9].*")),
          RUN_OUT, overwrite = TRUE)

# RUN_LOG
log_path <- file.path(RUN_OUT, "RUN_LOG.md")
writeLines(c(
  "# A3 Display Items run log",
  "",
  sprintf("**Date.** %s . **Run.** %s", Sys.Date(), basename(RUN_OUT)),
  "",
  sprintf("- IEP cohort-type rows loaded: %d", nrow(iep)),
  sprintf("- PTP analyte-subject rows: %d", nrow(ptp)),
  "",
  "Outputs:",
  paste0("- ", list.files(DI_OUT, pattern = "^DI"))
), log_path)
cat(sprintf("Run log: %s\n", log_path))
cat("Done.\n")
