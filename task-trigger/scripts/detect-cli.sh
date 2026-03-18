#!/bin/bash
# Detect available CLI tools and output full path
# Outputs: full path to opencode or kiro-cli, or "none"

set -e

if which opencode >/dev/null 2>&1; then
  which opencode
elif which kiro-cli >/dev/null 2>&1; then
  which kiro-cli
else
  echo "none"
  exit 1
fi
