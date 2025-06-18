// Application build targets
const applicationTargets = {
  environments: ["modern browsers", "specific Node.js version"],
  bundling: "Single bundle with code splitting",
  optimization: "Runtime performance",
  dependencies: "All bundled together",
}

// Library build targets
const libraryTargets = {
  environments: ["Node.js LTS", "ES2015+ browsers", "SSR environments"],
  bundling: "Multiple formats (ESM, CJS, UMD)",
  optimization: "Bundle size and tree-shaking",
  dependencies: "Peer dependencies to avoid conflicts",
}

// This affects ESLint rules like:
const eslintDifferences = {
  application: {
    "no-console": "warn", // OK for debugging
    "import/no-default-export": "off", // Pages need default exports
    "@typescript-eslint/explicit-function-return-type": "off", // Internal functions
  },
  library: {
    "no-console": "error", // Never log in libraries
    "import/no-default-export": "error", // Hurts tree-shaking
    "@typescript-eslint/explicit-function-return-type": "error", // Public API clarity
  },
}
