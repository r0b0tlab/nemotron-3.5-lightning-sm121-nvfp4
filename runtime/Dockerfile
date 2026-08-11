# Private wrapper only: the model checkpoint is mounted at runtime and is never baked in.
FROM vllm/vllm-openai@sha256:3af90144a0926e5c5fe46ee16e5201e763dd854538b9d7ce433755f11dadaf78

ARG REPRO_REVISION=unknown
LABEL org.opencontainers.image.title="Private Nemotron Lightning vLLM runtime"
LABEL org.opencontainers.image.description="Pinned NVIDIA vLLM image plus guide-required fastokens dependency"
LABEL org.opencontainers.image.base.name="vllm/vllm-openai@sha256:3af90144a0926e5c5fe46ee16e5201e763dd854538b9d7ce433755f11dadaf78"
LABEL org.opencontainers.image.source="https://github.com/r0b0tlab/nemotron-lightning-repro"
LABEL org.opencontainers.image.documentation="https://github.com/r0b0tlab/nemotron-lightning-repro/blob/main/runtime/README.md"
LABEL org.opencontainers.image.revision="$REPRO_REVISION"
LABEL org.opencontainers.image.version="sm121-mtp1"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.private="true"

# The pinned NVIDIA image enables VLLM_USE_FASTOKENS=1 in the guide profile,
# but does not ship the required package. 0.3.1 has an ARM64 cp39-abi3 wheel.
RUN python3 -m pip install --no-cache-dir --no-deps 'fastokens==0.3.1' \
    && python3 -c 'import fastokens; print("fastokens", getattr(fastokens, "__version__", "0.3.1"))'
