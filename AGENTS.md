# AGENTS.md - Development Guide for AI Coding Agents

This repository contains **GitHub Actions workflows** for the Sessatakuma organization. It provides reusable workflows for PR quality gates across multiple tech stacks (Python, Go, Frontend, Config files).

## Project Overview

**Architecture**: Caller → Orchestrator (`entrypoint.yml`) → Composite Actions (`.github/actions/`)
**Languages**: Bash shell scripts, GitHub Actions YAML, JavaScript (for GitHub Scripts)
**No build system**: This is a workflow repository, not an application. No tests to run.

## Core Directories

```
.github/
├── workflows/           # Reusable workflow orchestration
│   ├── entrypoint.yml  # Main entry point (callers invoke this)
│   └── reusables-*.yml # Individual check suites (python, go, frontend, etc.)
└── actions/            # Composite actions (the actual check implementations)
    ├── basic-checks/   # PR title, branch name, commit messages, merge conflicts
    ├── python-checks/  # Ruff formatter, Ruff linter, Mypy type checking
    ├── go-checks/      # golangci-lint, go test -race, go build
    ├── frontend-checks/# Prettier, ESLint
    └── config-checks/  # YAML, JSON, TOML validation
```

## Development Workflow

### Build and Test Commands

**Local validation** (run before committing):

```bash
# 1. Validate all YAML files
yamllint .github/

# 2. Check shell scripts for common issues
find .github/actions -name "*.sh" -exec shellcheck {} \;

# 3. Test workflows locally with act (GitHub Actions runner)
# Note: act simulates GitHub Actions but has limitations with composite actions
act pull_request --list  # List available workflows
act pull_request -n      # Dry run (show what would execute)
act pull_request -j quality-checks  # Run specific job (requires .secrets file)
```

**act setup** (first time only):
```bash
# Install act: https://github.com/nektos/act
# Ubuntu/Debian: apt install act
# macOS: brew install act

# Create .secrets file for local testing (optional)
cat > .secrets << EOF
GITHUB_TOKEN=your_github_token_here
EOF
```

**act limitations**:
- Composite actions with relative paths may not work perfectly
- Some GitHub-specific features (OIDC, hosted runners) won't work
- Best for validating workflow structure, not full integration testing

### Testing Your Changes

**Recommended approach** (end-to-end test):
1. Create a test repository or use an existing one
2. Add a workflow that calls this repo's `entrypoint.yml`:
   ```yaml
   uses: sessatakuma/org-workflows/.github/workflows/entrypoint.yml@your-branch
   ```
3. Create a PR to trigger the workflow
4. Check the PR comment for results

**Quick validation** (local):
1. Run `yamllint .github/` to catch YAML syntax errors
2. Run `shellcheck` on modified shell scripts
3. Use `act -n` to dry-run workflow logic

## Code Style Guidelines

### 1. GitHub Actions YAML

**File naming**:
- Reusable workflows: `reusables-<category>.yml` (e.g., `reusables-python.yml`)
- Composite actions: `action.yml` (inside `.github/actions/<name>/`)
- Main orchestrator: `entrypoint.yml`

**Structure**:
```yaml
---
name: 'Descriptive Name in Title Case'

on:  # yamllint disable-line rule:truthy
  workflow_call:
    inputs:
      input-name:
        description: 'Clear description ending with period.'
        required: false
        type: boolean
        default: true
    secrets:
      SECRET_NAME:
        description: 'Description of secret.'
        required: true

jobs:
  job-name:
    name: Human Readable Job Name
    runs-on: ubuntu-latest
    steps:
      - name: Action Step Name (imperative mood)
        run: |
          echo "Multi-line commands"
```

**Conventions**:
- Use `---` YAML document start marker
- Add `# yamllint disable-line rule:truthy` after `on:` to satisfy yamllint
- Input/output names: `kebab-case`
- Job IDs: `kebab-case`
- Step names: Title Case, imperative mood ("Run Tests", not "Running Tests")
- Descriptions: End with period
- Always quote string values in inputs/outputs
- Use `if: always()` when aggregating results from `continue-on-error: true` steps

### 2. Shell Scripts

**File structure**:
```bash
#!/usr/bin/env bash
# Title: What This Script Does
# Brief description of validation logic and cascading checks

# Force standard locale
export LC_ALL=C

# Script reads from environment variables:
# - VAR_NAME: Description
# - ANOTHER_VAR: Description

# Script logic here...

# Output to GitHub Actions
{
  echo "status=$STATUS"
  echo "summary=$MESSAGE"
} >> "$GITHUB_OUTPUT"

# Exit based on outcome
if [ "$STATUS" == "failure" ]; then
  exit 0  # Don't fail the step; let orchestrator aggregate
fi
```

**Conventions**:
- Use `#!/usr/bin/env bash` shebang
- Always `export LC_ALL=C` for consistent regex behavior
- Document expected environment variables at the top
- Use `[[:space:]]` instead of literal spaces in regex (POSIX compatibility)
- Variable names: `SCREAMING_SNAKE_CASE` for constants/env vars
- Use `"$VARIABLE"` quoting (always quote variables)
- Prefer `[[ ]]` over `[ ]` for conditionals (bash-specific but more robust)
- Use tabs for indentation (repository convention observed in scripts)
- Output status/summary via `$GITHUB_OUTPUT` redirection
- Exit with `exit 0` even on logical failure; use `status=failure` output instead
- Use `continue-on-error: true` in action.yml when calling scripts

### 3. Naming Conventions

**Outputs** (in YAML):
- Format: `<category>-<check>-<type>`
- Examples:
  - `python-status` (overall status)
  - `python-summary` (human-readable summary)
  - `pr-title-summary` (specific check summary)
  - `commit-messages-report` (detailed report for collapsible section)

**Environment variables**:
- `SCREAMING_SNAKE_CASE`
- Examples: `PR_TITLE`, `MAX_LENGTH`, `BASE_SHA`

**Job IDs**:
- `kebab-case`
- Examples: `call-python-checks`, `report-summary`, `lint-docs`

**Action directories**:
- `kebab-case`
- Examples: `basic-checks`, `python-checks`, `frontend-checks`

### 4. Error Handling

**Continue-on-error pattern**:
```yaml
- name: Run Check That Might Fail
  id: check_step
  continue-on-error: true  # Don't crash job
  run: |
    # Check logic here
    
- name: Aggregate Results
  if: always()  # Run even if previous steps failed
  run: |
    if [[ "${{ steps.check_step.outcome }}" == "failure" ]]; then
      echo "status=failure" >> $GITHUB_OUTPUT
    else
      echo "status=success" >> $GITHUB_OUTPUT
    fi
```

**Never**:
- Let individual checks crash the entire workflow
- Use `exit 1` in scripts that are part of a check suite (use `status=failure` output)
- Fail without setting a status output

**Always**:
- Use `continue-on-error: true` for check steps
- Aggregate outcomes in a final step with `if: always()`
- Provide clear, actionable error messages with emoji indicators (❌/✅/⚠️)

### 5. Output Formatting

**Summary format**:
```
✅ **Check Category:** Passed (details if any)
❌ **Check Category:** Failed (reason, actionable fix)
⚠️ **Check Category:** Warning or no output received
```

**Detailed reports** (collapsible):
```markdown
<details><summary>📋 Click for detailed report</summary>

\`\`\`
Raw output or structured report
\`\`\`

</details>
```

**Consistency**:
- Use emoji prefixes: ✅ success, ❌ failure, ⚠️ warning
- Bold check category names: `**Python Quality:**`
- Inline code for values: `` `$PR_TITLE` ``
- Use backticks for commands/code in summaries

## Adding New Workflow Checks

Follow the plugin architecture pattern. See `HOW_TO_ADD_WORKFLOWS.md` for detailed guide.

**Required changes**:
1. Create `.github/workflows/reusables-<name>.yml` with standardized outputs
2. Update `.github/workflows/entrypoint.yml`:
   - Add input parameter (`run-<name>-checks`)
   - Add job calling your reusable workflow
   - Update `report-summary` job's `needs` array
   - Add output aggregation logic in JavaScript
3. Update `README.md` documentation

**Output contract** (every reusable workflow MUST provide):
```yaml
outputs:
  <category>-status:
    description: 'Status: success or failure'
    value: ${{ jobs.<job-id>.outputs.status }}
  <category>-summary:
    description: 'Human-readable summary with emoji'
    value: ${{ jobs.<job-id>.outputs.summary }}
```

## Common Patterns

### Pattern 1: Cascading Validation
Check multiple conditions in sequence; only proceed if previous checks passed:
```bash
STATUS="success"

if [ condition1 ]; then
  STATUS="failure"
fi

if [ "$STATUS" == "success" ]; then
  # Only check condition2 if condition1 passed
  if [ condition2 ]; then
    STATUS="failure"
  fi
fi
```

### Pattern 2: Default Configuration Injection
Provide fallback configs if caller doesn't have them:
```yaml
- name: Create default config if missing
  env:
    DEFAULT_CONFIG: |
      # Config content here
  run: |
    if [ ! -f config-file ]; then
      echo "$DEFAULT_CONFIG" > config-file
    fi
```

### Pattern 3: Sticky Comment Reporting
Delete old bot comments, post fresh one:
```javascript
const comments = await github.rest.issues.listComments({...});
const botComments = comments.data.filter(c => 
  c.user.type === 'Bot' && c.body.includes('Marker String')
);
for (const comment of botComments) {
  await github.rest.issues.deleteComment({comment_id: comment.id});
}
await github.rest.issues.createComment({body: newComment});
```

## Commit Message Format

Follow Conventional Commits:
- Format: `<type>: <description>`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Description must start with lowercase letter
- Max length: 50 characters (configurable per check)

## Documentation

When modifying workflows:
- Update `README.md` if changing user-facing inputs/behavior
- Update `HOW_TO_ADD_WORKFLOWS.md` if changing the plugin pattern
- Add inline comments in complex JavaScript (in `github-script` steps)
- Keep YAML comments minimal (prefer self-documenting names)
