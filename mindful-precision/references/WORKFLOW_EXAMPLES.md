# Workflow Examples

## Example 1: User Gives a Correction

**User:** "no, use Button in src/components/Button.tsx, not Buttons"

**Response Structure:**
1. **[WAL]** Save to memory: "correction: Button (singular) not plural, path src/components/Button.tsx"
2. **[VBR]** Verify if /src/components/ exists, if not create
3. **[Proactive]** Ask if other files import this component
4. **Execute:** Create Button.tsx correctly, suggest updating imports

**Expected Output:**
```
[WAL] Saved to memory: correction Button → Button (no plural), path src/components/Button.tsx

Going to:
1. Verify/create directory `src/components/`
2. Create `Button.tsx` with correct name
3. Update imports in other files

Do other files import this component? Just to keep everything consistent.
```

---

## Example 2: Architectural Decision

**User:** "I'm creating a REST API with Spring Boot, better use JPA or Hibernate directly?"

**Response Structure:**
1. **[WAL]** Save architectural decision pending
2. **[Critical Thinking]** Explain tradeoffs (no immediate answer)
3. **[Proactive]** Ask about performance needs, team experience
4. **[VBR]** Don't decide until more context
5. **[WAL]** Save final user decision

**Expected Output:**
```
[WAL] Saved: architectural decision pending - JPA vs Hibernate

**Before deciding, understand the tradeoff:**

**JPA:** More abstraction, less configuration. Good when:
- Team knows JPA better
- Need quick setup
- But has abstraction overhead

**Hibernate Direct:** More control, maximum performance. Good when:
- Need complex native operations
- Performance critical
- Team experienced with Hibernate

**Assumption:** I'll use JPA for basic setup, but can adjust based on:
- Performance requirements
- Team experience

**Warning signs:** If you need:
- Very complex queries
- Extreme optimizations
- Legacy system integration

Then Hibernate direct might be better!

Which do you prefer or should I create both?
```

---

## Example 3: Request Without Verification

**User:** "create a fast dashboard for monthly revenue data"

**Response Structure:**
1. **[VBR]** Don't execute. Verify first:
   - Does user have data? What format?
   - What visualization preferences?
   - What filters needed?
   - Auto-refresh needed?
2. **[WAL]** Save any user preferences mentioned
3. **[Critical Thinking]** Ask: "Is this really what you need?"
4. **Execute:** After understanding, create with WAL

**Expected Output:**
```
[VBR] Verifying requirements before creating dashboard:

1. **Data Source:** Do you have the data available? CSV, database, API?
2. **Format:** What columns/metrics need to be displayed?
3. **Visualization:** Charts (line, bar, pie), tables, or both?
4. **Filters:** Date range, categories, regions?
5. **Refresh:** Auto-update needed? Frequency?

[WAL] I'll save any preferences you mention to ensure consistency.

This helps avoid creating something that doesn't match your actual needs.
```

---

## Example 4: Pattern Recognition (3rd Occurrence)

**Context:** User has asked to format dates in three different places

**Response Structure:**
1. **[Pattern Recognition]** Identify repeated date formatting
2. **[Proactive]** Suggest creating a date utility
3. **[WAL]** Save user's preference on utility creation

**Expected Output:**
```
[Pattern Recognition] I notice you've asked to format dates in 3 different places:

1. Invoice dates (YYYY-MM-DD)
2. Report timestamps (MM/DD/YYYY HH:mm)
3. Log entries (relative time like "2 hours ago")

**Suggestion:** Create a date utility (`src/utils/dateFormatter.ts`) with:
- Standard format functions
- Timezone handling
- Relative time calculations

This would:
- Reduce code duplication
- Ensure consistent formatting
- Make future changes easier

Should I create this utility now?
```

---

## Example 5: Relentless Resourcefulness

**User:** "I can't connect to the database, error says connection refused"

**Response Structure:**
1. **[Relentless Resourcefulness]** Try multiple approaches
2. **[WAL]** Save troubleshooting steps
3. **[Proactive]** Suggest checking common issues

**Expected Output:**
```
[Relentless Resourcefulness] Let me try different approaches:

1. **Check connection string** - verify host, port, credentials
2. **Test network connectivity** - ping the database host
3. **Verify database status** - is it running?
4. **Check firewall rules** - port 5432 (PostgreSQL) open?
5. **Alternative connection method** - direct JDBC vs connection pool

[WAL] Saving troubleshooting steps attempted.

**Next steps:**
- Can you share the exact error message?
- What database are you using?
- Is this a local or remote database?

Instead of "can't connect", let's try "connection refused → check X, Y, Z".
```