#!/usr/bin/env node

/**
 * Optimized Nx Lint-Staged Script
 * Uses Nx's affected command capabilities for efficient linting
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

printInfo(`Processing ${stagedFiles.length} staged files with Nx...`)

// Function to run command with proper cross-platform handling
function runCommand(command, args, options = {}) {
  return new Promise((resolve) => {
    // Handle Windows command extensions
    const isNxCommand = command === "nx" || command === "npx"
    const actualCommand = isWindows && isNxCommand ? `${command}.cmd` : command

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
async function isNxWorkspace() {
  try {
    const result = await runCommand("nx", ["--version"])
    return result.success
  } catch (error) {
    return false
  }
}

// Function to get affected projects for the staged files
async function getAffectedProjects(files) {
  try {
    // Create a temporary file list for Nx
    const tempFile = path.join(os.tmpdir(), `nx-files-${Date.now()}.txt`)
    fs.writeFileSync(tempFile, files.join("\n"), "utf8")

    const result = await runCommand("nx", ["show", "projects", "--affected", "--files", files.join(","), "--json"])

    // Clean up temp file
    try {
      fs.unlinkSync(tempFile)
    } catch (e) {
      // Ignore cleanup errors
    }

    if (result.success && result.stdout.trim()) {
      const projects = JSON.parse(result.stdout)
      return Array.isArray(projects) ? projects : []
    }
  } catch (error) {
    printWarning(`Could not determine affected projects: ${error.message}`)
  }
  return []
}

// Function to lint using Nx affected command
async function lintWithNxAffected(files) {
  printInfo("Using Nx affected:lint for optimal performance...")

  const fileList = files.join(",")

  const result = await runCommand("nx", [
    "affected:lint",
    "--fix",
    `--files=${fileList}`,
    "--parallel=3", // Limit parallelism for stability
    "--skip-nx-cache=false", // Use cache for better performance
  ])

  if (result.success) {
    printSuccess("Nx affected:lint completed successfully")
    return true
  } else {
    printWarning("Nx affected:lint failed, trying project-specific approach...")
    return false
  }
}

// Function to lint specific projects
async function lintAffectedProjects(projects, files) {
  printInfo(`Linting ${projects.length} affected projects...`)

  let overallSuccess = true

  for (const project of projects) {
    printInfo(`Linting project: ${project}`)

    const result = await runCommand("nx", ["lint", project, "--fix", `--files=${files.join(",")}`])

    if (!result.success) {
      printError(`Linting failed for project: ${project}`)
      overallSuccess = false
    } else {
      printSuccess(`Project ${project} linted successfully`)
    }
  }

  return overallSuccess
}

// Fallback to direct ESLint
async function fallbackToEslint(files) {
  printWarning("Falling back to direct ESLint...")

  const result = await runCommand("npx", ["eslint", "--fix", ...files])

  if (result.success) {
    printSuccess("ESLint completed successfully")
    return true
  } else {
    printError("ESLint failed")
    return false
  }
}

// Main execution function
async function main() {
  try {
    // Check if we're in an Nx workspace
    const isNx = await isNxWorkspace()

    if (!isNx) {
      printWarning("Not in an Nx workspace, falling back to ESLint...")
      const success = await fallbackToEslint(stagedFiles)
      process.exit(success ? 0 : 1)
    }

    // Try Nx affected:lint first (most efficient)
    let success = await lintWithNxAffected(stagedFiles)

    if (!success) {
      // Fallback: Get affected projects and lint them individually
      const affectedProjects = await getAffectedProjects(stagedFiles)

      if (affectedProjects.length > 0) {
        success = await lintAffectedProjects(affectedProjects, stagedFiles)
      } else {
        // Final fallback: direct ESLint
        success = await fallbackToEslint(stagedFiles)
      }
    }

    if (success) {
      printSuccess("All staged files linted successfully!")
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
