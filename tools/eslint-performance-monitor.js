"use client"
\
#!/usr/bin/env node

const { ESLint } = require("eslint")
const fs = require("fs")
const path = require("path")
const { performance } = require("perf_hooks")

console.log("📊 ESLint Performance Monitor")
console.log("=============================")

class ESLintPerformanceMonitor {
  constructor() {
    this.reportDir = "reports/eslint-performance"
    this.metricsFile = path.join(this.reportDir, "performance-metrics.json")

    if (!fs.existsSync(this.reportDir)) {
      fs.mkdirSync(this.reportDir, { recursive: true })
    }
  }

  async measurePerformance() {
    const metrics = {
      timestamp: new Date().toISOString(),
      measurements: [],
    }

    // Test scenarios
    const scenarios = [
      {
        name: "small-file",
        description: "Small TypeScript file (50 lines)",
        content: this.generateTestFile(50),
      },
      {
        name: "medium-file",
        description: "Medium TypeScript file (200 lines)",
        content: this.generateTestFile(200),
      },
      {
        name: "large-file",
        description: "Large TypeScript file (1000 lines)",
        content: this.generateTestFile(1000),
      },
    ]

    console.log("🔍 Running performance measurements...")

    for (const scenario of scenarios) {
      console.log(`   Testing: ${scenario.description}`)

      const measurement = await this.measureScenario(scenario)
      metrics.measurements.push(measurement)

      console.log(`   Duration: ${measurement.duration}ms`)
      console.log(`   Violations: ${measurement.violationCount}`)
    }

    // Save metrics
    this.saveMetrics(metrics)

    // Generate performance report
    this.generatePerformanceReport(metrics)

    return metrics
  }

  async measureScenario(scenario) {
    const testFile = path.join(this.reportDir, `${scenario.name}.ts`)
    fs.writeFileSync(testFile, scenario.content)

    const eslint = new ESLint()

    // Measure performance
    const startTime = performance.now()
    const results = await eslint.lintFiles([testFile])
    const endTime = performance.now()

    const duration = Math.round(endTime - startTime)
    const violationCount = results[0]?.messages?.length || 0
    const ruleViolations = {}

    // Count violations by rule
    if (results[0]?.messages) {
      results[0].messages.forEach((msg) => {
        if (msg.ruleId) {
          ruleViolations[msg.ruleId] = (ruleViolations[msg.ruleId] || 0) + 1
        }
      })
    }

    // Clean up test file
    fs.unlinkSync(testFile)

    return {
      scenario: scenario.name,
      description: scenario.description,
      duration,
      violationCount,
      ruleViolations,
      linesOfCode: scenario.content.split("\n").length,
    }
  }

  generateTestFile(lines) {
    let content = `// Generated test file with ${lines} lines
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { z } from 'zod';

interface TestInterface {
  id: number;
  name: string;
  data: any; // This should trigger @typescript-eslint/no-explicit-any
}

`

    for (let i = 1; i <= lines; i++) {
      if (i % 10 === 0) {
        // Add some variety to trigger different rules
        content += `
function testFunction${i}(param: string) {
  const unusedVar = 'test'; // Should trigger unused-vars
  return param.toUpperCase();
}
`
      } else if (i % 15 === 0) {
        content += `
const Component${i} = () => {
  const [state, setState] = useState('');
  const unused = 'test'; // Should trigger unused-vars
  return <div>{state}</div>;
};
`
      } else {
        content += `console.log('Line ${i}'); // Line ${i}\n`
      }
    }

    return content
  }

  saveMetrics(metrics) {
    // Load existing metrics if they exist
    let allMetrics = []
    if (fs.existsSync(this.metricsFile)) {
      try {
        allMetrics = JSON.parse(fs.readFileSync(this.metricsFile, "utf8"))
      } catch (error) {
        console.warn("Could not load existing metrics:", error.message)
      }
    }

    // Add new metrics
    allMetrics.push(metrics)

    // Keep only last 30 measurements
    if (allMetrics.length > 30) {
      allMetrics = allMetrics.slice(-30)
    }

    fs.writeFileSync(this.metricsFile, JSON.stringify(allMetrics, null, 2))
  }

  generatePerformanceReport(currentMetrics) {
    const reportPath = path.join(this.reportDir, "performance-report.md")

    // Load historical data
    let allMetrics = [currentMetrics]
    if (fs.existsSync(this.metricsFile)) {
      try {
        allMetrics = JSON.parse(fs.readFileSync(this.metricsFile, "utf8"))
      } catch (error) {
        console.warn("Could not load historical metrics")
      }
    }

    let report = `# ESLint Performance Report

Generated: ${new Date().toLocaleString()}

## Current Performance

`

    // Current measurements
    currentMetrics.measurements.forEach((measurement) => {
      report += `### ${measurement.description}

- **Duration**: ${measurement.duration}ms
- **Lines of Code**: ${measurement.linesOfCode}
- **Violations Found**: ${measurement.violationCount}
- **Performance**: ${(measurement.duration / measurement.linesOfCode).toFixed(2)}ms per line

#### Rule Violations:
`
      Object.entries(measurement.ruleViolations).forEach(([rule, count]) => {
        report += `- ${rule}: ${count}\n`
      })
      report += "\n"
    })

    // Performance trends
    if (allMetrics.length > 1) {
      report += `## Performance Trends

`

      const scenarios = ["small-file", "medium-file", "large-file"]
      scenarios.forEach((scenarioName) => {
        const scenarioData = allMetrics
          .map((m) => m.measurements.find((measurement) => measurement.scenario === scenarioName))
          .filter(Boolean)

        if (scenarioData.length > 1) {
          const latest = scenarioData[scenarioData.length - 1]
          const previous = scenarioData[scenarioData.length - 2]
          const change = latest.duration - previous.duration
          const changePercent = ((change / previous.duration) * 100).toFixed(1)

          report += `### ${latest.description}

- **Latest**: ${latest.duration}ms
- **Previous**: ${previous.duration}ms
- **Change**: ${change > 0 ? "+" : ""}${change}ms (${changePercent}%)
- **Trend**: ${change > 0 ? "📈 Slower" : change < 0 ? "📉 Faster" : "➡️ Same"}

`
        }
      })
    }

    // Performance recommendations
    report += `## Recommendations

`

    const avgDuration =
      currentMetrics.measurements.reduce((sum, m) => sum + m.duration, 0) / currentMetrics.measurements.length

    if (avgDuration > 1000) {
      report += `⚠️ **High Duration**: Average ESLint execution time is ${avgDuration.toFixed(0)}ms. Consider:
- Disabling expensive rules for large files
- Using ESLint cache
- Running ESLint only on changed files

`
    } else if (avgDuration > 500) {
      report += `⚡ **Moderate Duration**: Average ESLint execution time is ${avgDuration.toFixed(0)}ms. Consider:
- Enabling ESLint cache
- Optimizing rule configurations

`
    } else {
      report += `✅ **Good Performance**: Average ESLint execution time is ${avgDuration.toFixed(0)}ms.

`
    }

    // Plugin-specific recommendations
    const allRuleViolations = {}
    currentMetrics.measurements.forEach((m) => {
      Object.entries(m.ruleViolations).forEach(([rule, count]) => {
        allRuleViolations[rule] = (allRuleViolations[rule] || 0) + count
      })
    })

    const topRules = Object.entries(allRuleViolations)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)

    if (topRules.length > 0) {
      report += `## Most Frequent Rule Violations

`
      topRules.forEach(([rule, count]) => {
        report += `- **${rule}**: ${count} violations\n`
      })
    }

    fs.writeFileSync(reportPath, report)
    console.log(`📋 Performance report saved to: ${reportPath}`)
  }

  async generateTrendAnalysis() {
    if (!fs.existsSync(this.metricsFile)) {
      console.log("No historical data available for trend analysis")
      return
    }

    const allMetrics = JSON.parse(fs.readFileSync(this.metricsFile, "utf8"))

    if (allMetrics.length < 3) {
      console.log("Insufficient data for trend analysis (need at least 3 measurements)")
      return
    }

    console.log("\n📈 Performance Trend Analysis:")

    const scenarios = ["small-file", "medium-file", "large-file"]

    scenarios.forEach((scenarioName) => {
      const scenarioData = allMetrics
        .map((m) => m.measurements.find((measurement) => measurement.scenario === scenarioName))
        .filter(Boolean)

      if (scenarioData.length >= 3) {
        const durations = scenarioData.map((d) => d.duration)
        const avg = durations.reduce((a, b) => a + b, 0) / durations.length
        const trend = this.calculateTrend(durations)

        console.log(`\n   ${scenarioName}:`)
        console.log(`     Average: ${avg.toFixed(0)}ms`)
        console.log(`     Trend: ${trend > 0 ? "📈 Getting slower" : trend < 0 ? "📉 Getting faster" : "➡️ Stable"}`)
        console.log(`     Latest: ${durations[durations.length - 1]}ms`)
      }
    })
  }

  calculateTrend(values) {
    if (values.length < 2) return 0

    const n = values.length
    const sumX = (n * (n + 1)) / 2
    const sumY = values.reduce((a, b) => a + b, 0)
    const sumXY = values.reduce((sum, y, i) => sum + (i + 1) * y, 0)
    const sumX2 = (n * (n + 1) * (2 * n + 1)) / 6

    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
  }
}

// CLI execution
async function main() {
  const monitor = new ESLintPerformanceMonitor()

  try {
    const metrics = await monitor.measurePerformance()
    await monitor.generateTrendAnalysis()

    console.log("\n✅ Performance monitoring completed")

    // Check for performance issues
    const avgDuration = metrics.measurements.reduce((sum, m) => sum + m.duration, 0) / metrics.measurements.length

    if (avgDuration > 1000) {
      console.log("⚠️ Performance warning: ESLint is running slowly")
      process.exit(1)
    }
  } catch (error) {
    console.error("💥 Performance monitoring failed:", error)
    process.exit(1)
  }
}

if (require.main === module) {
  main()
}

module.exports = ESLintPerformanceMonitor
