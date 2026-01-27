## 📄 如何新增一個全新的檢查類別

> [!WARNING]
> Half written by claude-opus-4-5-thinking.

假設您想新增一個「文件拼寫檢查」（Doc Linting）類別，並希望它像 `run-python-checks` 一樣可以被開啟或關閉。

這需要三個部分的修改：

1.  **建立**新的可重用工作流程（`.github/workflows/reusables-docs.yml`）並設定其輸出。
2.  **修改**這個協同調度器檔案（`.github/workflows/entrypoint.yml`）來呼叫它並讀取其結果。
3. **更新**說明文件 `README.md` 讓其它人可以知道如何使用。

### 第 1 步：建立可重用的工作流程

這就是您「如何設定輸出」問題的答案。輸出是子工作流程回報給此協同調度器的方式。

您必須遵循 `report-summary` 腳本中設定的**命名慣例**：

  * `[check-name]-summary`: (必要) 一段人類可讀的摘要字串，將會被貼到 PR 留言中。
  * `[check-name]-status`: (必要) 一個狀態字串，通常是 `success` 或 `failure`。

**範例： `.github/workflows/reusables-docs.yml`**

```yaml
name: 'Reusable Docs Linting'

on:
  workflow_call:
    # 1. 在這裡定義工作流程的「輸出」，
    # 這樣協同調度器才能接收它們。
    outputs:
      docs-lint-summary:
        description: 'Summary of the docs linting check.'
        value: ${{ jobs.lint-docs.outputs.summary }}
      docs-lint-status:
        description: 'Status (success/failure) of the docs linting check.'
        value: ${{ jobs.lint-docs.outputs.status }}
    secrets:
      CHECKER_TOKEN:
        required: true

jobs:
  lint-docs:
    name: Run Docs Linter
    runs-on: ubuntu-latest
    
    # 2. 讓任務（Job）也定義「輸出」
    outputs:
      summary: ${{ steps.run-linter.outputs.summary }}
      status: ${{ steps.run-linter.outcome }} # 'outcome' 會是 'success' 或 'failure'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      # --- 這是您實際的檢查邏輯 ---
      - name: Run Spell Check
        id: run-linter # 3. 給這個步驟一個 ID
        # 假設 linter 成功時退出 0，失敗時退出 1
        # 'continue-on-error: true' 很重要，這樣才能繼續執行並報告失敗
        continue-on-error: true
        run: |
          echo "Running spell check..."
          # 這裡放您的實際 linter 指令
          # spell-check-command --report-file spell-report.txt
          
          # 假設檢查失敗
          echo "Spell check failed"
          exit 1 

      # --- 這是設定輸出的關鍵步驟 ---
      - name: Set Linter Output
        # 4. 根據 'run-linter' 步驟的結果來設定「步驟輸出」
        id: set-output
        if: always()
        run: |
          if: ${{ steps.run-linter.outcome == 'success' }}
          then
            echo "summary=✅ **Docs Linting:** All files look good!" >> $GITHUB_OUTPUT
          else
            echo "summary=❌ **Docs Linting:** Found spelling errors." >> $GITHUB_OUTPUT
          fi
```

#### 開發規範

##### yamllint 合規
所有 workflow 檔案必須通過 `yamllint` 檢查。常見注意事項：
- 檔案開頭加 `---`
- 避免行尾空白
- 確保檔案結尾有換行符

> [!TIP]
> `on:` 關鍵字會觸發 yamllint 的 truthy 警告，建議使用：
> ```yaml
> on:  # yamllint disable-line rule:truthy
> ```

##### 外部腳本
當 shell 指令較為複雜（例如包含迴圈、條件判斷、多行邏輯）時，應提取至 `.github/scripts/` 目錄：
- 腳本需為可執行檔（`chmod +x`）
- 透過 `env:` 區塊傳遞 workflow expressions 給腳本
- 輸出寫入 `$GITHUB_OUTPUT`

```yaml
- name: Check Something
  env:
    MY_VAR: ${{ github.event.pull_request.title }}
  run: .github/scripts/check-something.sh
```

-----

### 第 2 步：修改協同調度器

現在您有了一個 `.github/workflows/reusables-docs.yml`，您需要讓這個協同調度器檔案去呼叫它。

**1. 新增一個 `input` 來控制它：**

在 `on.workflow_call.inputs` 區塊，新增：

```yaml
      run-docs-checks:
        description: 'Whether to run the documentation quality checks.'
        required: false
        type: boolean
        default: false
```

**2. 新增一個 `job` 來呼叫它：**

在 `jobs` 區塊，新增一個 `call-docs-checks` 任務：

```yaml
  call-docs-checks:
    name: Run Documentation Quality Checks
    if: inputs.run-docs-checks # 使用您剛才新增的 input
    uses: ./.github/workflows/reusables-docs.yml
    secrets:
      CHECKER_TOKEN: ${{ secrets.CHECKER_TOKEN }}
```

**3. 更新 `report-summary` 任務：**

這是最後且最重要的一步。

  * **A. 新增 `needs` 依賴：**
    告訴 `report-summary` 任務也要等待 `call-docs-checks` 完成。

    ```yaml
    report-summary:
      name: Report Overall Summary
      runs-on: ubuntu-latest
      needs:
        - call-basic-checks
        - call-python-checks
        - call-config-checks
        - call-docs-checks  # <-- 新增這一行
      if: always()
      ...
    ```

  * **B. 更新 `github-script` 腳本：**
    在腳本中新增一個區塊來讀取 `needs['call-docs-checks']` 的輸出。把它放在 "Config Checks" 區塊後面即可。

    ```javascript
            // ... (Config Checks 區塊結束) ...

            // --- Docs Checks ---
            if (wasJobRun(needs['call-docs-checks'])) {
              anyJobRan = true;
              const { outputs } = needs['call-docs-checks'];
              
              if (outputs) {
                // 'docs-lint-summary' 必須符合您在 reusables-docs.yml 中定義的 output 名稱
                comment_body += getOutput(outputs, 'docs-lint-summary', '⚠️ **Docs Linting:** No output received') + "\n";
                
                // 'docs-lint-status' 也是
                if (getOutput(outputs, 'docs-lint-status') === 'failure') {
                  all_passed = false;
                }
              } else {
                comment_body += "⚠️ **Docs Checks:** Completed but no outputs received\n";
              }
            }
            
            // --- Detailed Reports ---
            // ...
    ```

### 第 3 步：更新說明文件


在功能開發完成後，最後一步是更新文件，讓組織中的其他成員知道這項新檢查的存在，以及如何在他們的專案中啟用它。

您主要需要更新`README.md`的兩個地方：

1. 新增arguments的說明。
2. 新增checking details的說明。 


在您的 `README.md` 檔案中，找到說明可用 `inputs` 的部分，並新增 `run-docs-checks` 的條目。

| Input | Description | Type | Default |
| :--- | :--- | :--- | :--- |
| `run-basic-checks` | Whether to run the basic PR quality checks. | `boolean` | `true` |
| `run-python-checks` | Whether to run the Python code quality checks. | `boolean` | `false` |
| `python-version` | The Python version to use for the Python checks. | `string` | `'3.11'` |
| `run-config-checks` | Whether to run the configuration files quality checks. | `boolean` | `false` |
| **`run-docs-checks`** | **Whether to run the documentation quality checks.** | **`boolean`** | **`false`** |

此外，記得在 `Checking details` 內簡單說明你的workflows檢查了什麼項目。


```
### Python Code Quality Checks
This checker will validate:
1. **Syntax of the markdown file**: ...
2. ... 
```

-----

完成這三步後，您的新檢查類別就完全整合並準備好供組織內的其他專案使用了。
