#!/usr/bin/env bash
# Check Commit Messages Format
# Validates all commit messages in PR against conventional commit format

# Script reads from environment variables:
# - TYPES: Valid commit types
# - MAX_LENGTH: Maximum commit message length
# - BASE_SHA: Base commit for comparison
# - HEAD_SHA: Head commit for comparison

REGEX="^($TYPES)(\(.+\))?(!?):\s.+"
# Get all commits between the base and head of the PR
COMMITS=$(git log --format="%H:::%s" "$BASE_SHA".."$HEAD_SHA")

FAILED_COMMITS_REPORT=""
TOTAL_COMMITS=0
FAILED_COUNT=0

# Use a while loop to read each commit line by line
while IFS= read -r line; do
	# Skip empty lines, which can happen with git log
	if [ -z "$line" ]; then
		continue
	fi

	TOTAL_COMMITS=$((TOTAL_COMMITS + 1))
	COMMIT_SHA=$(echo "$line" | cut -d':' -f1 | cut -c1-7)
	# Handle cases where the commit message itself contains colons
	COMMIT_MSG=$(echo "$line" | cut -d':' -f4-)

	ERRORS=""

	# 1. Length Check
	if [ "${#COMMIT_MSG}" -gt "$MAX_LENGTH" ]; then
		ERRORS="${ERRORS}  ↳ Title is too long (is **${#COMMIT_MSG}** chars, max is **$MAX_LENGTH**)\n"
	fi

	# 2. Format Check (Conventional Commit)
	if [[ ! "$COMMIT_MSG" =~ $REGEX ]]; then
		if [[ ! "$COMMIT_MSG" =~ : ]]; then
			ERRORS="${ERRORS}  ↳ Missing ':' separator\n"
		elif [[ ! "$COMMIT_MSG" =~ ^($TYPES) ]]; then
			ERRORS="${ERRORS}  ↳ Invalid type prefix\n"
		elif [[ "$COMMIT_MSG" =~ ^($TYPES)(\(.+\))?:[[:space:]]*$ ]]; then
			ERRORS="${ERRORS}  ↳ Missing description after ':'\n"
		else
			ERRORS="${ERRORS}  ↳ Invalid format\n"
		fi
	fi

	# 3. Lowercase Description Check
	DESC=$(echo "$COMMIT_MSG" | sed -E "s/^($TYPES)(\(.+\))?:\s+//")
	if [[ ! "$DESC" =~ ^[a-z] ]]; then
		ERRORS="${ERRORS}  ↳ Description must start with a lowercase letter\n"
	fi

	# If any errors were found, add them to the report
	if [ -n "$ERRORS" ]; then
		FAILED_COUNT=$((FAILED_COUNT + 1))
		# Append the formatted error message for this commit
		FAILED_COMMITS_REPORT="${FAILED_COMMITS_REPORT}- [\`${COMMIT_SHA}\`] \`${COMMIT_MSG}\`\n${ERRORS}"
	fi
done <<<"$COMMITS"

# Determine the final status and construct the output summary
if [ "$FAILED_COUNT" -eq 0 ]; then
	MESSAGE="✅ **Commit Messages:** All $TOTAL_COMMITS commit(s) passed (Length, Format, Case)"
	STATUS="success"
	REPORT=""
else
	MESSAGE="❌ **Commit Messages:** $FAILED_COUNT of $TOTAL_COMMITS commit(s) failed validation"
	STATUS="failure"
	# Construct a detailed report for failed commits
	REPORT="Expected format: \`type(scope): description\` (max $MAX_LENGTH chars)\n"
	REPORT+="Valid types: $TYPES\n\n"
	REPORT+="Failed commits:\n"
	REPORT+="$FAILED_COMMITS_REPORT"
fi

# Write the outputs to the GITHUB_OUTPUT file for the workflow to use
# The '<<EOF' syntax handles multi-line strings correctly
{
	echo "status=$STATUS"
	echo "summary=$MESSAGE"
	echo "report<<EOF"
	echo -e "$REPORT"
	echo "EOF"
} >>"$GITHUB_OUTPUT"
