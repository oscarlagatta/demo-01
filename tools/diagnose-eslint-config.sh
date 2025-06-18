#!/bin/bash

echo "🔍 Diagnosing ESLint Configuration Issues"
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
mkdir -p reports/eslint-config-diagnosis

print_header "Step 1: Locating ESLint Configuration Files"

# Find all possible ESLint config files
config_files=()
for config in .eslintrc.js .eslintrc.json .eslintrc.yml .eslintrc.yaml eslint.config.js eslint.config.mjs package.json; do
    if [ -f "$config" ]; then
        if [ "$config" = "package.json" ]; then
            if grep -q "eslintConfig" "$config"; then
                config_files+=("$config (eslintConfig section)")
            fi
        else
            config_files+=("$config")
        fi
    fi
done

if [ ${#config_files[@]} -eq 0 ]; then
    print_error "No ESLint configuration files found!"
    exit 1
else
    print_status "Found ESLint configuration files:"
    for config in "${config_files[@]}"; do
        echo "  - $config"
    done
fi

print_header "Step 2: Analyzing Configuration Content"

# Function to analyze configuration file
analyze_config() {
    local config_file="$1"
    echo "Analyzing $config_file..."
    
    case "$config_file" in
        *.json)
            if command -v jq >/dev/null 2>&1; then
                echo "  Plugins: $(jq -r '.plugins[]? // empty' "$config_file" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')"
                echo "  Extends: $(jq -r '.extends[]? // empty' "$config_file" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')"
                echo "  Parser: $(jq -r '.parser // "not specified"' "$config_file" 2>/dev/null)"
                
                # Check for simple-import-sort rules
                simple_import_rules=$(jq -r '.rules | to_entries[] | select(.key | contains("simple-import-sort")) | "\(.key): \(.value)"' "$config_file" 2>/dev/null)
                if [ -n "$simple_import_rules" ]; then
                    echo "  Simple Import Sort Rules:"
                    echo "$simple_import_rules" | sed 's/^/    /'
                else
                    print_warning "  No simple-import-sort rules found"
                fi
                
                # Check for TypeScript rules
                ts_rules=$(jq -r '.rules | to_entries[] | select(.key | contains("@typescript-eslint")) | "\(.key): \(.value)"' "$config_file" 2>/dev/null)
                if [ -n "$ts_rules" ]; then
                    echo "  TypeScript ESLint Rules (first 5):"
                    echo "$ts_rules" | head -5 | sed 's/^/    /'
                else
                    print_warning "  No @typescript-eslint rules found"
                fi
            else
                print_warning "jq not available - manual inspection needed"
                echo "  Content preview:"
                head -20 "$config_file" | sed 's/^/    /'
            fi
            ;;
        *.js|*.mjs)
            echo "  JavaScript config file detected"
            echo "  Content preview:"
            head -30 "$config_file" | sed 's/^/    /'
            ;;
        *package.json*)
            if command -v jq >/dev/null 2>&1; then
                echo "  ESLint config in package.json:"
                jq '.eslintConfig' package.json 2>/dev/null | sed 's/^/    /'
            fi
            ;;
    esac
    echo ""
}

# Analyze each configuration file
for config in "${config_files[@]}"; do
    config_file=$(echo "$config" | cut -d' ' -f1)
    analyze_config "$config_file"
done

print_header "Step 3: Testing Plugin Detection"

# Create test files for validation
test_ts_file="test-config-validation.ts"
test_js_file="test-config-validation.js"

# Create TypeScript test file
cat > "$test_ts_file" << 'EOF'
// Test file for TypeScript ESLint validation
import { z } from 'zod';
import React, { useState } from 'react';
import { readFileSync } from 'fs';
import path from 'path';
import { Component } from './local-component';
import { API_URL } from '../config/constants';

interface TestInterface {
    prop: any; // Should trigger @typescript-eslint/no-explicit-any
}

function testFunction(param: string): any { // Should trigger explicit return type and no-explicit-any
    const unusedVariable = 'test'; // Should trigger @typescript-eslint/no-unused-vars
    return param;
}

const TestComponent: React.FC = () => {
    const [count, setCount] = useState(0);
    return <div>{count}</div>;
};

export default TestComponent;
EOF

# Create JavaScript test file
cat > "$test_js_file" << 'EOF'
// Test file for simple-import-sort validation
import { z } from 'zod';
import React, { useState } from 'react';
import { readFileSync } from 'fs';
import path from 'path';
import { Component } from './local-component';
import { API_URL } from '../config/constants';

const TestComponent = () => {
    const [count, setCount] = useState(0);
    return React.createElement('div', null, count);
};

export default TestComponent;
EOF

print_info "Testing simple-import-sort plugin..."

# Test simple-import-sort
if npx eslint "$test_js_file" --format=json > reports/eslint-config-diagnosis/simple-import-test.json 2>&1; then
    if command -v jq >/dev/null 2>&1; then
        import_violations=$(jq '[.[].messages[] | select(.ruleId == "simple-import-sort/imports")] | length' reports/eslint-config-diagnosis/simple-import-test.json 2>/dev/null)
        if [ "$import_violations" -gt 0 ]; then
            print_status "simple-import-sort is working ($import_violations violations detected)"
        else
            print_warning "simple-import-sort may not be configured (no violations detected)"
        fi
    else
        print_info "jq not available - check reports/eslint-config-diagnosis/simple-import-test.json manually"
    fi
else
    print_error "ESLint failed on JavaScript test file"
    cat reports/eslint-config-diagnosis/simple-import-test.json
fi

print_info "Testing typescript-eslint plugin..."

# Test TypeScript ESLint
if npx eslint "$test_ts_file" --format=json > reports/eslint-config-diagnosis/typescript-test.json 2>&1; then
    if command -v jq >/dev/null 2>&1; then
        ts_violations=$(jq '[.[].messages[] | select(.ruleId | contains("@typescript-eslint"))] | length' reports/eslint-config-diagnosis/typescript-test.json 2>/dev/null)
        if [ "$ts_violations" -gt 0 ]; then
            print_status "typescript-eslint is working ($ts_violations violations detected)"
            echo "  Sample violations:"
            jq -r '.[].messages[] | select(.ruleId | contains("@typescript-eslint")) | "    \(.ruleId): \(.message)"' reports/eslint-config-diagnosis/typescript-test.json 2>/dev/null | head -3
        else
            print_warning "typescript-eslint may not be configured (no violations detected)"
        fi
    else
        print_info "jq not available - check reports/eslint-config-diagnosis/typescript-test.json manually"
    fi
else
    print_error "ESLint failed on TypeScript test file"
    cat reports/eslint-config-diagnosis/typescript-test.json
fi

print_header "Step 4: Configuration Resolution Analysis"

# Get resolved configuration for both file types
print_info "Analyzing resolved configuration for TypeScript files..."
if npx eslint --print-config "$test_ts_file" > reports/eslint-config-diagnosis/resolved-config-ts.json 2>&1; then
    if command -v jq >/dev/null 2>&1; then
        echo "  Parser: $(jq -r '.parser' reports/eslint-config-diagnosis/resolved-config-ts.json)"
        echo "  Plugins: $(jq -r '.plugins[]?' reports/eslint-config-diagnosis/resolved-config-ts.json | tr '\n' ', ' | sed 's/,$//')"
        echo "  TypeScript rules count: $(jq '[.rules | to_entries[] | select(.key | contains("@typescript-eslint"))] | length' reports/eslint-config-diagnosis/resolved-config-ts.json)"
        echo "  Simple import sort rules: $(jq '[.rules | to_entries[] | select(.key | contains("simple-import-sort"))] | length' reports/eslint-config-diagnosis/resolved-config-ts.json)"
    fi
else
    print_error "Failed to resolve TypeScript configuration"
fi

print_info "Analyzing resolved configuration for JavaScript files..."
if npx eslint --print-config "$test_js_file" > reports/eslint-config-diagnosis/resolved-config-js.json 2>&1; then
    if command -v jq >/dev/null 2>&1; then
        echo "  Parser: $(jq -r '.parser' reports/eslint-config-diagnosis/resolved-config-js.json)"
        echo "  Plugins: $(jq -r '.plugins[]?' reports/eslint-config-diagnosis/resolved-config-js.json | tr '\n' ', ' | sed 's/,$//')"
        echo "  Simple import sort rules: $(jq '[.rules | to_entries[] | select(.key | contains("simple-import-sort"))] | length' reports/eslint-config-diagnosis/resolved-config-js.json)"
    fi
else
    print_error "Failed to resolve JavaScript configuration"
fi

# Clean up test files
rm -f "$test_ts_file" "$test_js_file"

print_header "Step 5: Diagnosis Summary"

# Generate diagnosis report
{
    echo "# ESLint Configuration Diagnosis Report"
    echo ""
    echo "**Generated:** $(date)"
    echo ""
    echo "## Configuration Files Found"
    for config in "${config_files[@]}"; do
        echo "- $config"
    done
    echo ""
    echo "## Plugin Status"
    echo ""
    if [ -f "reports/eslint-config-diagnosis/simple-import-test.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            import_violations=$(jq '[.[].messages[] | select(.ruleId == "simple-import-sort/imports")] | length' reports/eslint-config-diagnosis/simple-import-test.json 2>/dev/null)
            if [ "$import_violations" -gt 0 ]; then
                echo "- ✅ **simple-import-sort**: Working ($import_violations violations detected)"
            else
                echo "- ⚠️ **simple-import-sort**: May need configuration"
            fi
        fi
    fi
    
    if [ -f "reports/eslint-config-diagnosis/typescript-test.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            ts_violations=$(jq '[.[].messages[] | select(.ruleId | contains("@typescript-eslint"))] | length' reports/eslint-config-diagnosis/typescript-test.json 2>/dev/null)
            if [ "$ts_violations" -gt 0 ]; then
                echo "- ✅ **typescript-eslint**: Working ($ts_violations violations detected)"
            else
                echo "- ⚠️ **typescript-eslint**: May need configuration"
            fi
        fi
    fi
    
    echo ""
    echo "## Recommendations"
    echo ""
    echo "1. Review the configuration files listed above"
    echo "2. Check the resolved configuration files in reports/eslint-config-diagnosis/"
    echo "3. Run the configuration fix script if issues are found"
    echo "4. Test the configuration with real project files"
    
} > reports/eslint-config-diagnosis/diagnosis-report.md

print_status "Diagnosis complete! Check reports/eslint-config-diagnosis/ for detailed results."
echo ""
echo "📋 Next steps:"
echo "1. Review the diagnosis report: reports/eslint-config-diagnosis/diagnosis-report.md"
echo "2. If issues found, run: ./tools/fix-eslint-config.sh"
echo "3. Validate fixes with: ./tools/validate-eslint-config.sh"
