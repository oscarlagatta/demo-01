#!/usr/bin/env node

/**
 * Nx Monorepo Lint-Staged Script
 * Optimized for Nx workspaces with proper project detection and affected linting
 * Cross-platform compatible (Windows, macOS, Linux)
 */

const { spawn } = require("child_process")
const fs = require("fs")
const path = require("path")
const os = require("os")

// Cross-platform colors
const colors = {
  reset: "\x1b[0m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
}

const isWindows = os.platform() === "win32"
const supportsColor = process.env.FORCE_COLOR || !isWindows || process.env.ConEmuANSI === "ON"

function colorize(color, text) {
  if (!supportsColor) return text
  return `${colors[color]}${text}${colors.reset}`
}

function printInfo(message) {
  console.log(colorize("blue", `ℹ️  ${message}`))
}

function printSuccess(message) {
  console.log(colorize("green", `✅ ${message}`))
}

function printWarning(message) {
  console.log(colorize("yellow", `⚠️  ${message}`))
}

function printError(message) {
  console.log(colorize("red", `❌ ${message}`))
}

// Get staged files from command line arguments
const stagedFiles = process.argv.slice(2)

if (stagedFiles.length === 0) {
  printWarning("No files provided to lint")
  process.exit(0)
}

printInfo(`Processing ${stagedFiles.length} staged files in Nx monorepo...`)

// Function to run command with proper cross-platform handling
function runCommand(command, args, options = {}) {
  return new Promise((resolve) => {
    // Handle Windows command extensions
    const actualCommand = isWindows && command === "nx" ? "nx.cmd" : command

    printInfo(`Running: ${actualCommand} ${args.join(" ")}`)

    const child = spawn(actualCommand, args, {
      stdio: ["pipe", "pipe", "pipe"],
      shell: isWindows,
      env: { ...process.env, FORCE_COLOR: "1" },
      ...options,
    })

    let stdout = ""
    let stderr = ""

    child.stdout?.on("data", (data) => {
      const output = data.toString()
      stdout += output
      // Stream output in real-time for better UX
      process.stdout.write(output)
    })

    child.stderr?.on("data", (data) => {
      const output = data.toString()
      stderr += output
      // Only show stderr if it's not just warnings
      if (!output.includes("warning") && !output.includes("deprecated")) {
        process.stderr.write(output)
      }
    })

    child.on("close", (code) => {
      resolve({
        success: code === 0,
        stdout,
        stderr,
        code,
      })
    })

    child.on("error", (error) => {
      printError(`Command failed to start: ${error.message}`)
      resolve({
        success: false,
        error: error.message,
        code: 1,
      })
    })
  })
}

// Function to check if we're in an Nx workspace
async function validateNxWorkspace() {
  try {
    // Check for nx.json
    if (!fs.existsSync("nx.json")) {
      printError("nx.json not found - not in an Nx workspace")
      return false
    }

    // Check nx command
    const result = await runCommand("nx", ["--version"])
    if (result.success) {
      printSuccess("Nx workspace validated")
      return true
    } else {
      printError("Nx command not available")
      return false
    }
  } catch (error) {
    printError(`Nx validation failed: ${error.message}`)
    return false
  }
}

// Function to get affected projects for the staged files
async function getAffectedProjects(files) {
  try {
    printInfo("Detecting affected projects...")

    // Use nx show projects --affected with files
    const fileList = files.join(",")
    const result = await runCommand("nx", ["show", "projects", "--affected", "--files", fileList])

    if (result.success && result.stdout.trim()) {
      const projects = result.stdout
        .trim()
        .split("\n")
        .filter((p) => p.trim())
      printInfo(`Found ${projects.length} affected projects: ${projects.join(", ")}`)
      return projects
    } else {
      printWarning("Could not determine affected projects, will use affected:lint")
      return []
    }
  } catch (error) {
    printWarning(`Could not determine affected projects: ${error.message}`)
    return []
  }
}

// Function to get projects with lint targets
async function getProjectsWithLintTargets() {
  try {
    const result = await runCommand("nx", ["show", "projects", "--with-target=lint"])

    if (result.success && result.stdout.trim()) {
      const projects = result.stdout
        .trim()
        .split("\n")
        .filter((p) => p.trim())
      printInfo(`Found ${projects.length} projects with lint targets`)
      return projects
    }
    return []
  } catch (error) {
    printWarning(`Could not get projects with lint targets: ${error.message}`)
    return []
  }
}

// Function to lint using Nx affected command (most efficient)
async function lintWithNxAffected(files) {
  printInfo("Using nx affected:lint for optimal performance...")

  const fileList = files.join(",")

  const result = await runCommand("nx", [
    "affected",
    "--target=lint",
    "--fix",
    `--files=${fileList}`,
    "--parallel=3", // Limit parallelism for stability
  ])

  if (result.success) {
    printSuccess("nx affected:lint completed successfully")
    return true
  } else {
    printWarning("nx affected:lint failed, trying individual project approach...")
    return false
  }
}

// Function to lint specific projects individually
async function lintAffectedProjects(projects, files) {
  if (projects.length === 0) {
    printWarning("No affected projects found")
    return true
  }

  printInfo(`Linting ${projects.length} affected projects individually...`)

  let overallSuccess = true
  const fileList = files.join(",")

  for (const project of projects) {
    printInfo(`Linting project: ${project}`)

    const result = await runCommand("nx", ["lint", project, "--fix", `--files=${fileList}`])

    if (!result.success) {
      printError(`Linting failed for project: ${project}`)
      overallSuccess = false
    } else {
      printSuccess(`Project ${project} linted successfully`)
    }
  }

  return overallSuccess
}

// Fallback to workspace-wide linting
async function fallbackToWorkspaceLint() {
  printWarning("Falling back to workspace-wide linting...")

  const result = await runCommand("nx", ["run-many", "--target=lint", "--all", "--fix"])

  if (result.success) {
    printSuccess("Workspace linting completed successfully")
    return true
  } else {
    printError("Workspace linting failed")
    return false
  }
}

// Main execution function
async function main() {
  try {
    // Validate Nx workspace
    const isValidNx = await validateNxWorkspace()
    if (!isValidNx) {
      printError("Not a valid Nx workspace. Please run this from the workspace root.")
      process.exit(1)
    }

    // Strategy 1: Try nx affected:lint (most efficient)
    let success = await lintWithNxAffected(stagedFiles)

    if (!success) {
      // Strategy 2: Get affected projects and lint them individually
      const affectedProjects = await getAffectedProjects(stagedFiles)
      const projectsWithLint = await getProjectsWithLintTargets()

      // Filter affected projects to only those with lint targets
      const lintableAffectedProjects = affectedProjects.filter((p) => projectsWithLint.includes(p))

      if (lintableAffectedProjects.length > 0) {
        success = await lintAffectedProjects(lintableAffectedProjects, stagedFiles)
      } else {
        // Strategy 3: Fallback to workspace-wide linting
        success = await fallbackToWorkspaceLint()
      }
    }

    if (success) {
      printSuccess("All staged files linted successfully in Nx monorepo!")
      process.exit(0)
    } else {
      printError("Linting failed. Please fix the issues and try again.")
      process.exit(1)
    }
  } catch (error) {
    printError(`Unexpected error: ${error.message}`)
    console.error(error.stack)
    process.exit(1)
  }
}

// Handle process termination gracefully
process.on("SIGINT", () => {
  printWarning("Linting interrupted by user")
  process.exit(1)
})

process.on("SIGTERM", () => {
  printWarning("Linting terminated")
  process.exit(1)
})

// Run the main function
main()
