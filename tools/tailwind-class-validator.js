// Tool to validate Tailwind CSS classes against your configuration
const fs = require("fs")
const path = require("path")

class TailwindClassValidator {
  constructor() {
    this.tailwindConfig = this.loadTailwindConfig()
    this.commonIssues = []
  }

  loadTailwindConfig() {
    try {
      // Attempt to load tailwind.config.ts/js
      const configPath = path.join(process.cwd(), "tailwind.config.ts")
      if (fs.existsSync(configPath)) {
        return require(configPath)
      }
      return null
    } catch (error) {
      console.warn("Could not load Tailwind config:", error.message)
      return null
    }
  }

  validateClass(className) {
    const issues = []

    // Check for common Tailwind v3 patterns that might be flagged
    const tailwindV3Patterns = [
      /^\[.*\]$/, // Arbitrary values: [123px], [#ff0000]
      /^data-\[.*\]:/, // Data attribute selectors
      /^group-\[.*\]:/, // Group selectors with arbitrary values
      /^peer-\[.*\]:/, // Peer selectors with arbitrary values
      /^supports-\[.*\]:/, // CSS @supports queries
      /^min-\[.*\]:/, // Arbitrary min-width values
      /^max-\[.*\]:/, // Arbitrary max-width values
    ]

    const isArbitraryValue = tailwindV3Patterns.some((pattern) => pattern.test(className))

    if (isArbitraryValue) {
      issues.push({
        type: "arbitrary-value",
        message: `Class "${className}" uses arbitrary values - ensure it's whitelisted`,
        suggestion: "Add to tailwindcss/no-custom-classname whitelist",
      })
    }

    // Check for custom utility patterns
    const customPatterns = [
      /^animate-/, // Custom animations
      /^data-\[/, // Data attributes
      /^group-/, // Group modifiers
      /^peer-/, // Peer modifiers
    ]

    const isCustomPattern = customPatterns.some((pattern) => pattern.test(className))

    if (isCustomPattern) {
      issues.push({
        type: "custom-pattern",
        message: `Class "${className}" may need whitelist configuration`,
        suggestion: "Verify against current ESLint tailwindcss plugin settings",
      })
    }

    return issues
  }

  analyzeComponent(filePath) {
    try {
      const content = fs.readFileSync(filePath, "utf8")
      const classMatches = content.match(/className=["']([^"']+)["']/g) || []

      const allIssues = []

      classMatches.forEach((match) => {
        const classes = match.match(/["']([^"']+)["']/)[1].split(/\s+/)
        classes.forEach((className) => {
          const issues = this.validateClass(className)
          if (issues.length > 0) {
            allIssues.push({
              file: filePath,
              className,
              issues,
            })
          }
        })
      })

      return allIssues
    } catch (error) {
      console.error(`Error analyzing ${filePath}:`, error.message)
      return []
    }
  }
}

// Example usage
const validator = new TailwindClassValidator()

// Test common problematic classes
const testClasses = [
  "bg-[#ff0000]", // Arbitrary color
  "w-[123px]", // Arbitrary width
  "data-[state=open]:block", // Data attribute selector
  "group-[.is-active]:opacity-100", // Group with arbitrary selector
  "animate-spin-slow", // Custom animation
  "supports-[display:grid]:grid", // CSS supports query
]

console.log("Tailwind Class Validation Results:")
console.log("=================================")

testClasses.forEach((className) => {
  const issues = validator.validateClass(className)
  if (issues.length > 0) {
    console.log(`\n❌ ${className}:`)
    issues.forEach((issue) => {
      console.log(`   ${issue.message}`)
      console.log(`   💡 ${issue.suggestion}`)
    })
  } else {
    console.log(`✅ ${className}: No issues detected`)
  }
})

module.exports = TailwindClassValidator
