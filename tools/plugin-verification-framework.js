#!/usr/bin/env node

const { ESLint } = require("eslint")
const fs = require("fs")
const path = require("path")
const { execSync } = require("child_process")

console.log("🚀 ESLint Plugin Verification Framework")
console.log("======================================")

class PluginVerificationFramework {
  constructor() {
    this.testDir = "test-files/plugin-verification"
    this.reportDir = "reports/eslint-verification"
    this.results = []

    // Ensure directories exist
    ;[this.testDir, this.reportDir].forEach((dir) => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true })
      }
    })
  }

  // Plugin test configurations
  getPluginConfigurations() {
    return {
      "simple-import-sort": {
        rules: {
          "simple-import-sort/imports": "error",
          "simple-import-sort/exports": "error",
        },
        tests: [
          {
            name: "import-sorting",
            description: "Verify import statement sorting",
            code: `
import { z } from 'zod';
import React from 'react';
import { Component } from './local';
import fs from 'fs';

export { z, Component };
export { React };
            `,
            expectedViolations: ["simple-import-sort/imports", "simple-import-sort/exports"],
            autoFixable: true,
          },
        ],
      },
      "@typescript-eslint/eslint-plugin": {
        rules: {
          "@typescript-eslint/no-unused-vars": "error",
          "@typescript-eslint/explicit-function-return-type": "warn",
          "@typescript-eslint/no-explicit-any": "error",
        },
        tests: [
          {
            name: "unused-vars",
            description: "Detect unused variables",
            code: `
function test(param: string): string {
  const unused = 'test';
  return param;
}
            `,
            expectedViolations: ["@typescript-eslint/no-unused-vars"],
            autoFixable: false,
          },
          {
            name: "explicit-any",
            description: "Detect explicit any usage",
            code: `
function badFunction(param: any): any {
  return param;
}
            `,
            expectedViolations: ["@typescript-eslint/no-explicit-any"],
            autoFixable: false,
          },
        ],
      },
      "eslint-plugin-react": {
        rules: {
          "react/jsx-uses-react": "error",
          "react/jsx-uses-vars": "error",
          "react/no-unused-prop-types": "warn",
        },
        tests: [
          {
            name: "jsx-vars",
            description: "Detect unused JSX variables",
            code: `
import React from 'react';

function Component() {
  const unused = 'test';
  return <div>Hello</div>;
}
            `,
            expectedViolations: ["react/jsx-uses-vars"],
            autoFixable: false,
          },
        ],
      },
      "eslint-plugin-import": {
        rules: {
          "import/order": "error",
          "import/no-duplicates": "error",
        },
        tests: [
          {
            name: "import-order",
            description: "Verify import ordering",
            code: `
import { z } from 'zod';
import React from 'react';
import fs from 'fs';
            `,
            expectedViolations: ["import/order"],
            autoFixable: true,
          },
        ],
      },
    }
  }

  async verifyPlugin(pluginName, config) {
    console.log(`\n🔍 Verifying ${pluginName}...`)

    const pluginResults = {
      plugin: pluginName,
      timestamp: new Date().toISOString(),
      tests: [],
      summary: { total: 0, passed: 0, failed: 0 },
    }

    // Check if plugin is installed
    try {
      execSync(`npm list ${pluginName}`, { stdio: "ignore" })
      console.log(`   ✅ ${pluginName} is installed`)
    } catch (error) {
      console.log(`   ❌ ${pluginName} is not installed`)
      pluginResults.error = "Plugin not installed"
      return pluginResults
    }

    // Run tests for this plugin
    for (const test of config.tests) {
      console.log(`   🧪 Running test: ${test.description}`)

      const testResult = await this.runTest(pluginName, test)
      pluginResults.tests.push(testResult)
      pluginResults.summary.total++

      if (testResult.success) {
        pluginResults.summary.passed++
        console.log(`      ✅ Test passed`)
      } else {
        pluginResults.summary.failed++
        console.log(`      ❌ Test failed: ${testResult.error || "Unknown error"}`)
      }
    }

    return pluginResults
  }

  async runTest(pluginName, test) {
    const testResult = {
      name: test.name,
      description: test.description,
      expectedViolations: test.expectedViolations,
      foundViolations: [],
      success: false,
      autoFixWorking: false,
    }

    try {
      // Create test file
      const fileName = `${pluginName.replace(/[@/]/g, "-")}-${test.name}.ts`
      const filePath = path.join(this.testDir, fileName)
      fs.writeFileSync(filePath, test.code)

      // Run ESLint
      const eslint = new ESLint()
      const results = await eslint.lintFiles([filePath])
      const fileResult = results[0]

      if (fileResult && fileResult.messages) {
        testResult.foundViolations = fileResult.messages.map((msg) => msg.ruleId).filter(Boolean)

        // Check if expected violations were found
        const missingViolations = test.expectedViolations.filter((rule) => !testResult.foundViolations.includes(rule))

        testResult.success = missingViolations.length === 0
        testResult.missingViolations = missingViolations

        // Test auto-fix if applicable
        if (test.autoFixable && testResult.success) {
          const originalContent = fs.readFileSync(filePath, "utf8")

          // Run ESLint with --fix
          const fixedResults = await ESLint.outputFixes(results)
          const fixedContent = fs.readFileSync(filePath, "utf8")

          testResult.autoFixWorking = originalContent !== fixedContent
        }
      }

      // Clean up test file
      fs.unlinkSync(filePath)
    } catch (error) {
      testResult.error = error.message
    }

    return testResult
  }

  async runAllVerifications() {
    console.log("🚀 Starting comprehensive plugin verification...\n")

    const configurations = this.getPluginConfigurations()
    const allResults = []

    for (const [pluginName, config] of Object.entries(configurations)) {
      const result = await this.verifyPlugin(pluginName, config)
      allResults.push(result)
    }

    // Generate comprehensive report
    const report = {
      timestamp: new Date().toISOString(),
      totalPlugins: allResults.length,
      results: allResults,
      summary: {
        pluginsWorking: allResults.filter((r) => !r.error && r.summary.failed === 0).length,
        pluginsFailing: allResults.filter((r) => r.error || r.summary.failed > 0).length,
        totalTests: allResults.reduce((sum, r) => sum + (r.summary?.total || 0), 0),
        totalPassed: allResults.reduce((sum, r) => sum + (r.summary?.passed || 0), 0),
        totalFailed: allResults.reduce((sum, r) => sum + (r.summary?.failed || 0), 0),
      },
    }

    // Save detailed report
    const reportPath = path.join(this.reportDir, "comprehensive-verification.json")
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2))

    // Generate summary report
    this.generateSummaryReport(report)

    return report
  }

  generateSummaryReport(report) {
    const summaryPath = path.join(this.reportDir, "verification-summary.md")

    let markdown = `# ESLint Plugin Verification Summary

Generated on: ${new Date(report.timestamp).toLocaleString()}

## Overall Results

- **Total Plugins Tested**: ${report.totalPlugins}
- **Plugins Working**: ${report.summary.pluginsWorking}
- **Plugins Failing**: ${report.summary.pluginsFailing}
- **Total Tests**: ${report.summary.totalTests}
- **Tests Passed**: ${report.summary.totalPassed}
- **Tests Failed**: ${report.summary.totalFailed}

## Plugin Details

`

    report.results.forEach((result) => {
      const status = result.error ? "❌ ERROR" : result.summary.failed === 0 ? "✅ WORKING" : "⚠️ ISSUES"

      markdown += `### ${result.plugin} ${status}

`

      if (result.error) {
        markdown += `**Error**: ${result.error}

`
      } else {
        markdown += `- Tests: ${result.summary.passed}/${result.summary.total} passed
`

        if (result.summary.failed > 0) {
          markdown += `- Failed tests:
`
          result.tests
            .filter((t) => !t.success)
            .forEach((test) => {
              markdown += `  - ${test.name}: ${test.error || "Rule violations not detected"}
`
            })
        }
      }

      markdown += `
`
    })

    markdown += `## Recommendations

`

    // Add recommendations based on results
    const failingPlugins = report.results.filter((r) => r.error || r.summary.failed > 0)

    if (failingPlugins.length === 0) {
      markdown += `✅ All plugins are working correctly! No action needed.

`
    } else {
      markdown += `The following plugins need attention:

`
      failingPlugins.forEach((plugin) => {
        markdown += `- **${plugin.plugin}**: `
        if (plugin.error) {
          markdown += `Install the plugin with \`npm install --save-dev ${plugin.plugin}\`
`
        } else {
          markdown += `Check configuration and rule settings
`
        }
      })
    }

    fs.writeFileSync(summaryPath, markdown)
    console.log(`\n📋 Summary report saved to: ${summaryPath}`)
  }
}

// Run the verification framework
async function main() {
  const framework = new PluginVerificationFramework()

  try {
    const report = await framework.runAllVerifications()

    console.log("\n📊 Verification Complete!")
    console.log(`   Plugins working: ${report.summary.pluginsWorking}/${report.totalPlugins}`)
    console.log(`   Tests passed: ${report.summary.totalPassed}/${report.summary.totalTests}`)

    if (report.summary.pluginsFailing > 0) {
      console.log("\n⚠️  Some plugins have issues. Check the reports for details.")
      process.exit(1)
    } else {
      console.log("\n✅ All plugins are working correctly!")
      process.exit(0)
    }
  } catch (error) {
    console.error("\n💥 Verification failed:", error)
    process.exit(1)
  }
}

if (require.main === module) {
  main()
}

module.exports = PluginVerificationFramework
