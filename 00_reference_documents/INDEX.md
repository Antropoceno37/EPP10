# Reference Documents — PTP/IEP Lancet D&E Trilogy

**Directory:** `~/Research/PTP_JCEM/00_reference_documents/`

**Purpose:** Single canonical location for all 10 supporting PDFs referenced in `META_PROMPT_FDEP_TP_TRILOGY_LANCET_DE.md`. All relative paths in the meta-prompt resolve to this directory.

---

## Structure

```
00_reference_documents/
├── D1_classification_framework/
│   └── ***** 13-04-2026 PTP_IEP_Classification_Framework 2.pdf
│       Author: Dr. Héctor M. Virgen-Ayala
│       Purpose: Taxonomía operativa de PTP/IEP (9 etiquetas, 8 reglas)
│       Referenced as: D1 in meta-prompt
│
├── D2_D3_mathematical_proofs/
│   ├── Geometría del BLUP de PACE y del operador de covarianza en mFPCA.pdf
│   │   Purpose: Axiomática matemática (L2.2, L2.3, L2.4)
│   │   Referenced as: D2 in meta-prompt
│   │
│   └── Estimación del kernel de covarianza en datos funcionales sparse...pdf
│       Purpose: Kernel estimation + tabla comparativa métodos
│       Referenced as: D3 in meta-prompt
│
├── clinical_evidence_cohorts/
│   ├── Precision subclassification of type 2 diabetes: a systematic review.pdf
│   │   Authors: Misra et al.
│   │   Journal: Communications Medicine 2023
│   │   Purpose: Precedent for T2DM subphenotyping
│   │
│   ├── Phenotype-based clusters, inflammation and cardiometabolic...pdf
│   │   Authors: Huemer et al.
│   │   Journal: Cardiovascular Diabetology 2025
│   │   Purpose: Multi-hormone cluster reference
│   │
│   └── Characterizing human postprandial metabolic response using multiway...pdf
│       Authors: Shi et al.
│       Journal: Metabolomics 2024
│       Purpose: PARAFAC multiway analysis reference
│
└── author_documentation/
    ├── Artículo 1 Eigenfunciones Multivariadas (mFPCA) en el Sistema Entero-Pancreático...pdf
    │   Purpose: Draft A1 — conceptual foundations
    │   Referenced as: Author rationale in meta-prompt
    │
    ├── Carta Consolidada de Respuesta al Reviewer.pdf
    │   Purpose: Reviewer response tracker (medRxiv v1)
    │   Referenced as: Historical context
    │
    └── Resolución de la Observación 4 del Reviewer.pdf
        Purpose: Specific methodological clarification
        Referenced as: Historical context
```

---

## Master Table (D4)

**Location (does NOT reside in 00_reference_documents/):**
```
~/Research/PTP_JCEM/01_data/raw/master_table.csv
```
**SHA-256:** `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117` (run 2026-05-08)
**Rows:** 1,843 (header + data)
**Source studies:** 23
**Productive arms:** 58 (regenerated run may differ)

---

## Usage in Meta-Prompt

All paths in `META_PROMPT_FDEP_TP_TRILOGY_LANCET_DE.md` reference these documents as:
- **D1:** `00_reference_documents/D1_classification_framework/`
- **D2:** `00_reference_documents/D2_D3_mathematical_proofs/`
- **D3:** `00_reference_documents/D2_D3_mathematical_proofs/`
- **D4:** `01_data/raw/master_table.csv`

**Verification:** Run this command to confirm all files are present:
```bash
find ~/Research/PTP_JCEM/00_reference_documents/ -type f -name "*.pdf" | wc -l
# Should return: 9
```

---

**Last updated:** 2026-05-09 · Established alongside meta-prompt v1.1.
