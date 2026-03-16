# Memory Management Architecture

## Decision Table

| Need | Tool | Location |
|------|------|----------|
| **Decisions and corrections** | MCP memory | Persistent |
| **Active task state** | File `SESSION-STATE.md` | Current workspace |
| **User context** | MCP memory | Persistent |
| **Session technical notes** | File `memory/YYYY-MM-DD.md` | Daily journal |

## Golden Rule

**If important for current task → `SESSION-STATE.md`**

If important for **future sessions** → MCP memory

### When to Use MCP Memory

- Architectural decisions made
- User preferences that will change future work
- Tradeoffs explained for context
- Specific values (ID, URL, configuration)
- Pattern recognition insights
- Technology stack preferences

### When to Use SESSION-STATE.md

- Active state of task in progress
- Temporary session notes
- Summary of what's been discussed today
- Next action items
- Files being worked on

### When to Create Session File

- At session end, create `memory/YYYY-MM-DD.md`
- Note repeated patterns
- Summarize important decisions
- Clean up SESSION-STATE

---

## SESSION-STATE.md Template

```markdown
# Session State: [Project/Task Name]
Date: YYYY-MM-DD
Last Updated: HH:MM

## Current Status
[Brief description of what we're working on]

## Decisions Made
- [ ] Decision 1 with reason
- [ ] Decision 2 with context

## Files in Progress
- `path/to/file1.ext` - [status]
- `path/to/file2.ext` - [status]

## Next Actions
- [ ] Action 1
- [ ] Action 2

## Notes
[Any temporary notes, TODOs, or reminders]
```

---

## Memory Examples

### Example: Saving a Correction
```javascript
// When user says: "no, use Button not Buttons"
MCP memory write:
- Key: "component_correction_button"
- Value: "Button (singular) not Buttons, path: src/components/Button.tsx"
- Reason: "User preference for naming convention"
```

### Example: Saving Architectural Decision
```javascript
// When user chooses JPA over Hibernate
MCP memory write:
- Key: "architecture_jpa_choice"
- Value: "Spring Boot JPA selected"
- Reason: "Team familiarity > performance needs, assumes standard CRUD"
- Alternatives considered: "Hibernate direct for complex queries"
- Warning signs: "If complex native queries needed, revisit"
```

### Example: Saving User Preference
```javascript
// When user mentions format preference
MCP memory write:
- Key: "user_format_preference"
- Value: "Dates in YYYY-MM-DD, not MM/DD/YYYY"
- Context: "For all reports and exports"
```

---

## Session Workflow

### Starting a Long Task

1. **Create SESSION-STATE.md** in workspace
2. **Load memory context**:
   - Technology stack preferences
   - Previous decisions
   - Known constraints
3. **WAL at start**: Save task state

### During Development

- Each decision → Immediate WAL
- Each correction → Immediate WAL
- Each pattern → Check recognition

### Session End

1. **Create daily file**: `memory/YYYY-MM-DD.md`
   - Architectural decisions
   - Tradeoffs explained
   - Patterns detected
   - Suggested next steps

2. **Distill to MCP memory**:
   - Main decisions
   - Important preferences
   - Key learnings

3. **Cleanup**:
   - SESSION-STATE.md → archive or keep if pending
   - Remove temporary notes

---

## Quick Reference

**To Remember:** Always ask "Will I need this tomorrow/next week?"

**For current session only:**
- Temporary file paths
- In-progress code state
- Today's TODO list

**For future sessions:**
- Technology preferences
- Naming conventions
- Architecture patterns
- User workflow habits
- Common issues encountered

**Critical:** Always write memory BEFORE responding when user gives:
- Corrections
- Decisions
- Specific values
- Preferences
- Constraints