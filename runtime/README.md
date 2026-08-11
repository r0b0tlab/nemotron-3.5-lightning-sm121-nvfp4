# Private runtime recipe

This directory contains the reproducible container recipe and launch/audit scripts for the local NVIDIA Nemotron 3.5 Lightning SM121 campaign.

The image is an ARM64 wrapper over the pinned vLLM base digest and installs `fastokens==0.3.1`. Model weights are mounted read-only at runtime through `MODEL_CKPT`; they are never copied into the image or repository.

The local evidence used a private image ID recorded in `image-provenance.json`. The image itself is not uploaded by this repository workflow.

Required host prerequisites:

- ARM64 Linux with NVIDIA GB10 / SM121.
- Docker with NVIDIA Container Toolkit.
- The exact checkpoint directory, including `config.json`, `model.safetensors.index.json`, all 52 shards, tokenizer files, and trained `mtp.*` tensors.
- Sufficient disk, memory, and model-license authorization.

Run `verify_sm121.sh` before `launch.sh`. Both scripts fail closed on missing model metadata or shards.
