#!/usr/bin/env node

const fs = require("fs")
const path = require("path")
const { execSync } = require("child_process")

// Load configuration
const config = require("./jira-config.js")

/**
 * ANSI color codes for terminal output
 */
const colors = {
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
  white: "\x1b[37m",
  reset: "\x1b[0m",
  bold: "\x1b[1m",
}

/**
 * Utility function to colorize console output
 */
function colorize(text, color) {
  return `${colors[color]}${text}${colors.reset}`
}

/**
 * Get current Git branch name
 */
function getCurrentBranch() {
  try {
    return execSync("git branch --show-current", { encoding: "utf8" }).trim()
  } catch (error) {
    console.warn(colorize("⚠️  Could not determine current branch", "yellow"))
    return ""
  }
}

/**
 * Check if current branch is exempt from Jira ticket requirement
 */
function isBranchExempt(branch) {
  return config.validation.exemptBranches.some((exemptPattern) => {
    if (exemptPattern.endsWith("/*")) {
      const prefix = exemptPattern.slice(0, -2)
      return branch.startsWith(prefix)
    }
    return branch === exemptPattern
  })
}

/**
 * Check if commit type is exempt from Jira ticket requirement
 */
function isCommitTypeExempt(message) {
  const lowerMessage = message.toLowerCase()
  return config.validation.exemptCommitTypes.some(
    (type) => lowerMessage.startsWith(type) || lowerMessage.includes(`${type}:`),
  )
}

/**
 * Generate regex pattern for Jira ticket validation
 */
function generateJiraPattern() {
  const prefixes = config.projectPrefixes.join("|")
  const minNum = config.validation.minTicketNumber
  const maxNum = config.validation.maxTicketNumber

  // Create number range pattern
  const numberPattern = `(?:[${minNum}-9]\\d{0,${maxNum.toString().length - 1}}|[1-9]\\d{${maxNum.toString().length - 1},${maxNum.toString().length - 1}})`

  if (config.validation.allowMultipleTickets) {
    return new RegExp(`^(?:(${prefixes})-(${numberPattern})(?:\\s+|,\\s*)?)+:?\\s*(.+)`, "i")
  } else {
    return new RegExp(`^(${prefixes})-(${numberPattern}):?\\s*(.+)`, "i")
  }
}

/**
 * Validate Jira ticket number format
 */
function validateJiraTicket(message) {
  const results = {
    isValid: false,
    tickets: [],
    remainingMessage: "",
    errors: [],
  }

  // Check for exempt commit types first
  if (isCommitTypeExempt(message)) {
    results.isValid = true
    results.remainingMessage = message
    return results
  }

  const jiraPattern = generateJiraPattern()
  const match = message.match(jiraPattern)

  if (!match) {
    results.errors.push("No valid Jira ticket found at the beginning of commit message")
    return results
  }

  // Extract ticket information
  if (config.validation.allowMultipleTickets) {
    // Handle multiple tickets (more complex parsing needed)
    const ticketPattern = new RegExp(`(${config.projectPrefixes.join("|")})-(\\d+)`, "gi")
    let ticketMatch
    while ((ticketMatch = ticketPattern.exec(message)) !== null) {
      results.tickets.push({
        project: ticketMatch[1].toUpperCase(),
        number: Number.parseInt(ticketMatch[2]),
      })
    }
    results.remainingMessage = message
      .replace(ticketPattern, "")
      .replace(/^[:\s,]+/, "")
      .trim()
  } else {
    // Single ticket
    const project = match[1].toUpperCase()
    const ticketNumber = Number.parseInt(match[2])

    results.tickets.push({ project, number: ticketNumber })
    results.remainingMessage = match[3] ? match[3].trim() : ""
  }

  // Validate ticket numbers
  for (const ticket of results.tickets) {
    if (ticket.number < config.validation.minTicketNumber || ticket.number > config.validation.maxTicketNumber) {
      results.errors.push(
        `Ticket number ${ticket.number} is out of valid range (${config.validation.minTicketNumber}-${config.validation.maxTicketNumber})`,
      )
    }
  }

  // Validate remaining message length
  if (config.customRules.minMessageLength && results.remainingMessage.length < config.customRules.minMessageLength) {
    results.errors.push(
      `Commit message too short after ticket number (minimum ${config.customRules.minMessageLength} characters)`,
    )
  }

  // Validate colon requirement
  if (config.customRules.requireColonAfterTicket && !message.includes(":")) {
    results.errors.push("Commit message must include a colon (:) after the ticket number")
  }

  results.isValid = results.errors.length === 0 && results.tickets.length > 0
  return results
}

/**
 * Display validation results and error messages
 */
function displayResults(validation, commitMessage) {
  if (validation.isValid) {
    console.log(colorize("✅ Jira ticket validation passed!", "green"))

    if (validation.tickets.length > 0) {
      console.log(colorize("🎫 Found tickets:", "cyan"))
      validation.tickets.forEach((ticket) => {
        console.log(colorize(`   ${ticket.project}-${ticket.number}`, "white"))
      })
    }

    return true
  } else {
    console.log(colorize("❌ Jira ticket validation failed!", "red"))
    console.log("")

    // Display specific errors
    validation.errors.forEach((error) => {
      console.log(colorize(`   • ${error}`, "red"))
    })

    console.log("")
    console.log(colorize("📋 Required format:", "yellow"))
    console.log(colorize(`   PROJECT-#### : commit message`, "white"))
    console.log("")

    console.log(colorize("✅ Valid examples:", "green"))
    config.messages.examples.forEach((example) => {
      console.log(colorize(`   ${example}`, "white"))
    })

    console.log("")
    console.log(colorize("🔧 Valid project prefixes:", "cyan"))
    config.projectPrefixes.forEach((prefix) => {
      console.log(colorize(`   ${prefix}-####`, "white"))
    })

    console.log("")
    console.log(colorize("💡 Your commit message:", "magenta"))
    console.log(colorize(`   "${commitMessage}"`, "white"))

    return false
  }
}

/**
 * Main validation function
 */
function validateCommitMessage(commitMessageFile) {
  try {
    // Read commit message
    const commitMessage = fs.readFileSync(commitMessageFile, "utf8").trim()

    console.log(colorize("🔍 Validating Jira ticket in commit message...", "blue"))

    // Check if validation is required
    if (!config.validation.required) {
      console.log(colorize("ℹ️  Jira ticket validation is disabled", "yellow"))
      return true
    }

    // Check branch exemptions
    const currentBranch = getCurrentBranch()
    if (currentBranch && isBranchExempt(currentBranch)) {
      console.log(colorize(`ℹ️  Branch '${currentBranch}' is exempt from Jira ticket requirement`, "yellow"))
      return true
    }

    // Perform validation
    const validation = validateJiraTicket(commitMessage)
    return displayResults(validation, commitMessage)
  } catch (error) {
    console.error(colorize("❌ Error reading commit message:", "red"), error.message)
    return false
  }
}

// Export for testing
module.exports = {
  validateJiraTicket,
  validateCommitMessage,
  getCurrentBranch,
  isBranchExempt,
  isCommitTypeExempt,
}

// CLI execution
if (require.main === module) {
  const commitMessageFile = process.argv[2]

  if (!commitMessageFile) {
    console.error(colorize("❌ Usage: node validate-jira-ticket.js <commit-msg-file>", "red"))
    process.exit(1)
  }

  const isValid = validateCommitMessage(commitMessageFile)
  process.exit(isValid ? 0 : 1)
}
