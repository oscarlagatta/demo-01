#!/bin/bash

echo "🔍 Commit-msg Hook Diagnostic"
echo "============================="

# Colors
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

# Check commit-msg hook file
check_commit_msg_file() {
    print_header "Commit-msg Hook File Analysis"
    
    local hook_file=".husky/commit-msg"
    
    # Check if file exists
    if [ ! -f "$hook_file" ]; then
        print_error "commit-msg hook file does not exist"
        print_info "Expected location: $hook_file"
        return 1
    fi
    print_status "commit-msg hook file exists"
    
    # Check file size
    local file_size=$(wc -c < "$hook_file")
    if [ "$file_size" -eq 0 ]; then
        print_error "commit-msg hook file is empty"
        return 1
    fi
    print_status "commit-msg hook has content ($file_size bytes)"
    
    # Check permissions
    if [ -x "$hook_file" ]; then
        print_status "commit-msg hook is executable"
    else
        print_error "commit-msg hook is not executable"
        return 1
    fi
    
    # Show permissions
    local perms=$(ls -l "$hook_file" | awk '{print $1}')
    print_info "File permissions: $perms"
    
    # Check line endings
    if command -v file >/dev/null 2>&1; then
        local file_info=$(file "$hook_file")
        print_info "File type: $file_info"
        
        if echo "$file_info" | grep -q "CRLF"; then
            print_warning "Hook has CRLF line endings (may cause issues)"
        else
            print_status "Hook has correct line endings"
        fi
    fi
    
    echo ""
    return 0
}

# Analyze hook content
analyze_hook_content() {
    print_header "Hook Content Analysis"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Cannot analyze - hook file missing"
        return 1
    fi
    
    print_info "Hook content:"
    echo "----------------------------------------"
    cat "$hook_file" | nl -ba
    echo "----------------------------------------"
    echo ""
    
    # Check for shebang
    local first_line=$(head -1 "$hook_file")
    if [[ "$first_line" =~ ^#! ]]; then
        print_status "Hook has shebang: $first_line"
    else
        print_warning "Hook missing shebang"
    fi
    
    # Check for Husky format
    if grep -q '\. "$(dirname -- "$0")/_/husky\.sh"' "$hook_file"; then
        print_info "Hook uses Husky v8.x format"
    else
        print_info "Hook uses modern format (v9+ compatible)"
    fi
    
    # Check for syntax errors
    print_info "Checking syntax..."
    if bash -n "$hook_file" 2>/dev/null; then
        print_status "Hook syntax is valid"
    else
        print_error "Hook has syntax errors:"
        bash -n "$hook_file" 2>&1 | sed 's/^/  /'
        return 1
    fi
    
    echo ""
    return 0
}

# Test hook execution with different scenarios
test_hook_execution() {
    print_header "Hook Execution Testing"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Cannot test - hook file missing"
        return 1
    fi
    
    # Test 1: Direct execution without arguments
    print_info "Test 1: Direct execution without arguments"
    if bash "$hook_file" >/dev/null 2>&1; then
        print_status "Hook executes without arguments"
    else
        print_warning "Hook fails without arguments (may be expected)"
        print_debug "Error output:"
        bash "$hook_file" 2>&1 | head -3 | sed 's/^/  /'
    fi
    
    # Test 2: Execution with test message file
    print_info "Test 2: Execution with test message file"
    echo "test: this is a test commit message" > /tmp/test_commit_msg
    
    if bash "$hook_file" /tmp/test_commit_msg >/dev/null 2>&1; then
        print_status "Hook executes successfully with test message"
    else
        print_error "Hook fails with test message"
        print_debug "Error output:"
        bash "$hook_file" /tmp/test_commit_msg 2>&1 | head -5 | sed 's/^/  /'
        rm -f /tmp/test_commit_msg
        return 1
    fi
    
    # Test 3: Execution with various message types
    print_info "Test 3: Testing with different message types"
    
    local test_messages=(
        "feat: add new feature"
        "fix: resolve bug"
        "docs: update documentation"
        "test commit message"
        "short"
        ""
    )
    
    for msg in "${test_messages[@]}"; do
        echo "$msg" > /tmp/test_commit_msg
        print_debug "Testing message: '$msg'"
        
        if bash "$hook_file" /tmp/test_commit_msg >/dev/null 2>&1; then
            print_debug "  ✅ Passed"
        else
            print_debug "  ❌ Failed"
        fi
    done
    
    rm -f /tmp/test_commit_msg
    echo ""
    return 0
}

# Test in Git environment
test_git_environment() {
    print_header "Git Environment Testing"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Cannot test - hook file missing"
        return 1
    fi
    
    # Set up Git environment variables
    export GIT_DIR=$(git rev-parse --git-dir)
    export GIT_WORK_TREE=$(git rev-parse --show-toplevel)
    
    print_info "Git environment variables:"
    echo "  GIT_DIR: $GIT_DIR"
    echo "  GIT_WORK_TREE: $GIT_WORK_TREE"
    
    # Test with Git environment
    echo "test: commit message in git environment" > /tmp/test_git_commit_msg
    
    print_info "Testing hook in Git environment..."
    if bash "$hook_file" /tmp/test_git_commit_msg >/dev/null 2>&1; then
        print_status "Hook works in Git environment"
    else
        print_error "Hook fails in Git environment"
        print_debug "Error output:"
        bash "$hook_file" /tmp/test_git_commit_msg 2>&1 | head -5 | sed 's/^/  /'
        rm -f /tmp/test_git_commit_msg
        return 1
    fi
    
    rm -f /tmp/test_git_commit_msg
    echo ""
    return 0
}

# Test actual Git commit
test_actual_commit() {
    print_header "Actual Git Commit Test"
    
    print_info "Testing with actual Git commit (dry run)..."
    
    # Create a test file
    echo "# Test file for commit-msg hook" > test_commit_msg_hook.md
    git add test_commit_msg_hook.md >/dev/null 2>&1
    
    # Try commit with dry run
    if git commit -m "test: verify commit-msg hook functionality" --dry-run >/dev/null 2>&1; then
        print_status "Git commit dry run with hook succeeded"
    else
        print_error "Git commit dry run with hook failed"
        print_debug "Commit error output:"
        git commit -m "test: verify commit-msg hook functionality" --dry-run 2>&1 | head -5 | sed 's/^/  /'
    fi
    
    # Clean up
    git reset HEAD test_commit_msg_hook.md >/dev/null 2>&1
    rm -f test_commit_msg_hook.md
    
    echo ""
}

# Check for common issues
check_common_issues() {
    print_header "Common Issues Check"
    
    local hook_file=".husky/commit-msg"
    
    # Issue 1: Missing $1 parameter handling
    if [ -f "$hook_file" ]; then
        if grep -q '\$1' "$hook_file"; then
            print_status "Hook properly handles \$1 parameter"
        else
            print_warning "Hook may not handle \$1 parameter (commit message file)"
        fi
        
        # Issue 2: Missing file existence check
        if grep -q 'cat.*\$1\|<.*\$1' "$hook_file"; then
            print_status "Hook reads commit message file"
        else
            print_warning "Hook may not read commit message file properly"
        fi
        
        # Issue 3: Exit codes
        if grep -q 'exit' "$hook_file"; then
            print_status "Hook uses exit codes"
        else
            print_warning "Hook may not use proper exit codes"
        fi
        
        # Issue 4: Error handling
        if grep -q 'if\|then\|else' "$hook_file"; then
            print_status "Hook has conditional logic"
        else
            print_warning "Hook may lack error handling"
        fi
    fi
    
    echo ""
}

# Generate diagnostic report
generate_diagnostic_report() {
    print_header "Diagnostic Summary"
    
    local hook_file=".husky/commit-msg"
    
    echo "📋 Commit-msg Hook Status:"
    echo "  File exists: $([ -f "$hook_file" ] && echo 'Yes' || echo 'No')"
    echo "  Executable: $([ -x "$hook_file" ] && echo 'Yes' || echo 'No')"
    echo "  Size: $([ -f "$hook_file" ] && wc -c < "$hook_file" || echo '0') bytes"
    
    if [ -f "$hook_file" ]; then
        echo "  Syntax valid: $(bash -n "$hook_file" 2>/dev/null && echo 'Yes' || echo 'No')"
    fi
    
    echo ""
    echo "🔧 Recommended Actions:"
    
    if [ ! -f "$hook_file" ]; then
        echo "  1. Create commit-msg hook: ./tools/fix-commit-msg-hook.sh"
    elif [ ! -x "$hook_file" ]; then
        echo "  1. Fix permissions: chmod +x $hook_file"
    elif ! bash -n "$hook_file" 2>/dev/null; then
        echo "  1. Fix syntax errors in hook"
    else
        echo "  1. Run fix script: ./tools/fix-commit-msg-hook.sh"
    fi
    
    echo "  2. Test the fix: ./tools/test-commit-msg-hook.sh"
    echo "  3. Verify with commit: git commit -m 'test: message'"
    echo ""
}

# Main diagnostic function
main_diagnostic() {
    echo "Starting commit-msg hook diagnostic..."
    echo ""
    
    local overall_status=0
    
    if ! check_commit_msg_file; then
        overall_status=1
    fi
    
    if ! analyze_hook_content; then
        overall_status=1
    fi
    
    if ! test_hook_execution; then
        overall_status=1
    fi
    
    if ! test_git_environment; then
        overall_status=1
    fi
    
    test_actual_commit
    check_common_issues
    generate_diagnostic_report
    
    echo "🎯 Diagnostic complete!"
    
    return $overall_status
}

# Run the diagnostic
main_diagnostic
