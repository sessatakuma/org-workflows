#!/usr/bin/env bash
# Check PR Title Format
# Validates PR title with cascading checks: length, format, lowercase

# Force standard locale
export LC_ALL=C

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
	# Use [[:space:]] for POSIX compatibility
	REGEX="^($TYPES)(\(.+\))?(!?):[[:space:]].+"
	if [[ ! "$PR_TITLE" =~ $REGEX ]]; then
		STATUS="failure"
		if [[ ! "$PR_TITLE" =~ : ]]; then
			ERROR_DETAIL="Missing ':' separator"
		elif [[ ! "$PR_TITLE" =~ ^($TYPES) ]]; then
			ERROR_DETAIL="Invalid or missing type prefix (must be one of: $TYPES)"
		elif [[ "$PR_TITLE" =~ ^($TYPES)(\(.+\))?(!?)?:[[:space:]]*$ ]]; then
			ERROR_DETAIL="Missing description after ':'"
		else
			ERROR_DETAIL="Invalid format"
		fi
		MESSAGE="❌ **PR Title:** $ERROR_DETAIL. Current: \`$PR_TITLE\`. Expected: \`type: description\` (e.g., \`feat: add new feature\`)"
	fi
fi

# 3. Lowercase Description Check (only if previous checks passed)
if [ "$STATUS" == "success" ]; then
    # 使用與 Step 2 相同的 Regex，但在最後加上 (.+) 來捕獲描述
    # Group 1: Types, Group 2: Scope, Group 3: Bang, Group 4: Description
    CAPTURE_REGEX="^($TYPES)(\(.+\))?(!?)?:[[:space:]]+(.+)"

    if [[ "$PR_TITLE" =~ $CAPTURE_REGEX ]]; then
        DESC="${BASH_REMATCH[4]}"

        if [[ ! "$DESC" =~ ^[a-z] ]]; then
            STATUS="failure"
            MESSAGE="❌ **PR Title:** Description must start with a lowercase letter. Current: \`$PR_TITLE\`"
        fi
    else
        # 理論上 Step 2 已攔截格式錯誤，這裡只是防禦性編程
        STATUS="failure"
        MESSAGE="❌ **PR Title:** Could not parse description from title."
    fi
fi

# Set final success message if no failure occurred
if [ "$STATUS" == "success" ]; then
	MESSAGE="✅ **PR Title:** Passed (Length: $TITLE_LENGTH/$MAX_LENGTH, Format: OK). \`$PR_TITLE\`"
fi

{
	echo "status=$STATUS"
	echo "summary=$MESSAGE"
} >>"$GITHUB_OUTPUT"

if [ "$STATUS" == "failure" ]; then
	exit 0
fi
