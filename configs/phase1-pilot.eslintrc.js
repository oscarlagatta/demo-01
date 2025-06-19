// ESLint Configuration for Phase 1: Pilot Project
// Conservative rule set focusing on errors only

module.exports = {
  root: true,
  extends: ["@nx/eslint-plugin-nx/recommended"],
  ignorePatterns: ["!**/*"],
  overrides: [
    {
      files: ["*.ts", "*.tsx", "*.js", "*.jsx"],
      rules: {
        // Error-level rules only (will fail builds)
        semi: "error",
        "no-unused-vars": "error",
        "no-undef": "error",
        "no-unreachable": "error",
        "no-dupe-keys": "error",
        "no-duplicate-case": "error",
        "valid-typeof": "error",

        // Disabled rules that will be introduced later
        quotes: "off",
        indent: "off",
        "comma-dangle": "off",
        "no-console": "off",
        "prefer-const": "off",
      },
    },
  ],
}
