#!/usr/bin/env node

/**
 * Script to fix the @typescript-eslint/prefer-nullish-coalescing error
 */

const fs = require("fs")
const path = require("path")

function analyzeTypeScriptConfig() {
  const tsconfigPath = path.join(process.cwd(), "tsconfig.json")

  if (!fs.existsSync(tsconfigPath)) {
    console.error("❌ tsconfig.json not found")
    return null
  }

  const tsconfig = JSON.parse(fs.readFileSync(tsconfigPath, "utf8"))

  console.log("📋 Current TypeScript Configuration Analysis:")
  console.log("==========================================")

  const compilerOptions = tsconfig.compilerOptions || {}

  // Check strict mode settings
  console.log(`strict: ${compilerOptions.strict || false}`)
  console.log(`strictNullChecks: ${compilerOptions.strictNullChecks || false}`)

  // Determine the issue
  if (!compilerOptions.strictNullChecks && !compilerOptions.strict) {
    console.log("\n❌ Issue: strictNullChecks is disabled")
    console.log("💡 Solution: Enable strictNullChecks or strict mode")
    return "missing-strict-null-checks"
  }

  if (compilerOptions.strict && compilerOptions.strictNullChecks === false) {
    console.log("\n❌ Issue: strictNullChecks explicitly disabled despite strict mode")
    console.log("💡 Solution: Remove strictNullChecks: false or set to true")
    return "explicit-disable"
  }

  console.log("\n✅ TypeScript configuration looks correct")
  return "config-ok"
}

function suggestESLintFix() {
  console.log("\n🔧 ESLint Configuration Options:")
  console.log("================================")

  console.log("Option 1: Disable the rule (not recommended)")
  console.log(
    JSON.stringify(
      {
        rules: {
          "@typescript-eslint/prefer-nullish-coalescing": "off",
        },
      },
      null,
      2,
    ),
  )

  console.log("\nOption 2: Configure the rule to be less strict")
  console.log(
    JSON.stringify(
      {
        rules: {
          "@typescript-eslint/prefer-nullish-coalescing": [
            "warn",
            {
              ignoreConditionalTests: true,
              ignoreMixedLogicalExpressions: true,
            },
          ],
        },
      },
      null,
      2,
    ),
  )

  console.log("\nOption 3: Enable strictNullChecks (recommended)")
  console.log("Add to tsconfig.json:")
  console.log(
    JSON.stringify(
      {
        compilerOptions: {
          strictNullChecks: true,
        },
      },
      null,
      2,
    ),
  )
}

// Run the analysis
const issue = analyzeTypeScriptConfig()
suggestESLintFix()

if (issue === "missing-strict-null-checks") {
  console.log("\n🚀 Quick Fix Command:")
  console.log('Add "strictNullChecks": true to your tsconfig.json compilerOptions')
  process.exit(1)
}
