#!/usr/bin/env bash
# SessionStart hook: emit JSON whose `additionalContext` field is injected
# into the model context at the start of each session.
#
# Customize the body below with whatever context you want Claude to see.
# The script must print a single JSON object on stdout.

set -euo pipefail

CURRENT_DATE=$(date "+%Y-%m-%d")
TRAINING_CUTOFF="2026-01-01"  # For Claude Opus-4.7
MONTHS_GAP=$(( ($(date -d "$CURRENT_DATE" +%s) - $(date -d "$TRAINING_CUTOFF" +%s)) / (30*24*3600) ))

context=$(cat <<EOF
Current date: ${CURRENT_DATE}
Your knowledge cutoff: ${TRAINING_CUTOFF}
Time gap: ~${MONTHS_GAP} months of potential changes

HIGH-RISK LIBRARIES (frequent breaking changes):
Pydantic, FastAPI, NumPy, Pandas, ONNX, TensorRT

CRITICAL EPISTEMIC WARNING:
Your training data is ${MONTHS_GAP}+ months old. During this period:
- Libraries have released new major versions
- APIs have changed, been deprecated, or added new features
- Best practices may have evolved
- New tools and frameworks may have emerged

MANDATORY VERIFICATION PROTOCOL:
1. For ANY question about versions, APIs, current state → SEARCH FIRST
2. Never claim "this doesn't exist" without verification
3. If code looks unfamiliar → assume it's valid modern syntax
4. Mark uncertain claims: "Based on training (may be outdated)..."
EOF
)

jq -n --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
