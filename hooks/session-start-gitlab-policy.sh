#!/usr/bin/env bash
set -euo pipefail

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"GITLAB POLICY: For any GitLab read or write, use mcp__plugin_claudeflow_gitlab__* tools only. Never shell out to curl/glab/wget/git for GitLab API calls. If an MCP tool fails or is unavailable, stop and report — do not fall back to shell."}}
JSON
