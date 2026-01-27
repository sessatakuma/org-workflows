#!/usr/bin/env bash
# Go Checks Outcome Script
# Aggregates results from tidy, lint, test, and build steps

TIDY_STATUS="$1"
LINT_STATUS="$2"
TEST_STATUS="$3"
BUILD_STATUS="$4"

ALL_PASSED=true
for status in "$TIDY_STATUS" "$LINT_STATUS" "$TEST_STATUS" "$BUILD_STATUS"; do
	if [ "$status" != "success" ]; then
		ALL_PASSED=false
		break
	fi
done

if $ALL_PASSED; then
	echo "status=success" >>"$GITHUB_OUTPUT"
	echo "summary=✅ **Go Quality:** All checks passed." >>"$GITHUB_OUTPUT"
else
	echo "status=failure" >>"$GITHUB_OUTPUT"
	DETAILS="tidy=$TIDY_STATUS, lint=$LINT_STATUS, test=$TEST_STATUS, build=$BUILD_STATUS"
	echo "summary=❌ **Go Quality:** Checks failed ($DETAILS)." >>"$GITHUB_OUTPUT"
fi
