#!/bin/bash

echo "🔍 ESLint Plugin Discovery and Inventory"
echo "========================================"

# Colors for output
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

# Create output directory
mkdir -p reports/eslint-verification

print_header "Discovering ESLint Configuration"

# Find all ESLint config files
echo "📁 ESLint configuration files:"
config_files=$(find . -maxdepth 3 -name ".eslintrc*" -o -name "eslint.config.*" 2>/dev/null | head -10)
if [ -n "$config_files" ]; then
    echo "$config_files"
else
    print_warning "No ESLint configuration files found"
fi

# Extract plugins from configuration
print_info "Extracting plugin information..."

# Function to extract plugins from different config formats
extract_plugins() {
    local config_file="$1"
    local format="$2"
    
    case $format in
        "json")
            if command -v jq >/dev/null 2>&1; then
                jq -r '.plugins[]? // empty' "$config_file" 2>/dev/null
                jq -r '.extends[]? // empty' "$config_file" 2>/dev/null | grep -o '[^/]*$'
            else
                print_warning "jq not available - skipping JSON config parsing"
            fi
            ;;
        "js")
            grep -o "plugin:[^,]*" "$config_file" 2>/dev/null | cut -d: -f2 | tr -d "'" | tr -d '"' | tr -d ' '
            grep -o "extends:.*\[" -A 20 "$config_file" 2>/dev/null | grep -o "'[^']*'" | tr -d "'"
            ;;
        "yaml"|"yml")
            if command -v yq >/dev/null 2>&1; then
                yq eval '.plugins[]' "$config_file" 2>/dev/null
                yq eval '.extends[]' "$config_file" 2>/dev/null
            else
                print_warning "yq not available - skipping YAML config parsing"
            fi
            ;;
    esac
}

# Discover all plugins
{
    echo "# ESLint Plugin Inventory"
    echo "Generated on: $(date)"
    echo ""
    echo "## Configured Plugins"
    echo ""
    
    # Check different config file types
    for config in .eslintrc.json .eslintrc.js .eslintrc.yml .eslintrc.yaml eslint.config.js eslint.config.mjs; do
        if [ -f "$config" ]; then
            echo "### From $config"
            case "$config" in
                *.json) extract_plugins "$config" "json" ;;
                *.js|*.mjs) extract_plugins "$config" "js" ;;
                *.yml|*.yaml) extract_plugins "$config" "yaml" ;;
            esac
            echo ""
        fi
    done
} > reports/eslint-verification/plugin-inventory.md

print_status "Plugin inventory saved to reports/eslint-verification/plugin-inventory.md"

print_header "Installed ESLint Packages"

# Check installed ESLint-related packages with better error handling
if npm list --depth=0 2>/dev/null | grep -E "(eslint|@typescript-eslint)" > reports/eslint-verification/installed-packages.txt; then
    echo "📦 Installed ESLint packages:"
    cat reports/eslint-verification/installed-packages.txt
else
    print_warning "Could not retrieve package list or no ESLint packages found"
    echo "Attempting alternative package detection..."
    
    # Alternative method using package.json
    if [ -f "package.json" ]; then
        echo "📦 ESLint packages from package.json:"
        if command -v jq >/dev/null 2>&1; then
            {
                jq -r '.devDependencies | to_entries[] | select(.key | contains("eslint")) | "\(.key)@\(.value)"' package.json 2>/dev/null
                jq -r '.dependencies | to_entries[] | select(.key | contains("eslint")) | "\(.key)@\(.value)"' package.json 2>/dev/null
            } | tee reports/eslint-verification/installed-packages.txt
        else
            grep -E '".*eslint.*"' package.json | tee reports/eslint-verification/installed-packages.txt
        fi
    fi
fi

print_header "Plugin Status Check"

# Function to check if a package is installed
check_package_installed() {
    local package_name="$1"
    local display_name="${2:-$package_name}"
    
    # Try multiple methods to check if package is installed
    if npm list "$package_name" >/dev/null 2>&1; then
        print_status "$display_name is installed"
        return 0
    elif [ -f "package.json" ] && grep -q "\"$package_name\"" package.json; then
        print_status "$display_name is installed (found in package.json)"
        return 0
    elif [ -d "node_modules/$package_name" ]; then
        print_status "$display_name is installed (found in node_modules)"
        return 0
    else
        print_warning "$display_name is not installed"
        return 1
    fi
}

# Common plugins to check - using exact package names
echo "🔌 Checking common plugin installations:"

# Define plugins with their exact package names and display names
declare -A plugin_map=(
    ["eslint-plugin-simple-import-sort"]="simple-import-sort"
    ["typescript-eslint"]="typescript-eslint (unified package)"
    ["eslint-plugin-react"]="eslint-plugin-react"
    ["eslint-plugin-react-hooks"]="eslint-plugin-react-hooks"
    ["eslint-plugin-import"]="eslint-plugin-import"
    ["eslint-plugin-jsx-a11y"]="eslint-plugin-jsx-a11y"
    ["eslint-plugin-unused-imports"]="eslint-plugin-unused-imports"
    ["eslint-plugin-tailwindcss"]="eslint-plugin-tailwindcss"
    ["eslint-plugin-cypress"]="eslint-plugin-cypress"
    ["eslint-plugin-playwright"]="eslint-plugin-playwright"
    # Optional plugins (comment out if not needed)
    # ["eslint-plugin-prettier"]="eslint-plugin-prettier"
    # ["eslint-plugin-prefer-arrow"]="eslint-plugin-prefer-arrow"
)

installed_count=0
total_count=${#plugin_map[@]}

for package_name in "${!plugin_map[@]}"; do
    display_name="${plugin_map[$package_name]}"
    if check_package_installed "$package_name" "$display_name"; then
        ((installed_count++))
    fi
done

echo ""
print_info "Plugin installation summary: $installed_count/$total_count plugins installed"

print_header "ESLint Configuration Validation"

# Create a test file for ESLint configuration validation
test_file="eslint-config-test.js"
cat > "$test_file" << 'EOF'
// Test file for ESLint configuration validation
import React from 'react';
import { useState } from 'react';

const TestComponent = () => {
  const [count, setCount] = useState(0);
  const unusedVariable = 'test';
  
  return <div>{count}</div>;
};

export default TestComponent;
EOF

# Validate ESLint configuration using the test file
print_info "Validating ESLint configuration..."

if npx eslint --print-config "$test_file" >/dev/null 2>&1; then
    print_status "ESLint configuration is valid"
    
    # Save resolved configuration
    npx eslint --print-config "$test_file" > reports/eslint-verification/resolved-config.json 2>/dev/null
    
    # Extract and display key configuration info
    if [ -f "reports/eslint-verification/resolved-config.json" ] && command -v jq >/dev/null 2>&1; then
        echo ""
        print_info "Configuration summary:"
        echo "  Parser: $(jq -r '.parser // "default"' reports/eslint-verification/resolved-config.json)"
        echo "  Plugins: $(jq -r '.plugins[]? // empty' reports/eslint-verification/resolved-config.json | tr '\n' ' ')"
        echo "  Rules count: $(jq '.rules | length' reports/eslint-verification/resolved-config.json)"
        echo "  Environment: $(jq -r '.env | keys[]? // empty' reports/eslint-verification/resolved-config.json | tr '\n' ' ')"
    fi
    
    # Test ESLint execution on the test file
    print_info "Testing ESLint execution..."
    if npx eslint "$test_file" --format=json > reports/eslint-verification/test-lint-results.json 2>&1; then
        print_status "ESLint execution successful"
        
        if command -v jq >/dev/null 2>&1; then
            error_count=$(jq '.[0].errorCount // 0' reports/eslint-verification/test-lint-results.json 2>/dev/null)
            warning_count=$(jq '.[0].warningCount // 0' reports/eslint-verification/test-lint-results.json 2>/dev/null)
            echo "  Errors: $error_count, Warnings: $warning_count"
        fi
    else
        print_warning "ESLint execution had issues"
        cat reports/eslint-verification/test-lint-results.json
    fi
    
else
    print_error "ESLint configuration has errors"
    echo "Attempting to get configuration error details..."
    npx eslint --print-config "$test_file" 2>&1 | tee reports/eslint-verification/config-errors.txt
fi

# Clean up test file
rm -f "$test_file"

print_header "Plugin Functionality Test"

# Test specific plugin functionality
print_info "Testing plugin functionality..."

# Test simple-import-sort
if check_package_installed "eslint-plugin-simple-import-sort" >/dev/null 2>&1; then
    cat > test-imports.js << 'EOF'
import { z } from 'zod';
import React from 'react';
import fs from 'fs';
import { localFunction } from './local';
EOF
    
    if npx eslint test-imports.js --format=json 2>/dev/null | jq -e '.[0].messages[] | select(.ruleId == "simple-import-sort/imports")' >/dev/null 2>&1; then
        print_status "simple-import-sort plugin is working"
    else
        print_warning "simple-import-sort plugin may not be configured properly"
    fi
    
    rm -f test-imports.js
fi

# Test TypeScript ESLint
if check_package_installed "@typescript-eslint/eslint-plugin" >/dev/null 2>&1 || check_package_installed "typescript-eslint" >/dev/null 2>&1; then
    cat > test-typescript.ts << 'EOF'
function testFunction(param: any): any {
    const unusedVariable = 'test';
    return param;
}
EOF
    
    if npx eslint test-typescript.ts --format=json 2>/dev/null | jq -e '.[0].messages[] | select(.ruleId | contains("@typescript-eslint"))' >/dev/null 2>&1; then
        print_status "TypeScript ESLint plugin is working"
    else
        print_warning "TypeScript ESLint plugin may not be configured properly"
    fi
    
    rm -f test-typescript.ts
fi

echo ""
echo "📊 Discovery complete! Check reports/eslint-verification/ for detailed results."

# Generate summary report
{
    echo "# ESLint Plugin Discovery Summary"
    echo ""
    echo "**Generated:** $(date)"
    echo "**Plugins Installed:** $installed_count/$total_count"
    echo ""
    echo "## Status"
    if [ -f "reports/eslint-verification/resolved-config.json" ]; then
        echo "- ✅ ESLint configuration is valid"
    else
        echo "- ❌ ESLint configuration has issues"
    fi
    echo "- 📦 Total plugins checked: $total_count"
    echo "- ✅ Plugins installed: $installed_count"
    echo "- ⚠️ Plugins missing: $((total_count - installed_count))"
    echo ""
    echo "## Next Steps"
    if [ $installed_count -lt $total_count ]; then
        echo "1. Review missing plugins and install if needed"
        echo "2. Update ESLint configuration to use installed plugins"
        echo "3. Test plugin functionality"
    else
        echo "1. Verify plugin configurations are correct"
        echo "2. Test plugin functionality in your codebase"
        echo "3. Consider running the comprehensive verification framework"
    fi
} > reports/eslint-verification/discovery-summary.md

print_status "Summary report saved to reports/eslint-verification/discovery-summary.md"
