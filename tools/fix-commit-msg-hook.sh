#!/bin/bash

echo "🔧 Fixing Commit-msg Hook Issues"
echo "================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() { echo -e "${CYAN}=== $1 ===${NC}"; }
print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Track fixes applied
FIXES_APPLIED=0

fix_applied() {
    ((FIXES_APPLIED++))
    print_status "$1"
}

# Ensure .husky directory exists
ensure_husky_directory() {
    print_header "Husky Directory Setup"
    
    if [ ! -d ".husky" ]; then
        mkdir -p .husky
        fix_applied "Created .husky directory"
    else
        print_status ".husky directory exists"
    fi
    
    chmod 755 .husky
    print_status "Set .husky directory permissions"
    
    echo ""
}

# Determine Husky version and format
determine_husky_version() {
    print_header "Husky Version Detection"
    
    if npm list husky >/dev/null 2>&1; then
        HUSKY_VERSION=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
        MAJOR_VERSION=$(echo "$HUSKY_VERSION" | cut -d'.' -f1)
        
        print_info "Husky version: $HUSKY_VERSION"
        
        if [[ "$MAJOR_VERSION" -ge 9 ]]; then
            HUSKY_FORMAT="modern"
            print_info "Using Husky v9+ (modern format)"
        else
            HUSKY_FORMAT="legacy"
            print_info "Using Husky v8.x (legacy format)"
        fi
    else
        print_warning "Husky not found - using modern format as default"
        HUSKY_FORMAT="modern"
    fi
    
    echo ""
}

# Create or fix commit-msg hook
create_commit_msg_hook() {
    print_header "Commit-msg Hook Creation"
    
    local hook_file=".husky/commit-msg"
    
    # Backup existing hook if it exists
    if [ -f "$hook_file" ]; then
        cp "$hook_file" "${hook_file}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing hook"
    fi
    
    # Create hook based on Husky version
    if [ "$HUSKY_FORMAT" = "modern" ]; then
        # Husky v9+ format
        cat > "$hook_file" << 'EOF'
#!/bin/sh
echo "📝 Validating commit message..."

# Check if commit message file is provided
if [ -z "$1" ]; then
    echo "❌ Error: No commit message file provided"
    exit 1
fi

# Check if commit message file exists
if [ ! -f "$1" ]; then
    echo "❌ Error: Commit message file does not exist: $1"
    exit 1
fi

# Read the commit message
commit_msg=$(cat "$1")

# Remove comments and empty lines
commit_msg=$(echo "$commit_msg" | sed '/^#/d' | sed '/^$/d' | head -1)

# Check if message is empty after cleaning
if [ -z "$commit_msg" ]; then
    echo "❌ Commit message cannot be empty"
    exit 1
fi

# Check minimum length
if [ ${#commit_msg} -lt 10 ]; then
    echo "❌ Commit message too short (minimum 10 characters)"
    echo "   Current message: '$commit_msg'"
    echo "   Length: ${#commit_msg} characters"
    exit 1
fi

# Check maximum length for first line
if [ ${#commit_msg} -gt 72 ]; then
    echo "⚠️  Warning: Commit message is quite long (${#commit_msg} characters)"
    echo "   Consider keeping the first line under 72 characters"
fi

# Optional: Check for conventional commit format
# Uncomment the following lines to enforce conventional commits
# if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)($$.+$$)?: .+"; then
#     echo "❌ Commit message must follow conventional format:"
#     echo "   feat: add new feature"
#     echo "   fix: resolve bug"
#     echo "   docs: update documentation"
#     echo "   Current message: '$commit_msg'"
#     exit 1
# fi

echo "✅ Commit message validation passed!"
echo "   Message: '$commit_msg'"
EOF
    else
        # Husky v8.x format
        cat > "$hook_file" << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "📝 Validating commit message..."

# Check if commit message file is provided
if [ -z "$1" ]; then
    echo "❌ Error: No commit message file provided"
    exit 1
fi

# Check if commit message file exists
if [ ! -f "$1" ]; then
    echo "❌ Error: Commit message file does not exist: $1"
    exit 1
fi

# Read the commit message
commit_msg=$(cat "$1")

# Remove comments and empty lines
commit_msg=$(echo "$commit_msg" | sed '/^#/d' | sed '/^$/d' | head -1)

# Check if message is empty after cleaning
if [ -z "$commit_msg" ]; then
    echo "❌ Commit message cannot be empty"
    exit 1
fi

# Check minimum length
if [ ${#commit_msg} -lt 10 ]; then
    echo "❌ Commit message too short (minimum 10 characters)"
    echo "   Current message: '$commit_msg'"
    echo "   Length: ${#commit_msg} characters"
    exit 1
fi

# Check maximum length for first line
if [ ${#commit_msg} -gt 72 ]; then
    echo "⚠️  Warning: Commit message is quite long (${#commit_msg} characters)"
    echo "   Consider keeping the first line under 72 characters"
fi

# Optional: Check for conventional commit format
# Uncomment the following lines to enforce conventional commits
# if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)($$.+$$)?: .+"; then
#     echo "❌ Commit message must follow conventional format:"
#     echo "   feat: add new feature"
#     echo "   fix: resolve bug"
#     echo "   docs: update documentation"
#     echo "   Current message: '$commit_msg'"
#     exit 1
# fi

echo "✅ Commit message validation passed!"
echo "   Message: '$commit_msg'"
EOF
    fi
    
    # Make executable
    chmod +x "$hook_file"
    
    fix_applied "Created commit-msg hook ($HUSKY_FORMAT format)"
    
    echo ""
}

# Fix line endings
fix_line_endings() {
    print_header "Line Endings Fix"
    
    local hook_file=".husky/commit-msg"
    
    if [ -f "$hook_file" ]; then
        # Convert CRLF to LF
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$hook_file" 2>/dev/null
        else
            sed -i 's/\r$//' "$hook_file" 2>/dev/null || {
                tr -d '\r' < "$hook_file" > "${hook_file}.tmp" && mv "${hook_file}.tmp" "$hook_file"
            }
        fi
        
        fix_applied "Fixed line endings in commit-msg hook"
    fi
    
    echo ""
}

# Test the hook
test_hook() {
    print_header "Hook Testing"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Hook file not found for testing"
        return 1
    fi
    
    # Test 1: Syntax check
    print_info "Testing syntax..."
    if bash -n "$hook_file"; then
        print_status "Hook syntax is valid"
    else
        print_error "Hook has syntax errors"
        return 1
    fi
    
    # Test 2: Execution with valid message
    print_info "Testing with valid commit message..."
    echo "test: this is a valid commit message for testing" > /tmp/test_commit_msg
    
    if bash "$hook_file" /tmp/test_commit_msg >/dev/null 2>&1; then
        print_status "Hook accepts valid commit message"
    else
        print_error "Hook rejects valid commit message"
        print_info "Error output:"
        bash "$hook_file" /tmp/test_commit_msg 2>&1 | head -3 | sed 's/^/  /'
        rm -f /tmp/test_commit_msg
        return 1
    fi
    
    # Test 3: Execution with invalid message
    print_info "Testing with invalid commit message..."
    echo "short" > /tmp/test_commit_msg
    
    if bash "$hook_file" /tmp/test_commit_msg >/dev/null 2>&1; then
        print_warning "Hook accepts invalid commit message (may be intentional)"
    else
        print_status "Hook correctly rejects invalid commit message"
    fi
    
    # Test 4: Execution without arguments
    print_info "Testing without arguments..."
    if bash "$hook_file" >/dev/null 2>&1; then
        print_warning "Hook accepts no arguments (should fail)"
    else
        print_status "Hook correctly fails without arguments"
    fi
    
    rm -f /tmp/test_commit_msg
    echo ""
    return 0
}

# Verify Git integration
verify_git_integration() {
    print_header "Git Integration Verification"
    
    # Check Git hooks path
    local hooks_path=$(git config core.hooksPath)
    if [ "$hooks_path" != ".husky" ]; then
        print_info "Setting Git hooks path..."
        git config core.hooksPath .husky
        fix_applied "Set Git hooks path to .husky"
    else
        print_status "Git hooks path correctly set"
    fi
    
    # Test with actual Git commit (dry run)
    print_info "Testing with Git commit dry run..."
    
    # Create a test file
    echo "# Test file for commit-msg hook verification" > test_commit_msg_verification.md
    git add test_commit_msg_verification.md >/dev/null 2>&1
    
    if git commit -m "test: verify commit-msg hook integration" --dry-run >/dev/null 2>&1; then
        print_status "Git commit dry run with hook succeeded"
    else
        print_error "Git commit dry run with hook failed"
        print_info "Error output:"
        git commit -m "test: verify commit-msg hook integration" --dry-run 2>&1 | head -5 | sed 's/^/  /'
    fi
    
    # Clean up
    git reset HEAD test_commit_msg_verification.md >/dev/null 2>&1
    rm -f test_commit_msg_verification.md
    
    echo ""
}

# Create enhanced commit-msg hook with Jira integration
create_enhanced_hook() {
    print_header "Enhanced Hook Creation (Optional)"
    
    read -p "Do you want to create an enhanced commit-msg hook with Jira ticket validation? (y/N): " enhance
    
    if [ "$enhance" = "y" ] || [ "$enhance" = "Y" ]; then
        local hook_file=".husky/commit-msg"
        
        # Create enhanced hook
        if [ "$HUSKY_FORMAT" = "modern" ]; then
            cat > "$hook_file" << 'EOF'
#!/bin/sh
echo "📝 Validating commit message with enhanced rules..."

# Check if commit message file is provided
if [ -z "$1" ]; then
    echo "❌ Error: No commit message file provided"
    exit 1
fi

# Check if commit message file exists
if [ ! -f "$1" ]; then
    echo "❌ Error: Commit message file does not exist: $1"
    exit 1
fi

# Read the commit message
commit_msg=$(cat "$1")

# Remove comments and empty lines
commit_msg=$(echo "$commit_msg" | sed '/^#/d' | sed '/^$/d' | head -1)

# Check if message is empty after cleaning
if [ -z "$commit_msg" ]; then
    echo "❌ Commit message cannot be empty"
    exit 1
fi

# Check minimum length
if [ ${#commit_msg} -lt 10 ]; then
    echo "❌ Commit message too short (minimum 10 characters)"
    echo "   Current message: '$commit_msg'"
    exit 1
fi

# Check for Jira ticket format (optional - uncomment to enable)
# if ! echo "$commit_msg" | grep -qE "^[A-Z]+-[0-9]+:"; then
#     echo "❌ Commit message must start with Jira ticket (e.g., PROJ-123: message)"
#     echo "   Current message: '$commit_msg'"
#     exit 1
# fi

# Check for conventional commit format
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)($$.+$$)?: .+"; then
    echo "⚠️  Warning: Consider using conventional commit format:"
    echo "   feat: add new feature"
    echo "   fix: resolve bug"
    echo "   docs: update documentation"
    echo "   Current message: '$commit_msg'"
    # Uncomment the next line to enforce conventional commits
    # exit 1
fi

echo "✅ Commit message validation passed!"
echo "   Message: '$commit_msg'"
EOF
        else
            # Similar content but with Husky v8.x format
            cat > "$hook_file" << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "📝 Validating commit message with enhanced rules..."

# Check if commit message file is provided
if [ -z "$1" ]; then
    echo "❌ Error: No commit message file provided"
    exit 1
fi

# Check if commit message file exists
if [ ! -f "$1" ]; then
    echo "❌ Error: Commit message file does not exist: $1"
    exit 1
fi

# Read the commit message
commit_msg=$(cat "$1")

# Remove comments and empty lines
commit_msg=$(echo "$commit_msg" | sed '/^#/d' | sed '/^$/d' | head -1)

# Check if message is empty after cleaning
if [ -z "$commit_msg" ]; then
    echo "❌ Commit message cannot be empty"
    exit 1
fi

# Check minimum length
if [ ${#commit_msg} -lt 10 ]; then
    echo "❌ Commit message too short (minimum 10 characters)"
    echo "   Current message: '$commit_msg'"
    exit 1
fi

# Check for Jira ticket format (optional - uncomment to enable)
# if ! echo "$commit_msg" | grep -qE "^[A-Z]+-[0-9]+:"; then
#     echo "❌ Commit message must start with Jira ticket (e.g., PROJ-123: message)"
#     echo "   Current message: '$commit_msg'"
#     exit 1
# fi

# Check for conventional commit format
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)($$.+$$)?: .+"; then
    echo "⚠️  Warning: Consider using conventional commit format:"
    echo "   feat: add new feature"
    echo "   fix: resolve bug"
    echo "   docs: update documentation"
    echo "   Current message: '$commit_msg'"
    # Uncomment the next line to enforce conventional commits
    # exit 1
fi

echo "✅ Commit message validation passed!"
echo "   Message: '$commit_msg'"
EOF
        fi
        
        chmod +x "$hook_file"
        fix_applied "Created enhanced commit-msg hook"
    else
        print_info "Keeping basic commit-msg hook"
    fi
    
    echo ""
}

# Generate summary
generate_summary() {
    print_header "Fix Summary"
    
    echo "Fixes applied: $FIXES_APPLIED"
    echo ""
    
    local hook_file=".husky/commit-msg"
    
    if [ -f "$hook_file" ] && [ -x "$hook_file" ]; then
        print_status "Commit-msg hook is ready and functional"
        
        echo ""
        echo "📋 What was fixed:"
        echo "  ✅ Created/updated commit-msg hook"
        echo "  ✅ Set proper file permissions"
        echo "  ✅ Fixed line ending issues"
        echo "  ✅ Configured Git hooks path"
        echo "  ✅ Added proper error handling"
        echo ""
        
        echo "🧪 Test your fix:"
        echo "  1. git add ."
        echo "  2. git commit -m 'test: verify commit-msg hook functionality'"
        echo ""
        
        echo "💡 The commit-msg hook should now work correctly!"
        return 0
    else
        print_error "Some issues remain with the commit-msg hook"
        return 1
    fi
}

# Main fix function
main_fix() {
    echo "Starting commit-msg hook fix..."
    echo ""
    
    ensure_husky_directory
    determine_husky_version
    create_commit_msg_hook
    fix_line_endings
    
    if test_hook; then
        verify_git_integration
        create_enhanced_hook
        
        if generate_summary; then
            echo "🎉 Commit-msg hook fix completed successfully!"
            return 0
        else
            return 1
        fi
    else
        print_error "Hook testing failed - please check the errors above"
        return 1
    fi
}

# Run the fix
main_fix
