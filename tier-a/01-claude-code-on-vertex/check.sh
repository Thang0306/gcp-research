#!/usr/bin/env bash
# Checks each prerequisite and makes ONE tiny Claude call (max 20 output tokens).
# Usage: ./check.sh PROJECT_ID [MODEL_ID] [LOCATION]
set -u
PROJECT_ID="${1:?usage: ./check.sh PROJECT_ID [MODEL_ID] [LOCATION]}"
MODEL="${2:-claude-sonnet-4-6}"
LOC="${3:-global}"

ok()   { printf '  \033[32mOK\033[0m   %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; }

echo "1. gcloud installed"
command -v gcloud >/dev/null && ok "$(gcloud --version 2>/dev/null | head -1)" || { bad "gcloud not on PATH (see README Step 0)"; exit 1; }

echo "2. gcloud login"
ACC=$(gcloud config get-value account 2>/dev/null)
[ -n "$ACC" ] && ok "logged in as $ACC" || bad "run: gcloud auth login"

echo "3. ADC (used by Claude Code and SDKs)"
TOKEN=$(gcloud auth application-default print-access-token 2>/dev/null) \
  && ok "ADC token works" || { bad "run: gcloud auth application-default login"; exit 1; }

echo "4. Billing on $PROJECT_ID"
BILL=$(gcloud billing projects describe "$PROJECT_ID" --format='value(billingEnabled)' 2>/dev/null)
[ "$BILL" = "True" ] && ok "billing enabled" || bad "billing not enabled (README Step 2)"

echo "5. Agent Platform API"
gcloud services list --enabled --project "$PROJECT_ID" --format='value(config.name)' 2>/dev/null \
  | grep -qx aiplatform.googleapis.com && ok "aiplatform.googleapis.com enabled" \
  || bad "run: gcloud services enable aiplatform.googleapis.com --project $PROJECT_ID"

echo "6. Call $MODEL in $LOC"
if [ "$LOC" = "global" ]; then HOST="aiplatform.googleapis.com"; else HOST="${LOC}-aiplatform.googleapis.com"; fi
URL="https://${HOST}/v1/projects/${PROJECT_ID}/locations/${LOC}/publishers/anthropic/models/${MODEL}:rawPredict"
RESP=$(curl -sS -w '\n%{http_code}' -X POST "$URL" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"anthropic_version":"vertex-2023-10-16","max_tokens":20,"messages":[{"role":"user","content":"Say hi in Vietnamese, 3 words max."}]}')
CODE=$(echo "$RESP" | tail -1); BODY=$(echo "$RESP" | sed '$d')
case "$CODE" in
  200) ok "HTTP 200: $(echo "$BODY" | python3 -c 'import sys,json; print(json.load(sys.stdin)["content"][0]["text"])' 2>/dev/null)";;
  403) bad "403: API off, no IAM role, or Marketplace terms not accepted. $BODY";;
  404) bad "404: model not enabled in Model Garden, wrong ID, or not offered in '$LOC'. $BODY";;
  429) bad "429: quota. Try LOCATION=global or request more quota. $BODY";;
  *)   bad "HTTP $CODE: $BODY";;
esac
