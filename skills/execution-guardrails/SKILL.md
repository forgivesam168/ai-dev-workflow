---
name: execution-guardrails
description: Cross-cutting quality guardrails for AI-assisted software work. Use when you want an explicit reminder to surface assumptions, prefer the simplest viable change, keep edits surgical, and define verifiable success criteria before brainstorming, specification, planning, implementation, refactoring, or review.
license: See LICENSE.txt in repository root
user-invocable: true
disable-model-invocation: true
argument-hint: "[task or artifact to inspect]"
---

# Execution Guardrails

Shared quality floor for the workflow. This skill does **not** replace a stage's primary skill; it reinforces how work should be carried out across brainstorm, spec, plan, TDD, and review.

## When to Use This Skill

Use this skill when:
- an agent is guessing instead of clarifying
- a plan or implementation is growing more abstract than the requirement justifies
- a diff starts touching unrelated code, comments, or formatting
- success criteria are vague ("make it work") and need to become testable
- you want an explicit quality reset before handing work to another agent

## Four Shared Guardrails

1. **Assumptions explicit**  
   Separate facts, assumptions, and unknowns. If ambiguity materially changes the approach, stop and clarify or label the assumption.

2. **Simplicity first**  
   Implement the smallest solution that satisfies the current requirement. Do not add speculative flexibility, abstraction, or configuration for future possibilities.

3. **Surgical changes**  
   Touch only what the request requires. Clean up only the dead code your change creates. Do not perform drive-by refactors.

4. **Verifiable success criteria**  
   Convert work into checks: tests, assertions, or explicit manual verification. Avoid vague definitions of done.

## How to Apply by Stage

- **Brainstorm**: separate confirmed requirements from assumptions; avoid prematurely collapsing options into one interpretation.
- **Spec**: keep assumptions, non-goals, and unresolved questions distinct from requirements and acceptance criteria.
- **Plan**: plan only current scope; every step needs a verification method; call out assumptions that could invalidate multiple phases.
- **Code / TDD**: prefer the smallest diff that makes the target test pass; reject speculative abstractions and unrelated edits.
- **Review**: explicitly flag hidden assumptions, overengineering, and diff-scope drift when present.

See:
- [Stage usage guide](./references/stage-usage.md)
- [Anti-patterns and corrections](./references/anti-patterns.md)

## Relationship to the Existing Workflow

Use this layering model:

1. **Agent** — who does the work
2. **Primary skill** — the main methodology for that stage
3. **Execution guardrails** — shared constraints on how the work is performed
4. **Quality gate** — `agentic-eval` / `gate-check` before handoff

Operationally:
- the **always-on core** lives in `copilot-instructions.md` and core agents
- this skill is the **manual fallback / explicit reload**
- `agentic-eval` rubrics score whether the resulting artifact is safe to hand off

## Manual Invocation Examples

**CLI**

```text
/execution-guardrails check this plan for hidden assumptions and speculative scope
/execution-guardrails review this diff for unrelated edits and overengineering
/execution-guardrails help me turn this vague goal into verifiable success criteria
```

**VS Code**

```text
/execution-guardrails review this spec for assumptions vs confirmed requirements
```

## Recommended Output Format

When using this skill directly, structure the response as:

1. **Assumptions / Unknowns**
2. **Simplicity Risks**
3. **Scope / Diff Hygiene Risks**
4. **Verification Gaps**
5. **Recommended correction**

Keep corrections targeted. Do not rewrite the entire artifact unless the user asks.
