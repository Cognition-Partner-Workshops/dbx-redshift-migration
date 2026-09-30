#!/usr/bin/env bash
# Lakebridge assessment of the legacy estate.
# TODO(operator): confirm --source-tech from `databricks labs lakebridge analyze --help`
# on your installed version; do not guess it.
set -euo pipefail

mkdir -p .migration/lakebridge

databricks labs lakebridge analyze \
  --source-directory legacy/redshift \
  --source-tech "<TODO: confirm from analyze --help>" \
  --report-file .migration/lakebridge/analyze.xlsx \
  --generate-json true
