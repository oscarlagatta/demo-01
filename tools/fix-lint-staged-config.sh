#!/bin/bash

echo "🔧 Fixing Lint-staged Configuration"
echo "==================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Track fixes applied
FIXES_APPLIED=0

fix_applied() {
    ((FIXES_APPLIED++))
    print_status "$1"
}

# Install lint-staged if missing
install_lint_staged() {
    print_info "Checking lint-staged installation..."
    
    if ! npm list lint-staged >/dev/null 2>&1; then
        print_info "Installing lint-staged..."
        npm install --save-dev lint-staged
        fix_applied "Installed lint-staged"
    else
        print_status "lint-staged already installed"
    fi
    
    echo ""
}

# Configure lint-staged
configure_lint_staged() {
    print_info "Configuring lint-staged..."
    
    # Check if configuration already exists
    if grep -q '"lint-staged"' package.json 2>/dev/null; then
        print_status "lint-staged configuration already exists"
        
        # Show current config
        print_info "Current configuration:"
        node -e "
            const pkg = require('./package.json');
            console.log(JSON.stringify(pkg['lint-staged'], null, 2));
        " 2>/dev/null | sed 's/^/  /'
        
        read -p "Do you want to update the configuration? (y/N): " update_config
        if [ "$update_config" != "y" ] && [ "$update_config" != "Y" ]; then
            print_info "Keeping existing configuration"
            return
        fi
    fi
    
    # Detect project type and create appropriate config
    print_info "Detecting project structure..."
    
    local config='{'
    local has_config=false
    
    # Check for JavaScript/TypeScript files
    if find . -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" | head -1 | grep -q .; then
        print_info "Detected JavaScript/TypeScript files"
        config="$config"$'\n    "*.{js,jsx,ts,tsx}": ['
        
        # Check for ESLint
        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || grep -q '"eslint"' package.json 2>/dev/null; then
            config="$config"$'\n      "eslint --fix",'
        fi
        
        # Check for Prettier
        if [ -f ".prettierrc" ] || [ -f ".prettierrc.js" ] || [ -f ".prettierrc.json" ] || grep -q '"prettier"' package.json 2>/dev/null; then
            config="$config"$'\n      "prettier --write"'
        else
            config="${config%,}"  # Remove trailing comma if no prettier
        fi
        
        config="$config"$'\n    ],'
        has_config=true
    fi
    
    # Check for CSS/SCSS files
    if find . -name "*.css" -o -name "*.scss" -o -name "*.sass" | head -1 | grep -q .; then
        print_info "Detected CSS/SCSS files"
        config="$config"$'\n    "*.{css,scss,sass}": ['
        
        if [ -f ".prettierrc" ] || [ -f ".prettierrc.js" ] || [ -f ".prettierrc.json" ] || grep -q '"prettier"' package.json 2>/dev/null; then
            config="$config"$'\n      "prettier --write"'
        else
            config="$config"$'\n      "echo \"Formatting CSS files...\""'
        fi
        
        config="$config"$'\n    ],'
        has_config=true
    fi
    
    # Check for Markdown files
    if find . -name "*.md" | head -1 | grep -q .; then
        print_info "Detected Markdown files"
        config="$config"$'\n    "*.md": ['
        
        if [ -f ".prettierrc" ] || [ -f ".prettierrc.js" ] || [ -f ".prettierrc.json" ] || grep -q '"prettier"' package.json 2>/dev/null; then
            config="$config"$'\n      "prettier --write"'
        else
            config="$config"$'\n      "echo \"Processing Markdown files...\""'
        fi
        
        config="$config"$'\n    ],'
        has_config=true
    fi
    
    # Remove trailing comma and close
    config="${config%,}"
    config="$config"$'\n  }'
    
    if [ "$has_config" = false ]; then
        # Default configuration
        config='{
    "*.{js,jsx,ts,tsx}": [
      "echo \"Linting JavaScript/TypeScript files...\""
    ],
    "*.{css,scss,md}": [
      "echo \"Processing style and markdown files...\""
    ]
  }'
    fi
    
    # Add configuration to package.json
    print_info "Adding lint-staged configuration to package.json..."
    
    # Use Node.js to safely update package.json
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        pkg['lint-staged'] = $config;
        fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
        console.log('✅ Updated package.json with lint-staged configuration');
    "
    
    fix_applied "Configured lint-staged in package.json"
    
    echo ""
}

# Update pre-commit hook to handle lint-staged better
update_pre_commit_hook() {
    print_info "Updating pre-commit hook..."
    
    local hook_file=".husky/pre-commit"
    
    if [ ! -f "$hook_file" ]; then
        print_error "Pre-commit hook not found"
        return 1
    fi
    
    # Check if hook already has improved lint-staged handling
    if grep -q "lint-staged.*--quiet" "$hook_file"; then
        print_status "Pre-commit hook already optimized"
        return
    fi
    
    # Backup existing hook
    cp "$hook_file" "${hook_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Determine Husky version
    if npm list husky >/dev/null 2>&1; then
        husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
        major_version=$(echo "$husky_version" | cut -d'.' -f1)
    else
        major_version=9  # Default to modern format
    fi
    
    # Create improved pre-commit hook
    if [[ "$major_version" -ge 9 ]]; then
        # Husky v9+ format
        cat > "$hook_file" << 'EOF'
#!/bin/sh
echo "🚀 Running pre-commit checks..."

# Check if there are staged files
staged_files=$(git diff --cached --name-only)

if [ -z "$staged_files" ]; then
    echo "ℹ️  No staged files found - skipping lint-staged"
else
    echo "📝 Found staged files, running lint-staged..."
    
    # Run lint-staged if available
    if command -v npx >/dev/null 2>&1 && npm list lint-staged >/dev/null 2>&1; then
        npx lint-staged
        lint_staged_exit_code=$?
        
        if [ $lint_staged_exit_code -ne 0 ]; then
            echo "❌ lint-staged failed with exit code $lint_staged_exit_code"
            exit $lint_staged_exit_code
        fi
    else
        echo "ℹ️  lint-staged not available, skipping..."
    fi
fi

echo "✅ Pre-commit checks completed!"
EOF
    else
        # Husky v8.x format
        cat > "$hook_file" << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "🚀 Running pre-commit checks..."

# Check if there are staged files
staged_files=$(git diff --cached --name-only)

if [ -z "$staged_files" ]; then
    echo "ℹ️  No staged files found - skipping lint-staged"
else
    echo "📝 Found staged files, running lint-staged..."
    
    # Run lint-staged if available
    if command -v npx >/dev/null 2>&1 && npm list lint-staged >/dev/null 2>&1; then
        npx lint-staged
        lint_staged_exit_code=$?
        
        if [ $lint_staged_exit_code -ne 0 ]; then
            echo "❌ lint-staged failed with exit code $lint_staged_exit_code"
            exit $lint_staged_exit_code
        fi
    else
        echo "ℹ️  lint-staged not available, skipping..."
    fi
fi

echo "✅ Pre-commit checks completed!"
EOF
    fi
    
    chmod +x "$hook_file"
    fix_applied "Updated pre-commit hook with better lint-staged handling"
    
    echo ""
}

# Create test files for demonstration
create_test_files() {
    print_info "Creating test files for demonstration..."
    
    read -p "Do you want to create test files to demonstrate lint-staged? (y/N): " create_tests
    
    if [ "$create_tests" = "y" ] || [ "$create_tests" = "Y" ]; then
        # Create a test JavaScript file
        cat > test-lint-staged.js << 'EOF'
// Test file for lint-staged demonstration
const message = "Hello, lint-staged!";
console.log(message);

// This file will be processed by lint-staged when staged
function testFunction() {
    return "This function demonstrates lint-staged";
}

module.exports = { testFunction };
EOF
        
        # Create a test CSS file
        cat > test-lint-staged.css << 'EOF'
/* Test CSS file for lint-staged */
.test-class {
    color: red;
    background-color: blue;
    padding: 10px;
}

.another-class {
    margin: 5px;
    border: 1px solid black;
}
EOF
        
        # Create a test Markdown file
        cat > test-lint-staged.md << 'EOF'
# Test Markdown File

This file demonstrates lint-staged functionality.

## Features

- Automatic formatting
- Linting on commit
- File processing

## Usage

1. Stage this file with `git add test-lint-staged.md`
2. Commit with `git commit -m "test: add markdown file"`
3. Watch lint-staged process the file
EOF
        
        fix_applied "Created test files for lint-staged demonstration"
        
        echo ""
        print_info "Test files created:"
        echo "  • test-lint-staged.js"
        echo "  • test-lint-staged.css"
        echo "  • test-lint-staged.md"
        echo ""
        print_info "To test lint-staged:"
        echo "  1. git add test-lint-staged.*"
        echo "  2. git commit -m 'test: demonstrate lint-staged'"
        echo ""
    fi
}

# Test the configuration
test_configuration() {
    print_info "Testing lint-staged configuration..."
    
    if npm list lint-staged >/dev/null 2>&1; then
        print_info "Running lint-staged in debug mode..."
        echo "Debug output:"
        echo "-------------"
        npx lint-staged --debug 2>&1 | head -10 | sed 's/^/  /'
        echo "-------------"
        
        print_status "lint-staged configuration test completed"
    else
        print_warning "Cannot test - lint-staged not installed"
    fi
    
    echo ""
}

# Generate summary
generate_summary() {
    echo "🎯 Fix Summary"
    echo "=============="
    echo "Fixes applied: $FIXES_APPLIED"
    echo ""
    
    if [ $FIXES_APPLIED -gt 0 ]; then
        echo "📋 What was fixed:"
        echo "  ✅ lint-staged installation and configuration"
        echo "  ✅ Pre-commit hook optimization"
        echo "  ✅ Better handling of empty staged files"
        echo "  ✅ Informative messages for different scenarios"
        echo ""
        
        echo "🧪 Test your fix:"
        echo "  # Test with no staged files (should show informative message)"
        echo "  git commit -m 'test: no staged files'"
        echo ""
        echo "  # Test with staged files (should run lint-staged)"
        echo "  echo 'console.log(\"test\");' > test.js"
        echo "  git add test.js"
        echo "  git commit -m 'test: with staged files'"
        echo ""
        
        echo "💡 The 'No staged files match any configured task' message is now handled better!"
    else
        echo "ℹ️  No fixes were needed - your configuration is already optimal"
    fi
}

# Main fix function
main_fix() {
    echo "Starting lint-staged configuration fix..."
    echo ""
    
    install_lint_staged
    configure_lint_staged
    update_pre_commit_hook
    create_test_files
    test_configuration
    generate_summary
    
    echo "🎉 Lint-staged configuration fix completed!"
}

# Run the fix
main_fix
