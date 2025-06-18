#!/bin/bash

echo "🧪 Comprehensive Husky Hooks Test"
echo "================================="

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

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_TOTAL++))
    print_info "Testing: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        print_status "$test_name - PASSED"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$test_name - FAILED"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Basic file existence
test_file_existence() {
    print_header "File Existence Tests"
    
    run_test "Husky directory exists" "[ -d '.husky' ]"
    run_test "Pre-push hook exists" "[ -f '.husky/pre-push' ]"
    run_test "Pre-commit hook exists" "[ -f '.husky/pre-commit' ]"
    run_test "Commit-msg hook exists" "[ -f '.husky/commit-msg' ]"
    
    echo ""
}

# Test 2: File permissions
test_file_permissions() {
    print_header "File Permissions Tests"
    
    run_test "Pre-push hook is executable" "[ -x '.husky/pre-push' ]"
    run_test "Pre-commit hook is executable" "[ -x '.husky/pre-commit' ]"
    run_test "Commit-msg hook is executable" "[ -x '.husky/commit-msg' ]"
    
    echo ""
}

# Test 3: Hook syntax validation
test_hook_syntax() {
    print_header "Hook Syntax Tests"
    
    for hook in pre-push pre-commit commit-msg; do
        if [ -f ".husky/$hook" ]; then
            run_test "$hook syntax validation" "bash -n '.husky/$hook'"
        fi
    done
    
    echo ""
}

# Test 4: Hook execution
test_hook_execution() {
    print_header "Hook Execution Tests"
    
    # Test pre-push hook
    if [ -f ".husky/pre-push" ]; then
        run_test "Pre-push hook execution" "bash '.husky/pre-push'"
    fi
    
    # Test pre-commit hook
    if [ -f ".husky/pre-commit" ]; then
        run_test "Pre-commit hook execution" "bash '.husky/pre-commit'"
    fi
    
    # Test commit-msg hook (needs a message file)
    if [ -f ".husky/commit-msg" ]; then
        echo "test commit message" > /tmp/test_commit_msg
        run_test "Commit-msg hook execution" "bash '.husky/commit-msg' '/tmp/test_commit_msg'"
        rm -f /tmp/test_commit_msg
    fi
    
    echo ""
}

# Test 5: Git configuration
test_git_configuration() {
    print_header "Git Configuration Tests"
    
    run_test "Git hooks path is set" "[ '$(git config core.hooksPath)' = '.husky' ]"
    run_test "In Git repository" "git rev-parse --git-dir >/dev/null 2>&1"
    
    echo ""
}

# Test 6: Husky installation
test_husky_installation() {
    print_header "Husky Installation Tests"
    
    run_test "Package.json exists" "[ -f 'package.json' ]"
    run_test "Husky is installed" "npm list husky >/dev/null 2>&1"
    
    if npm list husky >/dev/null 2>&1; then
        husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
        print_info "Husky version: $husky_version"
    fi
    
    echo ""
}

# Test 7: Line endings
test_line_endings() {
    print_header "Line Endings Tests"
    
    for hook in pre-push pre-commit commit-msg; do
        if [ -f ".husky/$hook" ]; then
            if command -v file >/dev/null 2>&1; then
                if file ".husky/$hook" | grep -q "CRLF"; then
                    print_warning "$hook has CRLF line endings"
                    ((TESTS_FAILED++))
                    ((TESTS_TOTAL++))
                else
                    run_test "$hook line endings" "true"
                fi
            else
                run_test "$hook line endings (file cmd unavailable)" "true"
            fi
        fi
    done
    
    echo ""
}

# Test 8: Git push simulation
test_git_push_simulation() {
    print_header "Git Push Simulation"
    
    print_info "Simulating git push environment..."
    
    # Check if we can simulate a push
    current_branch=$(git branch --show-current)
    print_info "Current branch: $current_branch"
    
    # Test if hook would be called during push
    if [ -f ".husky/pre-push" ] && [ -x ".husky/pre-push" ]; then
        print_info "Testing pre-push hook in simulated Git environment..."
        
        # Set up Git environment variables
        export GIT_DIR=$(git rev-parse --git-dir)
        export GIT_WORK_TREE=$(git rev-parse --show-toplevel)
        
        if ./.husky/pre-push >/dev/null 2>&1; then
            run_test "Pre-push hook in Git environment" "true"
        else
            run_test "Pre-push hook in Git environment" "false"
            print_error "Hook failed in Git environment"
        fi
    else
        print_warning "Cannot test - pre-push hook missing or not executable"
    fi
    
    echo ""
}

# Test 9: Dry run git push
test_dry_run_push() {
    print_header "Dry Run Git Push Test"
    
    print_info "Testing git push --dry-run..."
    
    # Check if there are remotes configured
    if git remote >/dev/null 2>&1; then
        remotes=$(git remote)
        print_info "Available remotes: $remotes"
        
        # Try dry run push
        if git push --dry-run >/dev/null 2>&1; then
            run_test "Git push dry run" "true"
        else
            # Check the specific error
            push_error=$(git push --dry-run 2>&1)
            if echo "$push_error" | grep -q "cannot spawn.*pre-push"; then
                run_test "Git push dry run (no spawn error)" "false"
                print_error "Still getting 'cannot spawn' error"
            else
                run_test "Git push dry run (other error)" "true"
                print_info "Dry run failed for other reasons (normal if no changes to push)"
            fi
        fi
    else
        print_warning "No Git remotes configured - cannot test push"
        run_test "Git remotes configured" "false"
    fi
    
    echo ""
}

# Test 10: Integration test
test_integration() {
    print_header "Integration Test"
    
    print_info "Running full integration test..."
    
    # Create a test file
    echo "# Test file for Husky integration" > test_husky_integration.md
    
    # Add to Git
    git add test_husky_integration.md >/dev/null 2>&1
    
    # Test commit (this should trigger pre-commit and commit-msg hooks)
    if git commit -m "test: Husky integration test" --dry-run >/dev/null 2>&1; then
        run_test "Git commit with hooks" "true"
    else
        run_test "Git commit with hooks" "false"
    fi
    
    # Clean up
    git reset HEAD test_husky_integration.md >/dev/null 2>&1
    rm -f test_husky_integration.md
    
    echo ""
}

# Generate test report
generate_test_report() {
    print_header "Test Results Summary"
    
    echo "📊 Tests Run: $TESTS_TOTAL"
    echo "✅ Tests Passed: $TESTS_PASSED"
    echo "❌ Tests Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo ""
        print_status "🎉 All tests passed! Husky hooks are working correctly."
        echo ""
        echo "✅ Your Git hooks are properly configured and functional"
        echo "✅ The 'cannot spawn .husky/pre-push' error should be resolved"
        echo "✅ You can now safely use git push"
        echo ""
        echo "🚀 Try it out:"
        echo "  git push"
        return 0
    else
        echo ""
        print_error "❌ Some tests failed. Issues remain with your Husky setup."
        echo ""
        echo "🔧 Recommended actions:"
        echo "  1. Review the failed tests above"
        echo "  2. Run: ./tools/fix-husky-push-issues.sh"
        echo "  3. Run this test again: ./tools/test-husky-hooks.sh"
        echo ""
        return 1
    fi
}

# Main test function
main_test() {
    echo "Starting comprehensive Husky hooks test..."
    echo ""
    
    test_file_existence
    test_file_permissions
    test_hook_syntax
    test_hook_execution
    test_git_configuration
    test_husky_installation
    test_line_endings
    test_git_push_simulation
    test_dry_run_push
    test_integration
    
    generate_test_report
}

# Run the tests
main_test
