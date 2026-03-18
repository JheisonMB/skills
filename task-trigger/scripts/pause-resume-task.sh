#!/bin/bash
# Pause or resume a task (disable/enable without removing)
# Usage: ./pause-resume-task.sh <task-id> --pause|--resume [--force]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TASK_ID=""
ACTION=""
FORCE=false

if [[ $# -gt 0 && "$1" != "--"* ]]; then
  TASK_ID="$1"; shift
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --pause)  ACTION="pause";  shift ;;
    --resume) ACTION="resume"; shift ;;
    --force)  FORCE=true;      shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$TASK_ID" || -z "$ACTION" ]]; then
  echo "Usage: $0 <task-id> --pause|--resume [--force]"
  exit 1
fi

TASKS_FILE="$HOME/.task-trigger/tasks.json"
if [[ ! -f "$TASKS_FILE" ]]; then
  echo "No tasks registered yet."
  exit 1
fi

PLATFORM=$("$SCRIPT_DIR/detect-platform.sh")

# Update enabled field in JSON — uses env vars like update-task.sh
export _PR_TASKS_FILE="$TASKS_FILE"
export _PR_TASK_ID="$TASK_ID"
export _PR_ACTION="$ACTION"

python3 << 'PYEOF'
import json, sys, os
from datetime import datetime, timezone

TF = os.environ["_PR_TASKS_FILE"]
TID = os.environ["_PR_TASK_ID"]
ACT = os.environ["_PR_ACTION"]

with open(TF, "r") as f:
    tasks = json.load(f)
task = next((t for t in tasks if t.get("id") == TID), None)
if not task:
    print(f'Task "{TID}" not found.')
    sys.exit(1)

new_state = ACT == "resume"
if task.get("enabled", True) == new_state:
    state_word = "enabled" if new_state else "paused"
    print(f'Task "{TID}" is already {state_word}.')
    sys.exit(0)

task["enabled"] = new_state
task["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
tmp = TF + ".tmp"
with open(tmp, "w") as f:
    json.dump(tasks, f, indent=2)
os.replace(tmp, TF)
print(f'Task "{TID}" {"resumed" if new_state else "paused"} in tasks.json.')
PYEOF

if [[ "$ACTION" == "pause" ]]; then
  case "$PLATFORM" in
    wsl|linux)
      TEMP_CRONTAB=$(mktemp)
      crontab -l 2>/dev/null | grep -v "# task-trigger: $TASK_ID$" | grep -v "task-trigger: $TASK_ID" > "$TEMP_CRONTAB" || true
      crontab "$TEMP_CRONTAB"
      rm -f "$TEMP_CRONTAB"
      echo "Removed from crontab."
      ;;
    macos)
      LABEL="com.task-trigger.$TASK_ID"
      PLIST_FILE="$HOME/.task-trigger/launchd/$LABEL.plist"
      if launchctl list "$LABEL" &>/dev/null; then
        launchctl remove "$LABEL" 2>/dev/null || true
      elif [[ -f "$PLIST_FILE" ]]; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
      fi
      echo "Unloaded from launchd."
      ;;
  esac
elif [[ "$ACTION" == "resume" ]]; then
  if [[ "$FORCE" == true ]]; then
    "$SCRIPT_DIR/reload-task.sh" "$TASK_ID" --force
  else
    "$SCRIPT_DIR/reload-task.sh" "$TASK_ID"
  fi
fi
