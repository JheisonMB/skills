#!/usr/bin/env python3
# List registered tasks from tasks.json, cross-referencing with OS scheduler

import json
import os
import subprocess
import sys
from datetime import datetime, timezone


TASKS_FILE = os.path.expanduser("~/.task-trigger/tasks.json")


def detect_platform():
    import platform
    if platform.system() == "Darwin":
        return "macos"
    try:
        with open("/proc/version", "r") as f:
            if "microsoft" in f.read().lower():
                return "wsl"
    except FileNotFoundError:
        pass
    return "linux"


def get_scheduler_tasks(platform, task_ids):
    """Return set of task IDs actually registered in the OS scheduler."""
    active = set()
    if platform == "macos":
        for tid in task_ids:
            label = f"com.task-trigger.{tid}"
            try:
                result = subprocess.run(
                    ["launchctl", "list", label],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    active.add(tid)
            except Exception:
                pass
    else:
        try:
            result = subprocess.run(
                ["crontab", "-l"], capture_output=True, text=True, timeout=5
            )
            for line in result.stdout.splitlines():
                if line.startswith("# task-trigger: "):
                    tid = line.replace("# task-trigger: ", "").strip()
                    if tid:
                        active.add(tid)
        except Exception:
            pass
    return active


def get_status(task, scheduler_active):
    """Determine task status, checking expiration and scheduler state."""
    task_id = task.get("id", "")

    if not task.get("enabled", True):
        expires_at = task.get("trigger", {}).get("expires_at")
        if expires_at:
            try:
                exp_time = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
                if datetime.now(timezone.utc) > exp_time:
                    return "Expired"
            except Exception:
                pass
        return "Paused"

    # Check expiration
    expires_at = task.get("trigger", {}).get("expires_at")
    if expires_at:
        try:
            exp_time = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
            if datetime.now(timezone.utc) > exp_time:
                task["enabled"] = False
                return "Expired"
        except Exception:
            pass

    # Cross-reference with scheduler
    if task_id in scheduler_active:
        return "Active"
    else:
        return "JSON-only"


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

        platform = detect_platform()
        task_ids = [t.get("id", "") for t in tasks]
        scheduler_active = get_scheduler_tasks(platform, task_ids)

        print(
            f"{'ID':<30} {'Name':<25} {'Schedule':<15} {'Status':<10} {'CLI':<10}"
        )
        print("-" * 90)

        dirty = False
        for task in tasks:
            task_id = task.get("id", "unknown")
            name = task.get("name", "Unnamed")
            if len(name) > 23:
                name = name[:23] + "..."
            cron = task.get("trigger", {}).get("expression", "N/A")
            status = get_status(task, scheduler_active)
            if status == "Expired":
                dirty = True
            agent = task.get("execution", {}).get("agent", "unknown")

            print(f"{task_id:<30} {name:<25} {cron:<15} {status:<10} {agent:<10}")

        print(f"\nTotal tasks: {len(tasks)}")
        print(f"Platform: {platform} | Scheduler tasks: {len(scheduler_active)}")

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
