# Sessatakuma Quality Checking Workflows
This is a repository with our shared workflows.

To use this to check code before PR, please refer to [sample caller](.github/workflows/main.yml).

We have implement following checkers:
## Basic PR Quality Checks
This checker will check:
1. PR title
2. Branch name
3. Commit messages
4. Conflicts

## Python Code Quality Checks
This checker will check:
1. Code formatting (with Ruff)
2. Code linting (with Ruff)
3. Type checking (with Mypy)

