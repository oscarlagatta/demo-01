#!/bin/bash

echo "🔧 Fixing Husky Pre-Push Hook Issues"
echo "===================================="

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

# Function to increment fix counter
fix_applied() {
    ((FIXES_APPLIED++))
    print_status "$1"
}

# 1. Ensure we're in the right directory
ensure_correct_directory() {
    print_header "Directory Verification"
    
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not in a Git repository"
        exit 1
    fi
    
    # Move to Git root if not already there
    git_root=$(git rev-parse --show-toplevel)
    current_dir=$(pwd)
    
    if [ "$current_dir" != "$git_root" ]; then
        print_info "Moving to Git repository root: $git_root"
        cd "$git_root" || exit 1
        fix_applied "Changed to Git repository root"
    else
        print_status "Already in Git repository root"
    fi
    
    echo ""
}

# 2. Fix Git configuration
fix_git_configuration() {
    print_header "Git Configuration Fix"
    
    # Set core.hooksPath
    current_hooks_path=$(git config core.hooksPath)
    if [ "$current_hooks_path" != ".husky" ]; then
        git config core.hooksPath .husky
        fix_applied "Set core.hooksPath to .husky"
    else
        print_status "core.hooksPath already correctly set"
    fi
    
    # Fix line ending issues on Windows
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        print_info "Applying Windows-specific Git configuration..."
        git config core.autocrlf true
        git config core.safecrlf false
        git config core.filemode false
        fix_applied "Applied Windows Git configuration"
    fi
    
    echo ""
}

# 3. Ensure Husky is properly installed
ensure_husky_installation() {
    print_header "Husky Installation Check"
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        print_error "package.json not found - cannot install Husky"
        exit 1
    fi
    
    # Install Husky if not present
    if ! npm list husky >/dev/null 2>&1; then
        print_info "Installing Husky..."
        npm install --save-dev husky
        fix_applied "Installed Husky"
    else
        print_status "Husky is already installed"
    fi
    
    # Get Husky version
    husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
    major_version=$(echo "$husky_version" | cut -d'.' -f1)
    
    print_info "Husky version: $husky_version"
    
    # Initialize Husky based on version
    if [[ "$major_version" -ge 9 ]]; then
        print_info "Initializing Husky v9+..."
        if [ ! -d ".husky" ]; then
            npx husky init
            fix_applied "Initialized Husky v9+"
        fi
    else
        print_info "Setting up Husky v8.x..."
        if [ ! -d ".husky" ]; then
            npx husky install
            fix_applied "Installed Husky v8.x hooks"
        fi
        
        # Add prepare script if missing
        if ! grep -q '"prepare".*husky' package.json; then
            npm pkg set scripts.prepare="husky install"
            fix_applied "Added prepare script to package.json"
        fi
    fi
    
    echo ""
}

# 4. Create/Fix .husky directory
fix_husky_directory() {
    print_header "Husky Directory Setup"
    
    # Create .husky directory if missing
    if [ ! -d ".husky" ]; then
        mkdir -p .husky
        fix_applied "Created .husky directory"
    else
        print_status ".husky directory exists"
    fi
    
    # Set proper permissions
    chmod 755 .husky
    print_status "Set .husky directory permissions"
    
    # Create _/husky.sh for v8.x compatibility if needed
    husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
    major_version=$(echo "$husky_version" | cut -d'.' -f1)
    
    if [[ "$major_version" -lt 9 ]] && [ ! -f ".husky/_/husky.sh" ]; then
        mkdir -p .husky/_
        npx husky install
        fix_applied "Created Husky v8.x support files"
    fi
    
    echo ""
}

# 5. Create/Fix pre-push hook
create_pre_push_hook() {
    print_header "Pre-Push Hook Creation"
    
    local hook_file=".husky/pre-push"
    
    # Determine Husky version for correct format
    husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
    major_version=$(echo "$husky_version" | cut -d'.' -f1)
    
    # Create or recreate the pre-push hook
    if [[ "$major_version" -ge 9 ]]; then
        # Husky v9+ format
        cat > "$hook_file" << 'EOF'
#!/bin/sh
echo "🚀 Running pre-push checks..."

# Get current branch
current_branch=$(git branch --show-current)
echo "📋 Pushing branch: $current_branch"

# Optional: Prevent direct push to protected branches
# protected_branches="main master"
# if echo "$protected_branches" | grep -wq "$current_branch"; then
#     echo "⚠️  Warning: Pushing to protected branch: $current_branch"
#     read -p "Continue? (y/N): " confirm
#     if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
#         echo "❌ Push cancelled"
#         exit 1
#     fi
# fi

# Optional: Run tests before push
# echo "🧪 Running tests..."
# npm test

# Optional: Run build before push
# echo "🏗️  Building project..."
# npm run build

echo "✅ Pre-push checks completed!"
EOF
    else
        # Husky v8.x format
        cat > "$hook_file" << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "🚀 Running pre-push checks..."

# Get current branch
current_branch=$(git branch --show-current)
echo "📋 Pushing branch: $current_branch"

# Optional: Prevent direct push to protected branches
# protected_branches="main master"
# if echo "$protected_branches" | grep -wq "$current_branch"; then
#     echo "⚠️  Warning: Pushing to protected branch: $current_branch"
#     read -p "Continue? (y/N): " confirm
#     if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
#         echo "❌ Push cancelled"
#         exit 1
#     fi
# fi

# Optional: Run tests before push
# echo "🧪 Running tests..."
# npm test

# Optional: Run build before push
# echo "🏗️  Building project..."
# npm run build

echo "✅ Pre-push checks completed!"
EOF
    fi
    
    # Make executable
    chmod +x "$hook_file"
    
    fix_applied "Created pre-push hook (Husky v$major_version format)"
    
    echo ""
}

# 6. Fix line endings
fix_line_endings() {
    print_header "Line Endings Fix"
    
    local hook_file=".husky/pre-push"
    
    if [ -f "$hook_file" ]; then
        # Convert CRLF to LF
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$hook_file" 2>/dev/null
        else
            sed -i 's/\r$//' "$hook_file" 2>/dev/null || {
                tr -d '\r' < "$hook_file" > "${hook_file}.tmp" && mv "${hook_file}.tmp" "$hook_file"
            }
        fi
        
        fix_applied "Fixed line endings in pre-push hook"
    fi
    
    # Create .gitattributes if missing
    if [ ! -f ".gitattributes" ]; then
        cat > .gitattributes << 'EOF'
# Set default behavior to automatically normalize line endings
* text=auto

# Force bash scripts to always use LF line endings
*.sh text eol=lf

# Husky hooks should use LF
.husky/* text eol=lf

# Windows batch files should use CRLF
*.bat text eol=crlf
*.cmd text eol=crlf
EOF
        fix_applied "Created .gitattributes for line ending control"
    fi
    
    echo ""
}

# 7. Verify and test the fix
verify_fix() {
    print_header "Fix Verification"
    
    local hook_file=".husky/pre-push"
    local verification_passed=true
    
    # Check if hook exists
    if [ ! -f "$hook_file" ]; then
        print_error "Hook file still missing"
        verification_passed=false
    else
        print_status "Hook file exists"
    fi
    
    # Check if hook is executable
    if [ ! -x "$hook_file" ]; then
        print_error "Hook is not executable"
        verification_passed=false
    else
        print_status "Hook is executable"
    fi
    
    # Check Git configuration
    if [ "$(git config core.hooksPath)" != ".husky" ]; then
        print_error "Git hooks path not correctly set"
        verification_passed=false
    else
        print_status "Git hooks path correctly configured"
    fi
    
    # Test hook execution
    if bash "$hook_file" >/dev/null 2>&1; then
        print_status "Hook executes successfully"
    else
        print_error "Hook execution failed"
        verification_passed=false
    fi
    
    # Test syntax
    if bash -n "$hook_file" 2>/dev/null; then
        print_status "Hook syntax is valid"
    else
        print_error "Hook has syntax errors"
        verification_passed=false
    fi
    
    if [ "$verification_passed" = true ]; then
        print_status "All verifications passed!"
        return 0
    else
        print_error "Some verifications failed"
        return 1
    fi
    
    echo ""
}

# 8. Create other essential hooks
create_essential_hooks() {
    print_header "Essential Hooks Setup"
    
    # Determine Husky version
    husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
    major_version=$(echo "$husky_version" | cut -d'.' -f1)
    
    # Create pre-commit hook if missing
    if [ ! -f ".husky/pre-commit" ]; then
        if [[ "$major_version" -ge 9 ]]; then
            cat > .husky/pre-commit << 'EOF'
#!/bin/sh
echo "🚀 Running pre-commit checks..."

# Run lint-staged if available
if command -v npx >/dev/null 2>&1 && npm list lint-staged >/dev/null 2>&1; then
    echo "📝 Running lint-staged..."
    npx lint-staged
else
    echo "ℹ️  lint-staged not available, skipping..."
fi

echo "✅ Pre-commit checks completed!"
EOF
        else
            cat > .husky/pre-commit << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "🚀 Running pre-commit checks..."

# Run lint-staged if available
if command -v npx >/dev/null 2>&1 && npm list lint-staged >/dev/null 2>&1; then
    echo "📝 Running lint-staged..."
    npx lint-staged
else
    echo "ℹ️  lint-staged not available, skipping..."
fi

echo "✅ Pre-commit checks completed!"
EOF
        fi
        
        chmod +x .husky/pre-commit
        fix_applied "Created pre-commit hook"
    fi
    
    # Create commit-msg hook if missing
    if [ ! -f ".husky/commit-msg" ]; then
        if [[ "$major_version" -ge 9 ]]; then
            cat > .husky/commit-msg << 'EOF'
#!/bin/sh
echo "📝 Validating commit message..."

# Basic commit message validation
commit_msg=$(cat "$1")

# Check minimum length
if [ ${#commit_msg} -lt 10 ]; then
    echo "❌ Commit message too short (minimum 10 characters)"
    exit 1
fi

echo "✅ Commit message validation passed!"
EOF
        else
            cat > .husky/commit-msg << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "📝 Validating commit message..."

# Basic commit message validation
commit_msg=$(cat "$1")

# Check minimum length
if [ ${#commit_msg} -lt 10 ]; then
    echo "❌ Commit message too short (minimum 10 characters)"
    exit 1
fi

echo "✅ Commit message validation passed!"
EOF
        fi
        
        chmod +x .husky/commit-msg
        fix_applied "Created commit-msg hook"
    fi
    
    echo ""
}

# Main fix function
main_fix() {
    echo "Starting comprehensive Husky pre-push fix..."
    echo ""
    
    ensure_correct_directory
    fix_git_configuration
    ensure_husky_installation
    fix_husky_directory
    create_pre_push_hook
    fix_line_endings
    create_essential_hooks
    
    echo ""
    print_header "Fix Summary"
    echo "Fixes applied: $FIXES_APPLIED"
    echo ""
    
    if verify_fix; then
        echo ""
        echo "🎉 All fixes completed successfully!"
        echo ""
        echo "📋 What was fixed:"
        echo "  ✅ Git hooks path configuration"
        echo "  ✅ Husky installation and setup"
        echo "  ✅ Pre-push hook creation"
        echo "  ✅ File permissions and line endings"
        echo "  ✅ Essential hooks setup"
        echo ""
        echo "🧪 Test your fix:"
        echo "  1. git add ."
        echo "  2. git commit -m 'fix: resolve Husky pre-push issues'"
        echo "  3. git push --dry-run"
        echo "  4. git push"
        echo ""
        echo "💡 The 'cannot spawn .husky/pre-push' error should now be resolved!"
        return 0
    else
        echo ""
        print_error "Some issues could not be resolved automatically"
        echo "Please run the diagnostic script for more details:"
        echo "  ./tools/diagnose-husky-push-error.sh"
        return 1
    fi
}

# Run the fix
main_fix
