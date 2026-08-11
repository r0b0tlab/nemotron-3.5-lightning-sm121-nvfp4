# NIAH at 75% of the published 1M context window (2026-08-11)

Verdict: **PASS** — bounded capacity row, single depth, lane-qualified from raw rows.

The model card claims context length up to 1M. This campaign served the exact primary-row image and checkpoint with a 1,000,000-token advertised window and ran a single r0b0bench NIAH probe at **75% of the usable window = 749,808 constructed prompt tokens**. The model returned the needle code exactly, with zero infrastructure errors.

Scope honesty: this is a **single-depth** probe. The 90–100% region of the window (~899,769–999,744 tokens) and near-1M output sequences remain **untested**. The run is a filtered single lane (`--only niah`), so `report.json` carries `invalid_for_publish=true` by contract; the lane verdict is qualified from the raw row, not from process exit status. Evidence here is standalone — it is not mixed into the primary 11-lane core-subset row.

## Claim row (raw-qualified)

| Field | Value |
|---|---|
| depth (constructed prompt tokens) | 749,808 (= 0.75 × (1,000,000 − 256 generation reserve)) |
| HTTP status | 200 |
| finish_reason | stop |
| response_text | `R0B0-NIAH-7K3M` (exact claim code, 13 completion tokens) |
| usage.prompt_tokens vs constructed | 749,808 == 749,808 (exact server-side parity) |
| needle position | 49.999% of prompt (needle_fraction 0.5) |
| request wall time | 527.4 s (~8.8 min; ≈1,422 effective prompt tok/s at 750K context) |
| temperature / max_tokens | 0 / 256 |
| infra_errors | 0 |
| preemptions delta | 0 |
| engine epoch | single container, no restart across the run |
| prompt_sha256 | `936095b5eecbb4540335cfc483ab40e8c8e208e4d8378984bda4de494af43256` |

## Serving configuration (long-1m capacity profile)

Identical image (`sha256:442df05bcaaf4ca33d1e7eb6d18ea0f4272be6b1503b6604dc191acbd4e47640`) and checkpoint as the primary row, with these deltas:

| Knob | Primary perf profile | Long-1m profile |
|---|---|---|
| `max_model_len` | 50,016 | **1,000,000** |
| `max_num_seqs` | 6 | **1** |
| `gpu_memory_utilization` | 0.70 | **0.80** |
| prefix caching | enabled | **disabled** (clean capacity read; NVIDIA's own TRT-LLM 1M configs likewise disable block reuse) |
| `max_num_batched_tokens` | 8,192 | 8,192 (unchanged) |
| MoE / KV / MTP / mamba | marlin / fp8 / MTP K=1 triton / flashinfer f16 + stochastic rounding (philox 5) | identical |

- 1M mechanism: vLLM-native `VLLM_ALLOW_LONG_MAX_MODEL_LEN=1` + `--max-model-len 1000000`. RoPE untouched (`rope_theta=10000`, no `rope_scaling`); checkpoint `config.json` (`max_position_embeddings=262144`) byte-identical — no config mutation.
- Server advertised `max_model_len=1,000,000` at `/v1/models`; `kv_cache_size_tokens=21,031,578` (KV need at depth ≈2.15 GiB — this hybrid has only 6 attention layers with GQA-2 FP8 KV).
- Client: r0b0bench 1.0.0rc2, campaign worktree = base `e0f0bf667d3ea8e97f2a9c4453f94201173c7082` + the repository's `benchmark/thinking-allowed.patch` lineage + two recorded NIAH-only overrides (`fractions:[0.75]`, `request_timeout_s:3600`, explicit single-depth honoring). Patch SHA-256 `632a7ed317c4f1e459cd2fba271bd6193eccbfb1a7c7b81ce002fa8ff6ca2521`.

## Supporting probes (diagnostic, distinct codes — never the claim code)

| Probe | Tokens | Result | Wall | Note |
|---|---|---|---|---|
| Canary chat | 28 | `PROBE-CANARY-OK`, stop | ~1 s | semantics OK |
| Canary tool-call | — | `get_weather("Paris")` | ~1 s | tool path OK |
| Needle | 8,192 | PASS, stop | 2.8 s | warmup |
| Needle | 100,000 | PASS, stop | 24.5 s | pace probe (~4,080 tok/s) |
| Needle | 300,000 | PASS, stop, answered code only | 117.4 s | crosses the 262,144 trained-position boundary cleanly |

Prefill pace degrades gracefully with context (≈4,080 tok/s @100K → 2,554 @300K → 1,422 @750K), consistent with attention-quadratic scaling on the 6 attention layers.

## Files

- `report.json`, `lane_result.json` — sanitized run report and lane result (`invalid_for_publish=true` is the filtered-lane contract).
- `niah.json`, `depth-749808.json` — raw lane summary and per-depth row.
- `probe-PROBE-NIAH-*.json` — smoke/pace/boundary probe rows.

## Omissions

Weights, tokenizer files, server logs, observer captures, caches, and machine-specific paths are not included (per `results/evidence/INVENTORY.md`). Scrubbed path fields use `<model-checkpoint>` / `<local-campaign-root>` placeholders.
