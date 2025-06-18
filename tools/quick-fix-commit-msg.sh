#!/bin/bash

echo "⚡ Quick Fix for Commit-msg Hook"
echo "==============================="

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

# Quick fix steps
quick_fix() {
    print_info "Applying quick fix for commit-msg hook..."
    
    # Ensure .husky directory exists
    if [ ! -d ".husky" ]; then
        mkdir -p .husky
        print_status "Created .husky directory"
    fi
    
    # Create a simple, working commit-msg hook
    cat > .husky/commit-msg << 'EOF'
#!/bin/sh
echo "📝 Validating commit message..."

# Check if commit message file is provided
if [ -z "$1" ]; then
    echo "❌ Error: No commit message file provided"
    exit 1
fi

# Check if commit message file exists
if [ ! -f "$1" ]; then
    echo "❌ Error: Commit message file does not exist: $1"
    exit 1
fi

# Read the commit message (first non-comment line)
commit_msg=$(grep -v '^#' "$1" | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

# Check if message is empty
if [ -z "$commit_msg" ]; then
    echo "❌ Commit message cannot be empty"
    exit 1
fi

# Check minimum length
if [ ${#commit_msg} -lt 5 ]; then
    echo "❌ Commit message too short (minimum 5 characters)"
    echo "   Current: '$commit_msg' (${#commit_msg} chars)"
    exit 1
fi

echo "✅ Commit message validation passed: '$commit_msg'"
EOF
    
    # Make executable
    chmod +x .husky/commit-msg
    print_status "Created and made commit-msg hook executable"
    
    # Set Git hooks path
    git config core.hooksPath .husky
    print_status "Set Git hooks path"
    
    # Test the hook
    echo "test: quick fix validation" > /tmp/quick_test_msg
    if bash .husky/commit-msg /tmp/quick_test_msg >/dev/null 2>&1; then
        print_status "Hook test passed"
        rm -f /tmp/quick_test_msg
        return 0
    else
        print_error "Hook test failed"
        rm -f /tmp/quick_test_msg
        return 1
    fi
}

# Run quick fix
if quick_fix; then
    echo ""
    echo "🎉 Quick fix completed successfully!"
    echo ""
    echo "🧪 Test it:"
    echo "  git commit -m 'test: verify commit-msg hook'"
    echo ""
    echo "💡 For more advanced features, run:"
    echo "  ./tools/fix-commit-msg-hook.sh"
else
    echo ""
    print_error "Quick fix failed. Try the comprehensive fix:"
    echo "  ./tools/fix-commit-msg-hook.sh"
fi
