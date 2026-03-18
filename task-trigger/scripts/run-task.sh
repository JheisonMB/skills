#!/bin/bash
# Execute a task immediately
# Usage: ./run-task.sh <task-id>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TASK_ID="$1"
if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <task-id>"
  exit 1
fi

TASKS_FILE="$HOME/.task-trigger/tasks.json"

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "No tasks registered yet."
  exit 1
fi

python3 << 'PYEOF'
import json, sys, os, subprocess, time, re
from datetime import datetime, timezone

TASK_ID = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("TASK_TRIGGER_ID", "")
SCRIPT_DIR = os.environ.get("SCRIPT_DIR", "")
TASKS_FILE = os.path.expanduser("~/.task-trigger/tasks.json")

with open(TASKS_FILE, "r") as f:
    tasks = json.load(f)

task = next((t for t in tasks if t.get("id") == TASK_ID), None)
if not task:
    print(f"Task '{TASK_ID}' not found.")
    sys.exit(1)

# Bug 5: Check expiration for temporal tasks
trigger = task.get("trigger", {})
expires_at = trigger.get("expires_at")
if expires_at:
    try:
        exp_time = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
        if datetime.now(timezone.utc) > exp_time:
            print(f"Task '{TASK_ID}' has expired (expires_at: {expires_at}). Disabling.")
            task["enabled"] = False
            with open(TASKS_FILE, "w") as f:
                json.dump(tasks, f, indent=2)
            # Try to remove from scheduler
            remove_script = os.path.join(SCRIPT_DIR, "remove-task.sh") if SCRIPT_DIR else None
            if remove_script and os.path.exists(remove_script):
                print(f"Removing expired task from scheduler...")
                # Can't use interactive remove, just note it
            print("Run '/task-trigger:remove " + TASK_ID + "' to clean up.")
            sys.exit(0)
    except Exception as e:
        print(f"Warning: Could not parse expires_at: {e}")

if not task.get("enabled", True):
    print(f"Task '{TASK_ID}' is disabled.")
    sys.exit(0)

exec_info = task.get("execution", {})
prompt = exec_info.get("prompt", "")
cli_path = exec_info.get("cli_path", "")
agent = exec_info.get("agent", "opencode")
model = exec_info.get("model", "")
log_path = task.get("log_path", f"$HOME/.task-trigger/logs/{TASK_ID}.log")

# Expand $HOME in paths
log_path = log_path.replace("$HOME", os.path.expanduser("~"))
log_path = os.path.expanduser(log_path)
os.makedirs(os.path.dirname(log_path), exist_ok=True)

# Bug 10: Expand prompt templates
now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
prompt = prompt.replace("{{TIMESTAMP}}", now_iso)
prompt = prompt.replace("{{TASK_ID}}", TASK_ID)
prompt = prompt.replace("{{LOG_PATH}}", log_path)
file_path = trigger.get("path", "")
prompt = prompt.replace("{{FILE_PATH}}", file_path)

timestamp = time.strftime("[%Y-%m-%d %H:%M:%S]")
with open(log_path, "a") as f:
    f.write(f"{timestamp} task={TASK_ID} status=started\n")

start_time = time.time()

# Bug 7: Use cli_path (full path) if available, fallback to agent name
if cli_path and cli_path != "none":
    cli_bin = cli_path
elif agent == "opencode":
    cli_bin = "opencode"
else:
    cli_bin = "kiro-cli"

# Build command
if "opencode" in cli_bin:
    cmd = [cli_bin, "run", "--prompt", prompt]
    if model:
        cmd.extend(["--model", model])
else:
    # Bug 4: kiro needs --trust-all-tools
    cmd = [cli_bin, "chat", "--no-interactive", "--trust-all-tools", prompt]
    if model:
        cmd.extend(["--model", model])

print(f"Executing: {' '.join(cmd)}")
print(f"Logging to: {log_path}")
print()

try:
    with open(log_path, "a") as log_file:
        log_file.write("--- output ---\n")
        result = subprocess.run(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=exec_info.get("timeout", 300),
        )

    duration = int(time.time() - start_time)
    timestamp = time.strftime("[%Y-%m-%d %H:%M:%S]")
    with open(log_path, "a") as f:
        f.write(f"\n{timestamp} task={TASK_ID} status=completed duration={duration}s\n")
    print(f"Task completed in {duration}s. Output written to log.")

except subprocess.TimeoutExpired:
    duration = int(time.time() - start_time)
    timestamp = time.strftime("[%Y-%m-%d %H:%M:%S]")
    with open(log_path, "a") as f:
        f.write(f"\n{timestamp} task={TASK_ID} status=timeout duration={duration}s\n")
    print(f"Task timed out after {duration}s.")
    sys.exit(1)
except Exception as e:
    duration = int(time.time() - start_time)
    timestamp = time.strftime("[%Y-%m-%d %H:%M:%S]")
    with open(log_path, "a") as f:
        f.write(f"\n{timestamp} task={TASK_ID} status=error error={str(e)} duration={duration}s\n")
    print(f"Error: {e}")
    sys.exit(1)
PYEOF
