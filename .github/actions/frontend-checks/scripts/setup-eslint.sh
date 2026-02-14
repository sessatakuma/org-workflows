#!/usr/bin/env bash

if [ ! -f ".eslintrc" ] && [ ! -f ".eslintrc.json" ] && \
   [ ! -f ".eslintrc.js" ] && [ ! -f "eslint.config.js" ] && \
   [ ! -f "eslint.config.mjs" ]; then

    echo "Creating default eslint.config.mjs..."
    cp "$ESLINT_TEMPLATE_PATH" eslint.config.mjs
else
    echo "ESLint config already exists, skipping creation."
fi
