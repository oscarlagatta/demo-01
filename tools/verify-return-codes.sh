#!/bin/bash

echo "🔍 Verifying Return Codes in Scripts"
echo "===================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check for problematic return statements
check_return_statements() {
    echo "Checking for problematic return statements..."
    
    local issues_found=0
    
    # Find all shell scripts
    find . -name "*.sh" -type f | while read -r script; do
        echo "Checking: $script"
        
        # Look for return statements with variables that might contain strings
        if grep -n "return \$[a-zA-Z_][a-zA-Z0-9_]*" "$script" 2>/dev/null; then
            echo "  Found potential return statement issues in $script"
            ((issues_found++))
        fi
        
        # Look for boolean variables being returned
        if grep -n "return.*true\|return.*false" "$script" 2>/dev/null; then
            echo "  Found boolean return values in $script"
            ((issues_found++))
        fi
    done
    
    if [ $issues_found -eq 0 ]; then
        print_status "No problematic return statements found"
    else
        print_warning "Found $issues_found potential issues"
    fi
}

# Test function return codes
test_function_returns() {
    echo ""
    echo "Testing function return codes..."
    
    # Create a test script
    cat > /tmp/test_returns.sh << 'EOF'
#!/bin/bash

# Test function with proper numeric returns
good_function() {
    local success=0
    return $success
}

# Test function with boolean conversion
boolean_function() {
    local test_passed=true
    if [ "$test_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# Test the functions
echo "Testing good_function..."
if good_function; then
    echo "✅ good_function returned: $?"
else
    echo "❌ good_function returned: $?"
fi

echo "Testing boolean_function..."
if boolean_function; then
    echo "✅ boolean_function returned: $?"
else
    echo "❌ boolean_function returned: $?"
fi
EOF
    
    if bash /tmp/test_returns.sh; then
        print_status "Function return code tests passed"
    else
        print_error "Function return code tests failed"
    fi
    
    rm -f /tmp/test_returns.sh
}

# Main verification
main() {
    check_return_statements
    test_function_returns
    
    echo ""
    echo "🎯 Verification complete!"
    echo ""
    echo "💡 Remember:"
    echo "  • Always use numeric return codes (0-255)"
    echo "  • 0 = success, 1-255 = failure"
    echo "  • Convert boolean variables before returning"
    echo "  • Test all functions after changes"
}

main
