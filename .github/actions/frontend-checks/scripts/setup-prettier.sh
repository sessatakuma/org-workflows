#!/usr/bin/env bash

if [ ! -f ".prettierrc" ] && [ ! -f ".prettierrc.json" ] && \
   [ ! -f "prettier.config.js" ]; then

    echo "Creating default .prettierrc.json..."
    cp "$TEMPLATE_PATH" .prettierrc.json
else
    echo "Prettier config already exists, skipping creation."
fi
