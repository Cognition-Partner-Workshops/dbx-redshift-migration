#!/usr/bin/env bash
# Draft-transpile one unit: bash lakebridge/transpile.sh <unit>
set -euo pipefail

UNIT="${1:?usage: transpile.sh <unit>}"
MIG_CATALOG="${MIG_CATALOG:-mig_redshift_dev}"

mkdir -p ".migration/lakebridge/transpiled/${UNIT}" ".migration/lakebridge/errors"

databricks labs lakebridge transpile \
  --input-source "legacy/redshift/units/${UNIT}" \
  --output-folder ".migration/lakebridge/transpiled/${UNIT}" \
  --source-dialect redshift \
  --error-file-path ".migration/lakebridge/errors/${UNIT}.log" \
  --skip-validation false \
  --catalog-name "${MIG_CATALOG}" \
  --schema-name mart
