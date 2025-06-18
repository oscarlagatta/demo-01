#!/bin/bash

echo "🧪 Commit-msg Hook Test Suite"
echo "============================="

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
    local expected_result="$3"  # "pass" or "fail"
    
    ((TESTS_TOTAL++))
    print_info "Testing: $test_name"
    
    local result
    if eval "$test_command" >/dev/null 2>&1; then
        result="pass"
    else
        result="fail"
    fi
    
    if [ "$result" = "$expected_result" ]; then
        print_status "$test_name - PASSED"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$test_name - FAILED (expected $expected_result, got $result)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Basic file checks
test_basic_checks() {
    print_header "Basic File Checks"
    
    run_test "Hook file exists" "[ -f '.husky/commit-msg' ]" "pass"
    run_test "Hook is executable" "[ -x '.husky/commit-msg' ]" "pass"
    run_test "Hook has content" "[ -s '.husky/commit-msg' ]" "pass"
    run_test "Hook syntax is valid" "bash -n '.husky/commit-msg'" "pass"
    
    echo ""
}

# Test 2: Hook execution with various messages
test_message_validation() {
    print_header "Message Validation Tests"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Hook file not found - skipping message tests"
        return 1
    fi
    
    # Test valid messages
    local valid_messages=(
        "feat: add new user authentication feature"
        "fix: resolve login bug in user module"
        "docs: update API documentation"
        "test: add unit tests for user service"
        "refactor: improve code structure in auth module"
        "chore: update dependencies"
        "This is a valid commit message with sufficient length"
    )
    
    for msg in "${valid_messages[@]}"; do
        echo "$msg" > /tmp/test_commit_msg
        run_test "Valid message: '${msg:0:30}...'" "bash '$hook_file' /tmp/test_commit_msg" "pass"
    done
    
    # Test invalid messages
    local invalid_messages=(
        "short"
        "x"
        ""
        "   "
    )
    
    for msg in "${invalid_messages[@]}"; do
        echo "$msg" > /tmp/test_commit_msg
        run_test "Invalid message: '$msg'" "bash '$hook_file' /tmp/test_commit_msg" "fail"
    done
    
    rm -f /tmp/test_commit_msg
    echo ""
}

# Test 3: Parameter handling
test_parameter_handling() {
    print_header "Parameter Handling Tests"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Hook file not found - skipping parameter tests"
        return 1
    fi
    
    # Test without parameters
    run_test "No parameters provided" "bash '$hook_file'" "fail"
    
    # Test with non-existent file
    run_test "Non-existent file parameter" "bash '$hook_file' /tmp/non_existent_file" "fail"
    
    # Test with valid file
    echo "test: valid commit message for parameter testing" > /tmp/test_param_msg
    run_test "Valid file parameter" "bash '$hook_file' /tmp/test_param_msg" "pass"
    rm -f /tmp/test_param_msg
    
    echo ""
}

# Test 4: Git comment handling
test_git_comments() {
    print_header "Git Comment Handling Tests"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Hook file not found - skipping comment tests"
        return 1
    fi
    
    # Test message with Git comments
    cat > /tmp/test_comment_msg << 'EOF'
feat: add new feature with proper implementation

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch feature/new-feature
# Changes to be committed:
#	modified:   src/app.js
#	new file:   src/feature.js
EOF
    
    run_test "Message with Git comments" "bash '$hook_file' /tmp/test_comment_msg" "pass"
    
    # Test message that becomes empty after removing comments
    cat > /tmp/test_empty_after_comments << 'EOF'
# This is just a comment
# Another comment
# 
# More comments
EOF
    
    run_test "Empty after removing comments" "bash '$hook_file' /tmp/test_empty_after_comments" "fail"
    
    rm -f /tmp/test_comment_msg /tmp/test_empty_after_comments
    echo ""
}

# Test 5: Integration with Git
test_git_integration() {
    print_header "Git Integration Tests"
    
    # Check Git hooks path
    local hooks_path=$(git config core.hooksPath)
    run_test "Git hooks path set to .husky" "[ '$hooks_path' = '.husky' ]" "pass"
    
    # Test actual Git commit (dry run)
    print_info "Testing actual Git commit integration..."
    
    # Create a test file
    echo "# Test file for commit-msg integration" > test_commit_integration.md
    git add test_commit_integration.md >/dev/null 2>&1
    
    # Test with valid commit message
    if git commit -m "test: verify commit-msg hook integration with Git" --dry-run >/dev/null 2>&1; then
        print_status "Git commit integration - PASSED"
        ((TESTS_PASSED++))
    else
        print_error "Git commit integration - FAILED"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
    
    # Test with invalid commit message
    if git commit -m "x" --dry-run >/dev/null 2>&1; then
        print_error "Git commit with invalid message - FAILED (should have been rejected)"
        ((TESTS_FAILED++))
    else
        print_status "Git commit with invalid message - PASSED (correctly rejected)"
        ((TESTS_PASSED++))
    fi
    ((TESTS_TOTAL++))
    
    # Clean up
    git reset HEAD test_commit_integration.md >/dev/null 2>&1
    rm -f test_commit_integration.md
    
    echo ""
}

# Test 6: Performance and edge cases
test_edge_cases() {
    print_header "Edge Cases and Performance Tests"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Hook file not found - skipping edge case tests"
        return 1
    fi
    
    # Test very long message
    local long_message=$(printf 'feat: %*s' 200 '' | tr ' ' 'a')
    echo "$long_message" > /tmp/test_long_msg
    run_test "Very long commit message" "bash '$hook_file' /tmp/test_long_msg" "pass"
    
    # Test message with special characters
    echo "feat: add feature with special chars !@#$%^&*()_+-=[]{}|;:,.<>?" > /tmp/test_special_msg
    run_test "Message with special characters" "bash '$hook_file' /tmp/test_special_msg" "pass"
    
    # Test message with unicode
    echo "feat: add feature with unicode 🚀 ✅ 📝" > /tmp/test_unicode_msg
    run_test "Message with unicode characters" "bash '$hook_file' /tmp/test_unicode_msg" "pass"
    
    # Test multiline message
    cat > /tmp/test_multiline_msg << 'EOF'
feat: add comprehensive user authentication system

This commit adds a complete user authentication system with the following features:
- Login and logout functionality
- Password reset capability
- Session management
- Security improvements

Closes #123
EOF
    
    run_test "Multiline commit message" "bash '$hook_file' /tmp/test_multiline_msg" "pass"
    
    rm -f /tmp/test_long_msg /tmp/test_special_msg /tmp/test_unicode_msg /tmp/test_multiline_msg
    echo ""
}

# Test 7: Error output quality
test_error_output() {
    print_header "Error Output Quality Tests"
    
    local hook_file=".husky/commit-msg"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Hook file not found - skipping error output tests"
        return 1
    fi
    
    print_info "Testing error output for short message..."
    echo "x" > /tmp/test_short_msg
    local error_output=$(bash "$hook_file" /tmp/test_short_msg 2>&1)
    
    if echo "$error_output" | grep -q "too short"; then
        print_status "Error output contains helpful message for short commits"
        ((TESTS_PASSED++))
    else
        print_error "Error output lacks helpful message for short commits"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
    
    print_info "Testing error output for missing file..."
    local missing_error=$(bash "$hook_file" /tmp/non_existent_file 2>&1)
    
    if echo "$missing_error" | grep -q "does not exist"; then
        print_status "Error output contains helpful message for missing file"
        ((TESTS_PASSED++))
    else
        print_error "Error output lacks helpful message for missing file"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
    
    rm -f /tmp/test_short_msg
    echo ""
}

# Generate test report
generate_test_report() {
    print_header "Test Results Summary"
    
    echo "📊 Tests Run: $TESTS_TOTAL"
    echo "✅ Tests Passed: $TESTS_PASSED"
    echo "❌ Tests Failed: $TESTS_FAILED"
    
    local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    echo "📈 Success Rate: $success_rate%"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo ""
        print_status "🎉 All tests passed! Commit-msg hook is working correctly."
        echo ""
        echo "✅ Your commit-msg hook is properly configured and functional"
        echo "✅ The hook correctly validates commit messages"
        echo "✅ Git integration is working properly"
        echo ""
        echo "🚀 Try it out:"
        echo "  git commit -m 'feat: add new feature'"
        echo "  git commit -m 'x'  # This should fail"
        return 0
    else
        echo ""
        print_error "❌ Some tests failed. Issues remain with your commit-msg hook."
        echo ""
        echo "🔧 Recommended actions:"
        echo "  1. Review the failed tests above"
        echo "  2. Run: ./tools/fix-commit-msg-hook.sh"
        echo "  3. Run this test again: ./tools/test-commit-msg-hook.sh"
        echo ""
        return 1
    fi
}

# Main test function
main_test() {
    echo "Starting comprehensive commit-msg hook tests..."
    echo ""
    
    test_basic_checks
    test_message_validation
    test_parameter_handling
    test_git_comments
    test_git_integration
    test_edge_cases
    test_error_output
    
    generate_test_report
}

# Run the tests
main_test
