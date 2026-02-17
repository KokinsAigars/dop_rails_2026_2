/* .eslintrc.cjs */
module.exports = {
    root: true,
    env: { browser: true, es2022: true, node: true },
    parser: "@typescript-eslint/parser",
    parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
        project: false, // set to true + tsconfig if you want type-aware rules
    },
    plugins: ["@typescript-eslint"],
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended",
        "prettier", // if you use Prettier
    ],
    ignorePatterns: ["node_modules/", "dist/", "build/", "coverage/"],
    overrides: [
        {
            files: ["**/*.{ts,tsx}"],
            rules: {
                /* ---- Naming Convention ---- */
                "@typescript-eslint/naming-convention": [
                    "error",

                    // Types (classes, interfaces, types, enums)
                    { "selector": "typeLike", "format": ["PascalCase"] },

                    // Variables (const/let)
                    {
                        "selector": "variable",
                        "format": ["camelCase", "UPPER_CASE", "PascalCase"], // allow PascalCase for React components
                        "leadingUnderscore": "allow",
                        "trailingUnderscore": "allow"
                    },

                    // Functions (declarations, expressions, methods)
                    {
                        "selector": "function",
                        "format": ["camelCase", "PascalCase"], // PascalCase for React components
                        "leadingUnderscore": "allow"
                    },

                    // Parameters
                    {
                        "selector": "parameter",
                        "format": ["camelCase"],
                        "leadingUnderscore": "allow" // e.g. _evt
                    },

                    // Members (class properties)
                    {
                        "selector": "memberLike",
                        "modifiers": ["private"],
                        "format": ["camelCase"],
                        "leadingUnderscore": "require"
                    },

                    // Booleans must start with is/has/should/can/did/does
                    {
                        "selector": "variable",
                        "types": ["boolean"],
                        "format": ["PascalCase", "camelCase"],
                        "custom": { "regex": "^(is|has|should|can|did|does)[A-Z].*", "match": true }
                    },

                    // Enums members UPPER_CASE (optional)
                    { "selector": "enumMember", "format": ["UPPER_CASE"] },
                ],
            },
        },
    ],
};
