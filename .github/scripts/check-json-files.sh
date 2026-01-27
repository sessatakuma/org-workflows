#!/usr/bin/env bash
# Check JSON Files
# Validates JSON syntax using jq and generates GitHub annotations

# Find all JSON files excluding node_modules and .git
JSON_FILES=$(find . -type f -name "*.json" \
	! -path "*/node_modules/*" \
	! -path "*/.git/*" \
	! -path "*/venv/*" \
	! -path "*/.venv/*" \
	! -path "*/.next/*" \
	! -path "*/dist/*" \
	! -path "*/build/*" \
	2>/dev/null || true)

if [ -z "$JSON_FILES" ]; then
	MESSAGE="✅ **JSON Files:** No JSON files found to check"
	STATUS="success"
else
	FILE_COUNT=$(echo "$JSON_FILES" | wc -l)
	FAILED_FILES=""
	FAILED_COUNT=0

	# Check each JSON file
	while IFS= read -r file; do
		if ! jq empty "$file" >/dev/null 2>&1; then
			FAILED_COUNT=$((FAILED_COUNT + 1))
			if [ -z "$FAILED_FILES" ]; then
				FAILED_FILES="$file"
			fi
			# Get error details
			ERROR_OUTPUT=$(jq empty "$file" 2>&1 || true)

			# Extract line and column if possible
			# Example: parse error: ... at line 10, column 20
			if echo "$ERROR_OUTPUT" | grep -q "at line [0-9]\+, column [0-9]\+"; then
				line=$(echo "$ERROR_OUTPUT" | grep -o "at line [0-9]\+" | grep -o "[0-9]\+")
				col=$(echo "$ERROR_OUTPUT" | grep -o "column [0-9]\+" | grep -o "[0-9]\+")
				msg=$(echo "$ERROR_OUTPUT" | sed -E 's/.*: (.*) at line.*/\1/')
				echo "::error file=${file},line=${line},col=${col}::${msg}"
			else
				echo "::error file=${file}::JSON validation failed: ${ERROR_OUTPUT}"
			fi
		fi
	done <<<"$JSON_FILES"

	if [ $FAILED_COUNT -eq 0 ]; then
		MESSAGE="✅ **JSON Files:** All $FILE_COUNT file(s) are valid"
		STATUS="success"
	else
		MESSAGE="❌ **JSON Files:** $FAILED_COUNT of $FILE_COUNT file(s) failed validation (e.g., \`$FAILED_FILES\`)"
		STATUS="failure"
	fi
fi

{
	echo "status=$STATUS"
	echo "summary=$MESSAGE"
} >>"$GITHUB_OUTPUT"
