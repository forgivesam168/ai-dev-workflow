---
name: workflow-orchestrator
description: 'Orchestrate the six-stage development workflow. Use when user asks "what stage am I at?", "what''s next?", "workflow status", "where should I start?", "工作流程", "下一步是什麼", "我在哪個階段", or wants guidance on the development process. Detects current state by checking changes/ folder and guides users through brainstorm → spec → plan → tdd → review → archive stages.'
license: See LICENSE.txt in repository root
---

# Workflow Orchestrator

> 🎯 **Purpose**: Detect current workflow stage and recommend the next step in ≤ 3 lines.

## When to Use This Skill

- Starting a new feature and unsure where to begin
- Wondering "what's next?" after completing a stage
- 想知道目前在哪個階段 / 不確定下一步該做什麼

## Stage Detection

Read the selected execution mode, package trigger, and declared plan/lifecycle or task/status SSOT before routing. For repository packages, run the deterministic semantic verifier (`tools/verify-change-package.ps1` when present). A filename is evidence to inspect, never proof that a stage is complete.

| Observed semantic state | Current stage | Route |
|---|---|---|
| Simple, no package | Lightweight workflow | Use the next incomplete Understand / Implement / Prove / Deliver checkpoint |
| Standard, no package trigger | Declared plan/lifecycle SSOT | Use its next incomplete checkpoint; do not create package padding |
| Package declaration missing or invalid | Intake | Resolve mode, trigger, Compact/Full, and the single task/status SSOT |
| Required decision or plan evidence incomplete | Brainstorm / Spec / Plan as selected | Return to the first incomplete selected role |
| Implementation evidence incomplete | Implement | Use `coder-agent` and the applicable verification path |
| Independent Review required but absent or incomplete | Review | Use `code-reviewer-agent`; new packages write `07-review.md` |
| Review is `BLOCKED`, or a deterministic gate is red | Blocked | Return to implementation or the owning earlier stage; do not advance |
| Review is `PASS` / `PASS_WITH_NOTES` and package Closeout is incomplete | Closeout | Complete pre-merge `99-archive.md` in the original implementation PR |
| Pre-merge Closeout is ready | Delivery pending | Report actual PR/Issue/Release evidence separately; do not infer merge or Complete |

Legacy `05-review.md` remains a recognized Review role and `99-closeout.md` a recognized Closeout alias. If canonical and alias files coexist, only the documented pointer-only alias is non-competing; two independent bodies are blocking.

## Output Format

Respond concisely (max 3 lines):

```
當前階段：[Stage] ✅
下一步：[Next Stage] → 使用 [agent-name]
指令：/[slash-command] 或輸入「[trigger phrase]」
```

## Execution Mode Routing

Read the canonical mode and lifecycle contract from [`WORKFLOW.md`](../../WORKFLOW.md). Select exactly one of Simple, Standard, or High-Risk and report that selection with the evidence used. Do not redefine entry criteria, package triggers, stage skip rules, or gate semantics in this router.

- Simple: recommend only the lightweight checkpoints and targeted verification needed by the task.
- Standard: route through the selected stages and declared plan/lifecycle SSOT; mention the compact Change Package only when a canonical trigger applies.
- High-Risk: route through the full Workflow and complete Change Package, preserving approvals, independent review, rollback/migration, and operational-evidence requirements.

If a task crosses a higher-risk boundary, stop routing and return to mode classification before suggesting further implementation.

## Troubleshooting

**No `changes/` folder** → Classify the mode. Simple and untriggered Standard may correctly have no package.

**Multiple `changes/` folders** → Use the current task/status SSOT or explicit user scope; do not select by filename date alone.

**Which agent for this stage?** → See each agent's `## Handoff` block for Entry Signals and Next Step.

---

💡 For complete workflow documentation, see [WORKFLOW.md](../../WORKFLOW.md).
