# Brainstorm: Install Surface Implementation

**Date**: 2026-04-30  
**Risk Level**: Medium  
**Workflow Path**: 🟢 Fast（Spec 已存在）

## 決策背景

`docs/install-surface-design.md` 已完整定義 `install-plan` / `install-apply` / `doctor` 三個工具的規格。
本 change package 為實作階段，不需重新討論設計。

## 確認的設計決策

| 決策 | 內容 |
|------|------|
| 目標範圍 | 兩種模式：自身 template（無 --Target）+ 部署到其他 repo（--Target 指定路徑）|
| 衝突處理 | 預設 skip-if-exists；`--Force` 覆蓋 |
| Manifest 檔案 | `.ai-workflow-install.json`，存放於目標 repo 根目錄 |
| 輸出語言 | 繁體中文 |
| 共用邏輯 | 提取至 `tools\install-helpers.psm1`，三支腳本 import |

## 範圍邊界

**In scope**: install-plan.ps1, install-apply.ps1, doctor.ps1, install-helpers.psm1  
**Out of scope**: profile presets, multi-harness distribution, auto-update, remote diff
