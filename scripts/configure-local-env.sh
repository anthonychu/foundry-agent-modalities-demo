#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOYMENT="$ROOT/deployment"
HOSTED_SOURCE="$DEPLOYMENT/src/agent-framework-agent-with-local-tools-responses"

if ! command -v azd >/dev/null 2>&1; then
  echo "Azure Developer CLI (azd) is required." >&2
  exit 1
fi

endpoint="$(cd "$DEPLOYMENT" && azd env get-value FOUNDRY_PROJECT_ENDPOINT)"
model="$(cd "$DEPLOYMENT" && azd env get-value AZURE_AI_MODEL_DEPLOYMENT_NAME)"

if [[ -z "$endpoint" || -z "$model" ]]; then
  echo "The Foundry project is not configured. Run azd provision from deployment/ first." >&2
  exit 1
fi

cat > "$ROOT/prompt_agent/.env" <<EOF
FOUNDRY_PROJECT_ENDPOINT=$endpoint
FOUNDRY_MODEL_NAME=$model
FOUNDRY_PROMPT_AGENT_NAME=field-demo-support-triage-prompt
DELETE_AFTER_RUN=false
EOF

cat > "$HOSTED_SOURCE/.env" <<EOF
FOUNDRY_PROJECT_ENDPOINT=$endpoint
AZURE_AI_MODEL_DEPLOYMENT_NAME=$model
EOF

printf 'Configured local demo files for model %s.\n' "$model"
printf 'No credentials or tokens were written.\n'
