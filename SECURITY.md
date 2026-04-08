# 安全政策 (Security Policy)

本文件定義 **ai-dev-workflow** 專案的安全策略與最佳實踐，適用於所有使用 Copilot CLI 及相關 AI 工具的開發情境。

---

## 1. Copilot CLI 安全考量

### Trusted Directories（受信任目錄）

Copilot CLI 僅在經過使用者明確核准的目錄中執行操作。首次在新目錄執行時，CLI 會要求確認信任該目錄。

- 請僅信任您擁有完整控制權的專案目錄
- 切勿將系統根目錄或使用者家目錄設為受信任目錄
- 定期檢視受信任目錄清單，移除不再使用的項目

### Tool Approval（工具核准）

Copilot CLI 預設會在執行每個工具前詢問使用者確認。

- **`--allow-all-tools` 風險**：此旗標會略過所有工具確認提示，在不受信任的環境中使用可能導致未授權的檔案修改或命令執行
- 建議僅在已建立完善 hooks 防護機制的環境中使用此旗標
- 生產環境部署時**絕對不應**使用 `--allow-all-tools`

### 危險旗標警告

- **`--yolo`** / **`--dangerously-skip-permissions`**：這些旗標會完全停用安全確認機制，包括工具核准和破壞性操作警告
- 使用這些旗標等同於放棄所有安全護欄，僅適用於完全隔離的測試環境
- **在任何包含真實資料或憑證的環境中，嚴禁使用這些旗標**

---

## 2. Hooks 安全策略

本專案透過 `.github/hooks/` 目錄下的 hooks 機制提供額外的安全防護層。

### Hook 設定

設定檔位於 `.github/hooks/copilot-hooks.json`，定義了三個事件 hook：

| Hook | 事件 | 用途 |
|------|------|------|
| `pre-tool-use.sh` | `preToolUse` | 攔截危險命令、掃描 secrets |
| `session-start.sh` | `sessionStart` | 記錄 session 啟動資訊（稽核） |
| `post-tool-use.sh` | `postToolUse` | 記錄工具執行結果（稽核） |

### Fail-Open vs Fail-Closed 策略

本專案採用 **fail-open（失敗時開放）** 策略（`failBehavior: "warn"`）：

- **Fail-open**（本專案採用）：hook 執行失敗時發出警告，但不阻塞操作。優先保障開發流暢性
- **Fail-closed**（替代方案）：hook 執行失敗時阻塞操作。優先保障安全性，但可能影響開發體驗

若需切換為 fail-closed，請將 `copilot-hooks.json` 中的 `failBehavior` 改為 `"block"`。

### 停用 Hooks

如需停用 hooks 機制，可刪除或重新命名 `.github/hooks/` 目錄。停用前請確認團隊已知悉安全防護將被移除。

---

## 3. Secrets 管理規範

### 基本原則

- **絕對不在程式碼中寫入任何憑證**（API Key、密碼、Token 等）
- 所有敏感資訊必須透過環境變數或 secret store 注入
- 使用 `.env` 檔案管理本地開發環境變數時，**必須**將 `.env` 加入 `.gitignore`

### 環境變數管理

```bash
# ✅ 正確做法：使用環境變數
export API_KEY="${API_KEY}"

# ❌ 錯誤做法：硬編碼憑證
API_KEY="sk-abc123..."
```

### Secret Store 建議

- GitHub Actions：使用 Repository Secrets 或 Environment Secrets
- 本地開發：使用 `.env` 檔案搭配 `dotenv` 載入
- 生產環境：使用 Azure Key Vault、AWS Secrets Manager 或 HashiCorp Vault

---

## 4. 危險命令防護

### preToolUse Hook 攔截規則

`pre-tool-use.sh`（及對應的 `pre-tool-use.ps1`）會攔截以下類別的危險命令：

| 類別 | 攔截模式範例 | 風險說明 |
|------|-------------|----------|
| 檔案系統破壞 | `rm -rf /`、`rm -rf ~`、`mkfs.` | 可能刪除系統或使用者所有檔案 |
| 資料庫破壞 | `DROP TABLE`、`DROP DATABASE`、`TRUNCATE TABLE` | 可能造成不可逆的資料遺失 |
| Git 強制推送 | `git push --force`、`git push -f` | 可能覆蓋遠端歷史記錄 |
| 權限過度開放 | `chmod 777`、`chmod -R 777` | 可能將敏感檔案暴露給所有使用者 |
| 遠端程式碼執行 | `curl \| sh`、`wget \| bash` | 可能執行未經審核的惡意程式 |
| 磁碟格式化 | `format c:`、`> /dev/sda` | 可能格式化整個磁碟 |

### Secret Scanning 功能

preToolUse hook 同時會掃描命令中是否包含疑似 secret 的模式：

- **API Keys**：OpenAI (`sk-`)、GitHub (`ghp_`)、AWS (`AKIA`) 格式
- **私鑰**：`-----BEGIN PRIVATE KEY-----` 等 PEM 格式
- **密碼/金鑰賦值**：`password=`、`api_key=` 等模式
- **高熵字串**：Base64 編碼的長字串（可能為 token 或金鑰）

偵測到疑似 secret 時，hook 會發出警告（`"decision":"warn"`），提醒使用者在繼續前審核命令內容。

---

## 5. 漏洞通報流程

如發現本專案的安全漏洞，請**私下通報**，切勿在公開 Issue 中揭露。

- **通報信箱**：security@your-company.com
- **預期回應時間**：3 個工作天內
- **處理流程**：
  1. 收到通報後於 3 個工作天內確認
  2. 評估漏洞嚴重性並決定修補優先順序
  3. 開發修補程式並進行安全審核
  4. 發布修補版本並通知通報者

### 支援版本

安全修補僅套用於預設分支（default branch）上的最新版本。

---

## 6. CODEOWNERS 要求

為確保安全相關檔案的變更經過適當審核，建議在 `CODEOWNERS` 中加入以下規則：

```
# 安全相關檔案需要安全團隊審核
.github/workflows/    @security-team
.github/hooks/        @security-team
SECURITY.md           @security-team
```

### 審核要求

- **`.github/workflows/`**：所有 CI/CD 工作流程變更必須經過 CODEOWNERS 審核，防止注入惡意 step 或洩漏 secrets
- **`.github/hooks/`**：hooks 設定變更需要安全審核，確保防護規則未被意外削弱或繞過
- **`SECURITY.md`**：安全政策變更需要安全團隊確認一致性

---

## 附錄：稽核日誌

本專案的 Copilot CLI hooks 會將操作記錄寫入 `.copilot/logs/audit.log`，記錄內容包括：

- Session 啟動時間、使用者、工作目錄
- 工具使用記錄（工具名稱、執行結果）

此日誌檔案**不應**被提交至版本控制。請確認 `.copilot/` 已加入 `.gitignore`。
