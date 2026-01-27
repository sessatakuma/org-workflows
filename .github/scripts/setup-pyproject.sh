#!/usr/bin/env bash
# Setup Default Python Project Configuration
# Creates or updates pyproject.toml with default ruff and mypy configs

# Script reads from environment variables:
# - DEFAULT_PROJECT_CONFIG
# - DEFAULT_RUFF_CONFIG
# - DEFAULT_MYPY_CONFIG

if [ ! -f "pyproject.toml" ]; then
	echo "Creating default pyproject.toml..."
	{
		echo "${DEFAULT_PROJECT_CONFIG}"
		echo ""
		echo "${DEFAULT_RUFF_CONFIG}"
		echo ""
		echo "${DEFAULT_MYPY_CONFIG}"
	} >pyproject.toml
else
	# Check and add ruff config if missing
	if ! grep -q "\[tool.ruff\]" pyproject.toml; then
		echo "Adding default ruff configuration to pyproject.toml..."
		echo "" >>pyproject.toml
		echo "${DEFAULT_RUFF_CONFIG}" >>pyproject.toml
	fi

	# Check and add mypy config if missing
	if ! grep -q "\[tool.mypy\]" pyproject.toml; then
		echo "Adding default mypy configuration to pyproject.toml..."
		echo "" >>pyproject.toml
		echo "${DEFAULT_MYPY_CONFIG}" >>pyproject.toml
	fi
fi
