// ESLint Configuration for Phase 3: Full Implementation
// Comprehensive rule set for production use

module.exports = {
  root: true,
  extends: ["@nx/eslint-plugin-nx/recommended", "eslint:recommended", "@typescript-eslint/recommended"],
  ignorePatterns: ["!**/*"],
  overrides: [
    {
      files: ["*.ts", "*.tsx", "*.js", "*.jsx"],
      rules: {
        // Code Quality
        semi: ["error", "always"],
        quotes: ["error", "single"],
        indent: ["error", 2],
        "comma-dangle": ["error", "always-multiline"],
        "no-unused-vars": "error",
        "no-console": "warn",
        "prefer-const": "error",
        "no-var": "error",

        // Best Practices
        eqeqeq: ["error", "always"],
        curly: ["error", "all"],
        "no-eval": "error",
        "no-implied-eval": "error",
        "no-new-func": "error",
        "no-return-assign": "error",
        "no-sequences": "error",
        "no-throw-literal": "error",
        "no-unused-expressions": "error",
        "no-useless-call": "error",
        "no-useless-concat": "error",
        "no-useless-return": "error",
        "prefer-promise-reject-errors": "error",
        radix: "error",

        // Style
        "array-bracket-spacing": ["error", "never"],
        "block-spacing": ["error", "always"],
        "brace-style": ["error", "1tbs", { allowSingleLine: true }],
        "comma-spacing": ["error", { before: false, after: true }],
        "comma-style": ["error", "last"],
        "computed-property-spacing": ["error", "never"],
        "eol-last": ["error", "always"],
        "func-call-spacing": ["error", "never"],
        "key-spacing": ["error", { beforeColon: false, afterColon: true }],
        "keyword-spacing": ["error", { before: true, after: true }],
        "no-multiple-empty-lines": ["error", { max: 2, maxEOF: 1 }],
        "no-trailing-spaces": "error",
        "object-curly-spacing": ["error", "always"],
        "semi-spacing": ["error", { before: false, after: true }],
        "space-before-blocks": ["error", "always"],
        "space-before-function-paren": [
          "error",
          {
            anonymous: "always",
            named: "never",
            asyncArrow: "always",
          },
        ],
        "space-in-parens": ["error", "never"],
        "space-infix-ops": "error",
        "space-unary-ops": ["error", { words: true, nonwords: false }],
      },
    },
    {
      files: ["*.ts", "*.tsx"],
      extends: ["@typescript-eslint/recommended"],
      rules: {
        "@typescript-eslint/no-unused-vars": "error",
        "@typescript-eslint/explicit-function-return-type": "off",
        "@typescript-eslint/explicit-module-boundary-types": "off",
        "@typescript-eslint/no-explicit-any": "warn",
        "@typescript-eslint/prefer-nullish-coalescing": "error",
        "@typescript-eslint/prefer-optional-chain": "error",
      },
    },
  ],
}
