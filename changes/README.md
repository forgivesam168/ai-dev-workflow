# Changes（Change Package）

本資料夾用來保存「每次需求/變更」的規格與決策產物，讓團隊在需求反覆變更、MVP 變棕地後仍可安全演進。

## 命名
建立資料夾：
- `changes/<YYYY-MM-DD>-<slug>/`
  - slug 以英文小寫 + `-`（例如：`2026-02-07-audit-workpaper-import`）

## 建立方式
1) 複製 `changes/_template/` 成新資料夾
2) 依序填寫：
   - `00-intake.md` → 最少要先寫這份
   - 需要釐清就寫 `01/02/03`
   - `/plan` 後補齊 `04/05`
   - 棕地或高風險再補 `06-impact-analysis.md`
3) PR 裡必填：Change Package 路徑（例如：`changes/2026-02-07-xxx/`）

## 何時可以用快速路？
- 低風險小修（文案/註解/非常局部的 bug）
- 仍需要 `00-intake.md` + PR 驗證步驟

## 合併後
- 補 `99-archive.md`（放 PR link、結果、後續）
- 不需要把資料夾搬去別處；保留在 `changes/` 即是你們的「可稽核歷史」。

