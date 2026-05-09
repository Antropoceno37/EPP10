# 08_figures.R
# Doc 2 §13 — Figuras publication-grade (originales redibujadas, Doc 1 §JCEM FORMAT)
# Genera Fig 2 (trayectorias medias por cohorte), Fig 3 (eigenfunciones),
# Fig 4 (score plot 2D). Outputs: 03_outputs/figures/fig_*.pdf + .png

suppressPackageStartupMessages({
  library(data.table); library(arrow); library(here); library(ggplot2)
  library(patchwork); library(viridis); library(cli)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

fig_dir <- here("03_outputs", "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

theme_jcem <- function() {
  theme_classic(base_size = 10) +
    theme(
      strip.background = element_blank(),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom",
      legend.key.size = unit(0.4, "cm"),
      axis.title = element_text(size = 9),
      plot.title = element_text(size = 11, face = "bold")
    )
}

# === Fig 2 — Trayectorias medias por cohorte × hormona ===
dt <- as.data.table(read_parquet(here("01_data", "harmonized", "ptp_long.parquet")))
agg <- dt[, .(mean_v = mean(value), sd_v = sd(value), .N),
          by = .(cohort, hormone, time_min)]
agg[, `:=`(lo = mean_v - 1.96 * sd_v / sqrt(N),
           hi = mean_v + 1.96 * sd_v / sqrt(N))]

p2 <- ggplot(agg, aes(time_min, mean_v, color = cohort, fill = cohort)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, color = NA) +
  geom_line(linewidth = 0.6) +
  facet_wrap(~ hormone, scales = "free_y", ncol = 4) +
  scale_color_viridis_d(end = 0.9) +
  scale_fill_viridis_d(end = 0.9) +
  labs(x = "Time post-meal (min)", y = "Hormone concentration (units vary)",
       title = "Figure 2 — Mean periprandial trajectories by cohort and hormone",
       subtitle = "Bands: 95% pointwise CI of the mean") +
  theme_jcem()

ggsave(file.path(fig_dir, "fig2_trajectories.pdf"), p2,
       width = 9, height = 6, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig2_trajectories.png"), p2,
       width = 9, height = 6, dpi = 300)
cli_alert_success("Fig 2: {.path {fig_dir}/fig2_trajectories.pdf}")

# === Fig 3 — Eigenfunciones φ_k(t) ===
uni <- readRDS(here("03_outputs", "fpca_univariate.rds"))
phi_long <- rbindlist(lapply(names(uni), function(h) {
  fit <- uni[[h]]$fit
  K <- min(3L, ncol(fit$phi))
  data.table(
    hormone = h,
    time = rep(fit$workGrid, K),
    pc = factor(rep(paste0("PC", seq_len(K)), each = length(fit$workGrid)),
                levels = c("PC1", "PC2", "PC3")),
    value = as.vector(fit$phi[, seq_len(K)])
  )
}))

p3 <- ggplot(phi_long, aes(time, value, color = pc)) +
  geom_hline(yintercept = 0, color = "grey60", linetype = 2, linewidth = 0.3) +
  geom_line(linewidth = 0.7) +
  facet_wrap(~ hormone, scales = "free_y", ncol = 4) +
  scale_color_manual(values = c(PC1 = "#440154", PC2 = "#21908C", PC3 = "#FDE725"),
                     labels = c(PC1 = "PC1: amplitude",
                                PC2 = "PC2: early-vs-late",
                                PC3 = "PC3: biphasic shape")) +
  labs(x = "Time post-meal (min)", y = expression(phi[k](t)),
       title = "Figure 3 — Univariate eigenfunctions per hormone (PC1–PC3)",
       color = NULL) +
  theme_jcem()

ggsave(file.path(fig_dir, "fig3_eigenfunctions.pdf"), p3,
       width = 9, height = 6, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig3_eigenfunctions.png"), p3,
       width = 9, height = 6, dpi = 300)
cli_alert_success("Fig 3: {.path {fig_dir}/fig3_eigenfunctions.pdf}")

# === Fig 4 — Score plot 2D MFPC1 vs MFPC2 ===
mfpca_path <- here("03_outputs", "mfpca_happgreven.rds")
if (file.exists(mfpca_path)) {
  mfpca <- readRDS(mfpca_path)
  scores <- as.data.table(mfpca$fit$scores[, 1:2])
  setnames(scores, c("MFPC1", "MFPC2"))
  scores[, subject_id := unique(dt$subject_id)]
  scores <- merge(scores, unique(dt[, .(subject_id, cohort)]), by = "subject_id")

  p4 <- ggplot(scores, aes(MFPC1, MFPC2, color = cohort, fill = cohort)) +
    geom_hline(yintercept = 0, color = "grey80", linetype = 2) +
    geom_vline(xintercept = 0, color = "grey80", linetype = 2) +
    stat_ellipse(geom = "polygon", alpha = 0.15, level = 0.68, color = NA) +
    geom_point(alpha = 0.7, size = 1.5) +
    scale_color_viridis_d(end = 0.9) +
    scale_fill_viridis_d(end = 0.9) +
    labs(x = "MFPC1 score (global amplitude)", y = "MFPC2 score (early-vs-late)",
         title = "Figure 4 — Multivariate FPC score plot by cohort",
         subtitle = "Ellipses: 68% covariance ellipses") +
    theme_jcem()

  ggsave(file.path(fig_dir, "fig4_scoreplot.pdf"), p4,
         width = 7, height = 5, device = cairo_pdf)
  ggsave(file.path(fig_dir, "fig4_scoreplot.png"), p4,
         width = 7, height = 5, dpi = 300)
  cli_alert_success("Fig 4: {.path {fig_dir}/fig4_scoreplot.pdf}")
}

cli_alert_success("Figuras generadas en: {.path {fig_dir}}")
