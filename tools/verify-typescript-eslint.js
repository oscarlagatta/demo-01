#!/usr/bin/env node

console.log("🔍 Verifying @typescript-eslint Plugin")
console.log("=====================================")

const { ESLint } = require("eslint")
const fs = require("fs")
const path = require("path")

async function verifyTypeScriptESLint() {
  // Create test directory
  const testDir = "test-files/typescript-eslint"
  if (!fs.existsSync(testDir)) {
    fs.mkdirSync(testDir, { recursive: true })
  }

  // Test cases for TypeScript ESLint rules
  const testCases = [
    {
      name: "no-unused-vars",
      description: "Test unused variables detection",
      code: `
function testFunction(param: string): string {
  const unusedVariable = 'this should trigger a warning';
  const anotherUnused: number = 42;
  return param;
}

interface UnusedInterface {
  prop: string;
}

type UnusedType = string | number;
      `,
      expectedRules: ["@typescript-eslint/no-unused-vars"],
    },
    {
      name: "explicit-function-return-type",
      description: "Test explicit return type requirement",
      code: `
// These functions should require explicit return types
function implicitReturn(x: number) {
  return x * 2;
}

const arrowFunction = (x: string) => {
  return x.toUpperCase();
};

// This should be fine
function explicitReturn(x: number): number {
  return x * 2;
}
      `,
      expectedRules: ["@typescript-eslint/explicit-function-return-type"],
    },
    {
      name: "no-explicit-any",
      description: "Test explicit any usage detection",
      code: `
// These should trigger no-explicit-any
function badFunction(param: any): any {
  return param;
}

const badVariable: any = 'test';

interface BadInterface {
  prop: any;
}

// This should be fine
function goodFunction(param: string): string {
  return param;
}
      `,
      expectedRules: ["@typescript-eslint/no-explicit-any"],
    },
  ]

  const eslint = new ESLint()
  const results = []

  for (const testCase of testCases) {
    console.log(`\n🧪 Testing: ${testCase.description}`)

    // Create test file
    const fileName = `${testCase.name}.ts`
    const filePath = path.join(testDir, fileName)
    fs.writeFileSync(filePath, testCase.code)

    try {
      // Run ESLint on the test file
      const lintResults = await eslint.lintFiles([filePath])
      const fileResult = lintResults[0]

      if (fileResult && fileResult.messages) {
        const foundRules = fileResult.messages.map((msg) => msg.ruleId).filter(Boolean)
        const expectedRules = testCase.expectedRules

        console.log(`   Expected rules: ${expectedRules.join(", ")}`)
        console.log(`   Found violations: ${foundRules.join(", ")}`)

        const missingRules = expectedRules.filter((rule) => !foundRules.includes(rule))
        const unexpectedRules = foundRules.filter((rule) => !expectedRules.includes(rule))

        if (missingRules.length === 0) {
          console.log(`   ✅ All expected rules are working`)
        } else {
          console.log(`   ❌ Missing rule violations: ${missingRules.join(", ")}`)
        }

        if (unexpectedRules.length > 0) {
          console.log(`   ℹ️  Additional violations found: ${unexpectedRules.join(", ")}`)
        }

        results.push({
          testCase: testCase.name,
          description: testCase.description,
          expectedRules,
          foundRules,
          missingRules,
          success: missingRules.length === 0,
        })
      } else {
        console.log(`   ⚠️  No violations found (rules may not be configured)`)
        results.push({
          testCase: testCase.name,
          description: testCase.description,
          expectedRules: testCase.expectedRules,
          foundRules: [],
          missingRules: testCase.expectedRules,
          success: false,
        })
      }
    } catch (error) {
      console.log(`   ❌ Error running ESLint: ${error.message}`)
      results.push({
        testCase: testCase.name,
        description: testCase.description,
        error: error.message,
        success: false,
      })
    }
  }

  // Generate report
  const report = {
    timestamp: new Date().toISOString(),
    plugin: "@typescript-eslint/eslint-plugin",
    results,
    summary: {
      totalTests: results.length,
      passedTests: results.filter((r) => r.success).length,
      failedTests: results.filter((r) => !r.success).length,
    },
  }

  // Save report
  const reportPath = "reports/eslint-verification/typescript-eslint-verification.json"
  if (!fs.existsSync("reports/eslint-verification")) {
    fs.mkdirSync("reports/eslint-verification", { recursive: true })
  }
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2))

  console.log(`\n📊 Verification Summary:`)
  console.log(`   Total tests: ${report.summary.totalTests}`)
  console.log(`   Passed: ${report.summary.passedTests}`)
  console.log(`   Failed: ${report.summary.failedTests}`)
  console.log(`   Report saved to: ${reportPath}`)

  // Cleanup test files
  fs.rmSync(testDir, { recursive: true, force: true })

  return report.summary.failedTests === 0
}

// Run verification
verifyTypeScriptESLint()
  .then((success) => {
    if (success) {
      console.log("\n✅ @typescript-eslint plugin verification completed successfully")
      process.exit(0)
    } else {
      console.log("\n❌ @typescript-eslint plugin verification failed")
      process.exit(1)
    }
  })
  .catch((error) => {
    console.error("\n💥 Verification failed with error:", error)
    process.exit(1)
  })
