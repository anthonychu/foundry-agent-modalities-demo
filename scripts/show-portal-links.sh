#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOYMENT="$ROOT/deployment"

get_value() {
  (cd "$DEPLOYMENT" && azd env get-value "$1")
}

subscription="$(get_value AZURE_SUBSCRIPTION_ID)"
resource_group="$(get_value AZURE_RESOURCE_GROUP)"
account="$(get_value AZURE_AI_ACCOUNT_NAME)"
project="$(get_value AZURE_AI_PROJECT_NAME)"
hosted_version="$(get_value AGENT_FIELD_DEMO_SUPPORT_TRIAGE_HOSTED_VERSION)"

for value_name in subscription resource_group account project hosted_version; do
  if [[ -z "${!value_name}" ]]; then
    echo "Missing $value_name. Complete provisioning and Hosted Agent deployment first." >&2
    exit 1
  fi
done

encoded_subscription="$(python3 - "$subscription" <<'PY'
import base64
import sys
import uuid

value = uuid.UUID(sys.argv[1]).bytes
print(base64.urlsafe_b64encode(value).rstrip(b"=").decode())
PY
)"

base="https://ai.azure.com/nextgen/r/${encoded_subscription},${resource_group},,${account},${project}/build/agents"

printf 'Prompt Agent — create, edit, version, and test in the portal:\n%s\n\n' \
  "$base/field-demo-support-triage-prompt/build"
printf 'Hosted Agent — test and operate the code-deployed agent in the portal:\n%s\n' \
  "$base/field-demo-support-triage-hosted/build?version=$hosted_version"
