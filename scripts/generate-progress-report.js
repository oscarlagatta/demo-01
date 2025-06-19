#!/usr/bin/env node

const fs = require("fs")
const { execSync } = require("child_process")

class ProgressReporter {
  constructor() {
    this.reportData = {
      timestamp: new Date().toISOString(),
      phase: "Unknown",
      metrics: {},
      violations: {},
      adoption: {},
      recommendations: [],
    }
  }

  async generateReport(outputPath = "reports/progress-report.json") {
    console.log("📊 Generating progress report...")

    try {
      // Ensure reports directory exists
      const reportsDir = "reports"
      if (!fs.existsSync(reportsDir)) {
        fs.mkdirSync(reportsDir, { recursive: true })
      }

      // Collect metrics
      await this.collectViolationMetrics()
      await this.collectAdoptionMetrics()
      await this.determineCurrentPhase()
      await this.generateRecommendations()

      // Save report
      fs.writeFileSync(outputPath, JSON.stringify(this.reportData, null, 2))

      console.log("✅ Progress report generated!")
      console.log(`📄 Report saved to: ${outputPath}`)
      this.printSummary()
    } catch (error) {
      console.error("❌ Report generation failed:", error.message)
      process.exit(1)
    }
  }

  async collectViolationMetrics() {
    console.log("🔍 Collecting violation metrics...")

    try {
      // Run ESLint and capture results
      const result = execSync("npx eslint . --format json --ext .js,.jsx,.ts,.tsx", { encoding: "utf8", stdio: "pipe" })

      const eslintResults = JSON.parse(result)
      this.processESLintResults(eslintResults)
    } catch (error) {
      if (error.stdout) {
        try {
          const eslintResults = JSON.parse(error.stdout)
          this.processESLintResults(eslintResults)
        } catch (parseError) {
          console.warn("⚠️  Could not parse ESLint output")
          this.reportData.violations = { error: "Could not collect violation data" }
        }
      }
    }
  }

  processESLintResults(results) {
    const violations = {
      totalFiles: results.length,
      filesWithViolations: results.filter((file) => file.messages.length > 0).length,
      totalViolations: results.reduce((sum, file) => sum + file.messages.length, 0),
      errorCount: results.reduce((sum, file) => sum + file.messages.filter((msg) => msg.severity === 2).length, 0),
      warningCount: results.reduce((sum, file) => sum + file.messages.filter((msg) => msg.severity === 1).length, 0),
      ruleBreakdown: {},
    }

    // Count violations by rule
    results.forEach((file) => {
      file.messages.forEach((message) => {
        const rule = message.ruleId || "unknown"
        violations.ruleBreakdown[rule] = (violations.ruleBreakdown[rule] || 0) + 1
      })
    })

    // Calculate compliance percentage
    violations.compliancePercentage =
      violations.totalFiles > 0
        ? Math.round(((violations.totalFiles - violations.filesWithViolations) / violations.totalFiles) * 100)
        : 100

    this.reportData.violations = violations
  }

  async collectAdoptionMetrics() {
    console.log("📈 Collecting adoption metrics...")

    const adoption = {
      eslintConfigExists: fs.existsSync(".eslintrc.js") || fs.existsSync(".eslintrc.json"),
      preCommitHooksSetup: fs.existsSync(".husky/pre-commit"),
      packageJsonLintStaged: false,
      ideConfigsDistributed: fs.existsSync(".vscode/settings.json"),
    }

    // Check package.json for lint-staged
    try {
      const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"))
      adoption.packageJsonLintStaged = !!packageJson["lint-staged"]
    } catch (error) {
      console.warn("⚠️  Could not read package.json")
    }

    // Calculate adoption score
    const adoptionChecks = Object.values(adoption).filter(Boolean).length
    const totalChecks = Object.keys(adoption).length
    adoption.adoptionScore = Math.round((adoptionChecks / totalChecks) * 100)

    this.reportData.adoption = adoption
  }

  async determineCurrentPhase() {
    const { violations, adoption } = this.reportData

    if (!adoption.eslintConfigExists) {
      this.reportData.phase = "Phase 1: Assessment and Communication"
    } else if (violations.compliancePercentage < 50) {
      this.reportData.phase = "Phase 2: Pilot Project"
    } else if (violations.compliancePercentage < 80) {
      this.reportData.phase = "Phase 3: Incremental Integration"
    } else if (!adoption.preCommitHooksSetup) {
      this.reportData.phase = "Phase 4: Tools and Automation"
    } else {
      this.reportData.phase = "Phase 5: Continuous Improvement"
    }
  }

  async generateRecommendations() {
    const { violations, adoption, phase } = this.reportData
    const recommendations = []

    if (phase.includes("Phase 1")) {
      recommendations.push("Complete codebase assessment")
      recommendations.push("Begin team communication and training")
      recommendations.push("Select pilot project")
    } else if (phase.includes("Phase 2")) {
      recommendations.push("Focus on pilot project compliance")
      recommendations.push("Gather team feedback")
      recommendations.push("Refine ESLint configuration")
    } else if (phase.includes("Phase 3")) {
      if (violations.compliancePercentage < 60) {
        recommendations.push("Prioritize auto-fixable violations")
        recommendations.push("Consider dedicated fix sprints")
      }
      recommendations.push("Continue incremental rollout")
      recommendations.push("Monitor team productivity impact")
    } else if (phase.includes("Phase 4")) {
      if (!adoption.preCommitHooksSetup) {
        recommendations.push("Set up pre-commit hooks")
      }
      if (!adoption.ideConfigsDistributed) {
        recommendations.push("Distribute IDE configurations")
      }
      recommendations.push("Integrate with CI/CD pipeline")
    } else {
      recommendations.push("Monitor violation trends")
      recommendations.push("Collect team satisfaction feedback")
      recommendations.push("Plan configuration evolution")
    }

    // Add specific recommendations based on metrics
    if (violations.totalViolations > 1000) {
      recommendations.push("Consider automated violation fixing tools")
    }

    if (violations.compliancePercentage < 80) {
      recommendations.push("Increase focus on violation resolution")
    }

    this.reportData.recommendations = recommendations
  }

  printSummary() {
    const { phase, violations, adoption } = this.reportData

    console.log("\n📋 PROGRESS REPORT SUMMARY")
    console.log("===========================")
    console.log(`Current Phase: ${phase}`)
    console.log(`Compliance: ${violations.compliancePercentage || 0}%`)
    console.log(`Total Violations: ${violations.totalViolations || 0}`)
    console.log(`Adoption Score: ${adoption.adoptionScore || 0}%`)
    console.log("\n🎯 TOP RECOMMENDATIONS:")
    this.reportData.recommendations.slice(0, 3).forEach((rec) => console.log(`  • ${rec}`))
  }
}

// CLI execution
if (require.main === module) {
  const outputPath = process.argv[2] || "reports/progress-report.json"
  const reporter = new ProgressReporter()
  reporter.generateReport(outputPath)
}

module.exports = ProgressReporter
