# Cover letter — Article A2 submission to *The Lancet Diabetes & Endocrinology*

**Date.** 2026-05-09  
**Author.** Dr. Héctor M. Virgen-Ayala, MD PhD · ORCID 0009-0006-2081-2286 · Universidad de Guadalajara / Instituto Mexicano del Seguro Social, Guadalajara, Mexico · hectorvirgenmd@gmail.com

**To.** The Editors, *The Lancet Diabetes & Endocrinology*

---

Dear Editors,

I am pleased to submit *Mathematical and statistical foundations of the FDEP-TP framework: covariance operators, spectral decomposition, and BLUP estimation in sparse periprandial data* as an Original Research Article for consideration in *The Lancet Diabetes & Endocrinology*.

**Methodological gap.** Existing data-driven taxonomies of metabolic disease decompose static cross-sectional variables (Ahlqvist 2018, Udler 2018, Wagner 2021); functional analyses of glucose curves (Frøslie 2013, Hulman 2018) examine a single trajectory. Despite a mature methodological literature on multivariate functional principal component analysis (Happ–Greven 2018, Chiou–Chen–Yang 2014, Li–Xiao–Luo 2021 mFACEs, Golovkine 2025) and on fast covariance kernel estimation under sparse design (Yao–Müller–Wang 2005, Xiao–Li–Checkley–Crainiceanu 2018), no published framework applies multivariate FPCA to a complete enteropancreatic panel — incretins, satiety hormones, glucagon, insulin, and glucose — across health, type 2 diabetes, caloric restriction, and metabolic surgery under the constraints of sparse irregular design (n≈50 per arm, m=8–9). This article fills that gap.

**Lancet Diabetes & Endocrinology precedent.** The journal has consistently published methodological advances that reshape the geometry of metabolic phenotyping (Ahlqvist 2018; Udler 2018; Lobato 2025 metabolic surgery commission; Rubino 2025 clinical-obesity definition). The framework reported here delivers a positive-semi-definite-by-construction joint covariance operator on a Hilbert product space, with eight axioms stated as theorems with proof citations rather than modelling assumptions, ten estimation procedures including FACEs as the primary covariance estimator and PACE as a sensitivity comparator, and the multivariate fraction-of-variance-explained criterion of Golovkine et al. 2025 applied directly to the joint operator. The methodological substrate is extensible, beyond the periprandial enteropancreatic application, to any future multivariate sparse functional analysis in metabolism, endocrinology, or pharmacology.

**Contribution.** Eight axiomatic theorems and ten estimation procedures, evaluated on a pre-registered ecological corpus of 23 source studies and 2,750 pseudo-subjects, sustain a transportable statistical scaffolding for sparse multivariate functional data on the joint enteropancreatic axis. The framework retains K=12 components at the multivariate-FVE ≥ 0·90 threshold of Golovkine et al. 2025, with N/K=29·2 (well above the identifiability cut-off) and stability across ρ ∈ {0·3, 0·5, 0·7, 0·9} of the AR(1) hyperparameter. FACEs outperformed PACE in the sparse regime characteristic of historical metabolic-disease cohorts.

**Position within a coherent trilogy.** This article isolates the statistical layer (axioms, estimation, inference). Companion articles A1 (conceptual–physiological interpretation of the joint eigenfunctions) and A3 (procedural and translational application of the PTP/IEP classification) develop the same framework on adjacent layers, with non-overlapping primary findings and distinguishing display items. Cross-citation policy: the present article does not cite A1 or A3 (independence of the methodological layer); A1 and A3 will cite this article as a sister manuscript when in review.

**Reproducibility.** The complete pipeline (16 R scripts), the harmonised input file (SHA-256 `2829cd78018e411783671ec00f849647858bda552cfa4ec23ad505ba9704a117`), and all numerical outputs are deposited at Zenodo (concept DOI 10.5281/zenodo.19743544; v1·3 DOI 10.5281/zenodo.19758429) and on GitHub (`sv8wmxnbp8-hash/EPP10` v1·3) under CC-BY 4·0. Pre-registration is at the Open Science Framework (DOI 10.17605/OSF.IO/3CZRE, project tr469, frozen 2026-04-22).

**Suggested reviewers.** Sonja Greven (Humboldt-Universität zu Berlin); Hans-Georg Müller (UC Davis); Ciprian Crainiceanu (Johns Hopkins); Tailen Hsing (University of Michigan); Jeff Goldsmith (Columbia). The first three have authored the canonical multivariate-FPCA and PACE/FACEs literature; Hsing supplies the operator-theoretic foundation; Goldsmith the simultaneous-bands construction.

**Excluded reviewers.** None. The author declares no competing interests, no industry support, and no funding for this work.

**Prior publication.** No part of this work has been published or is under consideration elsewhere. The empirical corpus has been used in companion submissions A1 and A3 with non-overlapping primary findings.

I look forward to the editors' consideration.

Sincerely,

**Dr. Héctor M. Virgen-Ayala, MD PhD**
