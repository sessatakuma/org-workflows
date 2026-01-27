#!/usr/bin/env bash
# Parse ESLint JSON Output
# Converts ESLint JSON to GitHub annotations

echo "Running ESLint with GitHub annotations..."
set +e
npx eslint ./src --format json --output-file eslint_output.json
ESLINT_EXIT_CODE=$?

if [ -f eslint_output.json ]; then
	node -e "
const fs = require('fs');
const results = JSON.parse(fs.readFileSync('eslint_output.json', 'utf8'));

let hasErrors = false;
results.forEach(result => {
  result.messages.forEach(message => {
    const file = result.filePath.replace(process.cwd() + '/', '');
    const line = message.line || 1;
    const column = message.column || 1;
    const severity = message.severity === 2 ? 'error' : 'warning';
    const ruleId = message.ruleId ? \` (\${message.ruleId})\` : '';
    const messageText = message.message;

    if (message.severity === 2) hasErrors = true;

    console.log(\`::\${severity} title=ESLint\${ruleId},file=\${file},line=\${line},col=\${column}::\${file}:\${line}:\${column}: \${messageText}\`);
  });
});
"
fi

if [ $ESLINT_EXIT_CODE -ne 0 ]; then
	echo "status=failure" >>"$GITHUB_OUTPUT"
	echo "summary=❌ **ESLint:** Issues found. Please review the annotations above." >>"$GITHUB_OUTPUT"
else
	echo "status=success" >>"$GITHUB_OUTPUT"
	echo "summary=✅ **ESLint:** No issues found." >>"$GITHUB_OUTPUT"
fi
