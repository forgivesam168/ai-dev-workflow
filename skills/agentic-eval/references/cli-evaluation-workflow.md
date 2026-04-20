# CLI Evaluation Workflow

Step-by-step guide for Tier 2 (external critic via subagent) and Tier 3 (tracked evaluation).

---

## Tier 2: External Critic via Subagent

Use the `task` tool to delegate evaluation to a separate subagent with a different model perspective.

### Prerequisites
- `task` tool available (check with `/skills info agentic-eval`)
- Optionally: `RUBBER_DUCK_AGENT` experimental flag enabled for rubber-duck agent
  - Enable: `/experimental on` in CLI, or set `enabledFeatureFlags.RUBBER_DUCK_AGENT: true` in `~/.copilot/config.json`

### Step-by-Step Workflow

**Step 1 — Generate output**
```
Generate the initial output (code, report, design, plan).
```

**Step 2 — Prepare critic payload (context efficiency is critical)**

Do NOT pass full file blobs. Pass focused context:

| Output type | What to pass to critic |
|-------------|------------------------|
| Code | File path(s) + diff excerpt + rubric |
| Report | Relevant section (≤500 words) + evaluation rubric |
| Design/Plan | Key decisions + constraints + known trade-offs |
| Test coverage | Failing test names + assertion messages |

**Step 3 — Invoke critic subagent**

```
If RUBBER_DUCK_AGENT is enabled (preferred — uses complementary model):
  Use task tool with agent_type: "rubber-duck"
  Prompt: "Critique this [output type] for [rubric dimensions].
           Identify weak points, logic errors, and blind spots.
           Do NOT suggest style fixes. Focus on correctness and soundness.
           [paste focused excerpt here]"

If rubber-duck is NOT available (fallback):
  Use task tool with agent_type: "general-purpose"
  Prompt: "Act as an adversarial reviewer. Critique this [output type]
           from the perspective of someone trying to find flaws.
           [paste focused excerpt here]"
```

**Step 4 — Parse critique and refine**
```
Identify the top 2–3 issues from the critique.
Refine the output targeting only those issues.
Do not rewrite everything — targeted edits preserve what works.
```

**Step 5 — Convergence check**
```
Stop if:
  - Critic finds no blocking issues
  - Score meets threshold
  - Max 3 iterations reached
  - Score is not improving vs. previous iteration
```

### Adversarial Prompt Templates

**For code review:**
```
You are an adversarial code reviewer. Your job is to find bugs, logic errors,
security issues, and incorrect assumptions in the following code.
Do NOT comment on style or formatting. Focus on correctness.

Rubric: accuracy, security, edge-case handling
Code excerpt:
[excerpt]
```

**For design/architecture critique:**
```
You are a skeptical senior architect. Find the weakest assumptions,
scalability risks, and missing failure modes in this design.

Rubric: correctness, scalability, failure handling
Design summary:
[summary]
```

**For report/document critique:**
```
You are a critical reviewer. Identify factual gaps, logical inconsistencies,
and unsupported claims in this content.

Rubric: accuracy, completeness, clarity
Content excerpt:
[excerpt]
```

---

## Tier 3: Tracked Evaluation

Track iteration scores and critiques in the per-session database for convergence analysis.

> ⚠️ Always use `database: "session"` (per-session DB). `database: "session_store"` is **read-only** — writes will fail.

### Schema Setup

Run once at the start of an evaluation session:

```sql
CREATE TABLE IF NOT EXISTS eval_iterations (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id    TEXT    NOT NULL,
    iteration  INTEGER NOT NULL,
    dimension  TEXT    NOT NULL,
    score      REAL    NOT NULL,
    critique   TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

Only store: task identifier, iteration number, dimension name, numeric score, brief critique summary.
**Never store full output text** — keep rows small.

### Recording an Iteration

```sql
INSERT INTO eval_iterations (task_id, iteration, dimension, score, critique)
VALUES
    ('my-task', 1, 'accuracy',     0.6, 'Missing null check on line 42'),
    ('my-task', 1, 'completeness', 0.8, 'Covers happy path only'),
    ('my-task', 1, 'clarity',      0.9, NULL);
```

### Convergence Check

```sql
-- Compare latest two iterations for a task
WITH ranked AS (
    SELECT iteration, dimension, score,
           LAG(score) OVER (PARTITION BY dimension ORDER BY iteration) AS prev_score
    FROM eval_iterations
    WHERE task_id = 'my-task'
)
SELECT dimension,
       score,
       prev_score,
       ROUND(score - COALESCE(prev_score, 0), 3) AS delta
FROM ranked
WHERE iteration = (SELECT MAX(iteration) FROM eval_iterations WHERE task_id = 'my-task');
```

Stop iterating if all deltas < 0.05 (score not improving meaningfully).

### Final Summary

```sql
SELECT task_id,
       MAX(iteration) AS total_iterations,
       AVG(score)     AS avg_score,
       MIN(score)     AS min_score
FROM eval_iterations
WHERE task_id = 'my-task'
  AND iteration = (SELECT MAX(iteration) FROM eval_iterations WHERE task_id = 'my-task')
GROUP BY task_id;
```

---

## When Tier 3 Is Worth the Overhead

Use tracked evaluation only when:
- Running 3+ iterations and need to compare progress
- Multiple dimensions with different weights (need audit trail)
- Team needs to share or review evaluation history
- Auto-stopping on convergence is required

Skip it for:
- Single-iteration checks
- Rapid exploratory evaluation
- Cases where informal score tracking suffices
