# Decision Log: Bootstrap Installer

## 決策 #1：腳本優先順序
**日期**：2026-02-09  
**決策者**：Team Lead  
**狀態**：✅ Approved

### 問題
團隊成員環境多樣，需要決定腳本開發優先順序。

### 選項
1. PowerShell 優先（Windows 為主）
2. Bash 優先（跨平台通用）
3. Python 優先（最大兼容性）

### 決策
**PowerShell 優先 + Python Fallback**

### 理由
- 團隊 Windows 為主（回答 A:1）
- PowerShell 在 Windows 上原生支援
- Python 作為 fallback 確保其他 OS 可用
- Bash 作為第三選擇（Linux/macOS 用戶）

### 權衡
- ✅ Windows 使用者體驗最佳
- ✅ 跨平台兼容性通過 Python 保證
- ⚠️ 需維護 3 個腳本版本

### 影響
- 開發工作量：需開發 ps1/py/sh 三版本
- 測試覆蓋：需測試 Windows/macOS/Linux
- 文件化：需說明不同 OS 的安裝方式

---

## 決策 #2：依賴策略
**日期**：2026-02-09  
**決策者**：Team Lead  
**狀態**：✅ Approved

### 問題
如何處理團隊成員可能缺少的依賴（pwsh、Node.js）？

### 選項
1. 強制安裝所有依賴
2. 檢測並提示安裝
3. 僅檢測，不安裝（最小侵入）

### 決策
**僅檢測並提示（選項 3）**

### 理由
- 用戶回答 C:3（Python 作為 fallback）
- 不強制安裝避免權限問題
- 保持腳本簡單可維護

### 依賴分級
- **必需**：Git（終止如果未安裝）
- **建議**：GitHub CLI（提示但不阻擋）
- **可選**：PowerShell 7+, Node.js（提示並提供安裝連結）

### 權衡
- ✅ 使用者有選擇權
- ✅ 避免權限問題
- ⚠️ 部分功能可能受限（無 gh 則無法用 template）

---

## 決策 #3：分發方式
**日期**：2026-02-09  
**決策者**：Team Lead  
**狀態**：✅ Approved

### 問題
工作流如何分發給團隊與外部使用者？

### 選項
1. 僅公開 GitHub Repo
2. 僅組織私有 Repo
3. 公開 Repo + 組織 Fork

### 決策
**公開 GitHub Repo（選項 1）**

### 理由
- 用戶回答 B:1（公開 repo）
- 開源精神，社群可貢獻
- 團隊內外均可使用

### 實施方式
```
github.com/your-org/ai-workflow-template (Public)
├── README.md (完整安裝指引)
├── bootstrap.ps1/py/sh
└── .github/ (工作流模板)
```

### 權衡
- ✅ 開放透明，利於協作
- ✅ 外部使用者可直接使用
- ⚠️ 需注意不提交敏感資訊
- ⚠️ 文件需更完善（考慮外部使用者）

### 安全考量
- 所有 secrets 必須使用 GitHub Secrets
- 範例配置不包含真實 API keys
- 文件中說明安全最佳實踐

---

## 決策 #4：版本更新機制
**日期**：2026-02-09  
**決策者**：Team Lead  
**狀態**：🔄 Deferred (Phase 2)

### 問題
當工作流模板更新時，使用者如何同步？

### 選項
1. 手動執行更新腳本
2. GitHub Actions 自動同步
3. CLI 工具自動檢測更新

### 暫定決策
**Phase 1: 手動更新，Phase 2: 考慮 Actions**

### 理由
- 先確保基礎功能穩定
- 手動更新簡單直接
- 未來可加入自動化

### 實施方式（Phase 1）
```powershell
# 手動更新
.\bootstrap.ps1 --update

# 或重新執行初始化
.\bootstrap.ps1 --force
```

### 待決事項
- 是否需要版本檢測？
- 如何處理客製化修改？
- 是否需要衝突解決機制？

---

## 附錄：環境決策摘要

| 決策項目 | 選擇 | 理由 |
|---------|-----|------|
| 作業系統 | Windows 為主 | 團隊現況 (A:1) |
| 分發方式 | 公開 Repo | 開源友善 (B:1) |
| 必備依賴 | Git + Python | 最小化依賴 (C:3) |
| 腳本優先順序 | PowerShell > Python > Bash | Windows 優化 |
| 依賴處理 | 檢測提示，不強制安裝 | 最小侵入 |
| 版本更新 | 手動（Phase 1） | 簡單優先 |
