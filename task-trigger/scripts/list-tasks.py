#!/usr/bin/env python3
# List registered tasks from tasks.json

import json
import os
import sys
from datetime import datetime, timezone

TASKS_FILE = os.path.expanduser("~/.task-trigger/tasks.json")


def get_status(task):
    """Determine task status, checking expiration."""
    if not task.get("enabled", True):
        return "Disabled"

    expires_at = task.get("trigger", {}).get("expires_at")
    if expires_at:
        try:
            exp_time = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
            if datetime.now(timezone.utc) > exp_time:
                # Opportunistic cleanup: mark as disabled
                task["enabled"] = False
                return "Expired"
        except Exception:
            pass

    return "Enabled"


def main():
    if not os.path.exists(TASKS_FILE):
        print("No tasks registered yet.")
        return 0

    try:
        with open(TASKS_FILE, "r") as f:
            tasks = json.load(f)

        if not tasks:
            print("No tasks registered yet.")
            return 0

        print(f"{'ID':<30} {'Name':<25} {'Schedule':<15} {'Status':<10} {'CLI':<10}")
        print("-" * 90)

        dirty = False
        for task in tasks:
            task_id = task.get("id", "unknown")
            name = (
                task.get("name", "Unnamed")[:23] + "..."
                if len(task.get("name", "")) > 23
                else task.get("name", "Unnamed")
            )
            cron = task.get("trigger", {}).get("expression", "N/A")
            status = get_status(task)
            if status == "Expired":
                dirty = True
            agent = task.get("execution", {}).get("agent", "unknown")

            print(f"{task_id:<30} {name:<25} {cron:<15} {status:<10} {agent:<10}")

        print(f"\nTotal tasks: {len(tasks)}")

        # Opportunistic save if any expired tasks were marked disabled
        if dirty:
            with open(TASKS_FILE, "w") as f:
                json.dump(tasks, f, indent=2)

        return 0

    except json.JSONDecodeError as e:
        print(f"Error parsing tasks.json: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
