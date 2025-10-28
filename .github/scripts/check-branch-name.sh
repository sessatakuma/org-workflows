#!/bin/bash
# Enforces branch naming conventions.

# Exit immediately if a command exits with a non-zero status.
set -e

# Check for required environment variables passed from the workflow
if [ -z "$BRANCH_NAME" ] || [ -z "$TYPES" ]; then
  echo "Error: Required environment variables (BRANCH_NAME, TYPES) are not set."
  exit 1
fi

STATUS="success" # Default to success

# Allow 'dev' as a special case; it's always valid
if [[ "$BRANCH_NAME" = "dev" ]]; then
  MESSAGE="✅ **Branch Name:** Valid special branch (\`$BRANCH_NAME\`)"
  STATUS="success"
# Otherwise, validate against the standard format
else
  FULL_REGEX="^($TYPES)\/([a-z0-9][a-z0-9-]*)$"

  if [[ ! "$BRANCH_NAME" =~ / ]]; then
    MESSAGE="❌ **Branch Name:** Missing '/' separator. Current: \`$BRANCH_NAME\`. Expected: \`type/description\`"
    STATUS="failure"
  elif [[ ! "$BRANCH_NAME" =~ ^($TYPES)\/ ]]; then
    MESSAGE="❌ **Branch Name:** Invalid type prefix. Current: \`$BRANCH_NAME\`. Must start with one of: \`$TYPES\`"
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
} >> "$GITHUB_OUTPUT"

# If the check failed, exit with 0 to prevent the script from stopping the workflow.
# The orchestrator job will handle the overall failure.
if [ "$STATUS" == "failure" ]; then
  exit 0
fi
