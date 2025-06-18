#!/bin/bash

echo "🔍 Package Installation Verification"
echo "===================================="

# Function to check package installation using multiple methods
verify_package() {
    local package_name="$1"
    local methods_passed=0
    local total_methods=4
    
    echo "Checking: $package_name"
    
    # Method 1: npm list
    if npm list "$package_name" >/dev/null 2>&1; then
        echo "  ✅ Found via 'npm list'"
        ((methods_passed++))
    else
        echo "  ❌ Not found via 'npm list'"
    fi
    
    # Method 2: package.json check
    if [ -f "package.json" ] && grep -q "\"$package_name\"" package.json; then
        echo "  ✅ Found in package.json"
        ((methods_passed++))
    else
        echo "  ❌ Not found in package.json"
    fi
    
    # Method 3: node_modules check
    if [ -d "node_modules/$package_name" ]; then
        echo "  ✅ Found in node_modules"
        ((methods_passed++))
    else
        echo "  ❌ Not found in node_modules"
    fi
    
    # Method 4: require check (for Node.js packages)
    if node -e "require('$package_name')" >/dev/null 2>&1; then
        echo "  ✅ Can be required"
        ((methods_passed++))
    else
        echo "  ❌ Cannot be required"
    fi
    
    echo "  📊 Verification score: $methods_passed/$total_methods"
    echo ""
    
    return $((total_methods - methods_passed))
}

# Verify the packages mentioned in the issue
packages_to_verify=(
    "eslint-plugin-simple-import-sort"
    "eslint-plugin-prettier"
    "eslint-plugin-prefer-arrow"
    "eslint-plugin-react"
    "eslint-plugin-react-hooks"
    "@typescript-eslint/eslint-plugin"
    "typescript-eslint"
)

echo "Verifying packages mentioned in the issue:"
echo ""

total_issues=0
for package in "${packages_to_verify[@]}"; do
    verify_package "$package"
    total_issues=$((total_issues + $?))
done

echo "Summary:"
echo "========"
if [ $total_issues -eq 0 ]; then
    echo "✅ All packages verified successfully"
else
    echo "⚠️  Some packages have verification issues"
    echo "   This may indicate installation problems or the packages may not be installed"
fi

# Additional check: Show what's actually in package.json
echo ""
echo "📦 ESLint-related packages in package.json:"
echo "============================================"

if [ -f "package.json" ] && command -v jq >/dev/null 2>&1; then
    echo "DevDependencies:"
    jq -r '.devDependencies | to_entries[] | select(.key | contains("eslint")) | "  \(.key): \(.value)"' package.json
    echo ""
    echo "Dependencies:"
    jq -r '.dependencies | to_entries[] | select(.key | contains("eslint")) | "  \(.key): \(.value)"' package.json
else
    echo "Using grep fallback:"
    grep -E '".*eslint.*"' package.json | sed 's/^[[:space:]]*/  /'
fi
