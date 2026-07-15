---
name: explore
description: >
  Explore mode for codebase investigation and requirements clarification before committing to a change package.
  Use when requirements are unclear, a codebase investigation is needed before planning, options are being compared,
  or a risk scan is needed before a commit. Triggers on: "explore", "investigate", "look around", "understand the codebase",
  "scan for risks", "what's in here", "before I commit to anything".
  Stays in read-only observe mode — no files created — until an explicit artifact commit signal is received.
---

# Explore Mode

Read-only investigation mode. Observe and analyze without creating artifacts until explicitly signaled to proceed.

## When to Enter Explore Mode

Enter explore mode when any of the following apply:

- Requirements are not yet clear; need to ask clarifying questions or read the codebase first
- A codebase investigation is needed before a plan can be written
- Option comparison is in progress (weighing approaches before deciding)
- Risk scan needed before committing to a change package scope

## While in Explore Mode

**No files are created or modified** until an explicit artifact commit signal is received.

Permitted actions in explore mode:
- Read files (`read` / `view` tools)
- Search codebase (`search` / `grep` tools)
- Ask the user clarifying questions
- Build an internal understanding of the system

Prohibited actions until signaled:
- Creating or modifying `changes/` files
- Creating or modifying any source or documentation file
- Running `sync-dotgithub.ps1`

## Explicit Artifact Commit Triggers

Explore mode ends and artifact creation begins **only** when one of the following explicit signals is received from the user:

1. `/proceed`
2. `"create change package"`
3. `"start brainstorm"`
4. `"I want to formalize this"`

Any other phrasing that sounds like "let's start writing" should be confirmed with the user before exiting explore mode: "Do you want me to create a change package now?"

## Explore Mode Summary Output

Before transitioning out of explore mode, produce a brief summary:

```
## Explore Summary
- **Scope**: [what was investigated]
- **Key Findings**: [2–5 bullet points]
- **Recommended Next Step**: [brainstorm / Simple or Standard plan / other, as selected under WORKFLOW.md]
- **Risk Signal**: [Low / Med / High — brief rationale]
```

This summary becomes input to the brainstorm or plan step.

## Common Rationalizations

在進行 explore 探索過程中，AI 可能以下列藉口略過關鍵步驟：

| 常見藉口 | 反制說明 |
|---------|---------|
| "看一看就夠了，不需要正式 explore" | ⛔ 非正式「看一看」沒有輸出物——Explore 必須產出 Findings 文件，才能作為 brainstorm/plan 的可靠輸入 |
| "程式碼庫我已經很熟了，可以直接進入計畫" | 熟悉感不等於對當前狀態的準確掌握——任何超過兩週未接觸的程式碼庫，或涉及 brownfield 改動，均應重新 explore |
| "Explore 會拖慢速度，直接開始實作更有效率" | 未探索就實作等於在未知地圖上規劃路線——explore 的時間投入遠低於因誤解現況而導致的返工成本 |

## Verification

在完成 explore 並準備移交產出物前，逐項確認（Gate = 交付前閘門；Verification = 自我完成確認）：

- [ ] `rg "## Findings\|## Key Findings" <output-file>` 有匹配（Findings 段落已存在）
- [ ] Findings 含至少 2 個具體觀察（非「程式碼看起來正常」等模糊描述）
- [ ] Risk Signal 已填寫（Low / Med / High + 一句理由）
- [ ] Recommended Next Step 已依 `WORKFLOW.md` 的 Simple / Standard / High-Risk 模式明確記錄（brainstorm / plan / 其他具體行動）
- [ ] Explore 範圍（Scope）已明確描述（調查了哪些模組/路徑/決策點）
- [ ] 未建立或修改任何非 Explore 產出物的程式碼檔案（Explore = read-only）
- [ ] 產出摘要可直接貼入 brainstorm-agent 或 plan-agent 的輸入脈絡
