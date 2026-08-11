# Runtime distribution and serving

Repository: https://github.com/r0b0tlab/nemotron-3.5-lightning-sm121-nvfp4

The repository is public; the GHCR runtime package currently remains **private** (not anonymously pullable). If you lack package access, build the identical image locally from `runtime/Dockerfile` against the pinned base image recorded in `runtime/image-provenance.json`.

The preferred image is the private GHCR package:

```text
ghcr.io/r0b0tlab/nemotron-lightning-repro-runtime:sm121-mtp1
```

The package is linked to the private GitHub repository through OCI source labels. It is not anonymously pullable. Authorized collaborators need:

1. access to the private repository;
2. access to the private GHCR package; and
3. an authorized local copy of the model checkpoint.

The image contains the runtime only. It does not contain model weights, tokenizer data, benchmark datasets, credentials, or API tokens.

## Pull and audit

```bash
export GHCR_USERNAME=YOUR_GITHUB_USERNAME
printf '%s' "$GHCR_READ_PACKAGES_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin
unset GHCR_READ_PACKAGES_TOKEN

docker pull ghcr.io/r0b0tlab/nemotron-lightning-repro-runtime:sm121-mtp1

export MODEL_CKPT=/absolute/path/to/nemotron-3.5-lightning-30b-a3b
export IMAGE=ghcr.io/r0b0tlab/nemotron-lightning-repro-runtime:sm121-mtp1
MODEL_CKPT="$MODEL_CKPT" IMAGE="$IMAGE" runtime/verify_sm121.sh
```

For an immutable pull, use the registry digest in `image-provenance.json` instead of the mutable convenience tag.

## Serve

```bash
MODEL_CKPT="$MODEL_CKPT" IMAGE="$IMAGE" runtime/launch.sh
```

## Long-1m capacity profile (NIAH at 1M, qualified 2026-08-11)

To serve the advertised 1M window for context-capacity testing, launch with these deltas from `runtime/launch.sh` defaults:

- `MAX_MODEL_LEN=1000000`
- `MAX_NUM_SEQS=1`
- `GPU_MEMORY_UTILIZATION=0.80`
- remove `--enable-prefix-caching` (clean capacity read; NVIDIA's TRT-LLM 1M configs likewise disable block reuse)
- add container env `VLLM_ALLOW_LONG_MAX_MODEL_LEN=1` (vLLM-native override of the checkpoint's 262,144 `max_position_embeddings`; RoPE untouched, config.json unmodified)
- keep `MAX_NUM_BATCHED_TOKENS=8192` and all MoE/KV/MTP/mamba flags identical

After READY, require `/v1/models` to advertise `max_model_len=1000000` and `/metrics` `kv_cache_size_tokens` ≥ 1,000,256 before sending long prompts (21,031,578 observed at util 0.80). Evidence and the qualified 749,808-token NIAH row: `../results/evidence/niah-1m-75pct/`.

`runtime/launch.sh` performs a fail-closed model preflight and starts the OpenAI-compatible endpoint on port 8000. It mounts the checkpoint read-only and uses the validated native MTP K=1 profile. Override `IMAGE`, `PORT`, `MAX_MODEL_LEN`, `MAX_NUM_SEQS`, or other documented environment variables only when the resulting profile is recorded separately.

## Local image build

When GHCR access is unavailable, build the same wrapper locally from the pinned base image:

```bash
docker build --platform linux/arm64 \
  --build-arg REPRO_REVISION="$(git rev-parse HEAD)" \
  -t nemotron-lightning-vllm:private-sm121-mtp runtime
```

Then set `IMAGE=nemotron-lightning-vllm:private-sm121-mtp` for the audit and launcher. A local build is not a registry publication and does not include weights.

## Privacy

Keep the repository, package, model checkpoint, logs, and benchmark outputs private. Do not add a public pull command or make the GHCR package public without a separate explicit authorization.
