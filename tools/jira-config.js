/**
 * Jira Commit Message Configuration
 *
 * This file contains all configuration options for Jira ticket validation
 * in commit messages. Modify these settings to match your project requirements.
 */

module.exports = {
  // Project prefixes - add all valid Jira project keys
  projectPrefixes: [
    "EARS", // Example: EARS-1887
    "PROJ", // Example: PROJ-123
    "DEV", // Example: DEV-456
    "BUG", // Example: BUG-789
    // Add more project prefixes as needed
  ],

  // Validation settings
  validation: {
    // Minimum ticket number (e.g., 1 for PROJ-1)
    minTicketNumber: 1,

    // Maximum ticket number (e.g., 99999 for PROJ-99999)
    maxTicketNumber: 99999,

    // Whether to allow multiple ticket numbers (e.g., "EARS-123 PROJ-456: message")
    allowMultipleTickets: false,

    // Whether ticket number is required for all commits
    required: true,

    // Branches where Jira tickets are NOT required (e.g., hotfix branches)
    exemptBranches: ["main", "master", "develop", "release/*", "hotfix/*"],

    // Commit types that don't require Jira tickets
    exemptCommitTypes: ["merge", "revert", "initial"],
  },

  // Custom validation rules
  customRules: {
    // Enforce uppercase project prefix
    enforceUppercase: true,

    // Allow ticket number at any position (not just beginning)
    allowAnyPosition: false,

    // Require specific format after ticket number
    requireColonAfterTicket: true,

    // Minimum commit message length after ticket number
    minMessageLength: 10,
  },

  // Error messages
  messages: {
    missing: "Commit message must start with a Jira ticket number",
    invalid: "Invalid Jira ticket format",
    tooShort: "Commit message too short after ticket number",
    examples: [
      "EARS-1887: fix user authentication bug",
      "PROJ-123: add new dashboard component",
      "DEV-456: update API documentation",
    ],
  },
}
