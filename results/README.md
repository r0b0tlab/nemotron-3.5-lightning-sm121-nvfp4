# Results snapshot

This directory contains sanitized private evidence snapshots for the native-thinking Nemotron Lightning campaign.

## Contents

- `evidence/reconciled/report.json` — local reconciled 11-lane report.
- `evidence/reconciled/reconciliation-manifest.json` — lane-level provenance and reconciliation status.
- `evidence/full-native-thinking/` — retained successful lanes and protocol manifest from the corrected full run.
- `evidence/gsm8k-retest/` — higher-budget GSM8K report, audit, lane result, and selected raw GSM8K rows.
- `evidence/niah-1m-75pct/` — 1M-window NIAH capacity probe at 749,808 tokens (75% of usable window), probe rows, and claims document (2026-08-11).
- `campaign-handoff.md` / `campaign-handoff.json` — sanitized local handoff.
- `campaign-manifest.json` — sanitized campaign manifest.

## Data boundary

Weights, benchmark datasets, raw BFCL traces, caches, logs, credentials, and local host paths are not included. Raw BFCL traces were deliberately excluded because fixture conversations can contain credential-like fields. The score summaries and lane metrics are retained.

The reconciled result combines ten successful lanes from the corrected full run with the corrected GSM8K lane. It has complete per-lane provenance, but remains secondary evidence rather than a single-process full-suite publication row. Full-suite nonstop completion is not a pass/fail gate; lane evidence and explicit reconciliation are the gate.
