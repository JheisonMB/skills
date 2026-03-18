#!/usr/bin/env python3
# List active file watchers

import json
import os
import sys
import subprocess

TASKS_FILE = os.path.expanduser("~/.task-trigger/tasks.json")
WATCHERS_DIR = os.path.expanduser("~/.task-trigger/watchers")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def check_watcher_status(task_id, platform):
    """Check if a watcher is currently running."""
    if platform in ["wsl", "linux"]:
        # Check systemd
        service_name = f"task-trigger-{task_id}.service"
        try:
            result = subprocess.run(
                ["systemctl", "--user", "is-active", service_name],
                capture_output=True,
                text=True,
            )
            return result.stdout.strip() == "active"
        except:
            return False

    elif platform == "macos":
        # Check launchd
        plist_name = f"com.task-trigger.{task_id}"
        try:
            result = subprocess.run(
                ["launchctl", "list"], capture_output=True, text=True
            )
            return plist_name in result.stdout
        except:
            return False

    return False


def main():
    if not os.path.exists(TASKS_FILE):
        print("No tasks registered yet.")
        return 0

    try:
        with open(TASKS_FILE, "r") as f:
            tasks = json.load(f)

        watcher_tasks = [t for t in tasks if t.get("trigger", {}).get("type") == "file"]

        if not watcher_tasks:
            print("No file watcher tasks found.")
            return 0

        print(f"{'ID':<30} {'Path':<40} {'Events':<20} {'Status':<10}")
        print("-" * 100)

        for task in watcher_tasks:
            task_id = task.get("id", "unknown")
            trigger = task.get("trigger", {})
            path = (
                trigger.get("path", "N/A")[:38] + "..."
                if len(trigger.get("path", "")) > 38
                else trigger.get("path", "N/A")
            )
            events = ", ".join(trigger.get("watch_events", []))

            # Detect platform
            try:
                result = subprocess.run(
                    [os.path.join(SCRIPT_DIR, "detect-platform.sh")],
                    capture_output=True,
                    text=True,
                )
                platform = result.stdout.strip()
            except:
                platform = "unknown"

            # Check status
            status = "Active" if check_watcher_status(task_id, platform) else "Inactive"

            print(f"{task_id:<30} {path:<40} {events:<20} {status:<10}")

        print(f"\nTotal watchers: {len(watcher_tasks)}")

        # List available monitoring tools
        print("\nAvailable monitoring tools:")
        try:
            result = subprocess.run(
                [os.path.join(SCRIPT_DIR, "detect-watcher.sh")],
                capture_output=True,
                text=True,
            )
            tool = result.stdout.strip()
            print(f"  - {tool}")
        except:
            print("  - Unknown")

        return 0

    except json.JSONDecodeError as e:
        print(f"Error parsing tasks.json: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
