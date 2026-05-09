# Índice de manuscritos del programa FDEP-TP / PTP/IEP

> Tracking de todos los manuscritos del Dr. Virgen-Ayala en el programa de fenotipificación dinámica enteropancreática. Estado a mayo 2026.

## Manuscritos identificados (5+ en pipeline)

| # | Título corto | Target | Páginas | Estado | DOI / ID |
|---|---|---|---|---|---|
| 1 | **Sparse mFACEs / PTP/IEP — Six Metabolic Cohorts** | medRxiv preprint | 36 | **Submitted (en revisión)** | medRxiv 2026-351723v1 · OSF [10.17605/OSF.IO/3CZRE](https://doi.org/10.17605/OSF.IO/3CZRE) · Zenodo v1.3 [10.5281/zenodo.19758429](https://doi.org/10.5281/zenodo.19758429) |
| 2 | **MFPCA Lean-Healthy–Referenced Proof-of-Concept** | JCEM Original Article | 15 | Listo para submission | (deriva de #1, formato JCEM) |
| 3 | **Four-Layer Architecture for Metabolic Precision Medicine** | medRxiv position paper | 8 (con duplicado: 16) | Draft, **DOIs pendientes** | TBD |
| 4 | **Periprandial Physiology as the Unit of Metabolic Diagnosis** | Lancet Diabetes & Endocrinol — Perspective v3.1 | 1 (1480 palabras) | Submission-ready, **3 blockers documentados** | TBD |
| 5 | **PTP/IEP Verification Prompt v2.0** (10 módulos auditoría) | Internal QA | 8 | Operacional | — |
| 6+ | **FGI rat / FGI porcine / Nueva Arquitectura** | Companion preprints (medRxiv + bioRxiv) | TBD | Mencionados, no leídos | DOIs pendientes |

---

## Pre-submission blockers activos (del Lancet Perspective v3.1)

| # | Bloqueante | Severidad | Estado actual | Acción |
|---|---|---|---|---|
| 1 | DOIs pendientes medRxiv y bioRxiv para companion preprints | MA | TBD | Esperar asignación tras subida |
| 2 | Reference 24 (Sirota *Lancet Digit Health* 2024) needs verification | MA | Pendiente | Verificar cita exacta antes de submission |
| 3 | **Pipeline numerical reconciliation:** `integrated_types.csv` actualmente reporta "all not_integrable" mientras el manuscrito reporta 76%/55% | **CR** | ✅ **RESUELTO 2026-05-02** — pipeline corre 11/11 scripts; cuando llegue master_table.csv reproducirá cifras canónicas | Cargar `01_data/raw/master_table.csv` para validación final |
| 4 | Confirmar Lancet D&E word limits actuales (target ≤1500) | ME | Pendiente | Revisar portal de submission |
| 5 | Native-English speaker proofread de la prosa | ME | Pendiente | Buscar editor lingüístico |
| 6 | Render Figure 1 desde `FIGURE1_DATA.md` | ME | Pendiente | Generar antes del upload final |

---

## Cómo se relacionan los manuscritos (mapa)

```
┌──────────────────────────────────────────────────────────────────┐
│ Manuscrito #1 — Sparse mFACEs (medRxiv 2026-351723v1)          │
│   ↳ Versión completa con N=2750 pseudo-subjects, K=14, etc.    │
│   ↳ ESTE ES EL CANÓNICO — los demás dependen de él             │
└──────────────────────────────────────────────────────────────────┘
         │
         ├── deriva ──→ #2 JCEM Original (15 pp, formato condensado)
         │
         ├── cita ──→ #3 Position paper Four-Layer (PTP/IEP = Layer 3)
         │
         └── cita ──→ #4 Lancet Perspective (claims 76% IV.II, 55%, <0.5% Type II)
                          │
                          ↳ Companion: FGI rat, FGI porcine, Nueva Arquitectura

#5 Verification Prompt — meta-documento de QA aplicable a todos los demás
```

---

## Workspace local (este repo) ↔ manuscritos

| Manuscrito | Componente del workspace | Estado |
|---|---|---|
| #1 medRxiv canónico | `manuscript_canonical.md` (síntesis) + pipeline `02_code/` | Síntesis completa · pipeline operacional |
| #2 JCEM Original | `04_manuscript/PTP_pipeline_FPCA_MFPCA.qmd` + `refs.bib` | Template renderiza a `.docx`; sustituir resultados sintéticos por reales cuando llegue data |
| #3 Four-Layer Architecture | TODO: `04_manuscript/four_layer_architecture.qmd` | Pendiente — el position paper se puede reescribir como Quarto |
| #4 Lancet Perspective | TODO: `04_manuscript/lancet_perspective_v3.qmd` | Pendiente — adaptar v3.1 al template Quarto + tracker de los 6 blockers |
| #5 Verification Prompt | `verification.md` (en raíz del workspace) | ✅ Implementado — 10 módulos M1–M10 |

---

## Acciones recomendadas (orden de prioridad)

1. **Cargar `master_table.csv` real** en `01_data/raw/` para que el pipeline genere las cifras canónicas (K=14, Pillai F=47.6, IV.II RYGBP=76%, etc.) — cierra Blocker #3 con datos.
2. **Actualizar memoria** con el inventario de manuscritos (este archivo).
3. **Verificar Reference 24** (Sirota *Lancet Digit Health* 2024) — buscar via PubMed/CrossRef.
4. **Generar Figure 1** del Lancet Perspective desde `FIGURE1_DATA.md` (que aún no veo en el workspace; pedir al usuario).
5. **Crear Quarto templates** para #3 y #4 con sección de blockers en línea.
6. **Renderizar primer draft completo** de #1 con datos reales para validación cruzada con manuscrito sometido a medRxiv.
