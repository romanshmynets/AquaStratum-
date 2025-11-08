# Project Introspection & Snapshots

This repo auto-generates:
- Snapshots after each commit on `main` → `snapshots/*.md` (unique, no overwrite).
- Deep project state and SBOM → `state/<ts>_<sha>/` and `sbom/`.

Workflows:
- `.github/workflows/snapshot.yml`
- `.github/workflows/introspect.yml`

Artifacts are uploaded for each run.
