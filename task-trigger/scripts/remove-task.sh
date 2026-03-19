#!/bin/bash
# Remove a scheduled task
# Usage: ./remove-task.sh <task-id> [--force]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TASK_ID="$1"
FORCE=false

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --force|--no-confirm) FORCE=true; shift ;;
    *) if [[ -z "$TASK_ID" || "$TASK_ID" == "--"* ]]; then TASK_ID="$1"; fi; shift ;;
  esac
done

if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <task-id> [--force]"
  exit 1
fi

TASKS_FILE="$HOME/.task-trigger/tasks.json"

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "No tasks registered yet."
  exit 0
fi

if ! grep -q "\"id\": \"$TASK_ID\"" "$TASKS_FILE" 2>/dev/null; then
  echo "Task '$TASK_ID' not found."
  exit 1
fi

echo "Removing task: $TASK_ID"

if [[ "$FORCE" != true ]]; then
  echo "This will:"
  echo "1. Remove from tasks.json"
  echo "2. Remove from crontab (Linux/WSL) or launchd (macOS)"
  echo ""
  echo "Press Enter to continue or Ctrl+C to cancel..."
  read -r
fi

# Detect platform
PLATFORM=$("$SCRIPT_DIR/detect-platform.sh")

# Remove from crontab or launchd
case "$PLATFORM" in
  wsl|linux)
    echo "Removing from crontab..."
    TEMP_CRONTAB=$(mktemp)
    crontab -l 2>/dev/null | grep -v "# task-trigger: $TASK_ID$" | grep -v "task-trigger: $TASK_ID" > "$TEMP_CRONTAB" || true
    crontab "$TEMP_CRONTAB"
    rm -f "$TEMP_CRONTAB"
    ;;
  macos)
    echo "Removing from launchd..."
    PLIST_FILE="$HOME/.task-trigger/launchd/com.task-trigger.$TASK_ID.plist"
    if [[ -f "$PLIST_FILE" ]]; then
      launchctl unload "$PLIST_FILE" 2>/dev/null || true
      rm -f "$PLIST_FILE"
    fi
    ;;
esac

# Remove from tasks.json
if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required but not found in PATH"
  exit 1
fi
TEMP_JSON=$(mktemp)
python3 -c "
import json, sys
with open('$TASKS_FILE', 'r') as f:
    tasks = json.load(f)
filtered = [t for t in tasks if t.get('id') != '$TASK_ID']
if len(filtered) == len(tasks):
    print('Task not found in JSON')
    sys.exit(1)
with open('$TEMP_JSON', 'w') as f:
    json.dump(filtered, f, indent=2)
" && mv "$TEMP_JSON" "$TASKS_FILE"

echo "Task '$TASK_ID' removed successfully."
