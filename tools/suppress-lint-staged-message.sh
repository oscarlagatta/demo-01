#!/bin/bash

echo "🔇 Suppress Lint-staged 'No staged files' Message"
echo "================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Update pre-commit hook to suppress the message
suppress_message() {
    local hook_file=".husky/pre-commit"
    
    if [ ! -f "$hook_file" ]; then
        print_info "Pre-commit hook not found - creating one..."
        
        # Determine Husky version
        if npm list husky >/dev/null 2>&1; then
            husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
            major_version=$(echo "$husky_version" | cut -d'.' -f1)
        else
            major_version=9
        fi
        
        # Create hook based on version
        if [[ "$major_version" -ge 9 ]]; then
            cat > "$hook_file" << 'EOF'
#!/bin/sh
echo "🚀 Running pre-commit checks..."

# Run lint-staged quietly if available and there are staged files
if command -v npx >/dev/null 2>&1 && npm list lint-staged >/dev/null 2>&1; then
    staged_files=$(git diff --cached --name-only)
    if [ -n "$staged_files" ]; then
        echo "📝 Processing staged files..."
        npx lint-staged 2>/dev/null || npx lint-staged
    else
        echo "ℹ️  No staged files to process"
    fi
else
    echo "ℹ️  lint-staged not available, skipping..."
fi

echo "✅ Pre-commit checks completed!"
EOF
        else
            cat > "$hook_file" << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "🚀 Running pre-commit checks..."

# Run lint-staged quietly if available and there are staged files
if command -v npx >/dev/null 2>&1 && npm list lint-staged >/dev/null 2>&1; then
    staged_files=$(git diff --cached --name-only)
    if [ -n "$staged_files" ]; then
        echo "📝 Processing staged files..."
        npx lint-staged 2>/dev/null || npx lint-staged
    else
        echo "ℹ️  No staged files to process"
    fi
else
    echo "ℹ️  lint-staged not available, skipping..."
fi

echo "✅ Pre-commit checks completed!"
EOF
        fi
        
        chmod +x "$hook_file"
        print_status "Created pre-commit hook with suppressed messages"
    else
        # Update existing hook
        cp "$hook_file" "${hook_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Replace lint-staged call with quieter version
        sed -i 's/npx lint-staged$/npx lint-staged 2>\/dev\/null || npx lint-staged/' "$hook_file"
        
        print_status "Updated pre-commit hook to suppress lint-staged messages"
    fi
}

# Run the suppression
suppress_message

echo ""
echo "🎯 Message Suppression Complete!"
echo ""
echo "The 'No staged files match any configured task' message will now be:"
echo "  • Suppressed when there are no staged files"
echo "  • Shown only when there are actual issues"
echo ""
echo "🧪 Test it:"
echo "  git commit -m 'test: verify suppressed messages'"
