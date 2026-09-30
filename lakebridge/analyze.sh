#!/usr/bin/env bash
# Lakebridge assessment of the legacy estate.
# --source-tech must match Analyzer.supported_source_technologies() exactly (case-sensitive);
# "Redshift" verified against databricks-labs-lakebridge 0.15.2 / databricks-bb-analyzer 0.3.0.
set -euo pipefail

mkdir -p .migration/lakebridge

databricks labs lakebridge analyze \
  --source-directory legacy/redshift \
  --source-tech Redshift \
  --report-file .migration/lakebridge/analyze.xlsx \
  --generate-json true
