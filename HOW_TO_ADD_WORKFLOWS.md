# 🛠️ 如何新增工作流程 (How to Add Workflows)

本專案採用 **Caller (呼叫者) → Orchestrator (協調者) → Reusable Workflow (可重複使用工作流程) → Composite Action (複合動作)** 的分層架構。新增檢查機制時，請依循此模式以保持架構整潔與一致性。

## 架構概觀

1.  **Entrypoint (`entrypoint.yml`)**: 協調者。定義所有可用的檢查開關，並彙整最終報告。
2.  **Reusable Workflow (`reusables-*.yml`)**: 中介層。負責呼叫具體的 Action，處理權限與 Secrets。
3.  **Composite Action (`actions/*/action.yml`)**: 實作層。包含實際的檢查邏輯、工具安裝與腳本執行。

---

## 步驟 1：建立 Composite Action

這是實際執行檢查的地方。

1.  在 `.github/actions/` 下建立新的目錄，例如 `my-new-checks`。
2.  建立 `action.yml` 和 `scripts/` 目錄。

**`.github/actions/my-new-checks/action.yml` 範例：**

```yaml
name: "My New Checks"
description: "Run my new custom checks"

inputs:
  my-option:
    description: "An option for the check"
    required: false
    default: "default-value"

outputs:
  # 統一輸出命名格式：<category>-status 和 <category>-summary
  new-check-status:
    description: "Status of the checks (success or failure)"
    value: ${{ steps.outcome.outputs.status }}
  new-check-summary:
    description: "Summary for the PR comment"
    value: ${{ steps.outcome.outputs.summary }}

runs:
  using: "composite"
  steps:
    - name: Run Check
      id: check_step
      shell: bash
      # 重要：使用 continue-on-error 避免單一檢查失敗導致整個 Job 中斷
      continue-on-error: true
      run: |
        # 執行您的檢查腳本
        ${{ github.action_path }}/scripts/run-check.sh

    - name: Set Outcome
      id: outcome
      if: always() # 確保即使檢查失敗也會執行此步驟
      shell: bash
      run: |
        if [[ "${{ steps.check_step.outcome }}" == "failure" ]]; then
          echo "status=failure" >> "$GITHUB_OUTPUT"
          echo "summary=❌ **My Check:** Failed." >> "$GITHUB_OUTPUT"
        else
          echo "status=success" >> "$GITHUB_OUTPUT"
          echo "summary=✅ **My Check:** Passed." >> "$GITHUB_OUTPUT"
        fi
```

### 腳本規範 (`scripts/*.sh`)

-   使用 `#!/usr/bin/env bash`
-   設定 `export LC_ALL=C`
-   腳本失敗時不要直接 `exit 1`（除非是致命錯誤），應輸出錯誤並由 `action.yml` 判斷 `outcome`。

---

## 步驟 2：建立 Reusable Workflow

這個 Workflow 負責包裝 Composite Action，讓 `entrypoint.yml` 可以呼叫。

**`.github/workflows/reusables-new-check.yml` 範例：**

```yaml
name: "My New Quality Checks"

on:  # yamllint disable-line rule:truthy
  workflow_call:
    inputs:
      my-option:
        description: "Option passed from entrypoint"
        required: false
        type: string
        default: "default"
    secrets:
      CHECKER_TOKEN:
        required: true
    outputs:
      # 對應 Composite Action 的輸出
      new-check-status:
        value: ${{ jobs.new-check-job.outputs.new-check-status }}
      new-check-summary:
        value: ${{ jobs.new-check-job.outputs.new-check-summary }}

jobs:
  new-check-job:
    name: "Run New Checks"
    runs-on: ubuntu-latest
    outputs:
      new-check-status: ${{ steps.run.outputs.new-check-status }}
      new-check-summary: ${{ steps.run.outputs.new-check-summary }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Run Composite Action
        id: run
        uses: ./.github/actions/my-new-checks
        with:
          my-option: ${{ inputs.my-option }}

---

## 步驟 3：更新 Entrypoint (`entrypoint.yml`)

這是最關鍵的一步，將新的 Workflow 整合到主流程中。

### 1. 新增 Input
在 `on: workflow_call: inputs:` 區段新增開關：

```yaml
      run-new-checks:
        description: 'Whether to run the new checks.'
        required: false
        type: boolean
        default: false
```

### 2. 新增 Job
呼叫您在步驟 2 建立的 Workflow：

```yaml
  call-new-checks:
    name: Run New Quality Checks
    if: inputs.run-new-checks
    uses: ./.github/workflows/reusables-new-check.yml
    with:
      my-option: 'some-value'
    secrets:
      CHECKER_TOKEN: ${{ secrets.CHECKER_TOKEN }}
```

### 3. 更新報告 (JavaScript)
在 `report-summary` Job 中：
1.  將 `call-new-checks` 加入 `needs` 列表。
2.  更新 `github-script` 步驟，解析輸出並產生報告。

```javascript
            // --- New Checks ---
            if (wasJobRun(needs['call-new-checks'])) {
              anyJobRan = true;
              const { outputs } = needs['call-new-checks'];

              if (outputs) {
                // 取得 Summary
                comment_body += getOutput(outputs, 'new-check-summary',
                  '⚠️ **New Check:** No output received') + "\n";
                
                // 判斷狀態
                if (getOutput(outputs, 'new-check-status') === 'failure') {
                  all_passed = false;
                }
              } else {
                comment_body += "⚠️ **New Checks:** Completed but no outputs received\n";
              }
            }
```

---

## 步驟 4：更新文件與測試

1.  **更新 `README.md`**：在 Inputs 列表中加入新的參數說明。
2.  **本地驗證**：
    ```bash
    # 檢查 YAML 語法
    yamllint .github/

    # 檢查 Shell 腳本
    shellcheck .github/actions/my-new-checks/scripts/*.sh

    # 使用 act 進行本地模擬測試 (需先安裝 act)
    # 列出可用工作流程
    act pull_request --list

    # 進行 dry-run (不實際執行)
    act pull_request -n
    ```
3.  **整合測試**：建立一個測試用的 PR，開啟該檢查，確認 Bot 有正確留言回報狀態。

## 命名慣例

-   **Workflow 檔案**: `reusables-<category>.yml`
-   **Action 目錄**: `.github/actions/<category>-checks/`
-   **Job ID**: `call-<category>-checks`
-   **Outputs**: `<category>-status`, `<category>-summary`