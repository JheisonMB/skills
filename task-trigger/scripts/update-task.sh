#!/bin/bash
# Update individual fields of an existing task
# Usage: ./update-task.sh <task-id> [--prompt "new"] [--schedule "cron"] [--model "m"]
#        [--name "n"] [--timeout N] [--working-dir /path] [--force]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TASK_ID=""
NEW_PROMPT=""
NEW_SCHEDULE=""
NEW_MODEL=""
NEW_NAME=""
NEW_TIMEOUT=""
NEW_WORKING_DIR=""
FORCE=false

if [[ $# -gt 0 && "$1" != "--"* ]]; then
  TASK_ID="$1"; shift
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --prompt)       NEW_PROMPT="$2";       shift 2 ;;
    --schedule)     NEW_SCHEDULE="$2";     shift 2 ;;
    --model)        NEW_MODEL="$2";        shift 2 ;;
    --name)         NEW_NAME="$2";         shift 2 ;;
    --timeout)      NEW_TIMEOUT="$2";      shift 2 ;;
    --working-dir)  NEW_WORKING_DIR="$2";  shift 2 ;;
    --force)        FORCE=true;            shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <task-id> [--prompt \"...\"] [--schedule \"...\"] [--model \"...\"] [--name \"...\"] [--timeout N] [--working-dir /path] [--force]"
  exit 1
fi

if [[ -z "$NEW_PROMPT" && -z "$NEW_SCHEDULE" && -z "$NEW_MODEL" && -z "$NEW_NAME" && -z "$NEW_TIMEOUT" && -z "$NEW_WORKING_DIR" ]]; then
  echo "Error: Specify at least one field to update"
  exit 1
fi

TASKS_FILE="$HOME/.task-trigger/tasks.json"
if [[ ! -f "$TASKS_FILE" ]]; then
  echo "No tasks registered yet."
  exit 1
fi

# Pass values safely via env vars to avoid quote injection
export _UT_TASK_ID="$TASK_ID"
export _UT_TASKS_FILE="$TASKS_FILE"
export _UT_PROMPT="$NEW_PROMPT"
export _UT_SCHEDULE="$NEW_SCHEDULE"
export _UT_MODEL="$NEW_MODEL"
export _UT_NAME="$NEW_NAME"
export _UT_TIMEOUT="$NEW_TIMEOUT"
export _UT_WORKING_DIR="$NEW_WORKING_DIR"

RESULT=$(python3 << 'PYEOF'
import json, sys, os
from datetime import datetime, timezone

TASK_ID = os.environ["_UT_TASK_ID"]
TASKS_FILE = os.environ["_UT_TASKS_FILE"]
fields = {
    "prompt": os.environ.get("_UT_PROMPT") or None,
    "schedule": os.environ.get("_UT_SCHEDULE") or None,
    "model": os.environ.get("_UT_MODEL") or None,
    "name": os.environ.get("_UT_NAME") or None,
    "timeout": os.environ.get("_UT_TIMEOUT") or None,
    "working_dir": os.environ.get("_UT_WORKING_DIR") or None,
}

with open(TASKS_FILE, "r") as f:
    tasks = json.load(f)

task = next((t for t in tasks if t.get("id") == TASK_ID), None)
if not task:
    print(f'Task "{TASK_ID}" not found.')
    sys.exit(1)

schedule_changed = False
if fields["prompt"]:
    task.setdefault("execution", {})["prompt"] = fields["prompt"]
    print("  prompt updated")
if fields["schedule"]:
    task.setdefault("trigger", {})["expression"] = fields["schedule"]
    print(f'  schedule → {fields["schedule"]}')
    schedule_changed = True
if fields["model"]:
    task.setdefault("execution", {})["model"] = fields["model"]
    print(f'  model → {fields["model"]}')
if fields["name"]:
    task["name"] = fields["name"]
    print(f'  name → {fields["name"]}')
if fields["timeout"]:
    task.setdefault("execution", {})["timeout"] = int(fields["timeout"])
    print(f'  timeout → {fields["timeout"]}s')
if fields["working_dir"]:
    task.setdefault("execution", {})["workingDirectory"] = fields["working_dir"]
    print(f'  workingDirectory → {fields["working_dir"]}')

task["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
tmp = TASKS_FILE + ".tmp"
with open(tmp, "w") as f:
    json.dump(tasks, f, indent=2)
os.replace(tmp, TASKS_FILE)

print(f'Task "{TASK_ID}" updated.')
if schedule_changed:
    print("__SCHEDULE_CHANGED__")
PYEOF
)

# Show output (filter signal)
echo "$RESULT" | grep -v "__SCHEDULE_CHANGED__"

# Auto-reload scheduler if schedule changed
if echo "$RESULT" | grep -q "__SCHEDULE_CHANGED__"; then
  echo ""
  echo "Schedule changed — reloading in scheduler..."
  if [[ "$FORCE" == true ]]; then
    "$SCRIPT_DIR/reload-task.sh" "$TASK_ID" --force
  else
    "$SCRIPT_DIR/reload-task.sh" "$TASK_ID"
  fi
fi
