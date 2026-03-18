#!/usr/bin/env python3
# List registered tasks from tasks.json

import json
import os
import sys
from datetime import datetime

TASKS_FILE = os.path.expanduser("~/.task-trigger/tasks.json")


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

        for task in tasks:
            task_id = task.get("id", "unknown")
            name = (
                task.get("name", "Unnamed")[:23] + "..."
                if len(task.get("name", "")) > 23
                else task.get("name", "Unnamed")
            )
            cron = task.get("trigger", {}).get("expression", "N/A")
            enabled = "Enabled" if task.get("enabled", True) else "Disabled"
            agent = task.get("execution", {}).get("agent", "unknown")

            print(f"{task_id:<30} {name:<25} {cron:<15} {enabled:<10} {agent:<10}")

        print(f"\nTotal tasks: {len(tasks)}")
        return 0

    except json.JSONDecodeError as e:
        print(f"Error parsing tasks.json: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
