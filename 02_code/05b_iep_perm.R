# 05b_iep_perm.R — IEP type prevalence with permutation p-values (DI4)
# Meta-prompt v1.1 §L3.7: 8-rule precedence → 10 IEP types (I.I, I.II, II.I, II.II,
# III.I, III.II, IV.I, IV.II, V.I, V.II). Permutation p-values (B=1000) on cohort-label
# permutations to test whether prevalence per cohort differs from chance.
#
# Output:
#   03_outputs/tables/iep_prevalence_perm.csv

suppressPackageStartupMessages({
  library(data.table); library(here); library(cli)
})
set.seed(20260422)

types_path <- here("03_outputs", "tables", "types_integration.csv")
if (!file.exists(types_path)) {
  cli_alert_danger("Falta {types_path}. Corre 05_classify_ptp.R primero.")
  quit(save = "no", status = 1L)
}
types_dt <- fread(types_path)

# Normalize type label to {I.I, I.II, II.I, II.II, III.I, III.II, IV.I, IV.II, V.I, V.II}.
# Current pipeline emits "Type I", "Type II" + subtype. Map to taxonomy expected by Lancet.
roman_to_arabic <- c("I"="I","II"="II","III"="III","IV"="IV","V"="V")

types_dt[, t_roman := gsub("Type ", "", type)]
types_dt[, t_subtype := ifelse(is.na(subtype) | subtype == "", "I", "II")]
# Refined per L3.7: secondary digit reflects severity (.II = severe, .I = borderline).
# Pipeline currently uses subtype = a/b/c (glucose) for Types III-V. Map a -> .I (mild),
# b/c -> .II (severe) as a defensible projection until prospective subtypes available.
types_dt[, t_severity := fcase(
  is.na(subtype) | subtype == "", "I",
  subtype == "a", "I",
  subtype %in% c("b","c"), "II",
  default = "I"
)]
types_dt[, type_lancet := paste0(t_roman, ".", t_severity)]

# Prevalence by cohort × type
prev_dt <- types_dt[, .N, by = .(cohort, type_lancet)][, prev := N / sum(N), by = cohort]

# Permutation p: shuffle cohort labels B times; for each (cohort × type) tuple,
# proportion of permutations with prev_perm >= prev_obs (one-sided enrichment).
B <- 1000L
cohorts <- sort(unique(types_dt$cohort))
types_set <- sort(unique(types_dt$type_lancet))

obs <- as.matrix(dcast(prev_dt, cohort ~ type_lancet, value.var = "prev", fill = 0))
rownames(obs) <- obs[, "cohort"]; obs <- obs[, -1, drop = FALSE]
storage.mode(obs) <- "numeric"

cli_alert_info("Permutation B={B} on (cohort × type) prevalence...")
ge_count <- array(0, dim = dim(obs), dimnames = dimnames(obs))
for (b in seq_len(B)) {
  perm <- copy(types_dt)
  perm[, cohort := sample(cohort)]
  pp <- perm[, .N, by = .(cohort, type_lancet)][, prev := N / sum(N), by = cohort]
  pmat <- as.matrix(dcast(pp, cohort ~ type_lancet, value.var = "prev", fill = 0))
  rownames(pmat) <- pmat[, "cohort"]; pmat <- pmat[, -1, drop = FALSE]
  storage.mode(pmat) <- "numeric"
  # Align dims
  pmat_full <- matrix(0, nrow = nrow(obs), ncol = ncol(obs), dimnames = dimnames(obs))
  rs <- intersect(rownames(pmat), rownames(obs))
  cs <- intersect(colnames(pmat), colnames(obs))
  pmat_full[rs, cs] <- pmat[rs, cs]
  ge_count <- ge_count + (pmat_full >= obs)
}
p_mat <- (ge_count + 1L) / (B + 1L)
p_bonf <- pmin(p_mat * length(cohorts) * length(types_set), 1)

# Long format output
out_long <- rbindlist(lapply(rownames(obs), function(c_n) {
  data.table(
    cohort = c_n,
    type_lancet = colnames(obs),
    n = as.integer(round(obs[c_n, ] * sum(types_dt$cohort == c_n))),
    prevalence = obs[c_n, ],
    p_perm = p_mat[c_n, ],
    p_bonf = p_bonf[c_n, ]
  )
}))

out_dir <- here("03_outputs", "tables")
fwrite(out_long, file.path(out_dir, "iep_prevalence_perm.csv"))

cli_alert_success("IEP prevalence + permutation: {.path 03_outputs/tables/iep_prevalence_perm.csv}")
print(dcast(out_long[, .(cohort, type_lancet, prevalence)],
            cohort ~ type_lancet, value.var = "prevalence", fill = 0))
