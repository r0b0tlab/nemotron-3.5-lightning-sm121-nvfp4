#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_CKPT="${MODEL_CKPT:?Set MODEL_CKPT to the local Nemotron checkpoint directory}"
IMAGE="${IMAGE:-nemotron-lightning-vllm:private-sm121-mtp}"
CONTAINER_NAME="${CONTAINER_NAME:-nemotron-lightning-mtp-k1-repro}"
PORT="${PORT:-8000}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-nvidia/nemotron-3.5-lightning-30b-a3b}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-50016}"
MAX_NUM_BATCHED_TOKENS="${MAX_NUM_BATCHED_TOKENS:-8192}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-6}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.70}"
CACHE_ROOT="${CACHE_ROOT:-$ROOT/.cache}"
mkdir -p "$CACHE_ROOT"

MODEL_CKPT="$MODEL_CKPT" python3 - <<'PY'
from pathlib import Path
import json, os
root=Path(os.environ['MODEL_CKPT'])
if not (root/'config.json').is_file() or not (root/'model.safetensors.index.json').is_file():
    raise SystemExit('model metadata missing')
missing=[f'model-{i:05d}-of-00052.safetensors' for i in range(1,53) if not (root/f'model-{i:05d}-of-00052.safetensors').is_file()]
if missing: raise SystemExit('missing model shards: '+','.join(missing))
index=json.loads((root/'model.safetensors.index.json').read_text())
mtp=sum(k.startswith('mtp.') for k in index.get('weight_map',{}))
if not mtp: raise SystemExit('trained mtp tensors missing')
print('model_preflight=PASS shards=52 trained_mtp_tensors='+str(mtp))
PY

if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  printf 'container already exists: %s\n' "$CONTAINER_NAME" >&2
  exit 3
fi

exec docker run --rm \
  --name "$CONTAINER_NAME" \
  --gpus all \
  --ipc=host \
  --shm-size=64g \
  --ulimit memlock=-1:-1 \
  --cap-add=IPC_LOCK \
  --publish "$PORT:8000" \
  --env VLLM_USE_FASTOKENS=1 \
  --env VLLM_ENGINE_READY_TIMEOUT_S="${VLLM_ENGINE_READY_TIMEOUT_S:-1800}" \
  --volume "$MODEL_CKPT:/model:ro" \
  --volume "$CACHE_ROOT:/root/.cache" \
  "$IMAGE" \
  --model /model \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name "$SERVED_MODEL_NAME" \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --reasoning-parser nemotron_v3 \
  --moe-backend marlin \
  --kv-cache-dtype fp8 \
  --trust-remote-code \
  --max-model-len "$MAX_MODEL_LEN" \
  --max-num-batched-tokens "$MAX_NUM_BATCHED_TOKENS" \
  --max-num-seqs "$MAX_NUM_SEQS" \
  --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION" \
  --enable-prefix-caching \
  --compilation-config '{"cudagraph_capture_sizes":[1,2,4,8,16,24,32,40,48,56,64,72,80,88,96,104,112,120,128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,256,1024,2048,4096,8192]}' \
  --mamba-backend flashinfer \
  --mamba-ssm-cache-dtype float16 \
  --enable-mamba-cache-stochastic-rounding \
  --mamba-cache-philox-rounds 5 \
  --mamba-cache-mode align \
  --speculative-config '{"method":"mtp","num_speculative_tokens":1,"moe_backend":"triton"}'
