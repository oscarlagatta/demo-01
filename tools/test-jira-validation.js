#!/usr/bin/env node

const { validateJiraTicket, isBranchExempt, isCommitTypeExempt } = require("./validate-jira-ticket.js")

// Test cases
const testCases = [
  // Valid cases
  {
    message: "EARS-1887: fix user authentication bug",
    expected: true,
    description: "Valid ticket with colon",
  },
  {
    message: "PROJ-123 add new dashboard component",
    expected: true,
    description: "Valid ticket without colon",
  },
  {
    message: "DEV-456: update API documentation with examples",
    expected: true,
    description: "Valid ticket with longer message",
  },

  // Invalid cases
  {
    message: "fix user authentication bug",
    expected: false,
    description: "Missing ticket number",
  },
  {
    message: "ears-1887: fix bug",
    expected: false,
    description: "Lowercase project prefix",
  },
  {
    message: "INVALID-123: test message",
    expected: false,
    description: "Invalid project prefix",
  },
  {
    message: "EARS-0: test message",
    expected: false,
    description: "Invalid ticket number (too low)",
  },
  {
    message: "EARS-999999: test",
    expected: false,
    description: "Invalid ticket number (too high)",
  },
  {
    message: "EARS-123: x",
    expected: false,
    description: "Message too short",
  },

  // Exempt cases
  {
    message: "merge branch feature into main",
    expected: true,
    description: "Merge commit (exempt)",
  },
  {
    message: "revert: previous commit",
    expected: true,
    description: "Revert commit (exempt)",
  },
  {
    message: "initial commit",
    expected: true,
    description: "Initial commit (exempt)",
  },
]

// Branch exemption tests
const branchTests = [
  { branch: "main", expected: true },
  { branch: "master", expected: true },
  { branch: "develop", expected: true },
  { branch: "release/v1.0.0", expected: true },
  { branch: "hotfix/critical-bug", expected: true },
  { branch: "feature/user-auth", expected: false },
  { branch: "bugfix/login-issue", expected: false },
]

// Colors for output
const colors = {
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  reset: "\x1b[0m",
  bold: "\x1b[1m",
}

function colorize(text, color) {
  return `${colors[color]}${text}${colors.reset}`
}

// Run validation tests
function runValidationTests() {
  console.log(colorize("🧪 Running Jira Validation Tests", "blue"))
  console.log("================================")

  let passed = 0
  let failed = 0

  testCases.forEach((testCase, index) => {
    const result = validateJiraTicket(testCase.message)
    const success = result.isValid === testCase.expected

    if (success) {
      console.log(colorize(`✅ Test ${index + 1}: ${testCase.description}`, "green"))
      passed++
    } else {
      console.log(colorize(`❌ Test ${index + 1}: ${testCase.description}`, "red"))
      console.log(colorize(`   Expected: ${testCase.expected}, Got: ${result.isValid}`, "red"))
      console.log(colorize(`   Message: "${testCase.message}"`, "yellow"))
      if (result.errors.length > 0) {
        console.log(colorize(`   Errors: ${result.errors.join(", ")}`, "red"))
      }
      failed++
    }
  })

  console.log("")
  console.log(colorize(`📊 Validation Tests: ${passed} passed, ${failed} failed`, failed > 0 ? "red" : "green"))

  return failed === 0
}

// Run branch exemption tests
function runBranchTests() {
  console.log("")
  console.log(colorize("🌿 Running Branch Exemption Tests", "blue"))
  console.log("=================================")

  let passed = 0
  let failed = 0

  branchTests.forEach((test, index) => {
    const result = isBranchExempt(test.branch)
    const success = result === test.expected

    if (success) {
      console.log(colorize(`✅ Branch Test ${index + 1}: ${test.branch}`, "green"))
      passed++
    } else {
      console.log(colorize(`❌ Branch Test ${index + 1}: ${test.branch}`, "red"))
      console.log(colorize(`   Expected: ${test.expected}, Got: ${result}`, "red"))
      failed++
    }
  })

  console.log("")
  console.log(colorize(`📊 Branch Tests: ${passed} passed, ${failed} failed`, failed > 0 ? "red" : "green"))

  return failed === 0
}

// Run commit type exemption tests
function runCommitTypeTests() {
  console.log("")
  console.log(colorize("📝 Running Commit Type Exemption Tests", "blue"))
  console.log("======================================")

  const commitTypeTests = [
    { message: "merge: combine branches", expected: true },
    { message: "revert: undo changes", expected: true },
    { message: "initial: first commit", expected: true },
    { message: "feat: add new feature", expected: false },
    { message: "fix: resolve bug", expected: false },
  ]

  let passed = 0
  let failed = 0

  commitTypeTests.forEach((test, index) => {
    const result = isCommitTypeExempt(test.message)
    const success = result === test.expected

    if (success) {
      console.log(colorize(`✅ Type Test ${index + 1}: ${test.message}`, "green"))
      passed++
    } else {
      console.log(colorize(`❌ Type Test ${index + 1}: ${test.message}`, "red"))
      console.log(colorize(`   Expected: ${test.expected}, Got: ${result}`, "red"))
      failed++
    }
  })

  console.log("")
  console.log(colorize(`📊 Commit Type Tests: ${passed} passed, ${failed} failed`, failed > 0 ? "red" : "green"))

  return failed === 0
}

// Main test runner
function runAllTests() {
  console.log(colorize("🚀 Starting Jira Validation Test Suite", "bold"))
  console.log("")

  const validationPassed = runValidationTests()
  const branchPassed = runBranchTests()
  const commitTypePassed = runCommitTypeTests()

  const allPassed = validationPassed && branchPassed && commitTypePassed

  console.log("")
  console.log("=".repeat(50))

  if (allPassed) {
    console.log(colorize("🎉 All tests passed!", "green"))
    console.log(colorize("Your Jira validation setup is working correctly.", "green"))
  } else {
    console.log(colorize("❌ Some tests failed!", "red"))
    console.log(colorize("Please check your configuration and fix any issues.", "red"))
  }

  return allPassed
}

// CLI execution
if (require.main === module) {
  const success = runAllTests()
  process.exit(success ? 0 : 1)
}

module.exports = { runAllTests }
