import js from "@eslint/js";
import globals from "globals";

export default [
    js.configs.recommended,
    {
        files: ["**/*.{js,mjs,cjs,jsx}"],

        languageOptions: {
            ecmaVersion: "latest",
            sourceType: "module",
            globals: {
                ...globals.browser,
                ...globals.node,
                ...globals.es2021
            },
            parserOptions: {
                ecmaFeatures: {
                    jsx: true
                }
            }
        },
        rules: {
            "no-console": "warn",
            "no-unused-vars": "warn",
            "no-var": "error"
        },
    },
    {
        ignores: [
            "dist/**",
            "node_modules/**",
            "build/**"
        ]
    }
];
