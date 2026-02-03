#!/usr/bin/env bash
# Check Prettier Formatting
# Runs prettier --check and generates annotations for files needing formatting

echo "Running prettier format check..."
set +e # Don't exit on prettier failure
npx prettier --check ./src 2>&1 | tee prettier_output.txt
PRETTIER_EXIT_CODE=$?
set -e

if [ $PRETTIER_EXIT_CODE -ne 0 ]; then
	# Extract filenames from prettier output and generate annotations
	grep -E "^\S+\.(js|jsx|ts|tsx|json|css|scss|md|yaml|yml)$" prettier_output.txt | while read -r file; do
		if [ -f "$file" ]; then
			echo "::error title=Prettier Formatting,file=${file},line=1,col=1::File needs formatting. Run 'npm run format' to fix."
		fi
	done
	echo "status=failure" >>"$GITHUB_OUTPUT"
	echo "summary=❌ **Prettier:** Formatting issues found. Please review the annotations above." >>"$GITHUB_OUTPUT"
else
	echo "status=success" >>"$GITHUB_OUTPUT"
	echo "summary=✅ **Prettier:** All files are properly formatted." >>"$GITHUB_OUTPUT"
fi
