#!/usr/bin/env node

/**
 * Test script for Nx monorepo lint-staged integration
 * Simulates lint-staged behavior for testing
 */

const { spawn } = require("child_process")
const fs = require("fs")
const path = require("path")
const glob = require("glob")

console.log("🧪 Testing Nx Monorepo Lint-Staged Integration...")

// Function to find TypeScript/JavaScript files
function findTestFiles() {
  const patterns = ["apps/**/*.{ts,tsx,js,jsx}", "libs/**/*.{ts,tsx,js,jsx}", "*.{ts,tsx,js,jsx}"]

  let files = []
  patterns.forEach((pattern) => {
    try {
      const matches = glob.sync(pattern, { ignore: ["node_modules/**", "dist/**", ".next/**"] })
      files = files.concat(matches)
    } catch (error) {
      console.log(`Warning: Could not search pattern ${pattern}`)
    }
  })

  return files.slice(0, 5) // Limit to 5 files for testing
}

async function runTest() {
  // Find some test files
  const testFiles = findTestFiles()

  if (testFiles.length === 0) {
    console.log("❌ No test files found")
    process.exit(1)
  }

  console.log(`📁 Found ${testFiles.length} test files:`)
  testFiles.forEach((file) => console.log(`   - ${file}`))

  // Run the nx-monorepo-lint-staged script
  console.log("\n🚀 Running nx-monorepo-lint-staged.js...")

  const child = spawn("node", ["scripts/nx-monorepo-lint-staged.js", ...testFiles], {
    stdio: "inherit",
    shell: process.platform === "win32",
  })

  child.on("close", (code) => {
    if (code === 0) {
      console.log("\n✅ Test completed successfully!")
    } else {
      console.log(`\n❌ Test failed with exit code ${code}`)
    }
    process.exit(code)
  })

  child.on("error", (error) => {
    console.error(`❌ Test failed to start: ${error.message}`)
    process.exit(1)
  })
}

runTest()
