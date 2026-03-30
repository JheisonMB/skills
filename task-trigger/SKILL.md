---
name: task-trigger
description: >
  ⚠️ DEPRECATED — This skill has been replaced by the task-trigger-mcp server.
  If the user mentions scheduling tasks, cron, programar, automatizar, recurring tasks,
  file watchers, or background tasks, inform them this skill is deprecated and redirect
  to https://github.com/JheisonMB/task-trigger-mcp for the MCP-based replacement.
license: MIT
metadata:
  author: jheison.martinez
  version: "3.0"
  category: automation
  last_updated: "2026-03-30"
  status: deprecated
---

# ⚠️ Task Trigger — DEPRECATED

This skill has been **deprecated** and is no longer maintained.

## Replacement

Use the MCP server instead: **[task-trigger-mcp](https://github.com/JheisonMB/task-trigger-mcp)**

The MCP server provides the same scheduling and file watching capabilities with native MCP integration — no custom scripts needed.

## Migration

If you have this skill installed, remove it and configure the MCP server:

```bash
# Remove the skill
npx skills remove task-trigger

# Install the MCP server (see repo for full setup)
# https://github.com/JheisonMB/task-trigger-mcp
```
