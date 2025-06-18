#!/bin/bash

echo "🎫 Setting up Jira ticket validation for Git commits"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js is required but not installed"
        exit 1
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        print_error "Git is required but not installed"
        exit 1
    fi
    
    if [ ! -d ".git" ]; then
        print_error "This must be run from the root of a Git repository"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Install Husky if not already installed
setup_husky() {
    print_info "Setting up Husky..."
    
    if ! npm list husky >/dev/null 2>&1; then
        print_info "Installing Husky..."
        npm install --save-dev husky
    fi
    
    # Initialize Husky
    if [ ! -d ".husky" ]; then
        npx husky init
    fi
    
    print_status "Husky setup complete"
}

# Create tools directory if it doesn't exist
setup_directories() {
    print_info "Setting up directory structure..."
    
    mkdir -p tools
    
    print_status "Directory structure ready"
}

# Configure Git hooks path
configure_git() {
    print_info "Configuring Git hooks..."
    
    git config core.hooksPath .husky
    
    print_status "Git configuration updated"
}

# Make commit-msg hook executable
setup_hooks() {
    print_info "Setting up commit-msg hook..."
    
    if [ -f ".husky/commit-msg" ]; then
        chmod +x .husky/commit-msg
        print_status "commit-msg hook is ready"
    else
        print_error "commit-msg hook file not found"
        print_info "Please ensure the .husky/commit-msg file exists"
        exit 1
    fi
}

# Interactive configuration
configure_jira_settings() {
    print_info "Configuring Jira settings..."
    
    if [ -f "tools/jira-config.js" ]; then
        print_warning "Jira configuration already exists"
        read -p "Do you want to reconfigure? (y/N): " reconfigure
        
        if [ "$reconfigure" != "y" ] && [ "$reconfigure" != "Y" ]; then
            print_info "Keeping existing configuration"
            return
        fi
    fi
    
    echo ""
    echo "Please provide your Jira project configuration:"
    echo ""
    
    # Get project prefixes
    read -p "Enter Jira project prefixes (comma-separated, e.g., EARS,PROJ,DEV): " prefixes
    
    if [ -z "$prefixes" ]; then
        prefixes="EARS,PROJ"
        print_warning "Using default prefixes: $prefixes"
    fi
    
    # Convert comma-separated to array format
    prefix_array=$(echo "$prefixes" | sed "s/,/','/g" | sed "s/^/'/" | sed "s/$/'/" | sed "s/','/'\n    '/g")
    
    # Create configuration file
    cat > tools/jira-config.js << EOF
/**
 * Jira Commit Message Configuration
 * Generated on $(date)
 */

module.exports = {
  projectPrefixes: [
    $prefix_array
  ],

  validation: {
    minTicketNumber: 1,
    maxTicketNumber: 99999,
    allowMultipleTickets: false,
    required: true,
    exemptBranches: [
      'main',
      'master',
      'develop',
      'release/*',
      'hotfix/*'
    ],
    exemptCommitTypes: [
      'merge',
      'revert',
      'initial'
    ]
  },

  customRules: {
    enforceUppercase: true,
    allowAnyPosition: false,
    requireColonAfterTicket: true,
    minMessageLength: 10
  },

  messages: {
    missing: 'Commit message must start with a Jira ticket number',
    invalid: 'Invalid Jira ticket format',
    tooShort: 'Commit message too short after ticket number',
    examples: [
      '${prefixes%%,*}-1887: fix user authentication bug',
      '${prefixes%%,*}-123: add new dashboard component',
      '${prefixes%%,*}-456: update API documentation'
    ]
  }
};
EOF
    
    print_status "Jira configuration created"
}

# Test the setup
test_setup() {
    print_info "Testing Jira validation setup..."
    
    # Test with valid message
    echo "EARS-1234: test commit message" > /tmp/test-commit-msg
    
    if node tools/validate-jira-ticket.js /tmp/test-commit-msg >/dev/null 2>&1; then
        print_status "Validation script is working correctly"
    else
        print_error "Validation script test failed"
        print_info "Please check the configuration and try again"
    fi
    
    # Clean up
    rm -f /tmp/test-commit-msg
}

# Display usage instructions
show_instructions() {
    echo ""
    echo "🎉 Jira ticket validation setup complete!"
    echo ""
    echo "📋 Usage Instructions:"
    echo "====================="
    echo ""
    echo "✅ Valid commit message formats:"
    echo "   EARS-1887: fix user login bug"
    echo "   PROJ-123: add new feature"
    echo "   DEV-456: update documentation"
    echo ""
    echo "❌ Invalid formats:"
    echo "   fix user login bug (missing ticket)"
    echo "   ears-123: message (lowercase project)"
    echo "   EARS-0: message (invalid ticket number)"
    echo ""
    echo "🔧 Bypass validation (use sparingly):"
    echo "   git commit --no-verify -m 'emergency fix'"
    echo ""
    echo "⚙️  Customize settings:"
    echo "   Edit tools/jira-config.js"
    echo ""
    echo "🧪 Test your setup:"
    echo "   echo 'test' > test.txt"
    echo "   git add test.txt"
    echo "   git commit -m 'EARS-1234: test commit'"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    setup_directories
    setup_husky
    configure_git
    setup_hooks
    configure_jira_settings
    test_setup
    show_instructions
}

# Run main function
main
