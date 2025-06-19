#!/usr/bin/env node

const fs = require("fs")
const path = require("path")
const { execSync } = require("child_process")

class CodebaseAssessment {
  constructor() {
    this.results = {
      totalFiles: 0,
      totalLines: 0,
      estimatedViolations: 0,
      complexityScore: 0,
      riskLevel: "Low",
      estimatedFixTime: "0 hours",
      recommendations: [],
    }
  }

  async runAssessment(outputPath = "reports/assessment.json") {
    console.log("🔍 Starting codebase assessment...")

    try {
      // Ensure reports directory exists
      const reportsDir = path.dirname(outputPath)
      if (!fs.existsSync(reportsDir)) {
        fs.mkdirSync(reportsDir, { recursive: true })
      }

      // Step 1: Count files and lines
      await this.analyzeCodebase()

      // Step 2: Run ESLint dry-run to estimate violations
      await this.estimateViolations()

      // Step 3: Calculate complexity and risk
      this.calculateRiskAssessment()

      // Step 4: Generate recommendations
      this.generateRecommendations()

      // Step 5: Save results
      this.saveResults(outputPath)

      console.log("✅ Assessment complete!")
      console.log(`📊 Results saved to: ${outputPath}`)
      this.printSummary()
    } catch (error) {
      console.error("❌ Assessment failed:", error.message)
      process.exit(1)
    }
  }

  async analyzeCodebase() {
    console.log("📁 Analyzing codebase structure...")

    const extensions = [".js", ".jsx", ".ts", ".tsx"]
    const excludeDirs = ["node_modules", "dist", "build", ".git"]

    const files = this.findFiles(".", extensions, excludeDirs)
    this.results.totalFiles = files.length

    let totalLines = 0
    files.forEach((file) => {
      try {
        const content = fs.readFileSync(file, "utf8")
        totalLines += content.split("\n").length
      } catch (error) {
        console.warn(`⚠️  Could not read file: ${file}`)
      }
    })

    this.results.totalLines = totalLines
    console.log(`📊 Found ${files.length} files with ${totalLines} total lines`)
  }

  findFiles(dir, extensions, excludeDirs) {
    let files = []

    try {
      const items = fs.readdirSync(dir)

      for (const item of items) {
        const fullPath = path.join(dir, item)
        const stat = fs.statSync(fullPath)

        if (stat.isDirectory() && !excludeDirs.includes(item)) {
          files = files.concat(this.findFiles(fullPath, extensions, excludeDirs))
        } else if (stat.isFile() && extensions.some((ext) => item.endsWith(ext))) {
          files.push(fullPath)
        }
      }
    } catch (error) {
      console.warn(`⚠️  Could not read directory: ${dir}`)
    }

    return files
  }

  async estimateViolations() {
    console.log("🔧 Estimating ESLint violations...")

    try {
      // Create a temporary ESLint config for assessment
      const tempConfig = {
        extends: ["@nx/eslint-plugin-nx/recommended"],
        rules: {
          semi: "error",
          quotes: ["error", "single"],
          "no-unused-vars": "error",
          "no-console": "warn",
          indent: ["error", 2],
          "comma-dangle": ["error", "always-multiline"],
        },
      }

      fs.writeFileSync(".eslintrc.temp.json", JSON.stringify(tempConfig, null, 2))

      // Run ESLint with the temp config (dry run)
      const result = execSync("npx eslint . --config .eslintrc.temp.json --format json --ext .js,.jsx,.ts,.tsx", {
        encoding: "utf8",
        stdio: "pipe",
      })

      const eslintResults = JSON.parse(result)
      this.results.estimatedViolations = eslintResults.reduce((total, file) => total + file.messages.length, 0)

      // Clean up temp config
      fs.unlinkSync(".eslintrc.temp.json")
    } catch (error) {
      // ESLint will exit with non-zero code when violations found
      if (error.stdout) {
        try {
          const eslintResults = JSON.parse(error.stdout)
          this.results.estimatedViolations = eslintResults.reduce((total, file) => total + file.messages.length, 0)
        } catch (parseError) {
          console.warn("⚠️  Could not parse ESLint output, using estimation")
          this.results.estimatedViolations = Math.floor(this.results.totalLines * 0.1)
        }
      } else {
        console.warn("⚠️  ESLint dry-run failed, using line-based estimation")
        this.results.estimatedViolations = Math.floor(this.results.totalLines * 0.1)
      }
    }

    console.log(`🚨 Estimated violations: ${this.results.estimatedViolations}`)
  }

  calculateRiskAssessment() {
    console.log("📈 Calculating risk assessment...")

    const violationRatio = this.results.estimatedViolations / this.results.totalLines
    const fileComplexity = this.results.totalFiles > 1000 ? "High" : this.results.totalFiles > 500 ? "Medium" : "Low"

    // Calculate complexity score (0-100)
    this.results.complexityScore = Math.min(
      100,
      violationRatio * 50 + this.results.totalFiles / 100 + this.results.totalLines / 10000,
    )

    // Determine risk level
    if (this.results.complexityScore > 70) {
      this.results.riskLevel = "High"
    } else if (this.results.complexityScore > 40) {
      this.results.riskLevel = "Medium"
    } else {
      this.results.riskLevel = "Low"
    }

    // Estimate fix time (assuming 1 violation = 2 minutes average)
    const estimatedMinutes = this.results.estimatedViolations * 2
    const hours = Math.ceil(estimatedMinutes / 60)
    this.results.estimatedFixTime = `${hours} hours`

    console.log(`📊 Complexity Score: ${this.results.complexityScore}/100`)
    console.log(`⚠️  Risk Level: ${this.results.riskLevel}`)
    console.log(`⏱️  Estimated Fix Time: ${this.results.estimatedFixTime}`)
  }

  generateRecommendations() {
    console.log("💡 Generating recommendations...")

    const recommendations = []

    if (this.results.riskLevel === "High") {
      recommendations.push("Consider extended timeline (16+ weeks)")
      recommendations.push("Start with pilot project on smallest codebase section")
      recommendations.push("Focus on auto-fixable rules first")
      recommendations.push("Plan for significant exception handling")
    } else if (this.results.riskLevel === "Medium") {
      recommendations.push("Standard timeline (12-16 weeks) should work")
      recommendations.push("Incremental rollout by project complexity")
      recommendations.push("Emphasize team training and support")
    } else {
      recommendations.push("Accelerated timeline possible (8-12 weeks)")
      recommendations.push("Can implement more aggressive rule set")
      recommendations.push("Focus on advanced ESLint features")
    }

    if (this.results.totalFiles > 1000) {
      recommendations.push("Consider performance optimization strategies")
      recommendations.push("Implement ESLint caching")
      recommendations.push("Use incremental linting in CI/CD")
    }

    if (this.results.estimatedViolations > 10000) {
      recommendations.push("Prioritize auto-fixable violations")
      recommendations.push("Create dedicated violation fix sprints")
      recommendations.push("Consider gradual rule introduction")
    }

    this.results.recommendations = recommendations
  }

  saveResults(outputPath) {
    const report = {
      timestamp: new Date().toISOString(),
      assessment: this.results,
      nextSteps: [
        "Review this assessment with team leads",
        "Plan team communication strategy",
        "Select pilot project based on recommendations",
        "Begin Phase 1: Assessment and Communication",
      ],
    }

    fs.writeFileSync(outputPath, JSON.stringify(report, null, 2))
  }

  printSummary() {
    console.log("\n📋 ASSESSMENT SUMMARY")
    console.log("========================")
    console.log(`Files analyzed: ${this.results.totalFiles}`)
    console.log(`Total lines: ${this.results.totalLines.toLocaleString()}`)
    console.log(`Estimated violations: ${this.results.estimatedViolations.toLocaleString()}`)
    console.log(`Complexity score: ${this.results.complexityScore}/100`)
    console.log(`Risk level: ${this.results.riskLevel}`)
    console.log(`Estimated fix time: ${this.results.estimatedFixTime}`)
    console.log("\n💡 KEY RECOMMENDATIONS:")
    this.results.recommendations.forEach((rec) => console.log(`  • ${rec}`))
    console.log("\n🚀 Next: Review reports/assessment.json and begin Phase 1")
  }
}

// CLI execution
if (require.main === module) {
  const outputPath = process.argv[2] || "reports/assessment.json"
  const assessment = new CodebaseAssessment()
  assessment.runAssessment(outputPath)
}

module.exports = CodebaseAssessment
