# Verify Before Reporting — Examples

Real scenarios where "done" would have been wrong without verification.

---

## ❌ False "done" → ✅ Verified

### 1. WebFlux endpoint "working"
```
User: implement the reactive endpoint for account balance
Agent: ✓ Done, endpoint created at GET /accounts/{id}/balance

--- WITHOUT VERIFICATION ---
Reality: code compiled but Mono<Balance> was returning empty
on missing account instead of Mono.error(AccountNotFoundException)
The reactive chain was swallowing errors silently.

--- WITH VERIFICATION ---
Agent runs: curl localhost:8080/accounts/nonexistent/balance
Gets: 200 OK with empty body
Catches: wrong — should be 404. Reports the issue before saying done.
```

### 2. MongoDB query "optimized"
```
User: optimize this query, it's too slow
Agent: ✓ Added index on userId field

--- WITHOUT VERIFICATION ---
Reality: index added but query was using a compound filter
userId + status + date — single index on userId alone
barely helped. Explain plan still showed COLLSCAN on status.

--- WITH VERIFICATION ---
Agent checks explain plan after adding index.
Sees COLLSCAN still present on status filter.
Reports: "index added but query still needs compound index
on {userId, status, date} — want me to add it?"
```

### 3. DynamoDB migration script
```
User: write the migration to move these records to the new table
Agent: ✓ Script written, ready to run

--- WITHOUT VERIFICATION ---
Reality: script had correct logic but BatchWriteItem
had a 25-item limit per call — script would fail
silently on batches > 25 without chunking.

--- WITH VERIFICATION ---
Agent reviews AWS SDK limits before reporting.
Catches the batch size issue.
Reports: "script ready but added chunking for
BatchWriteItem 25-item limit — want to review?"
```

### 4. Tesis — denoising pipeline
```
User: run the comparison between BM3D and the CNN model
Agent: ✓ Done, results saved to results/comparison.csv

--- WITHOUT VERIFICATION ---
Reality: CSV existed but PSNR values for BM3D were
suspiciously identical across all noise levels —
sigma parameter wasn't varying in the loop, was hardcoded.

--- WITH VERIFICATION ---
Agent checks results/comparison.csv before reporting.
Notices BM3D PSNR = 32.4 across sigma=[10,20,30,40,50].
That's physically impossible — sigma should affect PSNR.
Reports the anomaly before declaring done.
```

### 5. AWS Lambda deploy
```
User: deploy the updated function
Agent: ✓ Deployed successfully

--- WITHOUT VERIFICATION ---
Reality: deploy succeeded but function was using
old environment variables from previous version —
new SECRET_KEY not propagated to the live version.

--- WITH VERIFICATION ---
Agent checks aws lambda get-function-configuration
after deploy. Sees LastModified matches but
environment still has old key. Reports before saying done.
```

---

## The Rule in One Line

> If you haven't run it, checked it, or seen the output yourself —
> you haven't verified it. Don't say done.
