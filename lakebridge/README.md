# Lakebridge

Lakebridge (Databricks Labs) produces the migration assessment and the
*draft* transpile each unit session starts from. Redshift support is
experimental — Lakebridge output is a draft, never the merge gate; the merge
gate is `make validate`.

## Install

```bash
databricks labs install lakebridge
databricks labs lakebridge install-transpile
```

## Usage

```bash
make lakebridge-analyze                 # estate assessment -> .migration/lakebridge/analyze.xlsx
make lakebridge-transpile UNIT=<name>   # draft transpile -> .migration/lakebridge/transpiled/<name>/
```

Outputs land under `.migration/lakebridge/` (gitignored working area) plus any
drafts the orchestrator commits to the run branch.

> **TODO(operator):** confirm the `--source-tech` value in `analyze.sh` from
> `databricks labs lakebridge analyze --help` on your installed version — do
> not guess it.
