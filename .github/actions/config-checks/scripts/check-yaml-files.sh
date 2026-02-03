#!/usr/bin/env bash
# Check YAML Files
# Runs yamllint on all YAML files and generates GitHub annotations

# Find all YAML files (*.yml, *.yaml) excluding node_modules and .git
YAML_FILES=$(find . -type f \( -name "*.yml" -o -name "*.yaml" \) \
	! -path "*/node_modules/*" \
	! -path "*/.git/*" \
	! -path "*/venv/*" \
	! -path "*/.venv/*" \
	2>/dev/null || true)

if [ -z "$YAML_FILES" ]; then
	MESSAGE="✅ **YAML Files:** No YAML files found to check"
	STATUS="success"
else
	FILE_COUNT=$(echo "$YAML_FILES" | wc -l)

	# Run yamllint with relaxed configuration
	set +e
	YAMLLINT_OUTPUT=$(echo "$YAML_FILES" | xargs uv run yamllint -f parsable 2>&1)
	YAMLLINT_EXIT=$?
	set -e

	if [ $YAMLLINT_EXIT -eq 0 ]; then
		MESSAGE="✅ **YAML Files:** All $FILE_COUNT file(s) passed validation"
		STATUS="success"
	else
		# Count failed files
		FAILED_COUNT=$(echo "$YAMLLINT_OUTPUT" | cut -d':' -f1 | sort -u | wc -l)
		# Get first failed file for summary
		FIRST_FAILED=$(echo "$YAMLLINT_OUTPUT" | head -n 1 | cut -d':' -f1)

		MESSAGE="❌ **YAML Files:** Found issues in $FAILED_COUNT of $FILE_COUNT file(s) (e.g., \`$FIRST_FAILED\`)"
		STATUS="failure"

		# Show errors in GitHub annotations
		echo "$YAMLLINT_OUTPUT" | while IFS=: read -r file line col level msg; do
			if [ -n "$file" ] && [ -n "$line" ]; then
				# Clean up level (remove brackets)
				clean_level=$(echo "$level" | tr -d '[]' | xargs)
				# Map yamllint level to GitHub annotation level
				if [ "$clean_level" = "warning" ]; then
					gh_level="warning"
				else
					gh_level="error"
				fi
				echo "::${gh_level} file=${file},line=${line},col=${col}::${msg}"
			fi
		done
	fi
fi

{
	echo "status=$STATUS"
	echo "summary=$MESSAGE"
} >>"$GITHUB_OUTPUT"
