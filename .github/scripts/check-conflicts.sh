#!/bin/bash
# Checks for unresolved merge conflict markers in the repository.

set -e

# Search for conflict markers recursively in the current directory.
# Exclude common directories like .git and node_modules.
# The '|| true' prevents the script from exiting if grep finds no matches.
CONFLICT_FILES=$(grep -r -n -E '<<<<<<<|=======|>>>>>>>' \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  . 2>/dev/null || true)

# If conflict markers were found...
if [ -n "$CONFLICT_FILES" ]; then
  # Get the name of the first file containing conflicts for the summary message.
  FIRST_FILE=$(echo "$CONFLICT_FILES" | head -n 1 | cut -d: -f1)
  # Count the total number of unique files with conflicts.
  FILE_COUNT=$(echo "$CONFLICT_FILES" | cut -d: -f1 | sort -u | wc -l)
  
  MESSAGE="❌ **Conflicts:** Found unresolved merge markers in $FILE_COUNT file(s) (e.g., \`$FIRST_FILE\`)"
  STATUS="failure"
# If no conflicts were found...
else
  MESSAGE="✅ **Conflicts:** No merge conflict markers found"
  STATUS="success"
fi

# Write the outputs for the workflow.
{
  echo "status=$STATUS"
  echo "summary=$MESSAGE"
} >> "$GITHUB_OUTPUT"

# If the check failed, exit with 0. The orchestrator will handle the failure.
if [ "$STATUS" == "failure" ]; then
  exit 0
fi
