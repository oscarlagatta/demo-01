#!/usr/bin/env node

console.log("🧪 Testing ESLint Plugin Configurations")
console.log("=======================================")

const { ESLint } = require("eslint")
const fs = require("fs")
const path = require("path")

class ESLintPluginTester {
  constructor() {
    this.eslint = new ESLint()
    this.testDir = "test-files/plugin-tests"
    this.results = {
      simpleImportSort: { passed: 0, failed: 0, tests: [] },
      typescriptEslint: { passed: 0, failed: 0, tests: [] },
      overall: { passed: 0, failed: 0 },
    }
  }

  async setup() {
    // Create test directory
    if (!fs.existsSync(this.testDir)) {
      fs.mkdirSync(this.testDir, { recursive: true })
    }
  }

  async cleanup() {
    // Remove test files
    if (fs.existsSync(this.testDir)) {
      fs.rmSync(this.testDir, { recursive: true, force: true })
    }
  }

  async testSimpleImportSort() {
    console.log("\n🔍 Testing simple-import-sort plugin...")

    const tests = [
      {
        name: "Unsorted imports detection",
        description: "Should detect unsorted imports",
        code: `
import { z } from 'zod';
import React from 'react';
import fs from 'fs';
import { localFunction } from './local';
        `,
        expectedRules: ["simple-import-sort/imports"],
        shouldHaveViolations: true,
      },
      {
        name: "Correctly sorted imports",
        description: "Should not flag correctly sorted imports",
        code: `
import fs from 'fs';
import React from 'react';
import { z } from 'zod';
import { localFunction } from './local';
        `,
        expectedRules: ["simple-import-sort/imports"],
        shouldHaveViolations: false,
      },
      {
        name: "Export sorting",
        description: "Should detect unsorted exports",
        code: `
export { z } from 'zod';
export { localFunction } from './local';
export { readFileSync } from 'fs';
        `,
        expectedRules: ["simple-import-sort/exports"],
        shouldHaveViolations: true,
      },
    ]

    for (const test of tests) {
      await this.runTest("simpleImportSort", test)
    }
  }

  async testTypescriptEslint() {
    console.log("\n🔍 Testing typescript-eslint plugin...")

    const tests = [
      {
        name: "No explicit any detection",
        description: "Should detect explicit any usage",
        code: `
function testFunction(param: any): any {
  return param;
}
        `,
        expectedRules: ["@typescript-eslint/no-explicit-any"],
        shouldHaveViolations: true,
      },
      {
        name: "Unused variables detection",
        description: "Should detect unused variables",
        code: `
function testFunction(param: string): string {
  const unusedVariable = 'test';
  const anotherUnused: number = 42;
  return param;
}
        `,
        expectedRules: ["@typescript-eslint/no-unused-vars"],
        shouldHaveViolations: true,
      },
      {
        name: "Prefer const detection",
        description: "Should suggest const over let when variable is not reassigned",
        code: `
function testFunction() {
  let value = 'test';
  return value;
}
        `,
        expectedRules: ["@typescript-eslint/prefer-const"],
        shouldHaveViolations: true,
      },
      {
        name: "Clean TypeScript code",
        description: "Should not flag clean TypeScript code",
        code: `
function testFunction(param: string): string {
  const value = param.toUpperCase();
  return value;
}
        `,
        expectedRules: ["@typescript-eslint/no-unused-vars", "@typescript-eslint/no-explicit-any"],
        shouldHaveViolations: false,
      },
    ]

    for (const test of tests) {
      await this.runTest("typescriptEslint", test)
    }
  }

  async runTest(category, test) {
    const fileName = `${test.name.replace(/\s+/g, "-").toLowerCase()}.ts`
    const filePath = path.join(this.testDir, fileName)

    try {
      // Write test file
      fs.writeFileSync(filePath, test.code)

      // Run ESLint
      const results = await this.eslint.lintFiles([filePath])
      const fileResult = results[0]

      if (!fileResult) {
        throw new Error("No ESLint results returned")
      }

      const violations = fileResult.messages
      const ruleViolations = violations.filter((msg) => test.expectedRules.some((rule) => msg.ruleId === rule))

      const testResult = {
        name: test.name,
        description: test.description,
        expectedRules: test.expectedRules,
        foundViolations: ruleViolations.map((v) => v.ruleId),
        shouldHaveViolations: test.shouldHaveViolations,
        actualViolations: ruleViolations.length,
        passed: false,
        message: "",
      }

      // Determine if test passed
      if (test.shouldHaveViolations) {
        testResult.passed = ruleViolations.length > 0
        testResult.message = testResult.passed
          ? `✅ Correctly detected ${ruleViolations.length} violation(s)`
          : `❌ Expected violations but none found`
      } else {
        testResult.passed = ruleViolations.length === 0
        testResult.message = testResult.passed
          ? `✅ Correctly found no violations`
          : `❌ Unexpected violations found: ${ruleViolations.map((v) => v.ruleId).join(", ")}`
      }

      // Update results
      this.results[category].tests.push(testResult)
      if (testResult.passed) {
        this.results[category].passed++
        this.results.overall.passed++
      } else {
        this.results[category].failed++
        this.results.overall.failed++
      }

      console.log(`  ${testResult.message} - ${test.name}`)

      // Clean up test file
      fs.unlinkSync(filePath)
    } catch (error) {
      console.log(`  ❌ Test failed with error: ${error.message} - ${test.name}`)
      this.results[category].failed++
      this.results.overall.failed++

      this.results[category].tests.push({
        name: test.name,
        description: test.description,
        passed: false,
        error: error.message,
      })
    }
  }

  async testAutoFix() {
    console.log("\n🔧 Testing auto-fix functionality...")

    const testCode = `
import { z } from 'zod';
import React from 'react';
import fs from 'fs';
import { localFunction } from './local';

function testFunction(param: string) {
  const unusedVariable = 'test';
  return param;
}
    `

    const fileName = "autofix-test.ts"
    const filePath = path.join(this.testDir, fileName)

    try {
      // Write test file
      fs.writeFileSync(filePath, testCode)
      const originalContent = fs.readFileSync(filePath, "utf8")

      // Run ESLint with fix
      await ESLint.outputFixes(await this.eslint.lintFiles([filePath]))
      const fixedContent = fs.readFileSync(filePath, "utf8")

      if (originalContent !== fixedContent) {
        console.log("  ✅ Auto-fix is working - file was modified")

        // Show sample of changes
        const originalLines = originalContent.split("\n").filter((line) => line.trim().startsWith("import"))
        const fixedLines = fixedContent.split("\n").filter((line) => line.trim().startsWith("import"))

        if (originalLines.join("") !== fixedLines.join("")) {
          console.log("  📝 Import order was corrected")
        }
      } else {
        console.log("  ⚠️ Auto-fix didn't modify file (may already be correct)")
      }

      // Clean up
      fs.unlinkSync(filePath)
    } catch (error) {
      console.log(`  ❌ Auto-fix test failed: ${error.message}`)
    }
  }

  generateReport() {
    console.log("\n📊 Test Summary")
    console.log("===============")

    console.log(
      `\nSimple Import Sort: ${this.results.simpleImportSort.passed}/${this.results.simpleImportSort.passed + this.results.simpleImportSort.failed} tests passed`,
    )
    console.log(
      `TypeScript ESLint: ${this.results.typescriptEslint.passed}/${this.results.typescriptEslint.passed + this.results.typescriptEslint.failed} tests passed`,
    )
    console.log(
      `Overall: ${this.results.overall.passed}/${this.results.overall.passed + this.results.overall.failed} tests passed`,
    )

    // Save detailed report
    const reportDir = "reports/eslint-plugin-tests"
    if (!fs.existsSync(reportDir)) {
      fs.mkdirSync(reportDir, { recursive: true })
    }

    const report = {
      timestamp: new Date().toISOString(),
      summary: {
        totalTests: this.results.overall.passed + this.results.overall.failed,
        passedTests: this.results.overall.passed,
        failedTests: this.results.overall.failed,
        successRate: Math.round(
          (this.results.overall.passed / (this.results.overall.passed + this.results.overall.failed)) * 100,
        ),
      },
      results: this.results,
    }

    fs.writeFileSync(path.join(reportDir, "plugin-test-results.json"), JSON.stringify(report, null, 2))

    // Generate markdown report
    let markdownReport = `# ESLint Plugin Test Results\n\n`
    markdownReport += `**Generated:** ${new Date().toLocaleString()}\n\n`
    markdownReport += `## Summary\n\n`
    markdownReport += `- **Total Tests:** ${report.summary.totalTests}\n`
    markdownReport += `- **Passed:** ${report.summary.passedTests}\n`
    markdownReport += `- **Failed:** ${report.summary.failedTests}\n`
    markdownReport += `- **Success Rate:** ${report.summary.successRate}%\n\n`

    markdownReport += `## Detailed Results\n\n`

    for (const [category, categoryResults] of Object.entries(this.results)) {
      if (category === "overall") continue

      markdownReport += `### ${category}\n\n`
      for (const test of categoryResults.tests) {
        const status = test.passed ? "✅" : "❌"
        markdownReport += `- ${status} **${test.name}**: ${test.description}\n`
        if (!test.passed && test.error) {
          markdownReport += `  - Error: ${test.error}\n`
        }
      }
      markdownReport += `\n`
    }

    fs.writeFileSync(path.join(reportDir, "plugin-test-report.md"), markdownReport)

    console.log(`\n📄 Detailed report saved to: ${reportDir}/plugin-test-report.md`)

    return report.summary.failedTests === 0
  }

  async run() {
    try {
      await this.setup()

      await this.testSimpleImportSort()
      await this.testTypescriptEslint()
      await this.testAutoFix()

      const allTestsPassed = this.generateReport()

      await this.cleanup()

      if (allTestsPassed) {
        console.log("\n🎉 All tests passed! ESLint plugins are configured correctly.")
        process.exit(0)
      } else {
        console.log("\n⚠️ Some tests failed. Check the detailed report for issues.")
        process.exit(1)
      }
    } catch (error) {
      console.error("\n💥 Test suite failed:", error.message)
      await this.cleanup()
      process.exit(1)
    }
  }
}

// Run the tests
const tester = new ESLintPluginTester()
tester.run()
