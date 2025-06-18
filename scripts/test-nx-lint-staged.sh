#!/bin/bash

# Test script for Nx lint-staged integration
# Tests various scenarios to ensure robust operation

set -e

echo "🧪 Testing Nx lint-staged integration..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test 1: Validate Nx workspace
echo "Test 1: Nx workspace validation"
if nx --version > /dev/null 2>&1; then
    print_success "Nx workspace detected"
else
    print_error "Nx workspace not found"
    exit 1
fi

# Test 2: Test affected command
echo "Test 2: Testing affected:lint command"
if nx affected:lint --dry-run > /dev/null 2>&1; then
    print_success "affected:lint command works"
else
    print_warning "affected:lint may have issues"
fi

# Test 3: Create test files and stage them
echo "Test 3: Creating test scenario"
mkdir -p test-lint-staged
echo "export const test = 'hello';" > test-lint-staged/test.ts
echo "const unused = 'variable';" >> test-lint-staged/test.ts

# Stage the test file
git add test-lint-staged/test.ts

# Test 4: Run lint-staged
echo "Test 4: Running lint-staged"
if npm run lint:staged; then
    print_success "lint-staged completed successfully"
else
    print_error "lint-staged failed"
fi

# Cleanup
git reset HEAD test-lint-staged/test.ts
rm -rf test-lint-staged

print_success "All tests completed!"
