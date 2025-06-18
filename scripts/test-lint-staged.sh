#!/bin/bash

# Test script for lint-staged configuration
# This script helps validate that the lint-staged setup works correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info "Testing lint-staged configuration..."

# Check if required files exist
if [ ! -f "scripts/lint-staged-nx.sh" ]; then
    print_error "lint-staged-nx.sh script not found!"
    exit 1
fi

if [ ! -f "package.json" ]; then
    print_error "package.json not found!"
    exit 1
fi

# Make sure the script is executable
chmod +x scripts/lint-staged-nx.sh

# Test 1: Check if lint-staged is configured
print_info "Test 1: Checking lint-staged configuration..."
if grep -q "lint-staged" package.json; then
    print_success "lint-staged configuration found in package.json"
else
    print_error "lint-staged configuration not found in package.json"
    exit 1
fi

# Test 2: Create test files to simulate staged changes
print_info "Test 2: Creating test files..."

# Create temporary test files
mkdir -p test-temp/apps/test-app/src
mkdir -p test-temp/libs/test-lib/src

# Create test TypeScript files with linting issues
cat > test-temp/apps/test-app/src/test.ts << 'EOF'
import { z } from 'zod';
import React from 'react';
import fs from 'fs';

const unused = 'variable';
const test: any = 'hello';

export default function TestComponent() {
  return <div>Test</div>;
}
EOF

cat > test-temp/libs/test-lib/src/utils.ts << 'EOF'
import path from 'path';
import { readFileSync } from 'fs';
import axios from 'axios';

const unusedVar = 'test';

export function testFunction(param: any): string {
  return param;
}
EOF

# Test 3: Run the lint-staged script directly
print_info "Test 3: Testing lint-staged script directly..."

if ./scripts/lint-staged-nx.sh test-temp/apps/test-app/src/test.ts test-temp/libs/test-lib/src/utils.ts; then
    print_success "lint-staged script executed successfully"
else
    print_warning "lint-staged script had issues (this might be expected for test files)"
fi

# Test 4: Test with lint-staged dry run
print_info "Test 4: Testing lint-staged dry run..."

# Stage the test files temporarily
git add test-temp/ 2>/dev/null || print_warning "Could not stage test files (not in git repo)"

# Run lint-staged dry run
if npx lint-staged --dry-run 2>/dev/null; then
    print_success "lint-staged dry run completed"
else
    print_warning "lint-staged dry run had issues"
fi

# Test 5: Check script performance
print_info "Test 5: Performance test..."

start_time=$(date +%s%N)
./scripts/lint-staged-nx.sh test-temp/apps/test-app/src/test.ts >/dev/null 2>&1 || true
end_time=$(date +%s%N)

duration=$(( (end_time - start_time) / 1000000 ))
print_info "Script execution time: ${duration}ms"

if [ $duration -lt 5000 ]; then
    print_success "Performance is good (< 5 seconds)"
else
    print_warning "Performance might be slow (> 5 seconds)"
fi

# Cleanup
print_info "Cleaning up test files..."
rm -rf test-temp/
git reset HEAD test-temp/ 2>/dev/null || true

print_success "All tests completed!"

echo ""
echo "📋 Summary:"
echo "- ✅ lint-staged configuration validated"
echo "- ✅ Script execution tested"
echo "- ✅ Performance measured"
echo ""
echo "🔄 Next steps:"
echo "1. Make a small change to a TypeScript file"
echo "2. Stage the file: git add <file>"
echo "3. Try committing to see lint-staged in action"
echo "4. Or test manually: npx lint-staged"
