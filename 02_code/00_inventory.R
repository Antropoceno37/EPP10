# 00_inventory.R
# Doc 1 §SOURCE INVENTORY · Doc 2 §3
# Construye el source inventory + provenance map de los archivos en 01_data/raw.
# Output: 03_outputs/tables/source_inventory.csv (gate del pipeline)

suppressPackageStartupMessages({
  library(data.table); library(here); library(fs); library(digest); library(cli)
})
set.seed(20260422)  # canonical seed (medRxiv 2026-351723v1, §2.13)

ROOT <- here::here()
raw_dir <- here("01_data", "raw")
if (!dir_exists(raw_dir)) dir_create(raw_dir, recurse = TRUE)

files <- dir_ls(raw_dir, recurse = TRUE, type = "file")

if (length(files) == 0L) {
  cli_alert_warning("01_data/raw/ vacío. El pipeline correrá con dataset sintético (Apéndice A).")
  inv <- data.table()
} else {
  inv <- data.table(
    path             = path_rel(files, ROOT),
    ext              = path_ext(files),
    size_kb          = round(file_info(files)$size / 1024, 1),
    md5              = vapply(files, digest::digest, file = TRUE, algo = "md5", FUN.VALUE = ""),
    added_on         = format(Sys.Date()),
    unit_of_analysis = NA_character_,    # A=participant · B=cohort-time-arm · C=scalar
    evidence_tier    = NA_character_,    # robust · cautious · withheld
    challenge_class  = NA_character_,    # mixed-meal · OGTT · liquid · solid
    cohort           = NA_character_,
    analyte_form     = NA_character_,    # active vs total GLP-1, etc.
    notes            = NA_character_
  )
}

out <- here("03_outputs", "tables", "source_inventory.csv")
dir_create(dirname(out), recurse = TRUE)
fwrite(inv, out)
cli_alert_success("Source inventory: {.path {out}} ({nrow(inv)} archivos)")
