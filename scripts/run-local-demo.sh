#!/usr/bin/env bash
# Start the Hosted Agent on localhost:8088, send it the Contoso case, then stop it.
#   bash scripts/run-local-demo.sh        # 95-minute outage (P0, score 8)
#   bash scripts/run-local-demo.sh 30     # 30-minute outage (P1, score 5)
set -euo pipefail

OUTAGE_MINUTES="${1:-95}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-300}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOYMENT="$ROOT/deployment"
SOURCE="$DEPLOYMENT/src/agent-framework-agent-with-local-tools-responses"
VENV="$SOURCE/.venv"

if [[ -x "$VENV/bin/python" ]]; then VENV_BIN="$VENV/bin"
elif [[ -x "$VENV/Scripts/python.exe" ]]; then VENV_BIN="$VENV/Scripts"
else echo "Hosted Agent venv not found at $VENV. Follow ai-deployment.md first." >&2; exit 1; fi

[[ -f "$SOURCE/.env" ]] || { echo "$SOURCE/.env is missing. Follow ai-deployment.md first." >&2; exit 1; }

PROMPT="$("$VENV_BIN/python" - "$ROOT/sample_case.json" "$OUTAGE_MINUTES" <<'PY'
import json, sys
case = json.load(open(sys.argv[1], encoding="utf-8"))
print(
    f"Triage this support case. Customer: {case['customer']}. "
    f"Annual contract: ${case['annual_contract_usd']:,}. "
    f"Production outage: {sys.argv[2]} minutes. "
    f"Regulated regions affected: {case['regulated_regions']}. "
    f"Renewal in: {case['renewal_days']} days. {case['request']}"
)
PY
)"

export VIRTUAL_ENV="$VENV" PATH="$VENV_BIN:$PATH" PYTHONIOENCODING=utf-8
export AZURE_DEV_USER_AGENT=microsoft_foundry_skill

LOG="$(mktemp -t local-agent.XXXXXX)"
echo "Starting local Hosted Agent (log: $LOG)..."
(cd "$DEPLOYMENT" && exec azd ai agent run --no-client) >"$LOG" 2>&1 &
SERVER_PID=$!

stop_server() {
  echo "Stopping local agent..."
  pkill -TERM -P "$SERVER_PID" 2>/dev/null || true
  kill "$SERVER_PID" 2>/dev/null || true
}
trap stop_server EXIT

for ((i = 0; i < TIMEOUT_SECONDS; i += 2)); do
  grep -q 'Running on http' "$LOG" && break
  kill -0 "$SERVER_PID" 2>/dev/null || { tail -30 "$LOG"; echo "Local agent exited early." >&2; exit 1; }
  sleep 2
done
grep -q 'Running on http' "$LOG" || { echo "Agent not ready after ${TIMEOUT_SECONDS}s. See $LOG" >&2; exit 1; }

printf 'Ready on http://localhost:8088\n\nPrompt: %s\n\n' "$PROMPT"
(cd "$DEPLOYMENT" && azd ai agent invoke field-demo-support-triage-hosted \
  --local --new-session --new-conversation "$PROMPT")

sleep 1
printf '\nPython tool calls (calculate_case_priority): %s\n' \
  "$(grep -c 'Function calculate_case_priority succeeded' "$LOG" || true)"
