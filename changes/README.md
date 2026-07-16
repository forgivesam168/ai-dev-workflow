# Changes（Change Package）

Change Package 是 lifecycle evidence container，不是每個 task 都必須建立的進度系統。

## Execution modes

- **Simple**：不要求 repository package、Review 或 Archive；保留 targeted verification 與準確 completion evidence。
- **Standard**：維護一個 declared plan/lifecycle SSOT；cross-session、cross-component、contract-change、independent-review、migration/audit-sensitive 或 escalation-prone trigger 成立時才要求 compact package。自願建立的 package 依其宣告驗證。
- **High-Risk**：使用 full package，包含 `00`–`06` substantive evidence、canonical `07-review.md` 與 pre-merge `99-archive.md` Closeout。

## Package path and declaration

需要或自願使用 package 時建立 `changes/<YYYY-MM-DD>-<slug>/`，並依宣告的 `Compact`／`Full` contract 驗證，不因 Simple mode 本身禁止 package。`00-intake.md` 的 Task/status SSOT、External tracker、Execution mode、Package trigger/reason 與 Package contract 各自只能宣告一次；file SSOT 必須可存取，external tracker 必須可識別，且全程只能有一個 dynamic progress owner。

不得複製空白檔案湊數，檔名存在不代表 role 或 stage complete。Compact package 只加入 selected-stage／risk 所需 evidence；Full package 使用完整 template roles。

## Review and Closeout compatibility

- 新 package 的 Review 是 `07-review.md`；legacy `05-review.md` 仍可辨識。
- 新 package 的 Closeout 是 `99-archive.md`；`99-closeout.md` 可作 narrow pointer-only alias。
- 兩份獨立 Review bodies 或兩份獨立 Closeout bodies 是 competing evidence，必須阻擋。
- Canonical Review 與 Closeout 的 structured fields 必須選定且有 substantive evidence；原樣 template、未解 Critical/High、deterministic BLOCKED 與狀態衝突均為 blocking。
- Triggered Standard 與 High-Risk 在原 implementation PR 內完成 pre-merge Closeout；不得預先宣稱 actual merge evidence，也不得為補 merge evidence 自動建立 post-merge commit/push。

詳見 root `WORKFLOW.md` 與 `instructions/changes.instructions.md`。
