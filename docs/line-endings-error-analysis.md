# Line Endings Error Analysis and Fix

## Problem Description

The error `fix-windows-line-endings.sh: line 200: return: true: numeric argument required` occurs because bash `return` statements expect numeric exit codes (0-255), but the script was attempting to return boolean variables containing string values.

## Root Cause Analysis

### The Problematic Code

The original issue was in the `test_hooks_windows()` function around line 200:

\`\`\`bash
# PROBLEMATIC CODE (Original)
test_hooks_windows() {
    # ... function logic ...
    local test_passed=true  # This creates a string variable
    
    # ... more logic that might set test_passed=false ...
    
    return $test_passed  # ERROR: Tries to return "true" or "false" as exit code
}
\`\`\`

### Why This Fails

1. **Bash Return Codes**: The `return` statement in bash functions expects a numeric value between 0-255
   - `0` = success/true
   - `1-255` = failure/false (with different error codes)

2. **Variable Expansion**: When `$test_passed` contains "true", bash tries to use "true" as a numeric exit code, which fails

3. **String vs Numeric**: Bash cannot convert the string "true" to a numeric exit code automatically

## The Fix

### Corrected Approach

\`\`\`bash
# CORRECTED CODE
test_hooks_windows() {
    print_info "Testing hooks execution on Windows..."
    
    local tests_passed=0    # Use numeric counters
    local tests_total=0
    
    for hook in pre-commit commit-msg pre-push; do
        if [ -f ".husky/$hook" ]; then
            ((tests_total++))
            print_info "Testing $hook..."
            
            # Test execution and count successes
            if bash ".husky/$hook" >/dev/null 2>&1; then
                print_status "$hook executes successfully"
                ((tests_passed++))
            else
                print_error "$hook failed to execute"
            fi
            
            # Test line endings and count successes
            if command -v file >/dev/null 2>&1; then
                if file ".husky/$hook" 2>/dev/null | grep -q "CRLF"; then
                    print_warning "$hook still has CRLF line endings"
                else
                    print_status "$hook has correct LF line endings"
                    ((tests_passed++))
                fi
            else
                ((tests_passed++))  # Assume success if 'file' not available
            fi
        fi
    done
    
    # Return numeric exit code based on results
    if [ $tests_passed -eq $((tests_total * 2)) ]; then
        return 0  # All tests passed
    else
        return 1  # Some tests failed
    fi
}
\`\`\`

### Key Changes Made

1. **Numeric Counters**: Replaced boolean variables with numeric counters
   - `tests_passed=0` instead of `test_passed=true`
   - `tests_total=0` to track total tests

2. **Proper Return Codes**: Always return numeric values
   - `return 0` for success
   - `return 1` for failure
   - `return 2` for partial success (where applicable)

3. **Conditional Logic**: Use proper conditional checks
   \`\`\`bash
   # Instead of: if [ "$test_passed" = true ]; then
   # Use: if [ $tests_passed -eq $tests_total ]; then
   \`\`\`

## Testing the Fix

### Step 1: Reproduce the Error

To reproduce the original error:

\`\`\`bash
# Create a script with the problematic code
cat > test_error.sh << 'EOF'
#!/bin/bash
test_function() {
    local test_passed=true
    return $test_passed  # This will fail
}
test_function
EOF

# Run it - you'll see the error
bash test_error.sh
\`\`\`

### Step 2: Verify the Fix

\`\`\`bash
# Make the corrected script executable
chmod +x tools/fix-windows-line-endings-corrected.sh

# Run the test suite
chmod +x tools/test-line-endings-fix.sh
./tools/test-line-endings-fix.sh
\`\`\`

### Step 3: Test in Git Hook Environment

\`\`\`bash
# Test the actual Git hooks
git add .
git commit -m "test: verify line endings fix"
git push
\`\`\`

## Prevention Strategies

### 1. Always Use Numeric Return Codes

\`\`\`bash
# GOOD
function_name() {
    if some_condition; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# BAD
function_name() {
    local success=true
    return $success  # Will fail if success contains "true"
}
\`\`\`

### 2. Use Proper Boolean Logic

\`\`\`bash
# GOOD - Convert boolean to numeric
function_name() {
    local success=true
    
    if [ "$success" = true ]; then
        return 0
    else
        return 1
    fi
}

# BETTER - Use numeric from start
function_name() {
    local success=0  # 0 = success, 1 = failure
    
    # ... logic that sets success=1 on failure ...
    
    return $success
}
\`\`\`

### 3. Validate Return Statements

Before using `return $variable`, ensure the variable contains a valid numeric value:

\`\`\`bash
function_name() {
    local exit_code=0
    
    # Validate exit code is numeric
    if [[ "$exit_code" =~ ^[0-9]+$ ]] && [ "$exit_code" -le 255 ]; then
        return $exit_code
    else
        return 1  # Default to failure if invalid
    fi
}
\`\`\`

## Side Effects and Mitigation

### Potential Side Effects

1. **Changed Function Behavior**: Functions now return different exit codes
   - **Mitigation**: Update all callers to handle numeric return codes properly

2. **Script Logic Changes**: Boolean logic converted to numeric comparisons
   - **Mitigation**: Thoroughly test all conditional statements

3. **Error Handling**: Different error codes might affect error handling
   - **Mitigation**: Document the new return code meanings

### Mitigation Strategies

1. **Comprehensive Testing**: Run the test suite to verify all functionality
2. **Gradual Rollout**: Test in development environment before production
3. **Documentation**: Update comments to reflect new return code meanings
4. **Monitoring**: Watch for any unexpected behavior after deployment

## Verification Checklist

- [ ] Script runs without "numeric argument required" errors
- [ ] All Git hooks execute properly
- [ ] Line endings are handled correctly
- [ ] Return codes are properly numeric (0-255)
- [ ] Boolean logic converted to numeric comparisons
- [ ] Test suite passes all checks
- [ ] Git operations (commit, push) work without errors
- [ ] No regression in existing functionality

## Conclusion

The fix addresses the root cause by:
1. Replacing string boolean variables with numeric counters
2. Ensuring all `return` statements use valid numeric exit codes
3. Converting boolean logic to numeric comparisons
4. Maintaining the original script functionality

This approach is more robust and follows bash best practices for function return codes.
\`\`\`

Finally, let's create a quick verification script:
