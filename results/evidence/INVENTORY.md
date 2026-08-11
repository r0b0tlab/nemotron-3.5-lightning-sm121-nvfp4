# Evidence inventory and omissions

The repository is a sanitized reproducibility snapshot. The report JSONs are preserved as sanitized provenance records; some original artifact paths point to local raw outputs that are intentionally not copied here.

Included:

- Reconciled report and reconciliation manifest.
- Full-run report and protocol metadata.
- Selected full-run lane summaries for canary, BFCL score summaries, latency, concurrency, throughput, NIAH, QA, IFEval, and HumanEval.
- The full native-thinking run's own GSM8K lane (182/200 = 91.0%, 5 disclosed length-finish rows at the 8,192 ceiling) under `full-native-thinking/lanes/gsm8k/`, completing the 11-lane pack.
- GSM8K replacement report, audit, lane result, and raw 200-row GSM8K lane artifact (49,152-token retest, 189/200 = 94.5%, the campaign-accepted GSM8K).
- 1M-window NIAH capacity probe: sanitized report, lane result, raw depth row, and smoke/pace/boundary probe rows (2026-08-11).
- Campaign handoff and campaign manifest.

Intentionally omitted:

- Model weights and tokenizer files.
- Benchmark datasets other than the selected GSM8K lane output; users must provide licensed datasets locally.
- Raw BFCL project directories, score CSVs, and full conversation traces.
- Runtime logs, controller logs, caches, temporary files, and container exports.
- Credentials, tokens, passwords, private endpoints, and machine-specific absolute paths.

Any report field that refers to an omitted raw artifact is provenance from the original local run, not a claim that the omitted file is present in this repository. Reproduction scripts generate fresh outputs outside the checkout.
