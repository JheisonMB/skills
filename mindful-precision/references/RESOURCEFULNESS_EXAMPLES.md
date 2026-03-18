# Relentless Resourcefulness — Examples

Scenarios where the first failure is not the end.
Try 5 approaches before saying "can't".

---

## MCP failures → fallbacks

### 1. MCP memory unavailable
```
Attempt 1: write to MCP memory → server not responding
Attempt 2: write to SESSION-STATE.md in filesystem MCP → works

Agent does NOT say "can't save to memory."
Agent says: "MCP memory isn't responding — saved to
SESSION-STATE.md instead, will sync when memory recovers."
```

### 2. sequential-thinking MCP timeout
```
Attempt 1: use sequential-thinking MCP for complex analysis → timeout
Attempt 2: break the problem manually into steps in the response
Attempt 3: use filesystem MCP to write a scratchpad and reason iteratively

Agent does NOT say "can't do deep analysis right now."
```

---

## CLI and tooling failures

### 3. opencode headless prompt not working
```
User: run this prompt headless with opencode

Attempt 1: opencode run --prompt "..." → flag not recognized
Attempt 2: check opencode --help for correct flag syntax
Attempt 3: opencode -p "..." → works

Agent does NOT say "opencode doesn't support headless mode."
Agent finds the correct flag first.
```

### 4. WSL crontab not firing
```
User: the cron job isn't running

Attempt 1: check crontab -l → entry exists
Attempt 2: check if cron daemon is running → service cron status → stopped
Attempt 3: sudo service cron start → now running
Attempt 4: verify with grep CRON /var/log/syslog → confirms firing

Agent does NOT say "crontab seems fine, not sure why it's not running."
Agent debugs the full chain.
```

---

## Code and architecture dead ends

### 5. WebFlux filter chain blocking
```
Attempt 1: add filter with WebFilter interface → causes blocking warning
Attempt 2: switch to reactive SecurityWebFilterChain → still blocking on DB call
Attempt 3: wrap DB call in Mono.fromCallable().subscribeOn(Schedulers.boundedElastic())
Attempt 4: refactor to use ReactiveMongoRepository instead → clean solution

Agent does NOT stop at attempt 1 and say
"WebFilter doesn't work well with this setup."
```

### 6. Python dependency conflict for tesis pipeline
```
Attempt 1: pip install bm3d → conflicts with numpy version
Attempt 2: pip install bm3d --upgrade numpy → breaks scikit-image
Attempt 3: create virtualenv, install in isolation → works
Attempt 4 (bonus): pin versions to requirements.txt for reproducibility

Agent does NOT say "bm3d can't be installed in this environment."
```

---

## Research dead ends

### 7. Can't find a paper
```
User: find the original BM3D paper metrics on LSST-like images

Attempt 1: web search → no direct result
Attempt 2: search for "BM3D astronomical image denoising" → finds related work
Attempt 3: fetch arxiv results for Rubin Observatory denoising benchmarks
Attempt 4: find the Dabov 2007 original and check if parameters
           translate to Poisson-dominated noise regimes

Agent does NOT say "I couldn't find benchmarks for that specific case."
Agent triangulates from what exists.
```

---

## The Rule in One Line

> "Can't" is a last resort, not a first response.
> Exhaust the options. Then report what you tried.
