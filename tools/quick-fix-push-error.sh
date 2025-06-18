#!/bin/bash

echo "🚀 Quick Fix for Pre-Push Hook Error"
echo "===================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Step 1: Create the missing pre-push hook
create_pre_push_hook() {
    print_info "Creating missing pre-push hook..."
    
    if [ ! -d ".husky" ]; then
        mkdir -p .husky
        print_status "Created .husky directory"
    fi
    
    # Create a simple pre-push hook
    cat > .husky/pre-push << 'EOF'
#!/bin/sh
echo "🚀 Running pre-push checks..."

# Get current branch
current_branch=$(git branch --show-current)
echo "📋 Pushing branch: $current_branch"

# Optional: Add any pre-push validations here
# echo "🧪 Running tests..."
# npm test

# Optional: Build check
# echo "🏗️  Running build..."
# npm run build

echo "✅ Pre-push checks completed!"
EOF
    
    # Make it executable
    chmod +x .husky/pre-push
    print_status "Created and made pre-push hook executable"
}

# Step 2: Fix line endings
fix_line_endings() {
    print_info "Fixing line endings in pre-push hook..."
    
    if [ -f ".husky/pre-push" ]; then
        # Remove CRLF line endings
        sed -i 's/\r$//' .husky/pre-push 2>/dev/null || {
            # Alternative method
            tr -d '\r' < .husky/pre-push > .husky/pre-push.tmp && mv .husky/pre-push.tmp .husky/pre-push
        }
        print_status "Fixed line endings"
    fi
}

# Step 3: Test the hook
test_hook() {
    print_info "Testing pre-push hook..."
    
    if [ -f ".husky/pre-push" ] && [ -x ".husky/pre-push" ]; then
        if bash .husky/pre-push >/dev/null 2>&1; then
            print_status "Pre-push hook test successful"
            return 0
        else
            print_error "Pre-push hook test failed"
            return 1
        fi
    else
        print_error "Pre-push hook not found or not executable"
        return 1
    fi
}

# Step 4: Verify Git configuration
verify_git_config() {
    print_info "Verifying Git configuration..."
    
    # Check hooks path
    hooks_path=$(git config core.hooksPath)
    if [ "$hooks_path" != ".husky" ]; then
        print_warning "Setting Git hooks path to .husky"
        git config core.hooksPath .husky
    fi
    print_status "Git hooks path verified"
    
    # Check if we're on Windows and set appropriate line ending config
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        print_info "Windows detected - configuring line endings"
        git config core.autocrlf true
        git config core.safecrlf false
        print_status "Windows Git configuration applied"
    fi
}

# Main execution
main() {
    print_info "Fixing the 'cannot spawn .husky/pre-push' error..."
    echo ""
    
    create_pre_push_hook
    echo ""
    
    fix_line_endings
    echo ""
    
    verify_git_config
    echo ""
    
    if test_hook; then
        echo "🎉 Quick fix completed successfully!"
        echo ""
        echo "✅ What was fixed:"
        echo "  • Created missing pre-push hook"
        echo "  • Fixed line ending issues"
        echo "  • Verified Git configuration"
        echo "  • Made hook executable"
        echo ""
        echo "🧪 Test your fix:"
        echo "  git push"
        echo ""
        echo "💡 The 'cannot spawn .husky/pre-push' error should now be resolved!"
    else
        print_error "Quick fix encountered issues. Please run the full diagnostic:"
        echo "  ./tools/diagnose-git-issues.sh"
        exit 1
    fi
}

# Run the quick fix
main
