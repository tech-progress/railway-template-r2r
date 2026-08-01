#!/usr/bin/env bash
set -euo pipefail

template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
required_files=(
  .dockerignore .env.example .gitignore .railway/railway.ts bun.lock CHANGELOG.md
  compose.yaml Dockerfile entrypoint.py FINDINGS.md LICENSE_REVIEW.md MARKETPLACE.md
  package.json PUBLISHING.md README.md r2r.toml.template sanitize-image.py SUPPORT.md
  template-defaults.json template-descriptions.json template-networking.json
  template-volumes.json UPGRADE.md VERSION scripts/audit-template.sh
  scripts/check-standalone.sh scripts/mock-openai.py scripts/restore-template-draft.sh
  scripts/smoke-client.py scripts/smoke.sh scripts/verify.sh
)
for file in "${required_files[@]}"; do
  test -f "${template_root}/${file}" || { echo "Missing required file: ${file}" >&2; exit 1; }
done

version="$(<"${template_root}/VERSION")"
[[ "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
grep -Eq "^## \[${version//./\\.}\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" "${template_root}/CHANGELOG.md"
for file in README.md PUBLISHING.md; do
  grep -Fq "current template release is \`v${version}\`" "${template_root}/${file}"
done
for heading in '# Deploy and Host' '## About Hosting' '## Why Deploy' '## Common Use Cases' '## Dependencies for' '### Deployment Dependencies'; do
  grep -Fq "${heading}" "${template_root}/MARKETPLACE.md"
done
publish_description="Authenticated R2R retrieval with pgvector and cited RAG."
(( ${#publish_description} <= 75 ))

POSTGRES_PASSWORD=verify-postgres R2R_SECRET_KEY=verify-secret \
R2R_ADMIN_EMAIL=admin@example.com R2R_ADMIN_PASSWORD=verify-password \
OPENAI_API_KEY=verify-key OPENAI_API_BASE= \
  docker compose -f "${template_root}/compose.yaml" config --quiet

for file in template-defaults.json template-descriptions.json template-networking.json template-volumes.json; do
  jq empty "${template_root}/${file}"
done
for file in "${template_root}"/scripts/*.sh; do bash -n "${file}"; done
python3 -m py_compile \
  "${template_root}/entrypoint.py" \
  "${template_root}/sanitize-image.py" \
  "${template_root}/scripts/mock-openai.py" \
  "${template_root}/scripts/smoke-client.py"

graph_json="$(cd "${template_root}" && ./node_modules/.bin/railway-iac-ts .railway/railway.ts)"
jq -e '
  .graph.resources |
  ([.[] | select(.type == "service") | .name] | sort) ==
    ["R2R API", "R2R Dashboard", "R2R Graph Clustering", "R2R PostgreSQL"] and
  ([.[] | select(.type == "volume") | .name]) == ["R2R PostgreSQL Data"] and
  ([.[] | select(.name == "R2R API")][0] |
    .source.repo == "tech-progress/railway-template-r2r" and
    .source.branch == "release-v1" and
    .build.dockerfilePath == "Dockerfile" and
    .deploy.healthcheckPath == "/v3/health") and
  ([.[] | select(.name == "R2R Dashboard")][0] |
    .deploy.healthcheckPath == "/" and
    .variables.NEXT_PUBLIC_R2R_DEFAULT_PASSWORD.value == "") and
  ([.[] | select(.name == "R2R PostgreSQL")][0] |
    .deploy.startCommand | contains("docker-entrypoint.sh postgres"))
' <<<"${graph_json}" >/dev/null

jq -e --slurpfile descriptions "${template_root}/template-descriptions.json" '
  to_entries | all(. as $service |
    (.value | keys | sort) == ($descriptions[0][$service.key] | keys | sort))
' "${template_root}/template-defaults.json" >/dev/null

for pin in \
  e7caf41aba36db5561a2579eeb3e4763c907ae4d4b241712a33e783fa381aa8a \
  a36250871de0833b8757561c72f2477ef1ddd1101afa4e617fb552e0de514c6b \
  53bcbcc114fe08906b6df6b4d3863644145b1efa240fd6643ef65986593938b6 \
  ba9bcb43c5e7d7d4eb9fe38970f976f6a0842297f3da078cb6223d1f078741d1; do
  grep -Rqs "${pin}" "${template_root}/Dockerfile" "${template_root}/compose.yaml" "${template_root}/.railway/railway.ts"
done

grep -Fq 'require_authentication = true' "${template_root}/r2r.toml.template"
grep -Fq 'os.environ.pop("R2R_POSTGRES_PASSWORD", None)' "${template_root}/entrypoint.py"
grep -Fq 'Initializing DatabaseProvider with config' "${template_root}/sanitize-image.py"

if find "${template_root}" -type f \( -name .env -o -name '*.local' \) -print -quit | grep -q .; then
  echo "Local secret file found in the template directory." >&2
  exit 1
fi
echo "R2R template structure, immutable images, auth, variables, volume, and networking are valid."

