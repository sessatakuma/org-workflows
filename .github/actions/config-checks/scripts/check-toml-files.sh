#!/usr/bin/env bash
# Check TOML Files
# Validates TOML syntax using taplo and generates GitHub annotations

# Find all TOML files excluding node_modules and .git
TOML_FILES=$(find . -type f -name "*.toml" \
	! -path "*/node_modules/*" \
	! -path "*/.git/*" \
	! -path "*/venv/*" \
	! -path "*/.venv/*" \
	2>/dev/null || true)

if [ -z "$TOML_FILES" ]; then
	MESSAGE="✅ **TOML Files:** No TOML files found to check"
	STATUS="success"
else
	FILE_COUNT=$(echo "$TOML_FILES" | wc -l)

	# Run taplo check
	set +e
	TAPLO_OUTPUT=$(echo "$TOML_FILES" | xargs taplo check 2>&1)
	TAPLO_EXIT=$?
	set -e

	if [ $TAPLO_EXIT -eq 0 ]; then
		MESSAGE="✅ **TOML Files:** All $FILE_COUNT file(s) are valid"
		STATUS="success"
	else
		# Extract failed files from taplo output
		FAILED_FILES=$(echo "$TAPLO_OUTPUT" | grep -oP '(?<=")[^"]+\.toml(?=")' | head -n 1 || echo "unknown")
		FAILED_COUNT=$(echo "$TAPLO_OUTPUT" | grep -c "error" || echo "1")

		MESSAGE="❌ **TOML Files:** Found syntax errors in TOML files (e.g., \`$FAILED_FILES\`)"
		STATUS="failure"

		# Show errors as GitHub annotations
		# Taplo output is visual, e.g.:
		#   ┌─ file.toml:1:15
		echo "$TAPLO_OUTPUT" | while IFS= read -r line; do
			# Check for location line: ┌─ file:line:col
			if echo "$line" | grep -q "┌─ "; then
				# Extract info using sed
				# Remove leading whitespace and ┌─
				clean_line=$(echo "$line" | sed 's/^[[:space:]]*┌─ //')
				file=$(echo "$clean_line" | cut -d':' -f1)
				line_num=$(echo "$clean_line" | cut -d':' -f2)
				col_num=$(echo "$clean_line" | cut -d':' -f3)

				if [ -n "$file" ] && [ -n "$line_num" ]; then
					echo "::error file=${file},line=${line_num},col=${col_num}::TOML syntax error"
				fi
			elif echo "$line" | grep -q "error:"; then
				# Fallback for general errors
				echo "::error::TOML: ${line}"
			fi
		done
	fi
fi

{
	echo "status=$STATUS"
	echo "summary=$MESSAGE"
} >>"$GITHUB_OUTPUT"
