#!/usr/bin/env node

/**
 * Debug script to trace lint-staged execution
 * Shows exactly what commands are being run
 */

const { execSync } = require("child_process")
const fs = require("fs")

console.log("🔍 Debugging lint-staged configuration...\n")

// 1. Check if lint-staged is installed
try {
  const version = execSync("npx lint-staged --version", { encoding: "utf8" }).trim()
  console.log(`✅ lint-staged version: ${version}`)
} catch (error) {
  console.log("❌ lint-staged not found or not working")
  process.exit(1)
}

// 2. Check package.json configuration
const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"))
console.log("\n📋 lint-staged configuration:")
console.log(JSON.stringify(packageJson["lint-staged"], null, 2))

// 3. Check if nx-lint-staged.js exists
const scriptPath = "./scripts/nx-lint-staged.js"
if (fs.existsSync(scriptPath)) {
  console.log(`\n✅ Script exists: ${scriptPath}`)
} else {
  console.log(`\n❌ Script missing: ${scriptPath}`)
}

// 4. Check git status
try {
  const gitStatus = execSync("git status --porcelain", { encoding: "utf8" })
  if (gitStatus.trim()) {
    console.log("\n📁 Current git status:")
    console.log(gitStatus)
  } else {
    console.log("\n📁 No staged or modified files")
  }
} catch (error) {
  console.log("\n❌ Not in a git repository")
}

// 5. Run lint-staged in dry-run mode
console.log("\n🧪 Running lint-staged dry-run...")
try {
  const dryRun = execSync("npx lint-staged --dry-run", { encoding: "utf8" })
  console.log(dryRun)
} catch (error) {
  console.log("❌ Dry-run failed:")
  console.log(error.message)
}

console.log("\n" + "=".repeat(60))
console.log("💡 To test manually:")
console.log("1. npm run lint:staged:test")
console.log("2. npm run lint:staged:test-file app/page.tsx")
console.log("3. npm run lint:staged:verbose")
console.log("=".repeat(60))
