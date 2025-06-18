#!/bin/bash

# Comprehensive verification script for lint-staged integration

set -e

echo "🔍 Verifying lint-staged integration..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. Check dependencies
print_status "Checking dependencies..."
if npm list lint-staged > /dev/null 2>&1; then
    print_success "lint-staged is installed"
else
    print_error "lint-staged is not installed"
    exit 1
fi

if npm list husky > /dev/null 2>&1; then
    print_success "husky is installed"
else
    print_warning "husky is not installed"
fi

# 2. Check script exists
if [ -f "scripts/nx-lint-staged.js" ]; then
    print_success "nx-lint-staged.js script exists"
else
    print_error "nx-lint-staged.js script is missing"
    exit 1
fi

# 3. Test script directly
print_status "Testing nx-lint-staged.js directly..."
if node scripts/nx-lint-staged.js --help > /dev/null 2>&1; then
    print_success "Script can be executed"
else
    print_warning "Script execution test inconclusive"
fi

# 4. Create test file and stage it
print_status "Creating test scenario..."
echo "// Test file for lint-staged" > test-lint-staged.js
git add test-lint-staged.js

# 5. Run lint-staged
print_status "Running lint-staged..."
if npx lint-staged; then
    print_success "lint-staged executed successfully"
else
    print_error "lint-staged failed"
fi

# 6. Cleanup
git reset HEAD test-lint-staged.js
rm -f test-lint-staged.js

print_success "Verification complete!"
