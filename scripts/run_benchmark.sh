#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENDPOINT="${ENDPOINT:-http://127.0.0.1:8000/v1}"
MODEL="${MODEL:-nvidia/nemotron-3.5-lightning-30b-a3b}"
TOKENIZER="${TOKENIZER:?Set TOKENIZER to the local tokenizer/model directory}"
OUTPUT="${OUTPUT:-/tmp/nemotron-lightning-r0b0bench-out}"
R0B0BENCH_BIN="${R0B0BENCH_BIN:-r0b0bench}"

export R0B0BENCH_CHAT_TEMPLATE_KWARGS="${R0B0BENCH_CHAT_TEMPLATE_KWARGS:-{\"thinking\":true,\"enable_thinking\":true}}"
export R0B0BENCH_CANARY_MAX_TOKENS="${R0B0BENCH_CANARY_MAX_TOKENS:-8192}"
export R0B0BENCH_BFCL_PYTHON="${R0B0BENCH_BFCL_PYTHON:-$(command -v python3)}"
export R0B0BENCH_BFCL_SCRIPTS="${R0B0BENCH_BFCL_SCRIPTS:-$ROOT/benchmark/scripts/bfcl}"
export R0B0BENCH_SERVED_MODEL="${R0B0BENCH_SERVED_MODEL:-$MODEL}"
export BFCL_NUM_THREADS="${BFCL_NUM_THREADS:-1}"
export BFCL_MAX_TOKENS="${BFCL_MAX_TOKENS:-8192}"
export BFCL_HTTP_TIMEOUT="${BFCL_HTTP_TIMEOUT:-7200}"
export BFCL_MAX_RETRIES="${BFCL_MAX_RETRIES:-3}"

mkdir -p "$OUTPUT"
exec "$R0B0BENCH_BIN" run \
  --profile "${PROFILE:-core-subset}" \
  --base-url "$ENDPOINT" \
  --model "$MODEL" \
  --tokenizer "$TOKENIZER" \
  --output "$OUTPUT" \
  --timeout "${TIMEOUT:-7200}"
