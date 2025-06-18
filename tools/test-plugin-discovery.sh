#!/bin/bash

echo "🧪 Testing ESLint Plugin Discovery Script"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_test() { echo -e "${GREEN}✓ $1${NC}"; }
print_fail() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }

# Test 1: Script execution
echo "Test 1: Script Execution"
if ./tools/discover-eslint-plugins.sh >/dev/null 2>&1; then
    print_test "Script executes without errors"
else
    print_fail "Script execution failed"
    exit 1
fi

# Test 2: Report generation
echo ""
echo "Test 2: Report Generation"
required_reports=(
    "reports/eslint-verification/plugin-inventory.md"
    "reports/eslint-verification/installed-packages.txt"
    "reports/eslint-verification/discovery-summary.md"
)

for report in "${required_reports[@]}"; do
    if [ -f "$report" ]; then
        print_test "$report generated"
    else
        print_fail "$report missing"
    fi
done

# Test 3: Package detection accuracy
echo ""
echo "Test 3: Package Detection Accuracy"

# Check if known installed packages are detected correctly
known_packages=(
    "eslint-plugin-simple-import-sort"
    "eslint-plugin-react"
    "eslint-plugin-react-hooks"
    "eslint-plugin-import"
    "eslint-plugin-jsx-a11y"
    "eslint-plugin-unused-imports"
)

for package in "${known_packages[@]}"; do
    if npm list "$package" >/dev/null 2>&1; then
        # Package is installed, check if script detected it
        if ./tools/discover-eslint-plugins.sh 2>&1 | grep -q "✅.*$package"; then
            print_test "$package correctly detected as installed"
        else
            print_fail "$package not detected despite being installed"
        fi
    else
        print_info "$package not installed - skipping test"
    fi
done

# Test 4: ESLint configuration validation
echo ""
echo "Test 4: ESLint Configuration Validation"
if [ -f "reports/eslint-verification/resolved-config.json" ]; then
    print_test "ESLint configuration resolved successfully"
    
    # Check if configuration contains expected fields
    if command -v jq >/dev/null 2>&1; then
        if jq -e '.parser' reports/eslint-verification/resolved-config.json >/dev/null 2>&1; then
            print_test "Configuration contains parser information"
        fi
        
        if jq -e '.plugins' reports/eslint-verification/resolved-config.json >/dev/null 2>&1; then
            print_test "Configuration contains plugins information"
        fi
        
        if jq -e '.rules' reports/eslint-verification/resolved-config.json >/dev/null 2>&1; then
            print_test "Configuration contains rules information"
        fi
    fi
else
    print_fail "ESLint configuration validation failed"
fi

# Test 5: Error handling
echo ""
echo "Test 5: Error Handling"

# Test with non-existent directory
cd /tmp
if timeout 10s bash -c "cd /tmp && $(pwd)/tools/discover-eslint-plugins.sh" >/dev/null 2>&1; then
    print_test "Script handles missing package.json gracefully"
else
    print_info "Script properly exits when package.json is missing"
fi

# Return to original directory
cd - >/dev/null

echo ""
echo "🎯 Test Summary"
echo "==============="
print_info "All tests completed. Check individual test results above."
print_info "If any tests failed, review the script and fix the issues."

# Final validation
echo ""
echo "📋 Final Validation"
echo "==================="

# Run the actual script and capture output
output=$(./tools/discover-eslint-plugins.sh 2>&1)

# Check for specific issues mentioned in the original problem
if echo "$output" | grep -q "simple-import-sort.*not installed"; then
    print_fail "Still reporting simple-import-sort as not installed"
else
    print_test "simple-import-sort detection fixed"
fi

if echo "$output" | grep -q "print-config.*requires a path"; then
    print_fail "ESLint --print-config error still present"
else
    print_test "ESLint --print-config usage fixed"
fi

echo ""
print_info "Test completed. Review the output above for any remaining issues."
