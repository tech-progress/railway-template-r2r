#!/usr/bin/env bash
set -euo pipefail

template_id="${1:?Usage: ./scripts/audit-template.sh TEMPLATE_ID [EXPECTED_STATUS]}"
expected_status="${2:-}"
template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_json="$(railway api 'query Audit($id: String!) { template(id: $id) { name status serializedConfig } }' --var "id=${template_id}" --compact)"
graph_json="$(cd "${template_root}" && ./node_modules/.bin/railway-iac-ts .railway/railway.ts)"

[[ "$(jq -r '.data.template.name' <<<"${template_json}")" == "R2R RAG backend" ]]
[[ -z "${expected_status}" || "$(jq -r '.data.template.status' <<<"${template_json}")" == "${expected_status}" ]]
expected_services=$'R2R API\nR2R Dashboard\nR2R Graph Clustering\nR2R PostgreSQL'
[[ "$(jq -r '.data.template.serializedConfig.services | [.[] | .name] | sort | join("\n")' <<<"${template_json}")" == "${expected_services}" ]]

failures=0
while IFS= read -r service_name; do
  desired="$(jq -c --arg service "${service_name}" '.graph.resources[] | select(.type == "service" and .name == $service)' <<<"${graph_json}")"
  actual="$(jq -c --arg service "${service_name}" '[.data.template.serializedConfig.services[] | select(.name == $service)][0]' <<<"${template_json}")"
  if [[ "$(jq -r '.source.type' <<<"${desired}")" == "image" ]]; then
    [[ "$(jq -r '.source.image' <<<"${actual}")" == "$(jq -r '.source.image' <<<"${desired}")" ]] || failures=$((failures + 1))
  else
    expected_repo="$(jq -r '.source.repo' <<<"${desired}")"
    actual_repo="$(jq -r '.source.repo | sub("^https://github.com/"; "") | sub("\\.git$"; "")' <<<"${actual}")"
    [[ "${actual_repo}" == "${expected_repo}" ]] || failures=$((failures + 1))
    for field in branch rootDirectory; do
      [[ "$(jq -r --arg field "${field}" '.source[$field]' <<<"${actual}")" == "$(jq -r --arg field "${field}" '.source[$field]' <<<"${desired}")" ]] || failures=$((failures + 1))
    done
    for field in builder dockerfilePath; do
      [[ "$(jq -r --arg field "${field}" '.build[$field]' <<<"${actual}")" == "$(jq -r --arg field "${field}" '.build[$field]' <<<"${desired}")" ]] || failures=$((failures + 1))
    done
  fi
  for field in startCommand healthcheckPath healthcheckTimeout; do
    [[ "$(jq -r --arg field "${field}" '.deploy[$field] // ""' <<<"${actual}")" == "$(jq -r --arg field "${field}" '.deploy[$field] // ""' <<<"${desired}")" ]] || failures=$((failures + 1))
  done
  while IFS= read -r variable; do
    key="$(jq -r '.key' <<<"${variable}")"; expected="$(jq -r '.value' <<<"${variable}")"
    value="$(jq -r --arg key "${key}" '.variables[$key].defaultValue // "__MISSING__"' <<<"${actual}")"
    if [[ -z "${expected}" ]]; then
      [[ "${value}" == "__MISSING__" || -z "${value}" ]] || failures=$((failures + 1))
    else
      [[ "${value}" == "${expected}" ]] || failures=$((failures + 1))
    fi
    description="$(jq -r --arg key "${key}" '.variables[$key].description // ""' <<<"${actual}")"
    expected_description="$(jq -r --arg service "${service_name}" --arg key "${key}" '.[$service][$key]' "${template_root}/template-descriptions.json")"
    [[ "${description}" == "${expected_description}" ]] || failures=$((failures + 1))
  done < <(jq -c --arg service "${service_name}" '.[$service] | to_entries[]' "${template_root}/template-defaults.json")
done <<<"${expected_services}"

expected_volume="$(jq -c '."R2R PostgreSQL"' "${template_root}/template-volumes.json")"
actual_volume="$(jq -c '[.data.template.serializedConfig.services[] | select(.name == "R2R PostgreSQL") | .volumeMounts[] | {mountPath,sizeMB}][0]' <<<"${template_json}")"
[[ "${actual_volume}" == "${expected_volume}" ]] || failures=$((failures + 1))

for service_name in "R2R API" "R2R Dashboard"; do
  expected_port="$(jq -r --arg service "${service_name}" '.[$service].publicPort' "${template_root}/template-networking.json")"
  actual_port="$(jq -r --arg service "${service_name}" '[.data.template.serializedConfig.services[] | select(.name == $service) | .networking.serviceDomains["<hasDomain>"].port][0] // 0' <<<"${template_json}")"
  [[ "${actual_port}" == "${expected_port}" ]] || failures=$((failures + 1))
done
public_count="$(jq '[.data.template.serializedConfig.services[] | select(.networking.serviceDomains["<hasDomain>"] != null)] | length' <<<"${template_json}")"
[[ "${public_count}" == "2" ]] || failures=$((failures + 1))

(( failures == 0 )) || { echo "R2R template audit failed with ${failures} mismatch(es)." >&2; exit 1; }
echo "Template ${template_id} matches the R2R source, pins, defaults, volume, and networking."

