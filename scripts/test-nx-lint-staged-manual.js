#!/usr/bin/env node

/**
 * Manual test script for nx-lint-staged.js
 * Allows you to test the linting process without git staging
 */

const { spawn } = require("child_process")
const fs = require("fs")
const path = require("path")
const glob = require("glob")

// Colors for output
const colors = {
  reset: "\x1b[0m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
}

function colorize(color, text) {
  return `${colors[color]}${text}${colors.reset}`
}

function printHeader(message) {
  console.log(colorize("magenta", `\n${"=".repeat(60)}`))
  console.log(colorize("magenta", `  ${message}`))
  console.log(colorize("magenta", `${"=".repeat(60)}\n`))
}

function printInfo(message) {
  console.log(colorize("blue", `ℹ️  ${message}`))
}

function printSuccess(message) {
  console.log(colorize("green", `✅ ${message}`))
}

function printError(message) {
  console.log(colorize("red", `❌ ${message}`))
}

// Function to get test files
function getTestFiles() {
  const patterns = [
    "app/**/*.{js,jsx,ts,tsx}",
    "components/**/*.{js,jsx,ts,tsx}",
    "lib/**/*.{js,jsx,ts,tsx}",
    "*.{js,jsx,ts,tsx}",
  ]

  let files = []
  patterns.forEach((pattern) => {
    try {
      const matches = glob.sync(pattern, { ignore: ["node_modules/**", ".next/**", "dist/**"] })
      files = files.concat(matches)
    } catch (error) {
      // Ignore glob errors
    }
  })

  return [...new Set(files)] // Remove duplicates
}

// Function to run the nx-lint-staged script
function runNxLintStaged(files) {
  return new Promise((resolve) => {
    const scriptPath = path.join(__dirname, "nx-lint-staged.js")

    if (!fs.existsSync(scriptPath)) {
      printError(`Script not found: ${scriptPath}`)
      resolve({ success: false, error: "Script not found" })
      return
    }

    printInfo(`Running: node ${scriptPath} ${files.join(" ")}`)

    const child = spawn("node", [scriptPath, ...files], {
      stdio: "inherit",
      env: { ...process.env, FORCE_COLOR: "1" },
    })

    child.on("close", (code) => {
      resolve({
        success: code === 0,
        code,
      })
    })

    child.on("error", (error) => {
      printError(`Failed to start script: ${error.message}`)
      resolve({
        success: false,
        error: error.message,
      })
    })
  })
}

// Main test function
async function main() {
  const args = process.argv.slice(2)

  printHeader("Manual Test for nx-lint-staged.js")

  let testFiles = []

  if (args.length > 0) {
    // Use provided files
    testFiles = args.filter((file) => fs.existsSync(file))
    printInfo(`Testing with provided files: ${testFiles.length} files`)
  } else {
    // Auto-discover files
    testFiles = getTestFiles()
    printInfo(`Auto-discovered ${testFiles.length} files to test`)

    if (testFiles.length > 10) {
      // Limit to first 10 files for testing
      testFiles = testFiles.slice(0, 10)
      printInfo(`Limited to first 10 files for testing`)
    }
  }

  if (testFiles.length === 0) {
    printError("No files found to test")
    process.exit(1)
  }

  console.log("\nFiles to be processed:")
  testFiles.forEach((file, index) => {
    console.log(`  ${index + 1}. ${file}`)
  })

  console.log("\n" + "─".repeat(60))

  const result = await runNxLintStaged(testFiles)

  console.log("\n" + "─".repeat(60))

  if (result.success) {
    printSuccess("nx-lint-staged.js completed successfully!")
  } else {
    printError(`nx-lint-staged.js failed with code: ${result.code}`)
  }

  process.exit(result.success ? 0 : 1)
}

// Handle interruption
process.on("SIGINT", () => {
  console.log(colorize("yellow", "\n⚠️  Test interrupted by user"))
  process.exit(1)
})

main().catch((error) => {
  printError(`Unexpected error: ${error.message}`)
  console.error(error.stack)
  process.exit(1)
})
