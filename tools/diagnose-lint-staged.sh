#!/bin/bash

echo "🔍 Lint-staged Configuration Diagnostic"
echo "======================================="

# Colors
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

# Check lint-staged installation
check_lint_staged_installation() {
    print_header "Lint-staged Installation Check"
    
    if npm list lint-staged >/dev/null 2>&1; then
        lint_staged_version=$(npm list lint-staged --depth=0 2>/dev/null | grep -o 'lint-staged@[0-9.]*' | cut -d'@' -f2)
        print_status "lint-staged is installed (version: $lint_staged_version)"
    else
        print_warning "lint-staged is not installed"
        echo "  This is why you're seeing 'No staged files match any configured task'"
        return 1
    fi
    
    echo ""
}

# Check lint-staged configuration
check_lint_staged_config() {
    print_header "Lint-staged Configuration Check"
    
    # Check package.json for lint-staged config
    if [ -f "package.json" ]; then
        if grep -q '"lint-staged"' package.json; then
            print_status "lint-staged configuration found in package.json"
            echo ""
            print_info "Current configuration:"
            echo "----------------------"
            # Extract lint-staged config from package.json
            node -e "
                const pkg = require('./package.json');
                if (pkg['lint-staged']) {
                    console.log(JSON.stringify(pkg['lint-staged'], null, 2));
                } else {
                    console.log('No lint-staged configuration found');
                }
            " 2>/dev/null || echo "Could not parse lint-staged config"
            echo "----------------------"
        else
            print_warning "No lint-staged configuration found in package.json"
        fi
    else
        print_error "package.json not found"
        return 1
    fi
    
    # Check for separate config files
    local config_files=(".lintstagedrc" ".lintstagedrc.json" ".lintstagedrc.js" "lint-staged.config.js")
    
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            print_status "Found separate config file: $config_file"
            echo "Content:"
            head -20 "$config_file" | sed 's/^/  /'
        fi
    done
    
    echo ""
}

# Check staged files
check_staged_files() {
    print_header "Staged Files Analysis"
    
    # Get staged files
    staged_files=$(git diff --cached --name-only)
    
    if [ -z "$staged_files" ]; then
        print_warning "No files are currently staged"
        echo "  This is why lint-staged says 'No staged files match any configured task'"
        echo ""
        print_info "To test lint-staged properly:"
        echo "  1. Make changes to some files"
        echo "  2. Stage them with 'git add <files>'"
        echo "  3. Then run 'git commit'"
    else
        print_status "Staged files found:"
        echo "$staged_files" | sed 's/^/  /'
        
        echo ""
        print_info "File extensions in staged files:"
        echo "$staged_files" | sed 's/.*\.//' | sort | uniq -c | sed 's/^/  /'
    fi
    
    echo ""
}

# Check pre-commit hook
check_pre_commit_hook() {
    print_header "Pre-commit Hook Analysis"
    
    if [ -f ".husky/pre-commit" ]; then
        print_status "Pre-commit hook exists"
        echo ""
        print_info "Hook content:"
        echo "-------------"
        cat .husky/pre-commit | sed 's/^/  /'
        echo "-------------"
        
        # Check if it calls lint-staged
        if grep -q "lint-staged" .husky/pre-commit; then
            print_status "Hook calls lint-staged"
        else
            print_warning "Hook does not call lint-staged"
        fi
    else
        print_error "Pre-commit hook not found"
    fi
    
    echo ""
}

# Simulate lint-staged execution
simulate_lint_staged() {
    print_header "Lint-staged Simulation"
    
    if ! npm list lint-staged >/dev/null 2>&1; then
        print_warning "Cannot simulate - lint-staged not installed"
        return 1
    fi
    
    print_info "Simulating lint-staged execution..."
    
    # Run lint-staged in debug mode
    if command -v npx >/dev/null 2>&1; then
        echo "Debug output:"
        echo "-------------"
        npx lint-staged --debug 2>&1 | head -20 | sed 's/^/  /'
        echo "-------------"
    fi
    
    echo ""
}

# Provide recommendations
provide_recommendations() {
    print_header "Recommendations"
    
    echo "🎯 Understanding the Message:"
    echo "  'No staged files match any configured task' means:"
    echo "  • lint-staged is working correctly"
    echo "  • No staged files match the patterns in your config"
    echo "  • This is NORMAL when committing without staged files"
    echo ""
    
    echo "🔧 Solutions:"
    echo ""
    
    # Check if lint-staged is installed
    if ! npm list lint-staged >/dev/null 2>&1; then
        echo "1. Install lint-staged:"
        echo "   npm install --save-dev lint-staged"
        echo ""
    fi
    
    # Check if config exists
    if ! grep -q '"lint-staged"' package.json 2>/dev/null; then
        echo "2. Add lint-staged configuration to package.json:"
        echo '   "lint-staged": {'
        echo '     "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],'
        echo '     "*.{css,scss,md}": ["prettier --write"]'
        echo '   }'
        echo ""
    fi
    
    echo "3. Test with actual staged files:"
    echo "   echo 'console.log(\"test\");' > test.js"
    echo "   git add test.js"
    echo "   git commit -m 'test: add test file'"
    echo ""
    
    echo "4. Or modify pre-commit hook to be less verbose:"
    echo "   Edit .husky/pre-commit to suppress the message"
    echo ""
    
    echo "💡 The commit is working fine - this is just an informational message!"
}

# Main diagnostic function
main_diagnostic() {
    echo "Analyzing why you're seeing 'No staged files match any configured task'..."
    echo ""
    
    check_lint_staged_installation
    check_lint_staged_config
    check_staged_files
    check_pre_commit_hook
    simulate_lint_staged
    provide_recommendations
    
    echo "🎯 Diagnostic complete!"
}

# Run the diagnostic
main_diagnostic
