#!/usr/bin/env node

/**
 * Validation script for Nx lint-staged configuration
 * Tests different scenarios and validates the setup
 */

const { spawn } = require("child_process")
const fs = require("fs")
const path = require("path")

async function runCommand(command, args) {
  return new Promise((resolve) => {
    const child = spawn(command, args, {
      stdio: "pipe",
      shell: true,
    })

    let stdout = ""
    let stderr = ""

    child.stdout?.on("data", (data) => {
      stdout += data.toString()
    })

    child.stderr?.on("data", (data) => {
      stderr += data.toString()
    })

    child.on("close", (code) => {
      resolve({ success: code === 0, stdout, stderr, code })
    })
  })
}

async function validateNxWorkspace() {
  console.log("🔍 Validating Nx workspace...")

  const result = await runCommand("nx", ["--version"])
  if (result.success) {
    console.log("✅ Nx workspace detected")
    console.log(`   Version: ${result.stdout.trim()}`)
    return true
  } else {
    console.log("❌ Nx workspace not found")
    return false
  }
}

async function validateLintTargets() {
  console.log("🔍 Checking lint targets...")

  const result = await runCommand("nx", ["show", "projects", "--with-target=lint", "--json"])
  if (result.success) {
    const projects = JSON.parse(result.stdout)
    console.log(`✅ Found ${projects.length} projects with lint targets`)
    console.log(`   Projects: ${projects.slice(0, 5).join(", ")}${projects.length > 5 ? "..." : ""}`)
    return projects
  } else {
    console.log("❌ Could not retrieve lint targets")
    return []
  }
}

async function testAffectedCommand() {
  console.log("🔍 Testing affected:lint command...")

  const result = await runCommand("nx", ["affected:lint", "--dry-run"])
  if (result.success) {
    console.log("✅ affected:lint command works")
    return true
  } else {
    console.log("⚠️  affected:lint may have issues")
    console.log(`   Error: ${result.stderr}`)
    return false
  }
}

async function validateLintStagedConfig() {
  console.log("🔍 Validating lint-staged configuration...")

  try {
    const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"))
    const lintStaged = packageJson["lint-staged"]

    if (lintStaged) {
      console.log("✅ lint-staged configuration found")
      console.log("   Configuration:")
      Object.entries(lintStaged).forEach(([pattern, commands]) => {
        console.log(`     ${pattern}: ${Array.isArray(commands) ? commands.join(", ") : commands}`)
      })
      return true
    } else {
      console.log("❌ lint-staged configuration not found")
      return false
    }
  } catch (error) {
    console.log(`❌ Error reading package.json: ${error.message}`)
    return false
  }
}

async function main() {
  console.log("🚀 Validating Nx lint-staged setup...\n")

  const checks = [validateNxWorkspace, validateLintTargets, testAffectedCommand, validateLintStagedConfig]

  let allPassed = true

  for (const check of checks) {
    const result = await check()
    if (!result) allPassed = false
    console.log("")
  }

  if (allPassed) {
    console.log("🎉 All validations passed! Your Nx lint-staged setup is ready.")
  } else {
    console.log("⚠️  Some validations failed. Please review the issues above.")
  }

  console.log("\n📋 Recommended next steps:")
  console.log("   1. Test with: npm run lint:staged:debug")
  console.log("   2. Stage some files and commit to test the full workflow")
  console.log("   3. Monitor performance with multiple files")
}

main().catch(console.error)
