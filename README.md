# NVIDIA Nemotron 3.5 Lightning — SM121 reproducibility suite

Repository: https://github.com/r0b0tlab/nemotron-3.5-lightning-sm121-nvfp4

Status: public reproducibility suite (published 2026-08-11 by owner decision). No model weights, credentials, caches, raw BFCL traces, or benchmark datasets are included.

This repository packages the reproducibility materials for the native MTP K=1 NVIDIA Nemotron 3.5 Lightning evaluation on NVIDIA GB10 / SM121:

- A pinned ARM64 runtime-container recipe and launch/audit scripts.
- The exact r0b0bench source tree used by the corrected native-thinking campaign.
- The in-tree compatibility patch and source identities.
- Sanitized reconciled 11-lane results and lane provenance.
- A repeatable lane-reconciliation and result-verification tool.
- `README.md` and `AGENTS.md` contracts for human and coding-agent use.

This repository packages only reproducibility materials: no weights, datasets, credentials, or raw traces. Provide licensed local copies of anything omitted.

## Model and runtime identity

Model:

- Served model ID: `nvidia/nemotron-3.5-lightning-30b-a3b`
- Architecture: `NemotronHForCausalLM`
- Model type: `nemotron_h`
- 30B total / approximately 3B active parameters
- 52 safetensors shards
- Trained native MTP tensors present; one MTP layer
- Model maximum position embeddings: 262,144
- Model weights are not in this repository; provide them through `MODEL_CKPT`

Runtime:

- Hardware: NVIDIA GB10 / SM121, Linux ARM64
- Base image: `vllm/vllm-openai@sha256:3af90144a0926e5c5fe46ee16e5201e763dd854538b9d7ce433755f11dadaf78`
- GHCR runtime image: `ghcr.io/r0b0tlab/nemotron-lightning-repro-runtime:sm121-mtp1`
- Local build image used for the evidence: `nemotron-lightning-vllm:private-sm121-mtp`
- Recorded local image ID: `sha256:442df05bcaaf4ca33d1e7eb6d18ea0f4272be6b1503b6604dc191acbd4e47640`
- The registry digest is recorded in `runtime/image-provenance.json` after each authorized image publication.
- vLLM: `0.23.1rc1.dev1327+gf25953cc5`
- PyTorch: `2.11.0+cu129`
- FlashInfer: `0.6.14`
- fastokens: `0.3.1`
- Target MoE backend: Marlin
- Native MTP drafter backend: Triton
- KV cache: FP8
- CUDA graphs enabled through the pinned compilation configuration
- Operational profile: `max_model_len=50016`, `max_num_batched_tokens=8192`, `max_num_seqs=6`, `gpu_memory_utilization=0.70`

The runtime Dockerfile builds the wrapper from the pinned base image and installs `fastokens==0.3.1`. The checkpoint is mounted read-only at runtime and is never baked into the image.

## Benchmark identity

The benchmark client lives under `benchmark/`.

- Package: `r0b0bench 1.0.0rc2`
- Base source commit: `e0f0bf667d3ea8e97f2a9c4453f94201173c7082`
- Corrected source patch: `benchmark/thinking-allowed.patch`
- Final corrected-tree patch SHA-256: `a243d10350cf83aa6dc7019d15198e2fae59cfad953a98506a638d973b961200`
- Native template controls: `{\"thinking\": true, \"enable_thinking\": true}`
- Public profiles remain `core`, `core-subset`, and `systems`.

The final local profile uses generous bounded response envelopes:

- Systems output/generation allowance: 8,192 tokens
- QA / IFEval / HumanEval quality allowance: 32,768 tokens
- GSM8K retest allowance: 49,152 tokens
- NIAH generation reserve: 8,192 tokens

The retained systems and quality lanes were not rerun when GSM8K was corrected. The reconciled result replaces only GSM8K with its higher-budget lane result.

## Reproduce locally

### 1. Prepare model and datasets

The repository does not contain weights or benchmark datasets. Provide local, licensed copies and set paths explicitly:

```bash
export MODEL_CKPT=/absolute/path/to/nemotron-3.5-lightning-30b-a3b
export R0B0BENCH_GSM8K_DATA=/absolute/path/to/gsm8k/test.jsonl
export R0B0BENCH_HUMANEVAL_DATA=/absolute/path/to/humaneval/HumanEval.jsonl
export R0B0BENCH_IFEVAL_DATA=/absolute/path/to/ifeval/input_data.jsonl
export R0B0BENCH_QA_DATA=/absolute/path/to/arc_easy_test.jsonl
```

Do not put those paths, weights, or credentials into commits.

### 2. Pull the runtime image

The runtime image is published to public GHCR and is anonymously pullable. Model weights are never included in the image.

Authenticate with a short-lived GitHub token that has `read:packages` access; do not put the token in this repository or in shell history:

```bash
export GHCR_USERNAME=YOUR_GITHUB_USERNAME
printf '%s' "$GHCR_READ_PACKAGES_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin
unset GHCR_READ_PACKAGES_TOKEN

docker pull ghcr.io/r0b0tlab/nemotron-lightning-repro-runtime:sm121-mtp1
```

For an immutable deployment, replace the tag with the `sha256:` registry digest recorded in `runtime/image-provenance.json`.

### 3. Prepare model weights and audit the image

On an ARM64/SM121 host with Docker and NVIDIA Container Toolkit:

```bash
export MODEL_CKPT=/absolute/path/to/nemotron-3.5-lightning-30b-a3b
export IMAGE=ghcr.io/r0b0tlab/nemotron-lightning-repro-runtime:sm121-mtp1

MODEL_CKPT="$MODEL_CKPT" IMAGE="$IMAGE" runtime/verify_sm121.sh
```

The model directory must contain `config.json`, `model.safetensors.index.json`, all 52 shards, tokenizer files, and trained `mtp.*` tensors. The audit fails closed if these are missing. The pinned base image must resolve to the digest recorded above; the image does not download or copy model weights.

### 4. Serve the model

```bash
MODEL_CKPT="$MODEL_CKPT" \
IMAGE="$IMAGE" \
runtime/launch.sh
```

The launcher uses a read-only model mount, FP8 KV, Marlin target MoE, Triton native MTP K=1, exact model identity, `--ipc=host`, a 64 GiB shared-memory limit, and NVIDIA GPU access. In a second shell, wait for readiness and verify identity:

```bash
curl --fail --silent http://127.0.0.1:8000/v1/models | python3 -m json.tool
curl --fail --silent http://127.0.0.1:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"nvidia/nemotron-3.5-lightning-30b-a3b","messages":[{"role":"user","content":"Give a one-sentence greeting."}],"max_tokens":128}'
```

The returned model ID must be `nvidia/nemotron-3.5-lightning-30b-a3b`. The repository and GHCR package are public; you still need authorized local model weights (NVIDIA Software and Model Evaluation License) to serve.

### 5. Install and run the benchmark client

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -e './benchmark[bfcl,dev]'

export R0B0BENCH_CHAT_TEMPLATE_KWARGS='{"thinking": true, "enable_thinking": true}'
export R0B0BENCH_CANARY_MAX_TOKENS=8192
export R0B0BENCH_BFCL_PYTHON="$VIRTUAL_ENV/bin/python"
export R0B0BENCH_BFCL_SCRIPTS="$PWD/benchmark/scripts/bfcl"
export R0B0BENCH_SERVED_MODEL='nvidia/nemotron-3.5-lightning-30b-a3b'
export BFCL_NUM_THREADS=1
export BFCL_MAX_TOKENS=8192
export BFCL_HTTP_TIMEOUT=7200
export BFCL_MAX_RETRIES=3

ENDPOINT=http://127.0.0.1:8000/v1 \
MODEL=nvidia/nemotron-3.5-lightning-30b-a3b \
TOKENIZER="$MODEL_CKPT" \
OUTPUT=/tmp/nemotron-lightning-r0b0bench-out \
scripts/run_benchmark.sh
```

Outputs must be outside the Git checkout. A full `core-subset` run is useful, but full-suite completion is not itself a pass/fail gate: qualify each lane from its raw evidence and reconcile a corrected lane when appropriate.

### 5. Reconcile a corrected lane

The included reconciler preserves the successful lane objects from a full report and replaces only a specified corrected lane. It emits explicit provenance and keeps the aggregate secondary/non-publishable unless independently promoted later:

```bash
python scripts/reconcile_results.py \
  --full-report results/evidence/full-native-thinking/report.json \
  --replacement-report results/evidence/gsm8k-retest/report.json \
  --lane gsm8k \
  --output /tmp/reconciled-report.json

python scripts/verify_results.py /tmp/reconciled-report.json
```

## Reconciled evidence snapshot

The local reconciled report contains all 11 lanes with `status=PASS` and zero infrastructure errors:

| Lane | Result |
|---|---:|
| Canary | 5/5 checks PASS |
| BFCL multi-turn base | 133/200 = 66.50% |
| BFCL AST | 175/600 = 29.1667% micro accuracy |
| Latency | TTFT 93.628 ms; stream E2E 10,085.781 ms; ITL p95 20.320 ms |
| Concurrency | C1/C2/C4/C6: 99.470 / 151.647 / 217.046 / 252.004 output tok/s |
| Throughput | Decode median 89.289 output tok/s; prefill proxy 2,031.666 prompt tok/s |
| NIAH | 3/3 PASS at 10,456 / 20,912 / 37,641 prompt tokens |
| QA ARC-Easy | 383/400 = 95.75% |
| IFEval lightweight | 155/200 = 77.50% |
| HumanEval | pass@1 93.9024% over 164 |
| GSM8K | 189/200 = 94.50% at 49,152 tokens |

GSM8K had 200/200 HTTP 200 responses and zero test/infrastructure errors. Its final finish-reason distribution was 199 `stop` and one persistent model nontermination at the generous cap; that row is retained as a scoreable model result and disclosed in the audit.

The reconciled report is local secondary evidence because it combines the ten successful lanes from one run with the corrected GSM8K lane from a lane-only run. It is not a claim that all lanes were produced in one uninterrupted process.

## 1M context-window capacity probe (2026-08-11)

The model card claims context length up to 1M; the checkpoint config caps `max_position_embeddings` at 262,144 (NVIDIA documents the override as the serving mechanism for this family). A long-1m capacity profile (`max_model_len=1,000,000`, `max_num_seqs=1`, `gpu_memory_utilization=0.80`, prefix caching disabled, `max_num_batched_tokens=8192` unchanged, identical image/checkpoint/MTP/mamba stack, RoPE untouched via vLLM-native `VLLM_ALLOW_LONG_MAX_MODEL_LEN=1`) served the advertised 1M window and passed a single NIAH probe at 75% of the usable window:

| Field | Value |
|---|---|
| depth | **749,808 constructed prompt tokens** (= 0.75 × (1,000,000 − 256 reserve)) |
| result | PASS — exact needle code `R0B0-NIAH-7K3M`, finish `stop`, HTTP 200, zero infra errors |
| token parity | server `usage.prompt_tokens` == 749,808 constructed |
| wall time | 527.4 s (~8.8 min; ≈1,422 effective prompt tok/s) |
| boundary evidence | diagnostic needle probes also PASS at 100K and at 300K (past the 262,144 trained-position cap) |
| scope | single depth; 90–100% of the window untested; filtered `--only niah` run, `invalid_for_publish=true` by contract |

Full row, probes, and configuration identity: `results/evidence/niah-1m-75pct/NIAH_1M_75PCT.md`.

## Data boundary

- Do not upload model weights, raw BFCL traces, caches, logs, `.env` files, tokens, or passwords.
- Raw BFCL traces are intentionally omitted because fixture conversations can contain credential-like test fields; score summaries are retained.
- Any future expansion of published artifacts requires a fresh sanitized-data review.
