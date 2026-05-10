# Zenodo v3.0-A3 deposit — manual instructions

**Status.** The submission package (`lancet_de_A3_submission_package.zip`) and metadata file (`ZENODO_metadata.json`) are ready. Deposit to Zenodo is a push to the public production infrastructure of an external service and therefore requires the author to execute the upload in person, with a personal access token, after final pre-flight review.

**Workspace state at packaging.** Branch `lancet-A3-methodological` · HEAD commit (see `git log -1 --oneline`) · tag `A3-submitted-2026-05-09`.

This document gives two equally valid paths.

## Path A — Web UI (recommended for first deposit of a new version)

1. Go to https://zenodo.org/deposit and sign in.
2. Open the **concept** record DOI 10.5281/zenodo.19743544 (the "Periprandial Transition Profiles" parent).
3. Click **New version**. Zenodo will pre-fill the metadata from the previous version (v1·4 deposited 2026-04-28, DOI 10.5281/zenodo.19758429; or v3·0-A1 / v2·0-A2 once those are minted).
4. Replace the title with: *FDEP-TP framework — Article A3: Methodological and translational foundations (Lancet Diabetes & Endocrinology submission package)*.
5. Set the version to `v3.0-A3`.
6. Replace the description, keywords, and related_identifiers using the values in `ZENODO_metadata.json`.
7. Upload `lancet_de_A3_submission_package.zip` generated alongside this folder.
8. Reserve a DOI (Zenodo will assign 10.5281/zenodo.XXXXXXX). Copy that DOI back into the manuscript's Data sharing block before final Lancet submission.
9. Review and **Publish**. Once published, DOIs are immutable.

## Path B — REST API (for repeat deposits or scripted workflows)

```bash
# Set the access token (generate one at https://zenodo.org/account/settings/applications/tokens/new/ with deposit:write deposit:actions)
export ZENODO_TOKEN="REPLACE_WITH_PERSONAL_TOKEN"

# 1. Create a new deposition (new version derived from concept 19743544)
curl -sX POST "https://zenodo.org/api/deposit/depositions/19743544/actions/newversion" \
  -H "Authorization: Bearer ${ZENODO_TOKEN}"

# Response includes "links": { "latest_draft": "https://zenodo.org/api/deposit/depositions/<NEW_ID>" }
NEW_ID="REPLACE_FROM_RESPONSE"
BUCKET_URL="REPLACE_FROM_RESPONSE_links_bucket"

# 2. Upload the package zip
curl -sX PUT "${BUCKET_URL}/lancet_de_A3_submission_package.zip" \
  -H "Authorization: Bearer ${ZENODO_TOKEN}" \
  --data-binary @~/Research/PTP_JCEM/04_manuscript/lancet_de_A3_submission_package.zip

# 3. Apply the metadata
curl -sX PUT "https://zenodo.org/api/deposit/depositions/${NEW_ID}" \
  -H "Authorization: Bearer ${ZENODO_TOKEN}" \
  -H "Content-Type: application/json" \
  --data @~/Research/PTP_JCEM/04_manuscript/lancet_de_A3_submission_package/ZENODO_metadata.json

# 4. Publish
curl -sX POST "https://zenodo.org/api/deposit/depositions/${NEW_ID}/actions/publish" \
  -H "Authorization: Bearer ${ZENODO_TOKEN}"
```

## Post-deposit checklist

After Zenodo publication:

- [ ] Copy the new article DOI into:
  - `04_manuscript/A3/manuscript.qmd` — Data sharing block
  - `04_manuscript/A3/numerical_ledger_A3.md` — Identifiers table (`Zenodo v3·0-A3`)
  - `04_manuscript/lancet_de_A3_submission_package/README.md`
- [ ] Re-render `manuscript.docx` and `manuscript.pdf` with the new DOI.
- [ ] Re-package `lancet_de_A3_submission_package.zip`.
- [ ] Push the GitHub tag (already configured): `git push origin A3-submitted-2026-05-09`.
- [ ] Submit to *Lancet Diabetes & Endocrinology* via the editorial portal with this package as primary attachment.

## Why this is not automated

A Zenodo deposit is a publish-to-production action with permanent DOI minting. The script above is provided for your manual execution under your personal access token. It is intentionally not run from this session.
