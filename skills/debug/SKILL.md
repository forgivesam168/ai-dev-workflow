---
name: debug
description: >
  Systematic debugging methodology for build failures, test failures, unexpected agent behavior, and drift-related errors.
  Use when a build fails, tests fail unexpectedly, an agent produces wrong output repeatedly, or sync drift is detected.
  Triggers on: "debug", "fix build", "tests failing", "unexpected behavior", "drift error", "can't reproduce",
  "something is broken", "why is this failing", "investigate the failure". Escalates to human after 2 consecutive
  failed debug cycles.
---

# Debug Skill

Systematic investigation methodology for failures. Follows a structured reproduce → isolate → hypothesize → test → record cycle. Escalates after **2 consecutive failed debug cycles**.

## 1. Invocation Criteria

Use this skill when any of the following apply:

| Trigger | Example |
|---------|---------|
| **Build failure** | Compilation error, `dotnet build` fails, `npm run build` fails |
| **Test failure** | Tests that were passing now fail; flaky test behavior |
| **Unexpected agent behavior** | Agent produces output inconsistent with spec or prior runs |
| **Drift-related error** | `sync-dotgithub.ps1` reports differences; `audit-catalog.ps1` fails unexpectedly |

## 2. Investigation Step Sequence

Execute steps in order. Do not skip steps.

1. **Reproduce**: Confirm the failure is deterministic. Run the failing command again from a clean state. If intermittent, capture conditions under which it occurs.

2. **Isolate**: Narrow the failure scope. Which file, function, or check is failing? What changed since the last known-good state? (`git diff` or `git log --oneline -5`)

3. **Hypothesize**: Form one specific hypothesis about the root cause. Write it down: *"I believe X is failing because Y."*

4. **Test hypothesis**: Make a minimal targeted change or investigation step to confirm or reject the hypothesis. Do NOT make sweeping changes.

5. **Record finding**: Document:
   - What was tested
   - What was observed (actual vs. expected)
   - Hypothesis status: **CONFIRMED** or **REJECTED**
   - If rejected: form a new hypothesis and return to step 3

## 3. Output Format

After completing an investigation cycle, produce a structured findings report:

```
## Debug Findings — <date>

**Failure**: [brief description of the failure]
**Reproduced**: [Yes / No / Intermittent]
**Isolated to**: [file / function / check / component]
**Hypothesis**: [your hypothesis]
**Test performed**: [what you did to test it]
**Result**: [CONFIRMED / REJECTED]
**Root cause** (if confirmed): [explanation]
**Fix applied**: [description of change made, or "none — escalating"]
**Remaining issue** (if unresolved): [what is still unknown or broken]
```

### Escalation Trigger

If the fix is applied and the check still fails, that completes **1 debug cycle**.

After **2 consecutive failed debug cycles** (attempt corrective action → rerun check → still fails = 1 cycle), the agent **must** terminate the debug loop and escalate to a human. Do NOT autonomously initiate a third cycle.

**Escalation message format**:
```
⚠️ ESCALATION REQUIRED — 2 debug cycles attempted without resolution.

Failure: [description]
Cycle 1: [hypothesis + fix attempted + result]
Cycle 2: [hypothesis + fix attempted + result]

Unresolved: [what is still broken]
Recommended next step: [human investigation / revert to last known-good / ask for expert input]
```

## 4. Escalation Threshold

The escalation threshold is **2 consecutive failed debug cycles**. This is a fixed number — not a variable, not "a few", not "several".

**Definition of one debug cycle**: hypothesis formed → corrective action taken → verification check rerun → check still fails.

**Why 2?** After 2 cycles without resolution, the agent is likely stuck in a local minimum. Human judgment is needed to break the loop.

**What NOT to do**:
- Do NOT run a third cycle autonomously
- Do NOT silently continue without escalating
- Do NOT expand scope of changes hoping something will work
