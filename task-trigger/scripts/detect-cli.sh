#!/bin/bash
# Detect available CLI tools and output full path
# Outputs: full path to opencode or kiro-cli, or "none"

set -e

if command -v opencode >/dev/null 2>&1; then
  command -v opencode
elif command -v kiro-cli >/dev/null 2>&1; then
  command -v kiro-cli
else
  echo "none"
  exit 1
fi
