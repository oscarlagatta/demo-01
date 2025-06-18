#!/usr/bin/env node

/**
 * Cross-platform Nx Lint-Staged Script
 * Prioritizes Nx lint commands over direct ESLint
 * Works on Windows, macOS, and Linux
 */

const { execSync, spawn } = require("child_process")
const fs = require("fs")
const path = require("path")
const os = require("os")

// Colors for cross-platform output
const colors = {
  reset: "\x1b[0m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
}

// Disable colors on Windows if not supported
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

printInfo(`Linting ${stagedFiles.length} staged files...`)

// Function to normalize paths for cross-platform compatibility
function normalizePath(filePath) {
  return filePath.replace(/\\/g, "/")
}

// Function to get project for a file
function getProjectForFile(filePath) {
  const normalized = normalizePath(filePath)

  const appsMatch = normalized.match(/^apps\/([^/]+)/)
  if (appsMatch) return appsMatch[1]

  const libsMatch = normalized.match(/^libs\/([^/]+)/)
  if (libsMatch) return libsMatch[1]

  return null
}

// Function to check if a project has lint target
async function projectHasLintTarget(project) {
  try {
    const result = await runCommand("nx", ["show", "project", project, "--json"])
    if (result.success) {
      const projectInfo = JSON.parse(result.stdout)
      return !!(projectInfo.targets && projectInfo.targets.lint)
    }
  } catch (error) {
    printWarning(`Could not check lint target for project '${project}': ${error.message}`)
  }
  return false
}

// Group files by project
const projectFiles = new Map()
const workspaceFiles = []

for (const file of stagedFiles) {
  if (fs.existsSync(file)) {
    const project = getProjectForFile(file)
    if (project) {
      if (!projectFiles.has(project)) {
        projectFiles.set(project, [])
      }
      projectFiles.get(project).push(file)
    } else {
      workspaceFiles.push(file)
    }
  }
}

// Function to run command with proper error handling
function runCommand(command, args, options = {}) {
  return new Promise((resolve) => {
    const isNpxCommand = command === "npx" || command === "nx"
    const actualCommand = isWindows && isNpxCommand ? `${command}.cmd` : command

    const child = spawn(actualCommand, args, {
      stdio: ["pipe", "pipe", "pipe"],
      shell: isWindows,
      ...options,
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
      resolve({
        success: code === 0,
        stdout,
        stderr,
        code,
      })
    })

    child.on("error", (error) => {
      resolve({
        success: false,
        error: error.message,
        code: 1,
      })
    })
  })
}

// Function to lint using Nx project-specific commands (PRIORITIZED)
async function lintProjectFiles(project, files) {
  printInfo(`Linting project '${project}' with ${files.length} files...`)

  // Check if project has lint target
  const hasLintTarget = await projectHasLintTarget(project)

  if (hasLintTarget) {
    // Use Nx lint command - this is preferred
    printInfo(`Using Nx lint for project '${project}'`)

    // Create file list for Nx
    const fileList = files.join(",")

    const result = await runCommand("nx", ["lint", project, "--fix", `--files=${fileList}`])

    if (result.success) {
      printSuccess(`Project '${project}' linted successfully with Nx`)
      return true
    } else {
      printWarning(`Nx lint failed for project '${project}', error: ${result.stderr}`)
      printWarning("Falling back to direct ESLint...")
      return await lintFilesDirect(files)
    }
  } else {
    printWarning(`Project '${project}' has no lint target, using direct ESLint...`)
    return await lintFilesDirect(files)
  }
}

// Function to lint files with ESLint directly (FALLBACK)
async function lintFilesDirect(files) {
  printInfo(`Running ESLint directly on ${files.length} files...`)

  try {
    // Try batch linting first
    const result = await runCommand("npx", ["eslint", "--fix", ...files])

    if (result.success) {
      printSuccess("ESLint completed successfully")
      return true
    } else {
      printWarning("Batch linting failed, trying individual files...")

      // Fallback: lint files individually
      const failedFiles = []
      for (const file of files) {
        const individualResult = await runCommand("npx", ["eslint", "--fix", file])
        if (!individualResult.success) {
          failedFiles.push(file)
          printError(`ESLint failed for ${file}: ${individualResult.stderr}`)
        }
      }

      if (failedFiles.length > 0) {
        printError(`Linting failed for files: ${failedFiles.join(", ")}`)
        return false
      } else {
        printSuccess("All files linted successfully")
        return true
      }
    }
  } catch (error) {
    printError(`ESLint execution failed: ${error.message}`)
    return false
  }
}

// Main linting logic
async function main() {
  let overallSuccess = true

  // Lint project-specific files (using Nx when possible)
  for (const [project, files] of projectFiles) {
    const success = await lintProjectFiles(project, files)
    if (!success) {
      overallSuccess = false
    }
  }

  // Lint workspace-level files
  if (workspaceFiles.length > 0) {
    printInfo(`Linting ${workspaceFiles.length} workspace-level files...`)
    const success = await lintFilesDirect(workspaceFiles)
    if (!success) {
      overallSuccess = false
    }
  }

  // Final result
  if (overallSuccess) {
    printSuccess("All staged files linted successfully!")
    process.exit(0)
  } else {
    printError("Some files failed linting. Please fix the issues and try again.")
    process.exit(1)
  }
}

// Run the main function
main().catch((error) => {
  printError(`Unexpected error: ${error.message}`)
  console.error(error.stack)
  process.exit(1)
})
