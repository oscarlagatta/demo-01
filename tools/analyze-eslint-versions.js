const packageJson = require("../package.json")

// Current ESLint plugin versions from package.json
const eslintPlugins = {
  eslint: "^8.57.1",
  "typescript-eslint": "^8.0.0",
  "eslint-plugin-tailwindcss": "^3.18.0",
  "eslint-plugin-react": "^7.35.0",
  "eslint-plugin-import": "^2.30.0",
  "eslint-plugin-simple-import-sort": "^12.1.1",
  tailwindcss: "3.4.3",
}

// Version compatibility matrix
const compatibilityMatrix = {
  "eslint-plugin-tailwindcss@3.18.0": {
    tailwindcss: ">=3.0.0",
    eslint: ">=8.0.0",
    knownIssues: [
      "Custom class validation may be overly strict",
      "Dynamic class generation not recognized",
      "Arbitrary value syntax may trigger false positives",
    ],
  },
  "typescript-eslint@8.0.0": {
    typescript: ">=4.7.0",
    eslint: ">=8.56.0",
    breakingChanges: ["Stricter type checking", "New rule defaults", "Parser option changes"],
  },
}

console.log("ESLint Plugin Analysis:")
console.log("======================")

Object.entries(eslintPlugins).forEach(([plugin, version]) => {
  console.log(`${plugin}: ${version}`)
})

console.log("\nPotential Compatibility Issues:")
console.log("==============================")

// Check for Tailwind CSS specific issues
if (eslintPlugins["eslint-plugin-tailwindcss"] === "^3.18.0") {
  console.log("⚠️  Tailwind CSS Plugin v3.18.0 Issues:")
  console.log("   - May flag valid Tailwind v3 classes as invalid")
  console.log("   - Arbitrary value syntax [&>*]:text-red-500 may cause errors")
  console.log("   - Custom utility classes need whitelist configuration")
}

// TypeScript ESLint v8 changes
if (eslintPlugins["typescript-eslint"] === "^8.0.0") {
  console.log("⚠️  TypeScript ESLint v8.0.0 Changes:")
  console.log("   - Stricter type checking enabled by default")
  console.log("   - Some rules have new default configurations")
  console.log("   - May require tsconfig.json adjustments")
}
