#!/usr/bin/env bash
# seed_splunk.sh — send sample events to Splunk via HEC, then verify they landed.
#
# Usage:
#   HEC_URL=https://your-splunk:8088 HEC_TOKEN=your-token ./seed_splunk.sh
#
# Defaults assume a local Splunk container with the standard demo HEC setup.
# Set SPLUNK_INDEX to change the target index (default: demo_ai_obs).

set -euo pipefail

HEC_URL="${HEC_URL:-https://localhost:8088/services/collector/event}"
HEC_TOKEN="${HEC_TOKEN:-security-lab-hec-token}"
SPLUNK_INDEX="${SPLUNK_INDEX:-demo_ai_obs}"
EVENTS_FILE="$(dirname "$0")/sample_events.jsonl"

log() { printf '[seed] %s\n' "$*"; }

if [ ! -f "$EVENTS_FILE" ]; then
  echo "ERROR: $EVENTS_FILE not found — run this script from the repo root or examples/ directory"
  exit 1
fi

log "Sending events to $HEC_URL (index=$SPLUNK_INDEX)"

ERRORS=0
while IFS= read -r event; do
  [ -z "$event" ] && continue

  # Inject the target index into each HEC payload
  payload="$(echo "$event" | python3 -c "
import json, sys
d = json.load(sys.stdin)
d['index'] = '${SPLUNK_INDEX}'
print(json.dumps(d))
")"

  response=$(curl -sk \
    -H "Authorization: Splunk $HEC_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$HEC_URL")

  code=$(echo "$response" | python3 -c "import json,sys; print(json.load(sys.stdin).get('code','?'))" 2>/dev/null || echo "?")
  if [ "$code" != "0" ]; then
    log "HEC error: $response"
    ERRORS=$((ERRORS + 1))
  fi
done < "$EVENTS_FILE"

if [ "$ERRORS" -gt 0 ]; then
  log "FAILED: $ERRORS events rejected by HEC"
  exit 1
fi

log "Done. Waiting 5 seconds for indexing..."
sleep 5

log ""
log "Verification query — run this in Splunk Search:"
log ""
log "  index=${SPLUNK_INDEX} trace_id=tr_file_share_001"
log "  | stats count by sourcetype"
log ""
log "Expected: ai:agent_log=6, ai:chat=3, ai:trace=5, edr:process=1  (total: 17)"
log ""
log "If counts differ, check: correct index name, HEC token has write access to $SPLUNK_INDEX,"
log "and Splunk has finished indexing (try again after 30s if counts are low)."
