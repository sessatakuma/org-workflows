# Sessatakuma CI workflows
```yml
name: PR Checks

on:
  pull_request:
    branches: [ "main", "dev" ]
    types:
      - opened
      - edited
      - reopened
      - synchronize
```

## Basic PR Quality Checks
This checker will check:
1. PR title
2. Branch name
3. Commit messages
4. Conflicts

Use the following settings in `.github/workflows/basic.yml`:
```yml
permissions:
  contents: read
  pull-requests: write
  issues: write

jobs:
  call-basic-checks:
    name: Run Organization Basic PR Quality Checks
    uses: sessatakuma/org-workflows/.github/workflows/basic.yml@main
    secrets:
      CHECKER_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```


## Python Code Quality Checks
This checker will check:
1. Code formatting (with Ruff)
2. Code linting (with Ruff)
3. Type checking (with Mypy)

Use the following settings in `.github/workflows/python.yml`:
```yml
permissions:
  contents: read

jobs:
  call-python-checks:
    name: Run Organization Python Quality Checks
    uses: sessatakuma/org-workflows/.github/workflows/python.yml@main
    with:
      # Optional: specify the Python version. Defaults to '3.11'.
      python-version: '3.11'
```

