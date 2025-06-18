#!/usr/bin/env node

/**
 * Nx Monorepo Lint-Staged Script - Optimized Version
 * Fast, targeted linting for Nx workspaces with proper project detection
 * Cross-platform compatible (Windows, macOS, Linux)
 */

const { spawn, execSync } = require("child_process")
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

// Libraries to exclude from linting
const EXCLUDED_LIBRARIES = ["ui-kit"]

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

// Filter out files from excluded libraries and non-lintable files
function filterLintableFiles(files) {
  return files.filter((file) => {
    // Normalize path to handle Windows backslashes
    const normalizedPath = file.replace(/\\/g, "/")

    // Check if file is in any excluded library
    const isExcluded = EXCLUDED_LIBRARIES.some(
      (lib) => normalizedPath.includes(`/libs/${lib}/`) || normalizedPath.includes(`\\libs\\${lib}\\`),
    )

    if (isExcluded) {
      printInfo(`Excluding file from ${EXCLUDED_LIBRARIES.find((lib) => normalizedPath.includes(lib))}: ${file}`)
      return false
    }

    // Only include TypeScript/JavaScript files
    const isLintableFile = /\.(ts|tsx|js|jsx)$/.test(file)

    // Check if file exists (might have been deleted)
    const fileExists = fs.existsSync(file)

    return isLintableFile && fileExists
  })
}

const filteredFiles = filterLintableFiles(stagedFiles)

if (filteredFiles.length === 0) {
  printSuccess("No lintable files found or all files are excluded. Skipping lint.")
  process.exit(0)
}

printInfo(
  `Processing ${filteredFiles.length} lintable files (${stagedFiles.length - filteredFiles.length} files excluded/filtered)...`,
)

// Function to run command synchronously for better control
function runCommandSync(command, args, options = {}) {
  try {
    const actualCommand = isWindows && command === "nx" ? "nx.cmd" : command
    const fullCommand = `${actualCommand} ${args.join(" ")}`

    printInfo(`Running: ${fullCommand}`)

    const result = execSync(fullCommand, {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
      shell: true,
      env: { ...process.env, FORCE_COLOR: "1" },
      maxBuffer: 1024 * 1024 * 10, // 10MB buffer
      ...options,
    })

    return {
      success: true,
      stdout: result,
      stderr: "",
    }
  } catch (error) {
    return {
      success: false,
      stdout: error.stdout || "",
      stderr: error.stderr || error.message,
      code: error.status || 1,
    }
  }
}

// Function to get project from file path
function getProjectFromFilePath(filePath) {
  const normalizedPath = filePath.replace(/\\/g, "/")

  // Match patterns like apps/my-app/... or libs/my-lib/...
  const appMatch = normalizedPath.match(/^apps\/([^/]+)/)
  if (appMatch) {
    return { type: "app", name: appMatch[1] }
  }

  const libMatch = normalizedPath.match(/^libs\/([^/]+)/)
  if (libMatch) {
    return { type: "lib", name: libMatch[1] }
  }

  // Root level files
  return { type: "root", name: null }
}

// Function to get affected projects from file paths
function getAffectedProjectsFromFiles(files) {
  const projects = new Set()

  for (const file of files) {
    const project = getProjectFromFilePath(file)
    if (project.name && !EXCLUDED_LIBRARIES.includes(project.name)) {
      projects.add(project.name)
    }
  }

  return Array.from(projects)
}

// Function to check if project has lint target
function projectHasLintTarget(projectName) {
  try {
    const result = runCommandSync("nx", ["show", "project", projectName, "--json"])
    if (result.success) {
      const projectConfig = JSON.parse(result.stdout)
      return projectConfig.targets && projectConfig.targets.lint
    }
  } catch (error) {
    printWarning(`Could not check lint target for project ${projectName}: ${error.message}`)
  }
  return false
}

// Function to lint specific files with ESLint directly (fastest for small sets)
async function lintFilesDirectly(files) {
  if (files.length === 0) return true

  printInfo(`Linting ${files.length} files directly with ESLint...`)

  return new Promise((resolve) => {
    const actualCommand = isWindows ? "npx.cmd" : "npx"

    const child = spawn(actualCommand, ["eslint", "--fix", ...files], {
      stdio: ["pipe", "pipe", "pipe"],
      shell: isWindows,
      env: { ...process.env, FORCE_COLOR: "1" },
    })

    let stdout = ""
    let stderr = ""

    child.stdout?.on("data", (data) => {
      const output = data.toString()
      stdout += output
      process.stdout.write(output)
    })

    child.stderr?.on("data", (data) => {
      const output = data.toString()
      stderr += output
      // Only show actual errors, not warnings
      if (output.includes("error") && !output.includes("warning")) {
        process.stderr.write(output)
      }
    })

    child.on("close", (code) => {
      if (code === 0) {
        printSuccess("Direct ESLint completed successfully")
        resolve(true)
      } else {
        printError("Direct ESLint failed")
        resolve(false)
      }
    })

    child.on("error", (error) => {
      printError(`ESLint command failed: ${error.message}`)
      resolve(false)
    })
  })
}

// Function to lint specific projects
async function lintSpecificProjects(projects, files) {
  if (projects.length === 0) {
    return await lintFilesDirectly(files)
  }

  printInfo(`Linting ${projects.length} specific projects: ${projects.join(", ")}`)

  let overallSuccess = true

  for (const project of projects) {
    if (!projectHasLintTarget(project)) {
      printWarning(`Project ${project} has no lint target, skipping...`)
      continue
    }

    printInfo(`Linting project: ${project}`)

    // Get files that belong to this project
    const projectFiles = files.filter((file) => {
      const projectInfo = getProjectFromFilePath(file)
      return projectInfo.name === project
    })

    if (projectFiles.length === 0) {
      printInfo(`No files to lint for project ${project}`)
      continue
    }

    const result = runCommandSync("nx", ["lint", project, "--fix"])

    if (!result.success) {
      printError(`Linting failed for project: ${project}`)
      printError(result.stderr)
      overallSuccess = false
    } else {
      printSuccess(`Project ${project} linted successfully`)
    }
  }

  return overallSuccess
}

// Main execution function
async function main() {
  try {
    // Check if we're in an Nx workspace
    if (!fs.existsSync("nx.json")) {
      printWarning("Not in an Nx workspace, falling back to direct ESLint...")
      const success = await lintFilesDirectly(filteredFiles)
      process.exit(success ? 0 : 1)
    }

    // Get affected projects from file paths (much faster than nx affected)
    const affectedProjects = getAffectedProjectsFromFiles(filteredFiles)

    if (affectedProjects.length === 0) {
      printInfo("No specific projects affected, linting files directly...")
      const success = await lintFilesDirectly(filteredFiles)
      process.exit(success ? 0 : 1)
    }

    printInfo(`Detected affected projects: ${affectedProjects.join(", ")}`)

    // Lint the specific affected projects
    const success = await lintSpecificProjects(affectedProjects, filteredFiles)

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
