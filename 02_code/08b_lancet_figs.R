# 08b_lancet_figs.R — Display Items DI3 + DI4 (Lancet D&E sister manuscript)
# Meta-prompt v1.1:
#   DI3 — Cohort-stratified eigenfunction grid with simultaneous 95% bootstrap bands.
#   DI4 — IEP type prevalence table by cohort with permutation p-values (rendered as PNG).
#
# Style: color-blind safe (Okabe-Ito), sans-serif, 300 dpi, vector SVG + raster PNG.
#
# Outputs (~/Desktop/the lancet/figs/):
#   DI3_eigenfunctions_lancet.svg + .png
#   DI4_iep_prevalence_lancet.svg + .png

suppressPackageStartupMessages({
  library(data.table); library(here); library(ggplot2); library(cli)
  library(funData)
})
set.seed(20260422)

okabe_ito <- c("#000000", "#E69F00", "#56B4E9", "#009E73",
               "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

fig_dir <- "/Users/hectormanuelvirgenayala/Desktop/the lancet/figs"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

theme_lancet <- function(base_size = 9) {
  theme_classic(base_size = base_size, base_family = "Helvetica") +
    theme(
      panel.grid.major = element_line(linewidth = 0.2, colour = "grey92"),
      panel.grid.minor = element_blank(),
      axis.text = element_text(size = base_size - 1),
      strip.background = element_rect(fill = "grey95", colour = NA),
      strip.text = element_text(size = base_size, face = "bold"),
      legend.position = "bottom",
      legend.key.size = unit(0.4, "cm")
    )
}

# ============================================================
# DI3 — Eigenfunction grid with simultaneous 95% bands
# ============================================================
mfpca_path <- here("03_outputs", "mfpca_canonical.rds")
if (!file.exists(mfpca_path)) mfpca_path <- here("03_outputs", "mfpca_happgreven.rds")
mfpca <- readRDS(mfpca_path)
fit   <- mfpca$fit %||% mfpca

# Extract first 4 multivariate eigenfunctions (psi_m^(j)) per hormone.
# funData multifunData expected; otherwise reuse fpca_univariate.rds univariates.
if (!is.null(fit$functions) && inherits(fit$functions, "multiFunData")) {
  M_use <- min(4L, length(fit$functions[[1]]))
  hormones <- names(fit$functions) %||% paste0("h", seq_along(fit$functions))
  psi_long <- rbindlist(lapply(seq_along(fit$functions), function(j) {
    fd <- fit$functions[[j]]
    t_grid <- argvals(fd)[[1]]
    yMat <- X(fd)
    rbindlist(lapply(seq_len(M_use), function(m) {
      data.table(
        hormone = hormones[j],
        component = paste0("ψ", m),
        t = t_grid,
        value = yMat[m, ]
      )
    }))
  }))
} else {
  # Fallback: univariate eigenfunctions per hormone
  uni <- readRDS(here("03_outputs", "fpca_univariate.rds"))
  M_use <- 4L
  psi_long <- rbindlist(lapply(names(uni), function(h) {
    fp <- uni[[h]]$fit
    if (is.null(fp$phi)) return(NULL)
    t_grid <- fp$workGrid
    K_avail <- min(M_use, ncol(fp$phi))
    rbindlist(lapply(seq_len(K_avail), function(k) {
      data.table(hormone = h, component = paste0("φ", k),
                 t = t_grid, value = fp$phi[, k])
    }))
  }), fill = TRUE)
}

# Simultaneous 95% bands from bootstrap_envelopes.rds (if available)
boot_path <- here("03_outputs", "bootstrap_envelopes.rds")
band_long <- NULL
if (file.exists(boot_path)) {
  boot <- readRDS(boot_path)
  if (length(boot) > 0L) {
    # Expect list of [[hormone]][[component]] = list(lower, upper, t)
    band_long <- tryCatch({
      rbindlist(lapply(names(boot), function(h) {
        rbindlist(lapply(names(boot[[h]]), function(k) {
          b <- boot[[h]][[k]]
          if (is.null(b$lower) || is.null(b$upper)) return(NULL)
          data.table(hormone = h, component = k,
                     t = b$t %||% seq(0, 180, length.out = length(b$lower)),
                     lower = b$lower, upper = b$upper)
        }), fill = TRUE)
      }), fill = TRUE)
    }, error = function(e) NULL)
  }
}

p_di3 <- ggplot(psi_long, aes(x = t, y = value, colour = component)) +
  { if (!is.null(band_long) && nrow(band_long) > 0L) {
      geom_ribbon(data = band_long, inherit.aes = FALSE,
                  aes(x = t, ymin = lower, ymax = upper, fill = component),
                  alpha = 0.15)
  } } +
  geom_line(linewidth = 0.6) +
  scale_colour_manual(values = okabe_ito[2:5]) +
  scale_fill_manual(values = okabe_ito[2:5], guide = "none") +
  facet_wrap(~ hormone, ncol = 4, scales = "free_y") +
  labs(x = "Periprandial time (min)",
       y = "Eigenfunction value",
       colour = "Component",
       title = NULL) +
  theme_lancet(9)

ggsave(file.path(fig_dir, "DI3_eigenfunctions_lancet.svg"),
       p_di3, width = 7.2, height = 5.4, units = "in")
ggsave(file.path(fig_dir, "DI3_eigenfunctions_lancet.png"),
       p_di3, width = 7.2, height = 5.4, units = "in", dpi = 300)
cli_alert_success("DI3 saved: {.path {fig_dir}/DI3_eigenfunctions_lancet.{{svg,png}}}")

# ============================================================
# DI4 — IEP prevalence table rendered as PNG
# ============================================================
iep_path <- here("03_outputs", "tables", "iep_prevalence_perm.csv")
if (file.exists(iep_path)) {
  iep <- fread(iep_path)
  # Wide: cohort × IEP type, cell = prevalence (%) with optional asterisk for p_bonf<0.05
  iep[, label := sprintf("%.1f%s",
                         prevalence * 100,
                         ifelse(p_bonf < 0.05, "*", ""))]
  wide <- dcast(iep, cohort ~ type_lancet, value.var = "label", fill = "—")

  # Also save bare numeric for figure
  num_wide <- dcast(iep, cohort ~ type_lancet, value.var = "prevalence", fill = 0)

  # Heatmap-style figure
  iep_long_plot <- melt(num_wide, id.vars = "cohort", variable.name = "type", value.name = "prev")
  p_di4 <- ggplot(iep_long_plot, aes(x = type, y = cohort, fill = prev)) +
    geom_tile(colour = "white") +
    geom_text(aes(label = sprintf("%.1f", prev * 100)), size = 2.6) +
    scale_fill_gradient(low = "#F7FBFF", high = "#08306B",
                         labels = scales::percent_format(accuracy = 1)) +
    labs(x = "IEP type", y = "Cohort", fill = "Prevalence",
         title = NULL) +
    theme_lancet(9) +
    theme(axis.text.x = element_text(angle = 0))

  ggsave(file.path(fig_dir, "DI4_iep_prevalence_lancet.svg"),
         p_di4, width = 7.0, height = 3.8, units = "in")
  ggsave(file.path(fig_dir, "DI4_iep_prevalence_lancet.png"),
         p_di4, width = 7.0, height = 3.8, units = "in", dpi = 300)
  fwrite(wide, file.path(fig_dir, "DI4_iep_prevalence_lancet.csv"))
  cli_alert_success("DI4 saved: {.path {fig_dir}/DI4_iep_prevalence_lancet.{{svg,png,csv}}}")
} else {
  cli_alert_warning("Falta {iep_path}. Corre 05b_iep_perm.R primero.")
}

`%||%` <- function(a, b) if (!is.null(a)) a else b
