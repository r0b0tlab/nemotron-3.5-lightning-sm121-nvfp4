# AGENTS.md — Nemotron Lightning reproducibility suite

## Repository boundary

- This repository is public (made so by the owner on 2026-08-11).
- Never upload model weights, benchmark datasets, raw BFCL traces, caches, logs, `.env` files, API keys, tokens, passwords, or local host paths.
- The local evidence snapshot is for reproducibility and review.

## What this repository contains

- `runtime/`: pinned ARM64/SM121 runtime Dockerfile, model preflight, container audit, and parameterized launch script.
- `benchmark/`: exact r0b0bench source tree plus the in-tree compatibility patch used for native-thinking evaluation.
- `scripts/`: benchmark launcher, lane reconciler, and fail-closed result verifier.
- `results/`: sanitized summaries, provenance, and selected raw GSM8K evidence. Raw BFCL traces are deliberately absent.

This is a model-specific reproducibility repository. Do not copy unrelated model names, results, runtime recipes, or credentials into it.

## Source and runtime contracts

- Base benchmark commit: `e0f0bf667d3ea8e97f2a9c4453f94201173c7082`.
- Current corrected-tree patch hash: `a243d10350cf83aa6dc7019d15198e2fae59cfad953a98506a638d973b961200`.
- Native template controls: `thinking=true`, `enable_thinking=true`.
- Served model ID: `nvidia/nemotron-3.5-lightning-30b-a3b`.
- Target: NVIDIA GB10 / SM121, ARM64.
- Runtime profile: Marlin target MoE, Triton native MTP K=1, FP8 KV, CUDA graphs, `max_model_len=50016`, `max_num_batched_tokens=8192`, `max_num_seqs=6`.

## Benchmark rules

1. Qualify lanes from raw artifacts, not process exit codes alone.
2. A full-suite nonstop completion is not itself a pass/fail gate.
3. Preserve eligible, diagnostic, and disqualified evidence separately.
4. A corrected failed lane may be reconciled with successful lanes when the exact endpoint/model/profile and provenance are documented.
5. Never silently overwrite old evidence or mix rows without a reconciliation manifest.
6. Count model wrong/empty/malformed/nonterminating answers as model results when the request was valid; count transport, engine, endpoint, and scorer failures separately as infrastructure/test errors.
7. Keep effective response ceilings and template kwargs explicit in every run.
8. Do not weaken a scorer to improve a result.
9. Keep benchmark output outside the checkout.

## Required verification

Before committing code:

```bash
python -m compileall benchmark/src benchmark/scripts benchmark/tests
python -m pytest -q benchmark/tests
bash -n runtime/launch.sh runtime/verify_sm121.sh scripts/run_benchmark.sh
python scripts/verify_results.py results/evidence/reconciled/report.json
```

Before pushing:

```bash
git diff --cached --check
git status --short
git ls-files
```

Run a broad safety scan over the staged tree. A token-like value, absolute host path, model-weight file, cache, or raw fixture trace is a blocker.

## GitHub boundary

- The target repository is public under the authorized owner/org (made public 2026-08-11).
- Use the least-privilege authenticated path configured for this environment.
- Never put credentials in remotes, scripts, commits, or logs.
- Verify public visibility and the exact pushed commit after any authorized push.
- A successful push is not proof of correct contents; inspect the remote tree and clone it with credentials disabled for read-back.
