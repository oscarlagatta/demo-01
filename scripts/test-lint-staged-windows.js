#!/usr/bin/env node

/**
 * Test script for Windows lint-staged functionality
 */

const { spawn } = require("child_process")
const fs = require("fs")
const path = require("path")

console.log("🧪 Testing lint-staged on Windows...")

// Create a test file
const testFile = path.join(__dirname, "..", "test-lint-file.ts")
const testContent = `
// Test file for lint-staged
export const testFunction = (value: string | null) => {
  return value || "default"; // This should trigger prefer-nullish-coalescing
};
`

fs.writeFileSync(testFile, testContent)

console.log("✅ Created test file:", testFile)

// Test the lint-staged script directly
const child = spawn("node", [path.join(__dirname, "lint-staged-nx.js"), testFile], {
  stdio: "inherit",
  shell: true,
})

child.on("close", (code) => {
  // Clean up test file
  try {
    fs.unlinkSync(testFile)
    console.log("🧹 Cleaned up test file")
  } catch (e) {
    console.warn("⚠️  Could not clean up test file:", e.message)
  }

  if (code === 0) {
    console.log("✅ Lint-staged test completed successfully!")
  } else {
    console.log("❌ Lint-staged test failed with code:", code)
  }

  process.exit(code)
})

child.on("error", (error) => {
  console.error("❌ Test failed:", error.message)
  process.exit(1)
})
