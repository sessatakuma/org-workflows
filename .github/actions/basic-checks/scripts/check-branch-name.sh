#!/usr/bin/env bash
# Check Branch Name Format
# Validates branch naming convention with special case for 'dev' branch

STATUS="success" # Default to success

# Allow 'dev' as a special case; it's always valid
if [[ "$BRANCH_NAME" = "dev" ]]; then
	MESSAGE="✅ **Branch Name:** Valid special branch (\`$BRANCH_NAME\`)"
	STATUS="success"
# Otherwise, validate against the standard format
else
	FULL_REGEX="^($TYPES)/([a-z0-9][a-z0-9-]*)$"

	if [[ ! "$BRANCH_NAME" =~ / ]]; then
		MESSAGE="❌ **Branch Name:** Missing '/' separator. Current: \`$BRANCH_NAME\`. Expected: \`type/description\`"
		STATUS="failure"
	elif [[ ! "$BRANCH_NAME" =~ ^($TYPES)/ ]]; then
		MESSAGE="❌ **Branch Name:** Invalid type prefix. Current: \`$BRANCH_NAME\`. Must start with one of: $TYPES\`"
		STATUS="failure"
	elif [[ ! "$BRANCH_NAME" =~ $FULL_REGEX ]]; then
		MESSAGE="❌ **Branch Name:** Invalid format after '/'. Must be lowercase alphanumeric and hyphens. Current: \`$BRANCH_NAME\`"
		STATUS="failure"
	fi
fi

# Set final success message if no failure occurred
if [ "$STATUS" == "success" ] && [[ "$BRANCH_NAME" != "dev" ]]; then
	MESSAGE="✅ **Branch Name:** Follows naming convention (\`$BRANCH_NAME\`)"
fi

# Write outputs for the workflow
{
	echo "status=$STATUS"
	echo "summary=$MESSAGE"
} >>"$GITHUB_OUTPUT"

if [ "$STATUS" == "failure" ]; then
	exit 0
fi
