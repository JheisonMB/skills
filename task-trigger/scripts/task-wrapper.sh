#!/bin/bash
# Wrapper script that launchd/crontab calls instead of the CLI directly.
# Checks expiration, auto-cleans expired tasks, logs execution with separators.
# Usage: ./task-wrapper.sh <task-id>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TASK_ID="$1"
if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <task-id>"
  exit 1
fi

TASKS_FILE="$HOME/.task-trigger/tasks.json"

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "No tasks file found."
  exit 1
fi

python3 - "$TASK_ID" "$SCRIPT_DIR" << 'PYEOF'
import json, sys, os, subprocess, time
from datetime import datetime, timezone

TASK_ID = sys.argv[1]
SCRIPT_DIR = sys.argv[2]
TASKS_FILE = os.path.expanduser("~/.task-trigger/tasks.json")

with open(TASKS_FILE, "r") as f:
    tasks = json.load(f)

task = next((t for t in tasks if t.get("id") == TASK_ID), None)
if not task:
    print(f"Task '{TASK_ID}' not found.")
    sys.exit(1)

log_path = task.get("log_path", f"$HOME/.task-trigger/logs/{TASK_ID}.log")
log_path = log_path.replace("$HOME", os.path.expanduser("~"))
log_path = os.path.expanduser(log_path)
os.makedirs(os.path.dirname(log_path), exist_ok=True)

# Mejora 10: Separador entre ejecuciones
separator = f"\n{'=' * 10} RUN {datetime.now().strftime('%Y-%m-%dT%H:%M:%S')} {'=' * 10}\n"
with open(log_path, "a") as f:
    f.write(separator)

# Mejora 1: Check expiration before executing
trigger = task.get("trigger", {})
expires_at = trigger.get("expires_at")
if expires_at:
    try:
        exp_time = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
        if datetime.now(timezone.utc) > exp_time:
            ts = time.strftime("[%Y-%m-%d %H:%M:%S]")
            with open(log_path, "a") as f:
                f.write(f"{ts} task={TASK_ID} status=expired\n")

            # Disable in tasks.json
            task["enabled"] = False
            with open(TASKS_FILE, "w") as f:
                json.dump(tasks, f, indent=2)

            # Auto-remove from scheduler (mejora 3: real cleanup)
            remove_script = os.path.join(SCRIPT_DIR, "remove-task.sh")
            if os.path.exists(remove_script):
                subprocess.run([remove_script, TASK_ID, "--force"], timeout=30)

            sys.exit(0)
    except Exception as e:
        with open(log_path, "a") as f:
            f.write(f"[warning] Could not parse expires_at: {e}\n")

if not task.get("enabled", True):
    ts = time.strftime("[%Y-%m-%d %H:%M:%S]")
    with open(log_path, "a") as f:
        f.write(f"{ts} task={TASK_ID} status=skipped reason=disabled\n")
    sys.exit(0)

# Cron-check: when launchd runs this every 60s for complex cron expressions,
# verify the current time matches the cron expression before executing.
cron_expr = trigger.get("expression", "")
if cron_expr:
    parts = cron_expr.split()
    if len(parts) == 5:
        now = datetime.now()

        def matches_field(field, value, max_val):
            """Check if a cron field matches a given value."""
            if field == "*":
                return True
            for item in field.split(","):
                if "/" in item:
                    base, step = item.split("/", 1)
                    step = int(step)
                    start = 0 if base == "*" else int(base)
                    if (value - start) % step == 0 and value >= start:
                        return True
                elif "-" in item:
                    lo, hi = item.split("-", 1)
                    if int(lo) <= value <= int(hi):
                        return True
                else:
                    if int(item) == value:
                        return True
            return False

        minute_ok = matches_field(parts[0], now.minute, 59)
        hour_ok = matches_field(parts[1], now.hour, 23)
        dom_ok = matches_field(parts[2], now.day, 31)
        month_ok = matches_field(parts[3], now.month, 12)
        # cron weekday: 0=Sunday, python isoweekday: 1=Mon..7=Sun
        py_dow = now.isoweekday() % 7  # convert to 0=Sun
        dow_ok = matches_field(parts[4], py_dow, 6)

        if not (minute_ok and hour_ok and dom_ok and month_ok and dow_ok):
            ts = time.strftime("[%Y-%m-%d %H:%M:%S]")
            with open(log_path, "a") as f:
                f.write(f"{ts} task={TASK_ID} status=skipped reason=cron_no_match\n")
            sys.exit(0)

# Execute via run-task.sh
run_script = os.path.join(SCRIPT_DIR, "run-task.sh")
result = subprocess.run([run_script, TASK_ID])
sys.exit(result.returncode)
PYEOF
