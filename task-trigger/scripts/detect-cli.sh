#!/bin/bash
# Detect available CLI tools
# Outputs: opencode, kiro, or none

set -e

if which opencode >/dev/null 2>&1; then
  echo "opencode"
elif which kiro >/dev/null 2>&1; then
  echo "kiro"
else
  echo "none"
  exit 1
fi