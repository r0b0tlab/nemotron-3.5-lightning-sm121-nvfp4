# Nemotron Lightning campaign handoff

Status: COMPLETE_WITH_DISCLOSURES

Model: nvidia/nemotron-3.5-lightning-30b-a3b
Hardware: NVIDIA GB10 / SM121
Image: nemotron-lightning-vllm:private-sm121-mtp
Image ID: sha256:442df05bcaaf4ca33d1e7eb6d18ea0f4272be6b1503b6604dc191acbd4e47640
Benchmark: r0b0bench 1.0.0rc2 with in-tree Nemotron/BFCL compatibility corrections

Primary eligible row
--------------------

Run:
results/local-campaign/nemotron-lightning-mtp-k1-general-thinking-off-full-core-subset-clean2-20260810T083800Z/report.json

Profile: full core-subset, native MTP K=1, thinking explicitly off
Server: MAX_MODEL_LEN=50016, MAX_NUM_BATCHED_TOKENS=8192, MAX_NUM_SEQS=6, GPU_MEMORY_UTILIZATION=0.70, FP8 KV, Marlin target, Triton MTP drafter, CUDA graphs, prefix caching

Verdict: invalid_for_publish=false, infra_errors_total=0, all 11 lanes PASS.

Quality:
- QA ARC-Easy: 381/400 = 95.25%
- IFEval lightweight scorer: 155/200 = 77.5% (not official full IFEval)
- HumanEval functional: pass@1 0.8597560975609756 over 164
- GSM8K flexible extract: 189/200 = 94.5%

Official BFCL:
- Multi-turn base: 142/200 = 71.0%
- AST micro: 165/600 = 27.5%
- AST multiple: 34/200 = 17.0%
- AST parallel: 97/200 = 48.5%
- AST parallel_multiple: 34/200 = 17.0%

Systems:
- Latency stable stream: TTFT 92.329 ms; E2E 1127.051 ms; fragment ITL mean 18.545 ms; p95 19.575 ms
- Concurrency aggregate output tok/s: C1 103.411; C2 180.465; C4 304.276; C6 376.315
- Dedicated C1 decode: median 90.954 tok/s, 2048 output tokens, 5 reps with first dropped, 4 stable
- Prefill proxy: 28,815.643 prompt tok/s at 24,541 prompt tokens, 3 reps with first dropped, 2 stable; this is an e2e wall proxy, not a pure prefill-kernel metric
- NIAH: PASS at 12,440 / 24,880 / 44,784 constructed prompt tokens; max_model_len 50,016; generation reserve 256; live KV cache size 11,753,760 tokens

Matched base-AR control
-----------------------

Run:
results/local-campaign/nemotron-lightning-base-ar-general-thinking-off-perf-20260810T083800Z/report.json

The base row is a selected latency/concurrency/throughput comparison, not a full core-subset profile, so it is diagnostic/invalid_for_publish by contract. All three selected lanes PASS with zero infrastructure errors.

- C1 decode median: 81.212 tok/s
- C1 prefill proxy: 5,033.532 prompt tok/s
- Stream TTFT: 74.561 ms
- Stream E2E: 1222.291 ms
- Concurrency aggregate: C1 80.973; C2 147.971; C4 243.486; C6 278.399 tok/s

Matched MTP K=1 vs base-AR deltas:
- decode median: +11.995%
- aggregate concurrency: +27.710% / +21.960% / +24.967% / +35.171% at C1/C2/C4/C6
- TTFT: +23.830%
- E2E: -7.792%
- prefill proxy: +472.474% as measured; interpret cautiously because this proxy includes request wall time and short decode

Native thinking-on row
----------------------

Run:
results/local-campaign/nemotron-lightning-mtp-k1-general-thinking-on-full-core-subset-20260810T034056Z/report.json

This is a preserved diagnostic full run, not a publication row:
- systems lanes, BFCL, latency, concurrency, throughput, NIAH, QA, IFEval, and GSM8K all executed;
- BFCL-MT 142/200 and AST micro 165/600;
- canary failed only the structured check because the native reasoning trace consumed the short 256-token canary budget; tool-call passed;
- QA 0/400, IFEval 30/200, GSM8K 58/200 show the known native-thinking short-budget artifact;
- HumanEval generated 164 HTTP-200 samples but the scorer import was missing at launch, so that lane was ERROR;
- controller exit was 2 and report invalid_for_publish=true.

Corrected native-thinking evidence
----------------------------------

The separate no-artificial-truncation worktree propagated native `thinking=true` and `enable_thinking=true` controls and retained the successful lanes from the corrected full run:

Run:
results/evidence/full-native-thinking/report.json

Source diff SHA-256: `a89df0b6ac9846d5ee3342ecf997a948f993c21b093700a6e53a538db452f149`

- Canary, BFCL-MT, BFCL-AST, latency, concurrency, throughput, NIAH, QA, IFEval, and HumanEval completed PASS with zero infrastructure errors.
- The initial corrected GSM8K lane had 5/200 `finish_reason=length` rows at the 8,192-token ceiling, so it was not accepted as the final GSM8K result.
- Those successful non-GSM lanes were not rerun or mixed with another endpoint epoch.

GSM8K higher-budget retest
--------------------------

Run:
results/evidence/gsm8k-retest/report.json

Audit:
results/evidence/gsm8k-retest/gsm8k-retest-audit.json

- Lane status: **PASS** at 49,152 requested output tokens; 189/200 = 94.5%, Wilson 95% CI [0.904212, 0.969015].
- 200/200 HTTP responses completed with zero infrastructure errors.
- Finish reasons: 199 `stop`, 1 `length`; the single persistent row exhausted the generous allowance with no visible answer and is counted as a scoreable model nontermination, not a lane-wide harness truncation.
- Budget ladder for length-limited rows: 5 at 8,192 → 2 at 32,768 → 1 at 49,152.
- This was a GSM8K-only `--only` retest, so its report remains `invalid_for_publish=true` as a standalone full-suite publication row. It is the accepted lane-level GSM8K result for this campaign, with the model-nontermination disclosure above.
- Local reconciled 11-lane result, with this PASS lane substituted for the prior GSM8K lane:
  `results/evidence/reconciled/report.json`
- Reconciliation manifest:
  `results/evidence/reconciled/reconciliation-manifest.json`
- All 11 reconciled lane statuses are PASS with zero infrastructure errors. This remains local secondary evidence with full per-lane provenance; nothing was uploaded.

MTP K ladder
------------

Evidence root:
results/local-campaign/epoch-3-mtp-k-ladder

K=1 was retained as the primary because it owns the complete valid full-suite evidence. K=2, K=3, and K=4 each completed a bounded 3-request semantic/telemetry probe:
- K2: 6 drafted / 6 accepted, 100%;
- K3: 9 drafted / 9 accepted, 100%;
- K4: 12 drafted / 12 accepted, 100%.

Every K probe had exact outputs, HTTP 200, zero prefix-cache hits, zero preemptions, and positive scoped decode/prefill metrics. These short deterministic probes do not establish an optimal K; no K2/K3/K4 full C1/C6 repeat matrix is claimed.

The primary K=1 server was restored and verified at:
results/local-campaign/epoch-3-mtp-k-ladder/k1-restored/probe.json

Blocker disposition
-------------------

- Missing HumanEval scorer: repaired by installing human-eval; subsequent clean full run passed HumanEval.
- BFCL vLLM template kwargs: repaired to use OpenAI SDK extra_body; clean2 BFCL-MT/AST passed.
- Two failed thinking-off handoff attempts caused only diagnostic adapter/transition artifacts; neither was merged into the primary row.
- One base handoff shell condition was corrected; no model traffic was lost and the endpoint was restored.
- pip check retains the unrelated pre-existing warning: nvidia-cusparselt-cu13 0.8.1 is not supported on this platform.

Canonical machine-readable handoff:
results/local-campaign/campaign-handoff.json
