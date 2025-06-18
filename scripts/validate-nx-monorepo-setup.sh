#!/bin/bash

# Validation script for Nx monorepo lint-staged setup
set -e

echo "🔍 Validating Nx Monorepo Setup..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check 1: Nx workspace
echo "1. Checking Nx workspace..."
if [ -f "nx.json" ]; then
    print_success "nx.json found"
    if command -v nx &> /dev/null; then
        print_success "nx command available"
        nx --version
    else
        print_error "nx command not found"
        exit 1
    fi
else
    print_error "nx.json not found - not in Nx workspace"
    exit 1
fi

# Check 2: Projects with lint targets
echo -e "\n2. Checking projects with lint targets..."
if nx show projects --with-target=lint > /dev/null 2>&1; then
    LINT_PROJECTS=$(nx show projects --with-target=lint)
    PROJECT_COUNT=$(echo "$LINT_PROJECTS" | wc -l)
    print_success "Found $PROJECT_COUNT projects with lint targets"
    echo "$LINT_PROJECTS" | head -5
    if [ $PROJECT_COUNT -gt 5 ]; then
        echo "   ... and $(($PROJECT_COUNT - 5)) more"
    fi
else
    print_warning "Could not retrieve projects with lint targets"
fi

# Check 3: Affected command
echo -e "\n3. Testing affected command..."
if nx affected --target=lint --dry-run > /dev/null 2>&1; then
    print_success "nx affected --target=lint works"
else
    print_warning "nx affected --target=lint may have issues"
fi

# Check 4: Lint-staged configuration
echo -e "\n4. Checking lint-staged configuration..."
if [ -f "package.json" ]; then
    if grep -q "lint-staged" package.json; then
        print_success "lint-staged configuration found"
        if grep -q "nx-monorepo-lint-staged.js" package.json; then
            print_success "Using Nx monorepo-specific script"
        else
            print_warning "Not using Nx monorepo-specific script"
        fi
    else
        print_error "lint-staged configuration not found"
    fi
else
    print_error "package.json not found"
fi

# Check 5: Husky setup
echo -e "\n5. Checking Husky setup..."
if [ -d ".husky" ]; then
    print_success ".husky directory found"
    if [ -f ".husky/pre-commit" ]; then
        print_success "pre-commit hook exists"
    else
        print_warning "pre-commit hook not found"
    fi
else
    print_warning ".husky directory not found"
fi

print_info "Validation complete!"
echo -e "\n📋 Next steps:"
echo "   1. Run: npm run lint:staged:test"
echo "   2. Stage some files and test: git add . && npm run lint:staged"
echo "   3. Test full commit workflow"
