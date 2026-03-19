#!/bin/bash
# Detect available file monitoring tools
# Outputs: inotifywait, fswatch, polling, or none

set -e

if command -v inotifywait >/dev/null 2>&1; then
  echo "inotifywait"
elif command -v fswatch >/dev/null 2>&1; then
  echo "fswatch"
elif command -v find >/dev/null 2>&1 && command -v stat >/dev/null 2>&1; then
  echo "polling"
else
  echo "none"
  exit 1
fi
