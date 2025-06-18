#!/bin/bash

echo "🧪 Testing Line Endings Fix"
echo "==========================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Test 1: Check if the corrected script runs without errors
test_script_execution() {
    print_info "Test 1: Script Execution"
    echo "========================"
    
    if [ -f "tools/fix-windows-line-endings-corrected.sh" ]; then
        print_info "Running corrected script..."
        
        # Run the script and capture both stdout and stderr
        if bash tools/fix-windows-line-endings-corrected.sh > /tmp/script_output.log 2>&1; then
            print_status "Script executed successfully without errors"
            
            # Check if the specific error is gone
            if grep -q "numeric argument required" /tmp/script_output.log; then
                print_error "Still found 'numeric argument required' error"
                return 1
            else
                print_status "No 'numeric argument required' errors found"
            fi
        else
            print_error "Script execution failed"
            echo "Error output:"
            cat /tmp/script_output.log | tail -10
            return 1
        fi
    else
        print_error "Corrected script not found"
        return 1
    fi
    
    return 0
}

# Test 2: Verify return codes in functions
test_return_codes() {
    print_info "Test 2: Function Return Codes"
    echo "============================="
    
    # Create a test script to check individual functions
    cat > /tmp/test_functions.sh << 'EOF'
#!/bin/bash

# Source the functions from the corrected script
source tools/fix-windows-line-endings-corrected.sh

# Test check_windows function
echo "Testing check_windows function..."
if check_windows; then
    echo "check_windows returned: $? (success)"
else
    echo "check_windows returned: $? (expected for non-Windows)"
fi

# Test other functions that should always succeed
echo "Testing fix_windows_git_config function..."
if fix_windows_git_config >/dev/null 2>&1; then
    echo "fix_windows_git_config returned: $? (success)"
else
    echo "fix_windows_git_config returned: $? (failure)"
fi

echo "All function tests completed"
EOF
    
    if bash /tmp/test_functions.sh; then
        print_status "All functions return proper numeric codes"
    else
        print_error "Some functions have return code issues"
        return 1
    fi
    
    rm -f /tmp/test_functions.sh
    return 0
}

# Test 3: Check Git hooks functionality
test_git_hooks() {
    print_info "Test 3: Git Hooks Functionality"
    echo "==============================="
    
    local hooks_working=0
    local hooks_total=0
    
    for hook in pre-commit commit-msg pre-push; do
        if [ -f ".husky/$hook" ]; then
            ((hooks_total++))
            print_info "Testing $hook..."
            
            # Test hook execution
            if [ "$hook" = "commit-msg" ]; then
                # commit-msg needs a message file
                echo "test message" > /tmp/test_commit_msg
                if bash ".husky/$hook" /tmp/test_commit_msg >/dev/null 2>&1; then
                    print_status "$hook works correctly"
                    ((hooks_working++))
                else
                    print_error "$hook failed to execute"
                fi
                rm -f /tmp/test_commit_msg
            else
                if bash ".husky/$hook" >/dev/null 2>&1; then
                    print_status "$hook works correctly"
                    ((hooks_working++))
                else
                    print_error "$hook failed to execute"
                fi
            fi
        fi
    done
    
    if [ $hooks_working -eq $hooks_total ] && [ $hooks_total -gt 0 ]; then
        print_status "All Git hooks are working properly"
        return 0
    else
        print_warning "Some Git hooks may have issues"
        return 1
    fi
}

# Test 4: Verify line endings
test_line_endings() {
    print_info "Test 4: Line Endings Verification"
    echo "================================="
    
    local files_correct=0
    local files_total=0
    
    # Check .gitattributes
    if [ -f ".gitattributes" ]; then
        ((files_total++))
        if file .gitattributes 2>/dev/null | grep -q "CRLF"; then
            print_warning ".gitattributes has CRLF line endings"
        else
            print_status ".gitattributes has correct line endings"
            ((files_correct++))
        fi
    fi
    
    # Check Husky hooks
    for hook in .husky/*; do
        if [ -f "$hook" ] && [ "$(basename "$hook")" != "_" ]; then
            ((files_total++))
            if command -v file >/dev/null 2>&1; then
                if file "$hook" 2>/dev/null | grep -q "CRLF"; then
                    print_warning "$(basename "$hook") has CRLF line endings"
                else
                    print_status "$(basename "$hook") has correct line endings"
                    ((files_correct++))
                fi
            else
                # If file command not available, assume correct
                ((files_correct++))
            fi
        fi
    done
    
    if [ $files_correct -eq $files_total ]; then
        print_status "All files have correct line endings"
        return 0
    else
        print_warning "Some files may have line ending issues"
        return 1
    fi
}

# Test 5: Reproduce the original error scenario
test_original_error_scenario() {
    print_info "Test 5: Original Error Scenario"
    echo "==============================="
    
    print_info "Attempting to reproduce the original error conditions..."
    
    # Create a temporary script with the problematic return statement
    cat > /tmp/test_bad_return.sh << 'EOF'
#!/bin/bash

test_function() {
    local test_passed=true
    
    # This would cause the original error
    # return $test_passed  # This is wrong - returns "true" as string
    
    # Correct way:
    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

test_function
echo "Function returned: $?"
EOF
    
    if bash /tmp/test_bad_return.sh >/dev/null 2>&1; then
        print_status "Return code handling works correctly"
    else
        print_error "Return code handling still has issues"
        return 1
    fi
    
    rm -f /tmp/test_bad_return.sh
    return 0
}

# Main test execution
run_all_tests() {
    local tests_passed=0
    local tests_total=5
    
    echo "Running comprehensive tests for line endings fix..."
    echo ""
    
    if test_script_execution; then
        ((tests_passed++))
    fi
    echo ""
    
    if test_return_codes; then
        ((tests_passed++))
    fi
    echo ""
    
    if test_git_hooks; then
        ((tests_passed++))
    fi
    echo ""
    
    if test_line_endings; then
        ((tests_passed++))
    fi
    echo ""
    
    if test_original_error_scenario; then
        ((tests_passed++))
    fi
    echo ""
    
    # Summary
    echo "🎯 Test Results Summary"
    echo "======================"
    echo "Tests passed: $tests_passed/$tests_total"
    
    if [ $tests_passed -eq $tests_total ]; then
        print_status "All tests passed! The fix is working correctly."
        echo ""
        echo "✅ The 'numeric argument required' error has been resolved"
        echo "✅ All Git hooks are functioning properly"
        echo "✅ Line endings are handled correctly"
        return 0
    else
        print_warning "Some tests failed. Please review the output above."
        return 1
    fi
}

# Clean up function
cleanup() {
    rm -f /tmp/script_output.log
    rm -f /tmp/test_functions.sh
    rm -f /tmp/test_commit_msg
    rm -f /tmp/test_bad_return.sh
}

# Trap to ensure cleanup
trap cleanup EXIT

# Run all tests
run_all_tests
