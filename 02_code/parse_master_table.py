#!/usr/bin/env python3
"""
parse_master_table.py
Parser para el CSV wide-format del usuario:
  "Tabla maestra AUC E and P Hormones" (95 estudios x 11 hormona-bloques)
Convierte a long format compatible con 01_harmonize.R modo 1.
Pandas maneja el quoting complejo mejor que data.table::fread.
"""
import pandas as pd
import re
from pathlib import Path

ROOT = Path.home() / "Research/PTP_JCEM"
RAW = ROOT / "01_data/raw/master_table_raw.csv"
OUT = ROOT / "01_data/raw/master_table.csv"

df = pd.read_csv(RAW, low_memory=False, dtype=str)
print(f"Raw CSV: {df.shape[0]} filas x {df.shape[1]} columnas")

# Bloques de hormona (verificados por inspeccion)
HORMONE_BLOCKS = [
    ("ghrelin_total", "Time",     "Pmol/L"),
    ("ghrelin_acyl",  "Time.1",   "Pmol/L.1"),
    ("GIP_total",     "Time.2",   "Pmol/L.2"),
    ("GIP_active",    "Time.3",   "Pmol/L.3"),
    ("GLP1_total",    "Time.4",   "Pmol/L.4"),
    ("GLP1_active",   "Time.5",   "Pmol/L.5"),
    ("PYY_total",     "Time.6",   "Pmol/L.6"),
    ("PYY_3_36",      "Time.7",   "Pmol/L.7"),
    ("insulin",       "Time.8",   "Pmol/L.8"),
    ("glucagon",      "Time.9",   "Pmol/L.9"),
    ("glucose",       "Time.10",  "mmol/L"),
]

def map_cohort(label):
    if pd.isna(label): return None
    l = label.lower().strip()
    if "no obesity" in l and "no t2dm" in l:                    return "no_obese_without_T2DM"
    if "obesity plus" in l and "t2dm" in l and "after" in l and "roux" in l: return "RYGBP"
    if "obesity plus" in l and "t2dm" in l and "after" in l and "sleeve" in l: return "SG"
    if "obesity plus" in l and "t2dm" in l and "before" in l:   return "Obesity_T2DM"
    if "obesity plus type 2 diabetes" in l or "obesity+t2dm" in l: return "Obesity_T2DM"
    if "type 2 diabetes mellitus" in l and "obesity" not in l:  return "T2DM"
    if "after roux" in l or ("roux" in l and "after" in l):     return "RYGBP"
    if "sleeve" in l:                                            return "SG"
    if "caloric restriction" in l:                               return "Post-CR"
    if "obesity" in l:                                           return "Obesity"
    return None

def map_challenge(s):
    if pd.isna(s): return None
    l = s.lower()
    if "ogtt" in l or "oral glucose tolerance" in l: return "OGTT"
    if "liquid mixed meal" in l:                     return "LMMT"
    if "solid mixed meal" in l or "mixed meal" in l: return "SMMT"
    return None

# Identifica filas study-header
df["is_header"] = df["Author"].notna() & df["Author"].astype(str).str.strip().ne("")
header_rows = df.index[df["is_header"]].tolist()
print(f"Study headers: {len(header_rows)}")

records = []
for i, hdr_idx in enumerate(header_rows):
    end_idx = header_rows[i+1] if i+1 < len(header_rows) else len(df)
    children = df.iloc[hdr_idx+1:end_idx]
    hdr = df.iloc[hdr_idx]

    cohort_canon = map_cohort(hdr.get("Cohorts")) or map_cohort(hdr.get(" Cohort"))
    if cohort_canon is None:
        continue

    challenge = map_challenge(hdr.get("Caloric test"))
    n_subj_str = hdr.get("Number of Subjects")
    try: n_subj = int(float(n_subj_str)) if pd.notna(n_subj_str) else None
    except (ValueError, TypeError): n_subj = None

    author_str = str(hdr.get("Author") or "")
    source_id = re.sub(r"[^A-Za-z0-9]", "_", author_str[:30])

    for hname, tcol, vcol in HORMONE_BLOCKS:
        if tcol not in children.columns or vcol not in children.columns:
            continue
        for _, row in children.iterrows():
            t_raw, v_raw = row.get(tcol), row.get(vcol)
            if pd.isna(t_raw) or pd.isna(v_raw): continue
            try:
                t = float(t_raw); v = float(v_raw)
            except (ValueError, TypeError):
                continue
            if t < 0 or t > 240: continue
            records.append({
                "cohort": cohort_canon,
                "hormone": hname,
                "time_min": t,
                "mean_value": v,
                "n": n_subj,
                "source_study": source_id,
                "challenge_class": challenge,
            })

if not records:
    raise SystemExit("Sin registros extraidos. Revisar mapeo.")

master = pd.DataFrame(records)
master = master[(master["time_min"] >= 0) & (master["time_min"] <= 180)]

# Deduplicar por (source_study, cohort, hormone, time_min) promediando valores
# (Hedbäck 2022 reporta SMMT y LMMT en mismo cohort; promediamos. Para split por
#  challenge_class, refinar el subject_id en 01_harmonize.R con sufijo de challenge.)
n_pre = len(master)
master = (master
          .groupby(["source_study", "cohort", "hormone", "time_min"], as_index=False, dropna=False)
          .agg(mean_value=("mean_value", "mean"), n=("n", "max"),
               challenge_class=("challenge_class", "first")))
print(f"\nDeduplicacion: {n_pre} -> {len(master)} (promediados)")
print(f"\nMaster table parseada: {len(master)} registros")
print(f"\nCohortes:\n{master['cohort'].value_counts()}")
print(f"\nHormonas:\n{master['hormone'].value_counts()}")
print(f"\nEstudios unicos: {master['source_study'].nunique()}")
print(f"(Author x Cohort) tuples (target = 71): {master.groupby(['source_study','cohort']).ngroups}")

master.to_csv(OUT, index=False)
print(f"\nSalida: {OUT}")
