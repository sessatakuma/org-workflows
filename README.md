# Sessatakuma Quality Checking Workflows
This is a repository with our shared workflows.

To use this to check code before PR, please refer to [sample caller](.github/workflows/main.yml).

We have implemented the following checkers:

## Basic PR Quality Checks
This checker will validate:
1. **PR title** - Conventional commit format, length, and case
2. **Branch name** - Type-based naming convention
3. **Commit messages** - Format, length, and case with detailed reports
4. **Conflicts** - Detects unresolved merge conflict markers

## Python Code Quality Checks
This checker will validate:
1. **Code formatting** (with Ruff) - Ensures consistent code style
2. **Code linting** (with Ruff) - Catches common errors and issues
3. **Type checking** (with Mypy) - Validates type hints

**Note:** Python checks create inline annotations on your PR for easy identification of issues.

## Configuration Files Quality Checks
This checker will validate:
1. **YAML files** (with yamllint) - Validates syntax and style
2. **JSON files** (with jq) - Validates JSON syntax
3. **TOML files** (with taplo-cli) - Validates TOML syntax and formatting

**Note:** Configuration checks create inline annotations for syntax errors.

