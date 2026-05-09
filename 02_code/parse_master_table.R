# parse_master_table.R
# Parser para el CSV wide-format del usuario:
#   "Tabla maestra AUC E and P Hormones" (~95 estudios × 11 hormona-bloques × ~10 timepoints)
# Convierte a long format compatible con 01_harmonize.R modo 1:
#   master_table.csv con cols: cohort, hormone, time_min, mean_value, n, source_study, challenge_class

suppressPackageStartupMessages({
  library(data.table); library(here); library(cli)
})

raw_path <- here("01_data", "raw", "master_table_raw.csv")
out_path <- here("01_data", "raw", "master_table.csv")

# === Leer con data.table (maneja quoting de strings largos con commas) ===
df <- fread(raw_path, na.strings = c("", "NA"), header = TRUE,
            check.names = FALSE, fill = TRUE)
cli_alert_info("Raw CSV: {nrow(df)} filas × {ncol(df)} columnas")

# === Mapeo bloques hormona (verificado por inspección Python) ===
# Cada bloque: nombre hormona | Time.X | Value.X (donde X es el sufijo pandas)
hormone_blocks <- list(
  list(name = "ghrelin_total", time_col = "Time",     val_col = "Pmol/L"),
  list(name = "ghrelin_acyl",  time_col = "Time.1",   val_col = "Pmol/L.1"),
  list(name = "GIP_total",     time_col = "Time.2",   val_col = "Pmol/L.2"),
  list(name = "GIP_active",    time_col = "Time.3",   val_col = "Pmol/L.3"),
  list(name = "GLP1_total",    time_col = "Time.4",   val_col = "Pmol/L.4"),
  list(name = "GLP1_active",   time_col = "Time.5",   val_col = "Pmol/L.5"),
  list(name = "PYY_total",     time_col = "Time.6",   val_col = "Pmol/L.6"),
  list(name = "PYY_3_36",      time_col = "Time.7",   val_col = "Pmol/L.7"),
  list(name = "insulin",       time_col = "Time.8",   val_col = "Pmol/L.8"),
  list(name = "glucagon",      time_col = "Time.9",   val_col = "Pmol/L.9"),
  list(name = "glucose",       time_col = "Time.10",  val_col = "mmol/L")
)

# === Identifica filas de "study header" (Author no-NA + Cohorts no-NA) ===
df[, is_header := !is.na(Author) & nchar(trimws(Author)) > 0]
header_idx <- which(df$is_header)
cli_alert_info("Study headers identificados: {length(header_idx)}")

# === Mapeo de cohort labels heterogéneos a las 6 canónicas (manuscrito §2.2) ===
map_cohort <- function(label) {
  if (is.na(label) || nchar(trimws(label)) == 0) return(NA_character_)
  l <- tolower(trimws(label))
  fcase(
    grepl("no obesity.*no t2dm|no obesity.no t2dm",  l), "no_obese_without_T2DM",
    grepl("obesity plus.*t2dm.*after.*roux|.*roux.*after.*1 year.*plus.*t2dm",  l), "RYGBP",
    grepl("obesity plus.*t2dm.*after.*sleeve|sleeve.*after.*plus.*t2dm",         l), "SG",
    grepl("obesity plus type 2 diabetes mellitus.*before.*roux",                 l), "Obesity_T2DM",
    grepl("obesity plus type 2 diabetes mellitus.*before.*sleeve",               l), "Obesity_T2DM",
    grepl("obesity plus type 2 diabetes|obesity\\+t2dm",                          l), "Obesity_T2DM",
    grepl("type 2 diabetes mellitus(?!.*obesity).*cohort|^t2dm",                  l, perl = TRUE), "T2DM",
    grepl("after roux|roux.*after|^rygbp",                                         l), "RYGBP",
    grepl("sleeve|^sg ",                                                            l), "SG",
    grepl("caloric restriction|^cr ",                                                l), "Post-CR",
    grepl("obesity",                                                                  l), "Obesity",
    default = NA_character_
  )
}

# === Identifica challenge class desde la columna "Caloric test" o "Caloric protocol" ===
map_challenge <- function(s) {
  if (is.na(s)) return(NA_character_)
  l <- tolower(s)
  fcase(
    grepl("ogtt|oral glucose tolerance",             l), "OGTT",
    grepl("liquid mixed meal|liquid mixed",          l), "LMMT",
    grepl("solid mixed meal|mixed meal|smmt",        l), "SMMT",
    default = NA_character_
  )
}

# === Para cada estudio, recorre filas hijas y extrae timepoints por hormona ===
header_idx_ext <- c(header_idx, nrow(df) + 1L)
records <- list()
rec_i <- 0L

for (h_i in seq_along(header_idx)) {
  start_row <- header_idx[h_i]
  end_row   <- header_idx_ext[h_i + 1L] - 1L
  child_rows <- df[(start_row + 1L):end_row]

  hdr <- df[start_row]
  cohort_canon <- map_cohort(hdr$Cohorts)
  if (is.na(cohort_canon)) cohort_canon <- map_cohort(hdr[[" Cohort"]])
  if (is.na(cohort_canon)) next

  challenge <- map_challenge(hdr[["Caloric test"]])
  n_subj    <- suppressWarnings(as.integer(hdr[["Number of Subjects"]]))
  author_str <- hdr$Author
  source_id  <- gsub("[^A-Za-z0-9]", "_",
                     substr(author_str, 1, 30))

  for (blk in hormone_blocks) {
    if (!all(c(blk$time_col, blk$val_col) %in% names(child_rows))) next
    times_raw <- child_rows[[blk$time_col]]
    vals_raw  <- child_rows[[blk$val_col]]

    keep <- !is.na(times_raw) & !is.na(vals_raw) &
            nchar(trimws(times_raw)) > 0 & nchar(trimws(vals_raw)) > 0
    if (!any(keep)) next

    times_n <- suppressWarnings(as.numeric(times_raw[keep]))
    vals_n  <- suppressWarnings(as.numeric(vals_raw[keep]))
    ok <- !is.na(times_n) & !is.na(vals_n) & times_n >= 0 & times_n <= 240
    if (!any(ok)) next

    rec_i <- rec_i + 1L
    records[[rec_i]] <- data.table(
      cohort          = cohort_canon,
      hormone         = blk$name,
      time_min        = times_n[ok],
      mean_value      = vals_n[ok],
      n               = n_subj,
      source_study    = source_id,
      challenge_class = challenge
    )
  }
}

if (length(records) == 0L) {
  cli_alert_danger("Ningún registro extraído. Revisar mapeo de cohortes / hormonas.")
  quit(save = "no", status = 1L)
}

master <- rbindlist(records, fill = TRUE)

# Filtra timepoints fuera de la ventana canónica [0, 180] (manuscrito §2.4)
master <- master[time_min >= 0 & time_min <= 180]

cli_alert_success("Master table parseada: {nrow(master)} registros")
cli_alert_info("Cohortes únicas:")
print(master[, .N, by = cohort][order(-N)])
cli_alert_info("Hormonas únicas:")
print(master[, .N, by = hormone][order(-N)])
cli_alert_info("Estudios únicos: {uniqueN(master$source_study)}")
cli_alert_info("(Author × Cohort) tuples (target = 71): {uniqueN(master[, .(source_study, cohort)])}")

fwrite(master, out_path)
cli_alert_success("Long-format master table: {.path {out_path}}")
