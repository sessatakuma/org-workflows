#!/usr/bin/env bash
# Parse Mypy Output
# Reads mypy_output.txt and generates GitHub annotations

if [ -f mypy_output.txt ]; then
	while IFS= read -r line; do
		# Match pattern: file.py:line:column: error_type: message
		if echo "$line" | grep -qE '^[^:]+:[0-9]+:[0-9]*:'; then
			# Extract file, line, column, error type, and message
			file=$(echo "$line" | cut -d':' -f1)
			line_num=$(echo "$line" | cut -d':' -f2)
			col_num=$(echo "$line" | cut -d':' -f3)
			rest=$(echo "$line" | cut -d':' -f4-)

			# Extract error type (error, warning, note) and message
			error_type=$(echo "$rest" | sed -E 's/^[[:space:]]*(error|warning|note):.*/\1/')
			message=$(echo "$rest" | sed -E 's/^[[:space:]]*(error|warning|note):[[:space:]]*//')

			# Determine annotation level
			case "$error_type" in
			error) level="error" ;;
			warning) level="warning" ;;
			note) level="notice" ;;
			*) level="error" ;;
			esac

			# Generate GitHub annotation
			if [ -n "$col_num" ] && [ "$col_num" != " " ]; then
				echo "::${level} title=Mypy (${error_type}),file=${file},line=${line_num},col=${col_num}::${file}:${line_num}:${col_num}: ${error_type}: ${message}"
			else
				echo "::${level} title=Mypy (${error_type}),file=${file},line=${line_num}::${file}:${line_num}: ${error_type}: ${message}"
			fi
		fi
	done <mypy_output.txt
fi
