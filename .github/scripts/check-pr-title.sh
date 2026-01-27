#!/usr/bin/env bash
# Check PR Title Format
# Validates PR title with cascading checks: length, format, lowercase

# Script reads from environment variables:
# - TYPES: Valid commit type prefixes
# - MAX_LENGTH: Maximum title length
# - PR_TITLE: The PR title to validate

TITLE_LENGTH=${#PR_TITLE}
STATUS="success" # Default to success

# 1. Length Check
if [ "$TITLE_LENGTH" -gt "$MAX_LENGTH" ]; then
	MESSAGE="❌ **PR Title:** Title is too long (is **$TITLE_LENGTH** chars, max is **$MAX_LENGTH**). Current: \`$PR_TITLE\`"
	STATUS="failure"
fi

# 2. Format Check (only if length check passed)
if [ "$STATUS" == "success" ]; then
	REGEX="^($TYPES)(\(.+\))?:\s.+"
	if [[ ! "$PR_TITLE" =~ $REGEX ]]; then
		STATUS="failure"
		if [[ ! "$PR_TITLE" =~ : ]]; then
			ERROR_DETAIL="Missing ':' separator"
		elif [[ ! "$PR_TITLE" =~ ^($TYPES) ]]; then
			ERROR_DETAIL="Invalid or missing type prefix (must be one of: $TYPES)"
		elif [[ "$PR_TITLE" =~ ^($TYPES)(\(.+\))?:[[:space:]]*$ ]]; then
			ERROR_DETAIL="Missing description after ':'"
		else
			ERROR_DETAIL="Invalid format"
		fi
		MESSAGE="❌ **PR Title:** $ERROR_DETAIL. Current: \`$PR_TITLE\`. Expected: \`type: description\` (e.g., \`feat: add new feature\`)"
	fi
fi

# 3. Lowercase Description Check (only if previous checks passed)
if [ "$STATUS" == "success" ]; then
	DESC=$(echo "$PR_TITLE" | sed -E "s/^($TYPES)(\(.+\))?:\s+//")
	if [[ ! "$DESC" =~ ^[a-z] ]]; then
		STATUS="failure"
		MESSAGE="❌ **PR Title:** Description must start with a lowercase letter. Current: \`$PR_TITLE\`"
	fi
fi

# Set final success message if no failure occurred
if [ "$STATUS" == "success" ]; then
	MESSAGE="✅ **PR Title:** Passed (Length: $TITLE_LENGTH/$MAX_LENGTH, Format: OK). \`$PR_TITLE\`"
fi

# Write outputs for the workflow
{
	echo "status=$STATUS"
	echo "summary=$MESSAGE"
} >>"$GITHUB_OUTPUT"

# If the check failed, exit with 0 to prevent the script from stopping the workflow.
# The orchestrator will handle the overall failure.
if [ "$STATUS" == "failure" ]; then
	exit 0
fi
