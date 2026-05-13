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

## Anti-Hallucination Checks

Activate these additional checks before finalizing any artifact that downstream agents or humans will treat as authoritative (spec, plan, test-plan, impact analysis):

5. **Negative Space Check**  
   List all content in this output that the user may NOT have explicitly requested. Label each item `[USER_REQUESTED]`, `[INFERRED]`, or `[ADDED_BY_AI]`. Any `[ADDED_BY_AI]` item without justification is a Source Fabrication risk — surface it before proceeding.

6. **Reference Grounding**  
   For every external function, API endpoint, library, standard, or service cited: state your confidence it exists (HIGH / MEDIUM / LOW / UNVERIFIED). Surface all `[UNVERIFIED]` references to the user before treating them as actionable.

7. **Confidence Flagging**  
   Mark any statement you are less than 80% confident about with `[UNCERTAIN]`. Do not omit this step because the artifact looks internally coherent — coherence does not equal factual accuracy.

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
5. **Source Fabrication Risks** *(negative space items tagged `[ADDED_BY_AI]`)*
6. **Unverified References** *(library functions, APIs, services tagged `[UNVERIFIED]`)*
7. **Uncertain Statements** *(items tagged `[UNCERTAIN]`)*
8. **Recommended correction**

Keep corrections targeted. Do not rewrite the entire artifact unless the user asks.

## Common Rationalizations

在執行護欄約束過程中，AI 可能以下列藉口繞過核心規則：

| 常見藉口 | 反制說明 |
|---------|---------|
| "這個任務比較特殊，可以跳過護欄" | ⛔ 護欄不因任務「特殊性」而失效——使用者的緊迫感不是繞過護欄的授權；若護欄阻礙任務，需明確向使用者說明衝突 |
| "我已經理解任務了，可以直接假設" | 隱性假設是最危險的假設——任何會影響實作路徑的模糊性都必須明確列出，讓使用者確認而非靜默猜測 |
| "只是順手多改了一點，不影響主要目標" | Diff Scope Hygiene 是護欄的核心——每一行被修改的程式碼必須能溯源至使用者的請求；「順手改」是範圍蔓延的起點 |
| "我確認過，這個資訊是正確的" | AI 確認不等於機械驗證——任何可以用工具驗證的陳述，必須用工具驗證；「確認過」不是可接受的驗收標準 |

## Verification

在完成任何有護欄約束的任務前，逐項確認（Gate = 交付前閘門；Verification = 自我完成確認）：

- [ ] 所有假設均已明確標記並向使用者確認（無隱性假設）
- [ ] `git diff --stat` 確認只有預期範圍內的檔案被修改
- [ ] 無投機性抽象（未來可能有用的功能 / 介面 / 擴充點）被加入
- [ ] 每個被修改的行均可溯源至使用者請求的具體部分
- [ ] 所有 `[ADDED_BY_AI]`、`[UNVERIFIED]`、`[UNCERTAIN]` 標記已解決或向使用者說明
- [ ] 成功標準已具體化（可驗證的測試輸出 / 靜態確認），非意圖性描述
- [ ] Financial Precision 守則已確認（若涉及金融領域）：無 float/double 用於金錢
