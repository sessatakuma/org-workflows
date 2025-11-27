# Sessatakuma Quality Checking Workflows
This is a repository with our shared workflows.


## Arguments
To use this to check code before PR, please refer to [sample caller](.github/workflows/main.yml).

To apply workflows, please set the following arguments in `with` section:

| Input | Description | Type | Default |
| :--- | :--- | :--- | :--- |
| `run-basic-checks` | Whether to run the basic PR quality checks. | `boolean` | `true` |
| `run-python-checks` | Whether to run the Python code quality checks. | `boolean` | `false` |
| `python-version` | The Python version to use for the Python checks. | `string` | `'3.11'` |
| `run-config-checks` | Whether to run the configuration files quality checks. | `boolean` | `false` |
| `run-frontend-checks` | Whether to run the frontend code quality checks. | `boolean` | `false` |

## Checking details
### Basic PR Quality Checks
This checker will validate:
1. **PR Title Validation**
   - Checks for conventional commit format (e.g., `feat:`, `fix:`, `docs:`)
   - Validates title length (typically 50-72 characters)
   - Ensures proper capitalization and formatting
   - Generates clear feedback for non-compliant titles
2. **Branch Name Validation**
   - Enforces type-based naming conventions (e.g., `feature/`, `bugfix/`, `hotfix/`)
   - Validates branch name format and structure
   - Provides suggestions for proper naming patterns
3. **Commit Message Analysis**
   - Analyzes all commit messages in the PR
   - Validates conventional commit format for each commit
   - Checks message length and capitalization rules
   - Provides detailed reports with specific line-by-line feedback
4. **Merge Conflict Detection**
   - Scans all files for unresolved merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
   - Creates annotations pointing to specific conflict locations
   - Prevents accidental merging of conflicted code

**Note:** Basic checks provide comprehensive feedback through PR comments and status checks.

### Python Code Quality Checks
This checker will validate:
1. **Ruff Code Formatting Check**
   - Runs `ruff format . --check --output-format=github` to verify code formatting
   - Automatically generates GitHub annotations for formatting violations
   - Uses Ruff's fast Python formatter for consistent code style
   - Provides clear indication of files that need formatting fixes
2. **Ruff Linting Analysis**
   - Executes `ruff check . --output-format=github` for comprehensive linting
   - Catches common Python errors, style issues, and code smells
   - Generates GitHub annotations with file, line, and column information
   - Includes rule codes (e.g., F401, E501) for easy reference and configuration
3. **Mypy Type Checking**
   - Runs `mypy .` to validate type hints and catch type-related errors
   - Parses mypy output format: `file.py:line:column: error_type: message`
   - Generates GitHub annotations with proper error/warning/notice levels
   - Creates detailed annotations with file locations and error descriptions
   - Distinguishes between errors, warnings, and informational notes

**Note:** Python checks create comprehensive inline annotations on your PR with precise file locations, making it easy to identify and fix issues directly from the GitHub interface.

### Configuration Files Quality Checks
This checker will validate:
1. **YAML File Validation (yamllint)**
   - Runs `yamllint` to check YAML syntax and style compliance
   - Validates indentation, line length, and YAML structure
   - Generates GitHub annotations for syntax errors and style violations
   - Checks for common YAML pitfalls like incorrect boolean values and quotes
2. **JSON File Validation (jq)**
   - Uses `jq` to parse and validate JSON file syntax
   - Detects malformed JSON, missing brackets, and trailing commas
   - Creates annotations pointing to specific syntax error locations
   - Ensures JSON files are properly formatted and parseable
3. **TOML File Validation (taplo-cli)**
   - Executes `taplo-cli check` for TOML syntax and formatting validation
   - Validates TOML structure, key-value pairs, and data types
   - Generates annotations for syntax errors and formatting issues
   - Ensures TOML files follow proper formatting standards

**Note:** Configuration file checks create precise inline annotations for syntax errors, with clear error messages and exact file locations for quick resolution.

### Frontend Code Quality Checks
This checker will validate:
1. **Prettier Formatting Check**
   - Runs prettier to verify code formatting
   - Generates GitHub annotations for files that need formatting
   - Provides helpful error messages with fix instructions
2. **ESLint Linting Check**
   - Runs ESLint with JSON output format
   - Parses the JSON results using Node.js
   - Creates proper GitHub annotations with file, line, column info
   - Distinguishes between errors and warnings
   - Includes rule IDs in annotation titles