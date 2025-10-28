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
      
permissions:
  contents: read
  pull-requests: write
```

## Basic PR Quality Checks
This checker will check:
1. commit format (with commitlint)
2. PR title format
3. Branch format
4. Unresolved conflicts

Use the following settings in `.github/workflows/ci.yml`:
```yml
jobs:
  call-basic-checks:
    name: Run Organization Basic PR Quality Checks
    uses: sessatakuma/org-workflows/.github/workflows/basic.yml@main
    secrets:
      CHECKER_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```