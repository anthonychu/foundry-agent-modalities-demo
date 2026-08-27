#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_PYTHON="$ROOT/prompt_agent/.venv/bin/python"
HOSTED_SERVICE="field-demo-support-triage-hosted"
CASE='Triage this support case. Customer: Contoso Retail. Annual contract: $240,000. Production outage: 95 minutes. Regulated regions affected: 2. Renewal in: 21 days. Summarize the priority, reason codes, first response, and next three actions.'

if [[ ! -x "$PROMPT_PYTHON" ]]; then
  echo "Prompt Agent environment not found. Complete the README setup first." >&2
  exit 1
fi

if [[ ! -f "$ROOT/prompt_agent/.env" ]]; then
  echo "prompt_agent/.env is missing. Run scripts/configure-local-env.sh first." >&2
  exit 1
fi

printf '\n============================================================\n'
printf '1 of 2: Prompt Agent — policy in instructions\n'
printf '============================================================\n\n'
"$PROMPT_PYTHON" "$ROOT/prompt_agent/invoke.py"

printf '\n============================================================\n'
printf '2 of 2: Hosted Agent — policy in customer-owned Python\n'
printf '============================================================\n\n'
(
  cd "$ROOT/deployment"
  AZURE_DEV_USER_AGENT=microsoft_foundry_skill \
    azd ai agent invoke "$HOSTED_SERVICE" \
      --new-session \
      --new-conversation \
      "$CASE"
)

printf '\nBoth agents received the same fictional case.\n'
printf 'Compare where the policy lives and who owns it — not which paragraph sounds better.\n'
