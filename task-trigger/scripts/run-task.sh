#!/bin/bash
# Execute a task immediately
# Usage: ./run-task.sh <task-id>

set -e

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

# Extract task info using Python
python3 -c "
import json, sys, os, subprocess, time

with open('$TASKS_FILE', 'r') as f:
    tasks = json.load(f)

task = None
for t in tasks:
    if t.get('id') == '$TASK_ID':
        task = t
        break

if not task:
    print(f\"Task '$TASK_ID' not found.\")
    sys.exit(1)

exec_info = task.get('execution', {})
prompt = exec_info.get('prompt', '')
agent = exec_info.get('agent', 'opencode')
model = exec_info.get('model', '')
log_path = task.get('log_path', f\"\$HOME/.task-trigger/logs/$TASK_ID.log\")

# Expand home directory
log_path = os.path.expanduser(log_path)
os.makedirs(os.path.dirname(log_path), exist_ok=True)

timestamp = time.strftime('[%Y-%m-%d %H:%M:%S]')
with open(log_path, 'a') as f:
    f.write(f\"{timestamp} task=$TASK_ID status=started\\n\")

start_time = time.time()

# Build command
if agent == 'opencode':
    cmd = ['opencode', 'run', '--prompt', prompt]
    if model:
        cmd.extend(['--model', model])
elif agent == 'kiro':
    cmd = ['kiro', 'chat', prompt]
else:
    print(f\"Unknown agent: {agent}\")
    sys.exit(1)

print(f\"Executing: {' '.join(cmd)}\")
print(f\"Logging to: {log_path}\")
print()

try:
    with open(log_path, 'a') as log_file:
        log_file.write('--- output ---\\n')
        result = subprocess.run(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=300
        )
    
    duration = int(time.time() - start_time)
    timestamp = time.strftime('[%Y-%m-%d %H:%M:%S]')
    
    with open(log_path, 'a') as f:
        f.write(f\"\\n{timestamp} task=$TASK_ID status=completed duration={duration}s\\n\")
    
    print(f\"Task completed in {duration}s. Output written to log.\")
    
except subprocess.TimeoutExpired:
    duration = int(time.time() - start_time)
    timestamp = time.strftime('[%Y-%m-%d %H:%M:%S]')
    with open(log_path, 'a') as f:
        f.write(f\"\\n{timestamp} task=$TASK_ID status=timeout duration={duration}s\\n\")
    print(f\"Task timed out after {duration}s.\")
    sys.exit(1)
except Exception as e:
    duration = int(time.time() - start_time)
    timestamp = time.strftime('[%Y-%m-%d %H:%M:%S]')
    with open(log_path, 'a') as f:
        f.write(f\"\\n{timestamp} task=$TASK_ID status=error error={str(e)} duration={duration}s\\n\")
    print(f\"Error: {e}\")
    sys.exit(1)
"