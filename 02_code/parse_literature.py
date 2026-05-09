#!/usr/bin/env python3
"""
parse_literature.py — Pipeline de extracción de literatura para PTP/IEP

Workflow combinado de las 2 estrategias:
  (A) Expandir master_table.csv con cohort-time-arms de papers nuevos.
  (C) Síntesis sistemática PRISMA para Introduction/Discussion del manuscrito.

Uso:
  python parse_literature.py extract --pdfs <dir>     # paso 1: PDF -> JSON
  python parse_literature.py prisma                   # paso 2: aplicar PRISMA
  python parse_literature.py merge                    # paso 3: integrar a master_table.csv
  python parse_literature.py report                   # paso 4: generar PRISMA flow + summary

Outputs:
  01_data/literature/extractions/per_paper/<paper_id>.json   — un JSON por PDF
  01_data/literature/extractions/trajectories.csv             — long format para merge a master
  01_data/literature/extractions/prisma_log.csv               — decisiones inclusión/exclusión
  04_manuscript/prisma/flow_diagram.mmd                       — Mermaid PRISMA flow
  04_manuscript/prisma/summary_table.md                       — tabla resumen para Discussion
"""

from __future__ import annotations
import argparse, json, re, sys, hashlib, os
from pathlib import Path
from datetime import date
from multiprocessing import Pool

import pandas as pd
import pdfplumber

# Suprime los logs verbosos de pdfplumber
import logging
logging.getLogger("pdfminer").setLevel(logging.ERROR)
logging.getLogger("pdfplumber").setLevel(logging.ERROR)

# ============================================================
# Paths del workspace
# ============================================================
ROOT = Path.home() / "Research/PTP_JCEM"
LIT_DIR = ROOT / "01_data/literature"
PDFS_DIR = LIT_DIR / "pdfs"
EXTR_DIR = LIT_DIR / "extractions"
PER_PAPER_DIR = EXTR_DIR / "per_paper"
PRISMA_DIR = ROOT / "04_manuscript/prisma"
MASTER_TABLE = ROOT / "01_data/raw/master_table.csv"

for d in (PDFS_DIR, PER_PAPER_DIR, PRISMA_DIR):
    d.mkdir(parents=True, exist_ok=True)

# ============================================================
# Vocabulario de hormonas y mapeo a esquema canónico
# ============================================================
HORMONE_PATTERNS = {
    "ghrelin_total":  [r"\btotal[\s\-]?ghrelin\b", r"\bghrelin\s+total\b"],
    "ghrelin_acyl":   [r"\bacyl[\s\-]?(?:ated)?[\s\-]?ghrelin\b", r"\boctanoyl[\s\-]?ghrelin\b"],
    "GIP_total":      [r"\btotal[\s\-]?gip\b"],
    "GIP_active":     [r"\bactive[\s\-]?gip\b", r"\bintact[\s\-]?gip\b"],
    "GLP1_total":     [r"\btotal[\s\-]?glp[\s\-]?1\b"],
    "GLP1_active":    [r"\bactive[\s\-]?glp[\s\-]?1\b", r"\bintact[\s\-]?glp[\s\-]?1\b"],
    "PYY_total":      [r"\btotal[\s\-]?pyy\b"],
    "PYY_3_36":       [r"\bpyy[\s\-]?3[\s\-]?36\b", r"\bpyy[\s\(]+3[\s\-–]+36"],
    "insulin":        [r"\binsulin\b"],
    "glucagon":       [r"\bglucagon\b"],
    "glucose":        [r"\bplasma\s+glucose\b", r"\bblood\s+glucose\b", r"\bglucose\b"],
}

COHORT_PATTERNS = {
    "no_obese_without_T2DM": [r"\b(lean|healthy|control|normal[\s\-]?weight|non[\s\-]?obese)\b"],
    "Obesity":               [r"\bobese\b(?!.*diabet)", r"\bobesity\b(?!.*t2dm)"],
    "T2DM":                  [r"\btype[\s\-]?2[\s\-]?diabet", r"\bt2dm\b", r"\bniddm\b"],
    "Obesity_T2DM":          [r"\bobese[\s\-]?diabet", r"\bobesity\s*\+\s*t2dm\b"],
    "SG":                    [r"\bsleeve[\s\-]?gastrectomy\b", r"\b\(sg\)\b", r"\bvsg\b"],
    "RYGBP":                 [r"\broux[\s\-]?en[\s\-]?y", r"\brygb\b", r"\bgastric\s+bypass\b"],
    "Post-CR":               [r"\bcaloric[\s\-]?restriction\b", r"\bweight[\s\-]?loss[\s\-]?diet\b"],
}

CHALLENGE_PATTERNS = {
    "OGTT": [r"\boral[\s\-]?glucose[\s\-]?tolerance\b", r"\bogtt\b"],
    "LMMT": [r"\bliquid[\s\-]?mixed[\s\-]?meal\b", r"\bliquid[\s\-]?meal\b"],
    "SMMT": [r"\bsolid[\s\-]?mixed[\s\-]?meal\b", r"\bmixed[\s\-]?meal[\s\-]?test\b", r"\bmmt\b"],
}

# Inclusion/exclusion criteria (PRISMA 2020) — refinables
PRISMA_CRITERIA = {
    "include_if": {
        "min_subjects":      5,
        "min_periprandial_timepoints": 4,
        "must_have_analytes": ["glucose"],  # gate mínimo del manuscrito §2.10.5
        "min_one_of":         ["GLP1_total", "GLP1_active", "GIP_total", "insulin"],
        "challenge_types":    ["SMMT", "LMMT", "OGTT"],
    },
    "exclude_if": {
        "animal_only":           True,
        "case_report":           True,
        "review_meta_only":      True,  # excluir reviews/meta-analyses (no datos primarios)
        "no_periprandial_data":  True,
    },
}

# ============================================================
# Extracción
# ============================================================
def extract_metadata(text: str) -> dict:
    md = {"doi": None, "pmid": None, "year": None, "title": None}
    m = re.search(r"\bdoi\.?\s*[:/]?\s*(10\.\d{4,9}/[^\s,;]+)", text, re.IGNORECASE)
    if m: md["doi"] = m.group(1).rstrip(".")
    m = re.search(r"\bPMID[:\s]+(\d+)", text)
    if m: md["pmid"] = m.group(1)
    m = re.search(r"\b(19[5-9]\d|20[0-3]\d)\b", text[:2000])
    if m: md["year"] = int(m.group(1))
    # Title heuristic: largest line in first 2 pages, alphanumeric, no email
    lines = [ln.strip() for ln in text[:3000].split("\n") if 20 <= len(ln.strip()) <= 200]
    candidates = [ln for ln in lines if not re.search(r"@|http|doi", ln, re.IGNORECASE)]
    if candidates: md["title"] = candidates[0]
    return md

def detect_cohorts(text: str) -> list[str]:
    found = set()
    text_low = text.lower()
    for cohort, patterns in COHORT_PATTERNS.items():
        for p in patterns:
            if re.search(p, text_low): found.add(cohort); break
    return sorted(found)

def detect_hormones(text: str) -> list[str]:
    found = set()
    text_low = text.lower()
    for hormone, patterns in HORMONE_PATTERNS.items():
        for p in patterns:
            if re.search(p, text_low): found.add(hormone); break
    return sorted(found)

def detect_challenge(text: str) -> str | None:
    text_low = text.lower()
    for ch, patterns in CHALLENGE_PATTERNS.items():
        for p in patterns:
            if re.search(p, text_low): return ch
    return None

def extract_n_subjects(text: str) -> int | None:
    """Heuristica multi-patron para detectar N. Busca en primeros 10k chars."""
    chunk = text[:10000]
    patterns = [
        r"\bn\s*=\s*(\d{1,3})\b",
        r"\bN\s*=\s*(\d{1,3})\b",
        r"\b(\d{1,3})\s+(?:patients|subjects|participants|volunteers|adults|individuals|men|women|pacientes|sujetos|adultos|hombres|mujeres)\b",
        r"\b(\d{1,3})\s+(?:obese|lean|healthy|diabetic|T2DM|RYGB|sleeve|controls?|cases?|recruited|enrolled)\b",
        r"\bsample\s+size\s*[:=]?\s*(\d{1,3})\b",
        r"\btotal\s+of\s+(\d{1,3})\b",
        r"\benrolled\s+(\d{1,3})\b",
        r"\brecruited\s+(\d{1,3})\b",
        r"\bcompleted\s+by\s+(\d{1,3})\b",
        r"\bnumber\s+of\s+(?:subjects|participants)\s*[:=]?\s*(\d{1,3})\b",
    ]
    candidates = []
    for p in patterns:
        for m in re.finditer(p, chunk, re.IGNORECASE):
            v = int(m.group(1))
            if 3 <= v <= 999: candidates.append(v)
    return max(candidates) if candidates else None

def extract_tables(pdf_path: Path) -> list[dict]:
    """Extrae tablas del PDF; retorna lista de dicts con bbox y rows."""
    tables_out = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page_idx, page in enumerate(pdf.pages):
                for tbl in page.extract_tables() or []:
                    if not tbl or len(tbl) < 2: continue
                    tables_out.append({"page": page_idx + 1, "rows": tbl})
    except Exception as e:
        print(f"  ! Error extrayendo tablas: {e}", file=sys.stderr)
    return tables_out

def parse_trajectory_table(rows: list[list[str]]) -> list[dict]:
    """Detecta tablas con cols 'Time' + valores numéricos por hormona/cohort.
    Retorna trajectory rows para `master_table.csv`."""
    if not rows or len(rows) < 3: return []
    # Encuentra la fila de header con "time" o "min"
    header_idx = None
    for i, row in enumerate(rows[:3]):
        if any(c and re.search(r"\b(time|min)\b", c, re.IGNORECASE) for c in row if c):
            header_idx = i; break
    if header_idx is None: return []

    header = [c.strip() if c else "" for c in rows[header_idx]]
    data_rows = rows[header_idx + 1:]
    time_col = next((i for i, c in enumerate(header) if re.search(r"\btime\b|\bmin\b", c, re.IGNORECASE)), None)
    if time_col is None: return []

    out = []
    for r in data_rows:
        if len(r) <= time_col: continue
        t_raw = r[time_col]
        if not t_raw: continue
        try: t = float(re.sub(r"[^0-9.\-]", "", str(t_raw)))
        except (ValueError, TypeError): continue
        if not (0 <= t <= 240): continue
        for ci, val in enumerate(r):
            if ci == time_col or not val: continue
            try: v = float(re.sub(r"[^0-9.\-]", "", str(val)))
            except (ValueError, TypeError): continue
            col_name = header[ci] if ci < len(header) else f"col{ci}"
            out.append({"time_min": t, "value": v, "raw_col": col_name})
    return out

def process_pdf(pdf_path: Path) -> dict:
    paper_id = hashlib.md5(pdf_path.name.encode()).hexdigest()[:10]
    record = {
        "paper_id":    paper_id,
        "filename":    pdf_path.name,
        "extracted_on": str(date.today()),
        "metadata":    {},
        "cohorts_detected": [],
        "hormones_detected": [],
        "challenge":   None,
        "n_subjects":  None,
        "tables":      [],
        "trajectory_rows_extracted": 0,
        "extraction_quality": "auto",  # auto | manual_required | excluded
        "prisma_decision": None,       # included | excluded — set by `prisma` step
        "prisma_reason": None,
    }

    # Extrae texto plano para metadata + detección
    try:
        with pdfplumber.open(pdf_path) as pdf:
            full_text = "\n".join((p.extract_text() or "") for p in pdf.pages[:30])
    except Exception as e:
        record["extraction_quality"] = "failed"
        record["error"] = str(e)
        return record

    record["metadata"]            = extract_metadata(full_text)
    record["cohorts_detected"]    = detect_cohorts(full_text)
    record["hormones_detected"]   = detect_hormones(full_text)
    record["challenge"]           = detect_challenge(full_text)
    record["n_subjects"]          = extract_n_subjects(full_text)

    # Tablas (puede contener trayectorias)
    tables = extract_tables(pdf_path)
    traj_rows = []
    for tbl in tables:
        rows = parse_trajectory_table(tbl["rows"])
        if rows:
            for r in rows: r["page"] = tbl["page"]
            traj_rows.extend(rows)
    record["tables"] = [{"page": t["page"], "n_rows": len(t["rows"])} for t in tables]
    record["trajectory_rows_extracted"] = len(traj_rows)
    if not traj_rows:
        record["extraction_quality"] = "manual_required"
        record["note"] = "Sin tablas con timepoints. Considerar WebPlotDigitizer si tiene figuras."
    record["trajectory_rows_raw"] = traj_rows
    return record

# ============================================================
# PRISMA gating
# ============================================================
def prisma_gate(record: dict) -> tuple[str, str]:
    """Aplica criterios de inclusión/exclusión PRISMA 2020.
    Retorna (decision, reason)."""
    n = record.get("n_subjects") or 0
    cohorts = record.get("cohorts_detected") or []
    hormones = record.get("hormones_detected") or []
    challenge = record.get("challenge")

    if record.get("extraction_quality") == "failed":
        return "excluded", "extraction_failed"

    cri = PRISMA_CRITERIA["include_if"]
    if n < cri["min_subjects"]:
        return "excluded", f"n={n} < {cri['min_subjects']}"
    if not any(h in hormones for h in cri["must_have_analytes"]):
        return "excluded", f"falta {cri['must_have_analytes']}"
    if not any(h in hormones for h in cri["min_one_of"]):
        return "excluded", f"sin pancreatic effector ni gut hormone"
    if challenge not in cri["challenge_types"]:
        return "excluded", f"challenge={challenge} no en {cri['challenge_types']}"
    if not cohorts:
        return "excluded", "sin cohort canónica detectada"
    return "included", "criterios PRISMA cumplidos"

# ============================================================
# CLI
# ============================================================
def _process_one(pdf_path: Path):
    """Worker para multiprocessing: procesa un PDF y guarda su JSON. Retorna (filename, status)."""
    try:
        record = process_pdf(pdf_path)
        out = PER_PAPER_DIR / f"{record['paper_id']}.json"
        out.write_text(json.dumps(record, indent=2, ensure_ascii=False))
        return (pdf_path.name, record["extraction_quality"])
    except Exception as e:
        return (pdf_path.name, f"FAILED: {e}")

def cmd_extract(args):
    pdfs_dir = Path(args.pdfs).expanduser() if args.pdfs else PDFS_DIR
    # Acepta cualquier extensión que parezca PDF tras sanitización
    pdfs = sorted([p for p in pdfs_dir.iterdir()
                   if p.is_file() or p.is_symlink()])
    pdfs = [p for p in pdfs if p.name.lower().endswith(".pdf")]
    if not pdfs:
        print(f"Sin PDFs en {pdfs_dir}", file=sys.stderr); return

    n_workers = args.workers
    print(f"Extrayendo {len(pdfs)} PDFs desde {pdfs_dir} con {n_workers} workers...")
    print(f"  (~{len(pdfs)*3/n_workers:.0f}s estimado @ 3s/PDF)")

    if n_workers > 1:
        with Pool(n_workers) as pool:
            for i, (name, status) in enumerate(pool.imap_unordered(_process_one, pdfs), 1):
                marker = "✓" if status in ("auto","manual_required") else "✗"
                print(f"  [{i:3d}/{len(pdfs)}] {marker} {status:18s} {name[:80]}")
    else:
        for i, pdf in enumerate(pdfs, 1):
            name, status = _process_one(pdf)
            marker = "✓" if status in ("auto","manual_required") else "✗"
            print(f"  [{i:3d}/{len(pdfs)}] {marker} {status:18s} {name[:80]}")

    print(f"\nOK. {len(pdfs)} JSONs en {PER_PAPER_DIR}")

def cmd_prisma(args):
    records = []
    for jf in sorted(PER_PAPER_DIR.glob("*.json")):
        rec = json.loads(jf.read_text())
        decision, reason = prisma_gate(rec)
        rec["prisma_decision"] = decision
        rec["prisma_reason"]   = reason
        jf.write_text(json.dumps(rec, indent=2, ensure_ascii=False))
        records.append({
            "paper_id":   rec["paper_id"],
            "filename":   rec["filename"],
            "title":      (rec.get("metadata") or {}).get("title"),
            "year":       (rec.get("metadata") or {}).get("year"),
            "doi":        (rec.get("metadata") or {}).get("doi"),
            "n_subjects": rec.get("n_subjects"),
            "cohorts":    "|".join(rec.get("cohorts_detected") or []),
            "hormones":   "|".join(rec.get("hormones_detected") or []),
            "challenge":  rec.get("challenge"),
            "n_traj_rows": rec.get("trajectory_rows_extracted"),
            "decision":   decision,
            "reason":     reason,
        })
    df = pd.DataFrame(records)
    out = EXTR_DIR / "prisma_log.csv"
    df.to_csv(out, index=False)
    print(f"PRISMA log: {out}")
    print(f"  Total identificados: {len(df)}")
    print(f"  Incluidos:  {(df['decision'] == 'included').sum()}")
    print(f"  Excluidos:  {(df['decision'] == 'excluded').sum()}")
    if (df["decision"] == "excluded").any():
        print("\n  Razones exclusión:")
        print(df[df["decision"] == "excluded"]["reason"].value_counts().to_string())

def cmd_merge(args):
    # Recolecta trajectory_rows de papers INCLUIDOS y emite CSV append-able a master_table
    out_rows = []
    for jf in sorted(PER_PAPER_DIR.glob("*.json")):
        rec = json.loads(jf.read_text())
        if rec.get("prisma_decision") != "included": continue
        cohorts = rec.get("cohorts_detected") or []
        if not cohorts: continue
        cohort_canon = cohorts[0]  # primario; refinar si multi-arm
        challenge = rec.get("challenge")
        n = rec.get("n_subjects")
        author_short = (rec.get("metadata") or {}).get("title") or rec["filename"]
        source = re.sub(r"[^A-Za-z0-9]", "_", str(author_short)[:30])
        for traj in rec.get("trajectory_rows_raw") or []:
            # Heurística: mapear raw_col a hormona conocida
            raw = (traj.get("raw_col") or "").lower()
            hormone = next((h for h, pats in HORMONE_PATTERNS.items()
                            if any(re.search(p, raw) for p in pats)), None)
            if not hormone: continue
            out_rows.append({
                "cohort": cohort_canon, "hormone": hormone,
                "time_min": traj["time_min"], "mean_value": traj["value"],
                "n": n, "source_study": source, "challenge_class": challenge,
            })
    if not out_rows:
        print("Sin trayectorias auto-extraídas con header reconocible.")
        print("  Razones probables:")
        print("  - Headers de tabla usan nombres no-canonicos (ej. 'Insulina', 'GLP-1 totale')")
        print("  - Tablas con formato no-estandar")
        print("  - Mayoria de papers tienen figuras (no tablas) -> usar WebPlotDigitizer")
        # Genera CSV vacío con headers para que el usuario pueda llenar
        df_empty = pd.DataFrame(columns=["cohort","hormone","time_min","mean_value",
                                         "n","source_study","challenge_class"])
        df_empty.to_csv(EXTR_DIR / "trajectories.csv", index=False)

        # Genera log con candidatos para WPD manual
        wpd_candidates = []
        for jf in sorted(PER_PAPER_DIR.glob("*.json")):
            rec = json.loads(jf.read_text())
            if rec.get("prisma_decision") == "included":
                wpd_candidates.append({
                    "paper_id":       rec["paper_id"],
                    "filename":       rec["filename"],
                    "n_subjects":     rec.get("n_subjects"),
                    "cohorts":        "|".join(rec.get("cohorts_detected") or []),
                    "hormones":       "|".join(rec.get("hormones_detected") or []),
                    "challenge":      rec.get("challenge"),
                    "n_tables_detected": len(rec.get("tables") or []),
                    "extraction_quality": rec.get("extraction_quality"),
                    "needs_wpd":      rec.get("extraction_quality") == "manual_required",
                })
        if wpd_candidates:
            wpd_path = EXTR_DIR / "wpd_candidates.csv"
            pd.DataFrame(wpd_candidates).to_csv(wpd_path, index=False)
            print(f"\n  Lista de papers para WPD manual: {wpd_path}")
        return
    df = pd.DataFrame(out_rows)
    df.to_csv(EXTR_DIR / "trajectories.csv", index=False)
    print(f"Trajectories extraídas: {len(df)} filas → {EXTR_DIR / 'trajectories.csv'}")
    print(f"Para integrar al master_table.csv, corre:")
    print(f"  cat {MASTER_TABLE} <(tail -n +2 {EXTR_DIR}/trajectories.csv) > {MASTER_TABLE}.merged")

def cmd_report(args):
    # Genera PRISMA flow Mermaid + summary table
    log_path = EXTR_DIR / "prisma_log.csv"
    if not log_path.exists():
        print("Falta prisma_log.csv. Corre `prisma` primero."); return
    df = pd.read_csv(log_path)
    n_id   = len(df)
    n_inc  = (df["decision"] == "included").sum()
    n_exc  = (df["decision"] == "excluded").sum()

    excl_reasons = df[df["decision"] == "excluded"]["reason"].value_counts()

    # PRISMA 2020 flow diagram en Mermaid (renderizable en Quarto/medRxiv)
    mermaid = f"""flowchart TB
    A[Records identified through database<br/>and other searching<br/>n = {n_id}] --> B[Records after duplicates removed<br/>n = {n_id}]
    B --> C[Records screened<br/>n = {n_id}]
    C --> D[Full-text articles assessed<br/>n = {n_id}]
    D --> E[Records excluded<br/>n = {n_exc}]
    D --> F[Studies included in synthesis<br/>n = {n_inc}]
    classDef excluded fill:#fde,stroke:#e44;
    classDef included fill:#dfe,stroke:#2a6;
    class E excluded
    class F included
"""
    (PRISMA_DIR / "flow_diagram.mmd").write_text(mermaid)

    # Summary table en Markdown
    summary = []
    summary.append("# PRISMA 2020 — Synthesis summary\n")
    summary.append(f"**Generated:** {date.today()}\n")
    summary.append(f"**Total identified:** {n_id}\n**Included in synthesis:** {n_inc}\n**Excluded:** {n_exc}\n")
    summary.append("\n## Exclusion reasons\n")
    summary.append("| Reason | n |\n|---|---|\n")
    for r, n in excl_reasons.items():
        summary.append(f"| {r} | {n} |\n")
    summary.append("\n## Included studies\n")
    inc = df[df["decision"] == "included"][["filename","year","n_subjects","cohorts","hormones","challenge"]]
    summary.append(inc.to_markdown(index=False))
    summary_path = PRISMA_DIR / "summary_table.md"
    summary_path.write_text("\n".join(str(x) for x in summary))

    print(f"PRISMA flow: {PRISMA_DIR / 'flow_diagram.mmd'}")
    print(f"Summary table: {summary_path}")
    print(f"\nRender flow diagram a SVG/PNG con: mmdc -i flow_diagram.mmd -o flow_diagram.svg")
    print("(requiere mermaid-cli: npm i -g @mermaid-js/mermaid-cli)")

# ============================================================
def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    pe = sub.add_parser("extract", help="PDF → JSON estructurado")
    pe.add_argument("--pdfs", help=f"directorio con PDFs (default: {PDFS_DIR})")
    pe.add_argument("--workers", type=int, default=4, help="workers paralelos (default: 4)")
    pe.set_defaults(fn=cmd_extract)

    pp = sub.add_parser("prisma", help="aplicar PRISMA 2020 (inclusión/exclusión)")
    pp.set_defaults(fn=cmd_prisma)

    pm = sub.add_parser("merge", help="extraer trajectorias de papers incluidos")
    pm.set_defaults(fn=cmd_merge)

    pr = sub.add_parser("report", help="generar PRISMA flow + summary table")
    pr.set_defaults(fn=cmd_report)

    args = p.parse_args()
    args.fn(args)

if __name__ == "__main__":
    main()
