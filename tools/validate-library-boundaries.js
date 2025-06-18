#!/usr/bin/env node

// Simple script to validate library import boundaries
const fs = require("fs")
const path = require("path")
const glob = require("glob")

function validateLibraryImports(libPath) {
  const files = glob.sync(`${libPath}/src/**/*.{ts,tsx}`)
  const violations = []

  files.forEach((file) => {
    const content = fs.readFileSync(file, "utf8")
    const imports = content.match(/import.*from\s+['"]([^'"]+)['"]/g) || []

    imports.forEach((importLine) => {
      const match = importLine.match(/from\s+['"]([^'"]+)['"]/)
      if (match) {
        const importPath = match[1]

        // Check for app imports
        if (importPath.includes("/apps/") || importPath.startsWith("../../apps")) {
          violations.push({
            file,
            import: importPath,
            rule: "no-app-imports",
            message: "Libraries cannot import from applications",
          })
        }

        // Check for deep imports
        if (importPath.match(/\.\.\/.*\/src\//)) {
          violations.push({
            file,
            import: importPath,
            rule: "no-deep-imports",
            message: "Use barrel exports instead of deep imports",
          })
        }
      }
    })
  })

  return violations
}

// Usage
const libPath = process.argv[2]
if (!libPath) {
  console.error("Usage: node validate-library-boundaries.js <library-path>")
  process.exit(1)
}

const violations = validateLibraryImports(libPath)
if (violations.length > 0) {
  console.error("Library boundary violations found:")
  violations.forEach((v) => {
    console.error(`${v.file}: ${v.message} (${v.import})`)
  })
  process.exit(1)
} else {
  console.log("No library boundary violations found")
}
