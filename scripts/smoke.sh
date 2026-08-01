#!/usr/bin/env bash
set -euo pipefail

template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${template_root}"

docker compose exec -T \
  -e R2R_SMOKE_URL="${R2R_SMOKE_URL:-http://127.0.0.1:7272}" \
  -e R2R_ADMIN_EMAIL="${R2R_ADMIN_EMAIL:?R2R_ADMIN_EMAIL is required}" \
  -e R2R_ADMIN_PASSWORD="${R2R_ADMIN_PASSWORD:?R2R_ADMIN_PASSWORD is required}" \
  r2r python /app/railway-smoke-client.py

