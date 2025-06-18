#!/bin/bash

echo "🔍 Verifying simple-import-sort Plugin"
echo "======================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Create test directory
mkdir -p test-files/simple-import-sort
cd test-files/simple-import-sort

# Test 1: Import sorting functionality
print_info "Test 1: Creating file with unsorted imports..."

cat > unsorted-imports.ts << 'EOF'
// This file has intentionally unsorted imports
import { z } from 'zod';
import React, { useState } from 'react';
import { readFileSync } from 'fs';
import path from 'path';
import { Component } from './local-component';
import { API_URL } from '../config/constants';
import axios from 'axios';

// Some code to make imports meaningful
const MyComponent: React.FC = () => {
  const [data, setData] = useState('');
  return <div>{data}</div>;
};
EOF

print_info "Test 2: Running ESLint to check for violations..."

# Run ESLint and capture output
eslint_output=$(npx eslint unsorted-imports.ts --format=json 2>/dev/null)

# Check if simple-import-sort violations were found
violations=$(echo "$eslint_output" | jq -r '.[0].messages[]? | select(.ruleId == "simple-import-sort/imports") | .ruleId' 2>/dev/null)

if [ -n "$violations" ]; then
    print_status "simple-import-sort/imports rule is active and detecting violations"
else
    print_error "simple-import-sort/imports rule is not detecting violations"
    echo "ESLint output:"
    echo "$eslint_output" | jq '.' 2>/dev/null || echo "$eslint_output"
fi

print_info "Test 3: Testing auto-fix functionality..."

# Create a copy for auto-fix testing
cp unsorted-imports.ts unsorted-imports-fix.ts

# Run ESLint with --fix
npx eslint unsorted-imports-fix.ts --fix >/dev/null 2>&1

# Check if file was modified (imports were sorted)
if ! diff unsorted-imports.ts unsorted-imports-fix.ts >/dev/null 2>&1; then
    print_status "Auto-fix is working - imports were sorted"
    print_info "Showing the difference:"
    echo "Before:"
    head -10 unsorted-imports.ts | grep "^import"
    echo ""
    echo "After:"
    head -10 unsorted-imports-fix.ts | grep "^import"
else
    print_warning "Auto-fix may not be working or imports were already sorted"
fi

# Test 4: Export sorting
print_info "Test 4: Testing export sorting..."

cat > unsorted-exports.ts << 'EOF'
export { z } from 'zod';
export { Component } from './local-component';
export { readFileSync } from 'fs';
export { API_URL } from '../config/constants';
export { default as React } from 'react';
EOF

# Check export sorting violations
export_violations=$(npx eslint unsorted-exports.ts --format=json 2>/dev/null | jq -r '.[0].messages[]? | select(.ruleId == "simple-import-sort/exports") | .ruleId' 2>/dev/null)

if [ -n "$export_violations" ]; then
    print_status "simple-import-sort/exports rule is active"
else
    print_warning "simple-import-sort/exports rule may not be configured or active"
fi

# Test 5: Configuration verification
print_info "Test 5: Verifying plugin configuration..."

# Check if plugin is in ESLint config
config_check=$(npx eslint --print-config . 2>/dev/null | jq -r '.plugins[]? | select(. == "simple-import-sort")' 2>/dev/null)

if [ -n "$config_check" ]; then
    print_status "simple-import-sort plugin is properly configured"
else
    print_error "simple-import-sort plugin may not be configured"
fi

# Check specific rules configuration
rules_config=$(npx eslint --print-config . 2>/dev/null | jq -r '.rules["simple-import-sort/imports"]' 2>/dev/null)

print_info "Rule configuration: simple-import-sort/imports = $rules_config"

# Cleanup
cd ../..
rm -rf test-files/simple-import-sort

echo ""
print_info "simple-import-sort verification completed"
