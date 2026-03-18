#!/bin/bash
# Verify a task is actually registered and active in the OS scheduler
# Usage: ./verify-task.sh <task-id>
# Exit 0 = active, Exit 1 = not found in scheduler

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TASK_ID="$1"
if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <task-id>"
  exit 1
fi

PLATFORM=$("$SCRIPT_DIR/detect-platform.sh")

case "$PLATFORM" in
  wsl|linux)
    if crontab -l 2>/dev/null | grep -q "task-trigger: $TASK_ID"; then
      echo "✓ Task '$TASK_ID' is registered in crontab"
      exit 0
    else
      echo "✗ Task '$TASK_ID' NOT found in crontab"
      exit 1
    fi
    ;;
  macos)
    LABEL="com.task-trigger.$TASK_ID"
    # Direct label lookup — O(1) instead of grepping full list
    if launchctl list "$LABEL" &>/dev/null; then
      echo "✓ Task '$TASK_ID' is active in launchd (label: $LABEL)"
      exit 0
    else
      PLIST_FILE="$HOME/.task-trigger/launchd/$LABEL.plist"
      if [[ -f "$PLIST_FILE" ]]; then
        echo "⚠ Task '$TASK_ID' has plist but is NOT loaded in launchd"
        echo "  Fix: launchctl load $PLIST_FILE"
        exit 1
      else
        echo "✗ Task '$TASK_ID' NOT found in launchd"
        exit 1
      fi
    fi
    ;;
esac
