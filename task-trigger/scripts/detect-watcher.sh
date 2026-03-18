#!/bin/bash
# Detect available file monitoring tools
# Outputs: inotifywait, fswatch, polling, or none

set -e

if which inotifywait >/dev/null 2>&1; then
  echo "inotifywait"
elif which fswatch >/dev/null 2>&1; then
  echo "fswatch"
elif which find >/dev/null 2>&1 && which stat >/dev/null 2>&1; then
  echo "polling"
else
  echo "none"
  exit 1
fi