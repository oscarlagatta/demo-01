#!/usr/bin/env node

const { ESLint } = require("eslint")
const fs = require("fs")
const path = require("path")
const { execSync } = require("child_process")

console.log("🔧 ESLint Plugin Debugging Framework")
console.log("====================================")

class PluginDebugger {
  constructor() {
    this.debugDir = "debug/eslint-plugins"
    this.reportDir = "reports/eslint-debugging"
    ;[this.debugDir, this.reportDir].forEach((dir) => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true })
      }
    })
  }

  async debugPlugin(pluginName) {
    console.log(`\n🔍 Debugging plugin: ${pluginName}`)

    const debugReport = {
      plugin: pluginName,
      timestamp: new Date().toISOString(),
      checks: [],
      issues: [],
      recommendations: [],
    }

    // Check 1: Installation verification
    const installCheck = this.checkInstallation(pluginName)
    debugReport.checks.push(installCheck)

    if (!installCheck.success) {
      debugReport.issues.push({
        type: "installation",
        message: `Plugin ${pluginName} is not installed`,
        solution: `Run: npm install --save-dev ${pluginName}`,
      })
    }

    // Check 2: Configuration verification
    const configCheck = await this.checkConfiguration(pluginName)
    debugReport.checks.push(configCheck)

    if (!configCheck.success) {
      debugReport.issues.push({
        type: "configuration",
        message: configCheck.error,
        solution: configCheck.solution,
      })
    }

    // Check 3: Rule verification
    const ruleCheck = await this.checkRules(pluginName)
    debugReport.checks.push(ruleCheck)

    if (!ruleCheck.success) {
      debugReport.issues.push({
        type: "rules",
        message: ruleCheck.error,
        solution: ruleCheck.solution,
      })
    }

    // Check 4: Dependency verification
    const depCheck = this.checkDependencies(pluginName)
    debugReport.checks.push(depCheck)

    if (!depCheck.success) {
      debugReport.issues.push({
        type: "dependencies",
        message: depCheck.error,
        solution: depCheck.solution,
      })
    }

    // Generate recommendations
    this.generateRecommendations(debugReport)

    // Save debug report
    const reportPath = path.join(this.reportDir, `${pluginName.replace(/[@/]/g, "-")}-debug.json`)
    fs.writeFileSync(reportPath, JSON.stringify(debugReport, null, 2))

    // Generate human-readable report
    this.generateDebugSummary(debugReport)

    return debugReport
  }

  checkInstallation(pluginName) {
    console.log(`   📦 Checking installation...`)

    try {
      execSync(`npm list ${pluginName}`, { stdio: "ignore" })

      // Get version info
      const versionOutput = execSync(`npm list ${pluginName} --depth=0`, { encoding: "utf8" })
      const versionMatch = versionOutput.match(new RegExp(`${pluginName}@([\\d\\.]+)`))
      const version = versionMatch ? versionMatch[1] : "unknown"

      return {
        check: "installation",
        success: true,
        message: `Plugin installed (version: ${version})`,
        details: { version },
      }
    } catch (error) {
      return {
        check: "installation",
        success: false,
        error: "Plugin not installed",
        solution: `npm install --save-dev ${pluginName}`,
      }
    }
  }

  async checkConfiguration(pluginName) {
    console.log(`   ⚙️  Checking configuration...`)

    try {
      const eslint = new ESLint()
      const config = await eslint.calculateConfigForFile("dummy.ts")

      // Check if plugin is in plugins array
      const pluginShortName = pluginName
        .replace("eslint-plugin-", "")
        .replace("@typescript-eslint/eslint-plugin", "@typescript-eslint")
      const isConfigured = config.plugins && config.plugins.includes(pluginShortName)

      if (!isConfigured) {
        return {
          check: "configuration",
          success: false,
          error: `Plugin ${pluginName} is not configured in ESLint`,
          solution: `Add "${pluginShortName}" to the plugins array in your ESLint configuration`,
        }
      }

      // Check if any rules from this plugin are configured
      const pluginRules = Object.keys(config.rules || {}).filter(
        (rule) =>
          rule.startsWith(pluginShortName + "/") ||
          (pluginName.includes("typescript-eslint") && rule.startsWith("@typescript-eslint/")),
      )

      return {
        check: "configuration",
        success: true,
        message: `Plugin configured with ${pluginRules.length} rules`,
        details: {
          configuredRules: pluginRules.length,
          sampleRules: pluginRules.slice(0, 5),
        },
      }
    } catch (error) {
      return {
        check: "configuration",
        success: false,
        error: `Configuration error: ${error.message}`,
        solution: "Check your ESLint configuration file for syntax errors",
      }
    }
  }

  async checkRules(pluginName) {
    console.log(`   📋 Checking rules...`)

    try {
      // Create a test file that should trigger plugin rules
      const testContent = this.generateTestContent(pluginName)
      const testFile = path.join(this.debugDir, `${pluginName.replace(/[@/]/g, "-")}-test.ts`)
      fs.writeFileSync(testFile, testContent)

      const eslint = new ESLint()
      const results = await eslint.lintFiles([testFile])

      const violations = results[0]?.messages || []
      const pluginViolations = violations.filter(
        (msg) =>
          msg.ruleId &&
          (msg.ruleId.includes(pluginName.replace("eslint-plugin-", "")) ||
            (pluginName.includes("typescript-eslint") && msg.ruleId.includes("@typescript-eslint"))),
      )

      // Clean up test file
      fs.unlinkSync(testFile)

      if (pluginViolations.length === 0) {
        return {
          check: "rules",
          success: false,
          error: "No rule violations detected from this plugin",
          solution: "Check if plugin rules are properly configured and enabled",
        }
      }

      return {
        check: "rules",
        success: true,
        message: `Plugin rules are working (${pluginViolations.length} violations detected)`,
        details: {
          violationCount: pluginViolations.length,
          rules: pluginViolations.map((v) => v.ruleId),
        },
      }
    } catch (error) {
      return {
        check: "rules",
        success: false,
        error: `Rule checking failed: ${error.message}`,
        solution: "Check plugin documentation and rule configuration",
      }
    }
  }

  checkDependencies(pluginName) {
    console.log(`   🔗 Checking dependencies...`)

    try {
      // Get package.json of the plugin
      const pluginPath = require.resolve(`${pluginName}/package.json`)
      const pluginPackage = JSON.parse(fs.readFileSync(pluginPath, "utf8"))

      const peerDeps = pluginPackage.peerDependencies || {}
      const missingDeps = []

      Object.keys(peerDeps).forEach((dep) => {
        try {
          require.resolve(dep)
        } catch (error) {
          missingDeps.push(dep)
        }
      })

      if (missingDeps.length > 0) {
        return {
          check: "dependencies",
          success: false,
          error: `Missing peer dependencies: ${missingDeps.join(", ")}`,
          solution: `Install missing dependencies: npm install --save-dev ${missingDeps.join(" ")}`,
        }
      }

      return {
        check: "dependencies",
        success: true,
        message: "All dependencies satisfied",
        details: { peerDependencies: Object.keys(peerDeps) },
      }
    } catch (error) {
      return {
        check: "dependencies",
        success: false,
        error: `Dependency check failed: ${error.message}`,
        solution: "Verify plugin installation and dependencies",
      }
    }
  }

  generateTestContent(pluginName) {
    const testCases = {
      "simple-import-sort": `
import { z } from 'zod';
import React from 'react';
import fs from 'fs';

export { z };
export { React };
      `,
      "@typescript-eslint/eslint-plugin": `
function test(param: string) {
  const unused = 'test';
  return param;
}

const badAny: any = 'test';
      `,
      "eslint-plugin-react": `
import React from 'react';

function Component() {
  const unused = 'test';
  return <div>Hello</div>;
}
      `,
      "eslint-plugin-import": `
import { z } from 'zod';
import React from 'react';
import fs from 'fs';
      `,
    }

    return (
      testCases[pluginName] ||
      `
// Generic test content
const test = 'hello';
console.log(test);
    `
    )
  }

  generateRecommendations(debugReport) {
    const { issues, checks } = debugReport

    if (issues.length === 0) {
      debugReport.recommendations.push({
        type: "success",
        message: "Plugin is working correctly",
        action: "No action needed",
      })
      return
    }

    // Installation issues
    if (issues.some((i) => i.type === "installation")) {
      debugReport.recommendations.push({
        type: "critical",
        message: "Install the plugin",
        action: `Run: npm install --save-dev ${debugReport.plugin}`,
      })
    }

    // Configuration issues
    if (issues.some((i) => i.type === "configuration")) {
      debugReport.recommendations.push({
        type: "high",
        message: "Fix plugin configuration",
        action: "Add plugin to ESLint configuration and configure rules",
      })
    }

    // Rule issues
    if (issues.some((i) => i.type === "rules")) {
      debugReport.recommendations.push({
        type: "medium",
        message: "Review rule configuration",
        action: "Check if plugin rules are enabled and properly configured",
      })
    }

    // Dependency issues
    if (issues.some((i) => i.type === "dependencies")) {
      debugReport.recommendations.push({
        type: "high",
        message: "Install missing dependencies",
        action: "Install all required peer dependencies",
      })
    }
  }

  generateDebugSummary(debugReport) {
    const summaryPath = path.join(this.reportDir, `${debugReport.plugin.replace(/[@/]/g, "-")}-debug-summary.md`)

    let summary = `# Debug Report: ${debugReport.plugin}

Generated: ${new Date(debugReport.timestamp).toLocaleString()}

## Status Overview

`

    const successfulChecks = debugReport.checks.filter((c) => c.success).length
    const totalChecks = debugReport.checks.length
    const status = debugReport.issues.length === 0 ? "✅ Working" : "❌ Issues Found"

    summary += `**Overall Status**: ${status}
**Checks Passed**: ${successfulChecks}/${totalChecks}
**Issues Found**: ${debugReport.issues.length}

## Detailed Results

`

    // Add check results
    debugReport.checks.forEach((check) => {
      const icon = check.success ? "✅" : "❌"
      summary += `### ${icon} ${check.check.charAt(0).toUpperCase() + check.check.slice(1)}

${check.success ? check.message : check.error}

`
      if (check.details) {
        summary += `**Details**: ${JSON.stringify(check.details, null, 2)}

`
      }
    })

    // Add issues
    if (debugReport.issues.length > 0) {
      summary += `## Issues Found

`
      debugReport.issues.forEach((issue, index) => {
        summary += `### ${index + 1}. ${issue.type.charAt(0).toUpperCase() + issue.type.slice(1)} Issue

**Problem**: ${issue.message}
**Solution**: ${issue.solution}

`
      })
    }

    // Add recommendations
    if (debugReport.recommendations.length > 0) {
      summary += `## Recommendations

`
      debugReport.recommendations.forEach((rec, index) => {
        const priority =
          rec.type === "critical" ? "🚨" : rec.type === "high" ? "⚠️" : rec.type === "medium" ? "⚡" : "💡"
        summary += `### ${priority} ${rec.message}

${rec.action}

`
      })
    }

    fs.writeFileSync(summaryPath, summary)
    console.log(`   📋 Debug summary saved: ${summaryPath}`)
  }

  async debugAllPlugins() {
    console.log("🔍 Debugging all configured plugins...")

    // Get list of installed ESLint plugins
    const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"))
    const allDeps = { ...packageJson.dependencies, ...packageJson.devDependencies }

    const eslintPlugins = Object.keys(allDeps).filter(
      (dep) => dep.includes("eslint-plugin") || dep === "@typescript-eslint/eslint-plugin",
    )

    console.log(`Found ${eslintPlugins.length} ESLint plugins to debug`)

    const results = []
    for (const plugin of eslintPlugins) {
      const result = await this.debugPlugin(plugin)
      results.push(result)
    }

    // Generate master debug report
    this.generateMasterDebugReport(results)

    return results
  }

  generateMasterDebugReport(results) {
    const masterReport = {
      timestamp: new Date().toISOString(),
      totalPlugins: results.length,
      workingPlugins: results.filter((r) => r.issues.length === 0).length,
      brokenPlugins: results.filter((r) => r.issues.length > 0).length,
      results,
    }

    const reportPath = path.join(this.reportDir, "master-debug-report.json")
    fs.writeFileSync(reportPath, JSON.stringify(masterReport, null, 2))

    // Generate summary
    const summaryPath = path.join(this.reportDir, "debug-summary.md")
    let summary = `# ESLint Plugin Debug Summary

Generated: ${new Date().toLocaleString()}

## Overview

- **Total Plugins**: ${masterReport.totalPlugins}
- **Working Plugins**: ${masterReport.workingPlugins}
- **Broken Plugins**: ${masterReport.brokenPlugins}

## Plugin Status

`

    results.forEach((result) => {
      const status = result.issues.length === 0 ? "✅" : "❌"
      const issueCount = result.issues.length
      summary += `- ${status} **${result.plugin}** ${issueCount > 0 ? `(${issueCount} issues)` : ""}
`
    })

    if (masterReport.brokenPlugins > 0) {
      summary += `
## Action Items

`
      results
        .filter((r) => r.issues.length > 0)
        .forEach((result) => {
          summary += `### ${result.plugin}

`
          result.recommendations.forEach((rec) => {
            summary += `- ${rec.message}: ${rec.action}
`
          })
          summary += `
`
        })
    }

    fs.writeFileSync(summaryPath, summary)
    console.log(`\n📊 Master debug report saved: ${reportPath}`)
    console.log(`📋 Debug summary saved: ${summaryPath}`)
  }
}

// CLI execution
async function main() {
  const pluginDebugger = new PluginDebugger()

  const pluginName = process.argv[2]

  try {
    if (pluginName) {
      console.log(`Debugging specific plugin: ${pluginName}`)
      await pluginDebugger.debugPlugin(pluginName)
    } else {
      console.log("Debugging all plugins...")
      const results = await pluginDebugger.debugAllPlugins()

      const brokenCount = results.filter((r) => r.issues.length > 0).length
      if (brokenCount > 0) {
        console.log(`\n⚠️ Found ${brokenCount} plugin(s) with issues`)
        process.exit(1)
      } else {
        console.log("\n✅ All plugins are working correctly")
      }
    }
  } catch (error) {
    console.error("💥 Debug process failed:", error)
    process.exit(1)
  }
}

if (require.main === module) {
  main()
}

module.exports = PluginDebugger
