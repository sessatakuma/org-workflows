#!/usr/bin/env bash
# Check Commit Messages Format
# Validates all commit messages in PR against conventional commit format

# Force standard locale to ensure [a-z] ranges work as expected
export LC_ALL=C

# Script reads from environment variables:
# - TYPES: Valid commit types
# - MAX_LENGTH: Maximum commit message length
# - BASE_SHA: Base commit for comparison
# - HEAD_SHA: Head commit for comparison

# Use [[:space:]] for POSIX compatibility
REGEX="^($TYPES)(\(.+\))?(!?):[[:space:]].+"

# Get all commits between the base and head of the PR
# Added --no-color to prevent ANSI codes from breaking regex
COMMITS=$(git log --no-color --format="%H:::%s" "$BASE_SHA".."$HEAD_SHA")

FAILED_COMMITS_REPORT=""
TOTAL_COMMITS=0
FAILED_COUNT=0

# Use a while loop to read each commit line by line
while IFS= read -r line; do
	# Skip empty lines
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
		elif [[ "$COMMIT_MSG" =~ ^($TYPES)(\(.+\))?(!?)?:[[:space:]]*$ ]]; then
			ERRORS="${ERRORS}  ↳ Missing description after ':'\n"
		else
			ERRORS="${ERRORS}  ↳ Invalid format\n"
		fi
	fi

	# 3. Lowercase Description Check
	CAPTURE_REGEX="^($TYPES)(\(.+\))?(!?)?:[[:space:]]+(.+)"

	if [[ "$COMMIT_MSG" =~ $CAPTURE_REGEX ]]; then
		DESC="${BASH_REMATCH[4]}"

		if [[ ! "$DESC" =~ ^[a-z] ]]; then
			ERRORS="${ERRORS}  ↳ Description must start with a lowercase letter\n"
		fi
	else
		:
	fi

	# If any errors were found, add them to the report
	if [ -n "$ERRORS" ]; then
		FAILED_COUNT=$((FAILED_COUNT + 1))
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
	REPORT="Expected format: \`type(scope): description\` (max $MAX_LENGTH chars)\n"
	REPORT+="Valid types: $TYPES\n\n"
	REPORT+="Failed commits:\n"
	REPORT+="$FAILED_COMMITS_REPORT"
fi

{
	echo "status=$STATUS"
	echo "summary=$MESSAGE"
	echo "report<<EOF"
	echo -e "$REPORT"
	echo "EOF"
} >>"$GITHUB_OUTPUT"
