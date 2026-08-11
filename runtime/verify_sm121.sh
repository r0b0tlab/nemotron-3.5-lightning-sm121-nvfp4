#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_CKPT="${MODEL_CKPT:?Set MODEL_CKPT to the local checkpoint directory}"
IMAGE="${IMAGE:-nemotron-lightning-vllm:private-sm121-mtp}"

docker image inspect "$IMAGE" --format 'image={{.Id}} arch={{.Architecture}} os={{.Os}} size={{.Size}} repo_digests={{json .RepoDigests}}'
MODEL_CKPT="$MODEL_CKPT" python3 - <<'PY'
from pathlib import Path
import json,os
root=Path(os.environ['MODEL_CKPT'])
config=json.loads((root/'config.json').read_text())
index=json.loads((root/'model.safetensors.index.json').read_text())
missing=[f'model-{i:05d}-of-00052.safetensors' for i in range(1,53) if not (root/f'model-{i:05d}-of-00052.safetensors').is_file()]
assert not missing, missing
mtp=sum(k.startswith('mtp.') for k in index['weight_map'])
assert mtp>0
assert config.get('model_type')=='nemotron_h'
print('model_preflight=PASS')
print('architecture='+','.join(config.get('architectures',[])))
print('max_position_embeddings='+str(config.get('max_position_embeddings')))
print('shards=52')
print('trained_mtp_tensors='+str(mtp))
PY

docker run --rm --gpus all --entrypoint python3 \
  --volume "$MODEL_CKPT:/model:ro" \
  --volume "$ROOT/container_audit.py:/audit.py:ro" \
  "$IMAGE" /audit.py
printf '%s\n' 'container_audit=PASS'
