#!/bin/bash

echo "🔍 Comprehensive Husky Pre-Push Hook Diagnostic"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() { echo -e "${CYAN}=== $1 ===${NC}"; }
print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_debug() { echo -e "${MAGENTA}🔧 $1${NC}"; }

# Global variables to track issues
ISSUES_FOUND=0
CRITICAL_ISSUES=0

# Function to increment issue counters
add_issue() {
    ((ISSUES_FOUND++))
    if [ "$1" = "critical" ]; then
        ((CRITICAL_ISSUES++))
    fi
}

# 1. Basic Environment Check
check_environment() {
    print_header "Environment Check"
    
    # Check if we're in a Git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not in a Git repository"
        add_issue critical
        return 1
    fi
    print_status "In a Git repository"
    
    # Check Git version
    git_version=$(git --version)
    print_info "Git version: $git_version"
    
    # Check if Node.js is available
    if command -v node >/dev/null 2>&1; then
        node_version=$(node --version)
        print_status "Node.js available: $node_version"
    else
        print_warning "Node.js not found (may affect Husky)"
        add_issue
    fi
    
    # Check npm
    if command -v npm >/dev/null 2>&1; then
        npm_version=$(npm --version)
        print_status "npm available: $npm_version"
    else
        print_warning "npm not found"
        add_issue
    fi
    
    # Check operating system
    print_info "Operating System: $OSTYPE"
    
    echo ""
}

# 2. Git Configuration Analysis
check_git_configuration() {
    print_header "Git Configuration Analysis"
    
    # Check core.hooksPath
    hooks_path=$(git config core.hooksPath)
    if [ -z "$hooks_path" ]; then
        print_error "core.hooksPath not set"
        add_issue critical
    elif [ "$hooks_path" = ".husky" ]; then
        print_status "core.hooksPath correctly set to .husky"
    else
        print_warning "core.hooksPath set to: $hooks_path (expected: .husky)"
        add_issue
    fi
    
    # Check other relevant Git configs
    print_info "Git configuration details:"
    echo "  core.hooksPath: $(git config core.hooksPath || echo 'not set')"
    echo "  core.autocrlf: $(git config core.autocrlf || echo 'not set')"
    echo "  core.filemode: $(git config core.filemode || echo 'not set')"
    echo "  core.safecrlf: $(git config core.safecrlf || echo 'not set')"
    
    # Check if hooks are enabled
    if git config --get-regexp '^core\.hooks' >/dev/null 2>&1; then
        print_info "Custom hook configurations found:"
        git config --get-regexp '^core\.hooks' | sed 's/^/  /'
    fi
    
    echo ""
}

# 3. Husky Installation Check
check_husky_installation() {
    print_header "Husky Installation Check"
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        print_error "package.json not found"
        add_issue critical
        return 1
    fi
    print_status "package.json found"
    
    # Check if Husky is installed
    if npm list husky >/dev/null 2>&1; then
        husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
        print_status "Husky installed: version $husky_version"
        
        # Determine Husky version type
        major_version=$(echo "$husky_version" | cut -d'.' -f1)
        if [[ "$major_version" -ge 9 ]]; then
            print_info "Using Husky v9+ (modern format)"
            HUSKY_VERSION_TYPE="modern"
        else
            print_info "Using Husky v8.x (legacy format)"
            HUSKY_VERSION_TYPE="legacy"
        fi
    else
        print_error "Husky not installed"
        add_issue critical
        return 1
    fi
    
    # Check for prepare script
    if grep -q '"prepare".*husky' package.json; then
        print_status "Prepare script found in package.json"
    else
        print_warning "No prepare script found (may be normal for v9+)"
    fi
    
    echo ""
}

# 4. .husky Directory Analysis
check_husky_directory() {
    print_header ".husky Directory Analysis"
    
    # Check if .husky directory exists
    if [ ! -d ".husky" ]; then
        print_error ".husky directory does not exist"
        add_issue critical
        return 1
    fi
    print_status ".husky directory exists"
    
    # List contents
    print_info ".husky directory contents:"
    ls -la .husky/ | sed 's/^/  /'
    
    # Check directory permissions
    husky_perms=$(stat -c "%a" .husky 2>/dev/null || stat -f "%A" .husky 2>/dev/null)
    if [ -n "$husky_perms" ]; then
        print_info ".husky directory permissions: $husky_perms"
    fi
    
    echo ""
}

# 5. Pre-Push Hook Specific Analysis
check_pre_push_hook() {
    print_header "Pre-Push Hook Analysis"
    
    local hook_file=".husky/pre-push"
    
    # Check if pre-push hook exists
    if [ ! -f "$hook_file" ]; then
        print_error "pre-push hook file does not exist"
        add_issue critical
        echo "  Expected location: $hook_file"
        return 1
    fi
    print_status "pre-push hook file exists"
    
    # Check file permissions
    if [ -x "$hook_file" ]; then
        print_status "pre-push hook is executable"
    else
        print_error "pre-push hook is not executable"
        add_issue critical
    fi
    
    # Show file permissions in detail
    hook_perms=$(ls -l "$hook_file" | awk '{print $1}')
    print_info "File permissions: $hook_perms"
    
    # Check file size
    hook_size=$(wc -c < "$hook_file")
    if [ "$hook_size" -eq 0 ]; then
        print_error "pre-push hook is empty"
        add_issue critical
    else
        print_status "pre-push hook has content ($hook_size bytes)"
    fi
    
    # Check line endings
    if command -v file >/dev/null 2>&1; then
        line_ending_info=$(file "$hook_file")
        print_info "File type: $line_ending_info"
        
        if echo "$line_ending_info" | grep -q "CRLF"; then
            print_warning "Hook has CRLF line endings (may cause issues on Unix)"
            add_issue
        fi
    fi
    
    # Show hook content
    print_info "Hook content preview:"
    head -10 "$hook_file" | sed 's/^/  /'
    
    echo ""
}

# 6. Hook Content Validation
validate_hook_content() {
    print_header "Hook Content Validation"
    
    local hook_file=".husky/pre-push"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Cannot validate - hook file missing"
        return 1
    fi
    
    # Check for shebang
    first_line=$(head -1 "$hook_file")
    if [[ "$first_line" =~ ^#! ]]; then
        print_status "Hook has shebang: $first_line"
    else
        print_warning "Hook missing shebang (may be normal for Husky v9+)"
    fi
    
    # Check for Husky v8 vs v9 format
    if grep -q '\. "$(dirname -- "$0")/_/husky\.sh"' "$hook_file"; then
        print_info "Hook uses Husky v8.x format"
        if [ "$HUSKY_VERSION_TYPE" = "modern" ]; then
            print_warning "Husky v9+ installed but hook uses v8.x format"
            add_issue
        fi
    else
        print_info "Hook uses modern format (v9+ compatible)"
    fi
    
    # Check for syntax errors
    if bash -n "$hook_file" 2>/dev/null; then
        print_status "Hook syntax is valid"
    else
        print_error "Hook has syntax errors"
        add_issue critical
        print_debug "Syntax check output:"
        bash -n "$hook_file" 2>&1 | sed 's/^/  /'
    fi
    
    echo ""
}

# 7. Test Hook Execution
test_hook_execution() {
    print_header "Hook Execution Test"
    
    local hook_file=".husky/pre-push"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Cannot test - hook file missing"
        return 1
    fi
    
    print_info "Testing hook execution..."
    
    # Test direct execution
    if bash "$hook_file" >/dev/null 2>&1; then
        print_status "Hook executes successfully when run directly"
    else
        print_error "Hook fails when executed directly"
        add_issue critical
        print_debug "Direct execution error:"
        bash "$hook_file" 2>&1 | head -5 | sed 's/^/  /'
    fi
    
    # Test with Git environment
    print_info "Testing in Git environment..."
    
    # Create a test scenario
    current_branch=$(git branch --show-current)
    print_debug "Current branch: $current_branch"
    
    # Check if there are any remotes
    if git remote >/dev/null 2>&1; then
        remotes=$(git remote)
        print_debug "Available remotes: $remotes"
    else
        print_warning "No Git remotes configured"
    fi
    
    echo ""
}

# 8. Git Push Simulation
simulate_git_push() {
    print_header "Git Push Simulation"
    
    print_info "Simulating git push environment..."
    
    # Check current Git status
    if git diff --quiet && git diff --cached --quiet; then
        print_info "Working directory is clean"
    else
        print_warning "Working directory has changes"
    fi
    
    # Check if there are commits to push
    current_branch=$(git branch --show-current)
    if git rev-parse --verify "origin/$current_branch" >/dev/null 2>&1; then
        commits_ahead=$(git rev-list --count "origin/$current_branch..$current_branch" 2>/dev/null || echo "0")
        if [ "$commits_ahead" -gt 0 ]; then
            print_info "Branch is $commits_ahead commits ahead of origin"
        else
            print_info "Branch is up to date with origin"
        fi
    else
        print_warning "No upstream branch found for $current_branch"
    fi
    
    # Test hook in push context (dry run)
    print_info "Testing hook in push context..."
    
    # Set up environment variables that Git would set
    export GIT_DIR=$(git rev-parse --git-dir)
    export GIT_WORK_TREE=$(git rev-parse --show-toplevel)
    
    # Try to execute the hook as Git would
    if [ -f ".husky/pre-push" ] && [ -x ".husky/pre-push" ]; then
        print_debug "Executing hook with Git environment..."
        if ./.husky/pre-push >/dev/null 2>&1; then
            print_status "Hook executes successfully in Git context"
        else
            print_error "Hook fails in Git context"
            add_issue critical
            print_debug "Git context execution error:"
            ./.husky/pre-push 2>&1 | head -5 | sed 's/^/  /'
        fi
    fi
    
    echo ""
}

# 9. Path Resolution Check
check_path_resolution() {
    print_header "Path Resolution Check"
    
    # Check current working directory
    current_dir=$(pwd)
    git_root=$(git rev-parse --show-toplevel)
    
    print_info "Current directory: $current_dir"
    print_info "Git repository root: $git_root"
    
    if [ "$current_dir" = "$git_root" ]; then
        print_status "Running from Git repository root"
    else
        print_warning "Not running from Git repository root"
        print_debug "This might affect hook execution"
    fi
    
    # Check relative path to .husky
    if [ -d ".husky" ]; then
        husky_abs_path=$(realpath .husky)
        print_info "Absolute path to .husky: $husky_abs_path"
    fi
    
    # Check if Git can find the hooks
    git_hooks_path=$(git config core.hooksPath)
    if [ -n "$git_hooks_path" ]; then
        if [ -d "$git_hooks_path" ]; then
            print_status "Git hooks path exists: $git_hooks_path"
        else
            print_error "Git hooks path does not exist: $git_hooks_path"
            add_issue critical
        fi
    fi
    
    echo ""
}

# 10. Generate Diagnostic Report
generate_report() {
    print_header "Diagnostic Summary"
    
    echo "📊 Issues Found: $ISSUES_FOUND"
    echo "🚨 Critical Issues: $CRITICAL_ISSUES"
    echo ""
    
    if [ $CRITICAL_ISSUES -eq 0 ] && [ $ISSUES_FOUND -eq 0 ]; then
        print_status "No issues detected - configuration appears correct"
        echo ""
        echo "🤔 If you're still experiencing problems:"
        echo "  1. Try running: git push --dry-run"
        echo "  2. Check for network/authentication issues"
        echo "  3. Verify remote repository access"
        
    elif [ $CRITICAL_ISSUES -eq 0 ]; then
        print_warning "Minor issues found - may not affect functionality"
        echo ""
        echo "🔧 Recommended actions:"
        echo "  1. Review warnings above"
        echo "  2. Run: ./tools/fix-husky-push-issues.sh"
        echo "  3. Test with: git push --dry-run"
        
    else
        print_error "Critical issues found - will prevent hook execution"
        echo ""
        echo "🚨 Required actions:"
        echo "  1. Run: ./tools/fix-husky-push-issues.sh"
        echo "  2. Verify fix with: ./tools/test-husky-hooks.sh"
        echo "  3. Test with: git push --dry-run"
    fi
    
    echo ""
    echo "📋 Next Steps:"
    echo "  • Run the fix script: ./tools/fix-husky-push-issues.sh"
    echo "  • Test the hooks: ./tools/test-husky-hooks.sh"
    echo "  • Verify with push: git push --dry-run"
    echo ""
}

# Main diagnostic function
main_diagnostic() {
    echo "Starting comprehensive Husky pre-push diagnostic..."
    echo "This will analyze your Git and Husky configuration."
    echo ""
    
    check_environment
    check_git_configuration
    check_husky_installation
    check_husky_directory
    check_pre_push_hook
    validate_hook_content
    test_hook_execution
    simulate_git_push
    check_path_resolution
    generate_report
    
    echo "🎯 Diagnostic complete!"
    
    # Return appropriate exit code
    if [ $CRITICAL_ISSUES -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Run the diagnostic
main_diagnostic
