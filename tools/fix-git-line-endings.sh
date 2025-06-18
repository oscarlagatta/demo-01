#!/bin/bash

echo "🔧 Fixing Git Line Ending and Hook Issues"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
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

# Step 1: Fix Git configuration for line endings
fix_git_line_endings() {
    print_info "Fixing Git line ending configuration..."
    
    # Set core.autocrlf based on OS
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        # Windows
        git config --global core.autocrlf true
        print_status "Set core.autocrlf=true for Windows"
    else
        # Unix/Linux/Mac
        git config --global core.autocrlf input
        print_status "Set core.autocrlf=input for Unix/Linux/Mac"
    fi
    
    # Set safecrlf to warn about mixed line endings
    git config --global core.safecrlf warn
    print_status "Set core.safecrlf=warn"
    
    # Add .gitattributes file to enforce line endings
    if [ ! -f ".gitattributes" ]; then
        cat > .gitattributes << 'EOF'
# Set default behavior to automatically normalize line endings
* text=auto

# Force batch scripts to always use CRLF line endings so that if a repo is accessed
# in Windows via a file share from Linux, the scripts will work
*.{cmd,[cC][mM][dD]} text eol=crlf
*.{bat,[bB][aA][tT]} text eol=crlf

# Force bash scripts to always use LF line endings so that if a repo is accessed
# in Unix via a file share from Windows, the scripts will work
*.sh text eol=lf

# Husky hooks should use LF
.husky/* text eol=lf

# Source code files
*.js text eol=lf
*.jsx text eol=lf
*.ts text eol=lf
*.tsx text eol=lf
*.json text eol=lf
*.md text eol=lf
*.css text eol=lf
*.scss text eol=lf
*.html text eol=lf

# Binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
EOF
        print_status "Created .gitattributes file"
    else
        print_warning ".gitattributes already exists"
    fi
}

# Step 2: Fix existing files with wrong line endings
fix_existing_files() {
    print_info "Fixing line endings in existing files..."
    
    # Find and fix shell scripts
    find . -name "*.sh" -type f -exec dos2unix {} \; 2>/dev/null || {
        # If dos2unix is not available, use sed
        find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
    }
    
    # Fix Husky hooks
    if [ -d ".husky" ]; then
        find .husky -type f -exec sed -i 's/\r$//' {} \; 2>/dev/null || true
        print_status "Fixed line endings in .husky directory"
    fi
    
    print_status "Fixed line endings in shell scripts"
}

# Step 3: Create missing pre-push hook
create_missing_hooks() {
    print_info "Creating missing Git hooks..."
    
    # Ensure .husky directory exists
    if [ ! -d ".husky" ]; then
        mkdir -p .husky
        print_status "Created .husky directory"
    fi
    
    # Create pre-push hook if missing
    if [ ! -f ".husky/pre-push" ]; then
        cat > .husky/pre-push << 'EOF'
#!/bin/sh
echo "🚀 Running pre-push checks..."

# Get current branch
current_branch=$(git branch --show-current)

# Prevent direct push to protected branches
protected_branches="main master develop"
if echo "$protected_branches" | grep -wq "$current_branch"; then
    echo "⚠️  Pushing to protected branch: $current_branch"
    read -p "Are you sure you want to push to $current_branch? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "❌ Push cancelled"
        exit 1
    fi
fi

# Run build check (optional - uncomment if needed)
# echo "🏗️  Running build check..."
# npm run build

# Run tests (optional - uncomment if needed)
# echo "🧪 Running tests..."
# npm test

echo "✅ Pre-push checks completed!"
EOF
        chmod +x .husky/pre-push
        print_status "Created pre-push hook"
    else
        print_warning "pre-push hook already exists"
    fi
    
    # Ensure all hooks are executable
    find .husky -type f -exec chmod +x {} \;
    print_status "Made all hooks executable"
}

# Step 4: Fix Git hooks configuration
fix_git_hooks_config() {
    print_info "Fixing Git hooks configuration..."
    
    # Set hooks path
    git config core.hooksPath .husky
    print_status "Set Git hooks path to .husky"
    
    # Verify Husky version and format
    if npm list husky >/dev/null 2>&1; then
        husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
        major_version=$(echo "$husky_version" | cut -d'.' -f1)
        
        print_info "Detected Husky version: $husky_version"
        
        if [[ "$major_version" -ge 9 ]]; then
            print_info "Updating hooks for Husky v9+ format..."
            
            # Remove deprecated lines from hooks
            for hook in .husky/pre-commit .husky/commit-msg .husky/pre-push; do
                if [ -f "$hook" ]; then
                    # Remove shebang and husky.sh source lines for v9+
                    sed -i '/^#!/d' "$hook" 2>/dev/null || true
                    sed -i '/\. "$(dirname -- "$0")/_\/husky\.sh"/d' "$hook" 2>/dev/null || true
                    chmod +x "$hook"
                    print_status "Updated $hook for Husky v9+"
                fi
            done
        else
            print_info "Husky v8.x detected - keeping current format"
        fi
    else
        print_warning "Husky not found in package.json"
    fi
}

# Step 5: Refresh Git index to apply .gitattributes
refresh_git_index() {
    print_info "Refreshing Git index to apply line ending fixes..."
    
    # This will update the index with the new line ending settings
    git add --renormalize . 2>/dev/null || {
        print_warning "Could not renormalize - this is normal if no changes needed"
    }
    
    print_status "Git index refreshed"
}

# Step 6: Verify the fixes
verify_fixes() {
    print_info "Verifying fixes..."
    
    # Check if hooks exist and are executable
    local hooks_ok=true
    for hook in pre-commit pre-push; do
        if [ -f ".husky/$hook" ]; then
            if [ -x ".husky/$hook" ]; then
                print_status "$hook hook is ready"
            else
                print_error "$hook hook is not executable"
                hooks_ok=false
            fi
        else
            print_warning "$hook hook not found (may be optional)"
        fi
    done
    
    # Check Git configuration
    hooks_path=$(git config core.hooksPath)
    if [ "$hooks_path" = ".husky" ]; then
        print_status "Git hooks path correctly configured"
    else
        print_error "Git hooks path not set correctly: $hooks_path"
        hooks_ok=false
    fi
    
    # Check line endings in a sample hook
    if [ -f ".husky/pre-commit" ]; then
        if file .husky/pre-commit | grep -q "CRLF"; then
            print_warning "pre-commit hook still has CRLF line endings"
        else
            print_status "pre-commit hook has correct line endings"
        fi
    fi
    
    if [ "$hooks_ok" = true ]; then
        print_status "All verifications passed!"
        return 0
    else
        print_error "Some issues remain - please check the output above"
        return 1
    fi
}

# Main execution
main() {
    echo "Starting Git hooks and line endings fix..."
    echo ""
    
    fix_git_line_endings
    echo ""
    
    fix_existing_files
    echo ""
    
    create_missing_hooks
    echo ""
    
    fix_git_hooks_config
    echo ""
    
    refresh_git_index
    echo ""
    
    if verify_fixes; then
        echo ""
        echo "🎉 All fixes completed successfully!"
        echo ""
        echo "📋 What was fixed:"
        echo "  ✅ Git line ending configuration"
        echo "  ✅ Created .gitattributes file"
        echo "  ✅ Fixed existing file line endings"
        echo "  ✅ Created missing pre-push hook"
        echo "  ✅ Updated Husky hook format"
        echo "  ✅ Set correct Git hooks path"
        echo ""
        echo "🧪 Test your setup:"
        echo "  git add ."
        echo "  git commit -m 'test: verify hooks'"
        echo "  git push"
        echo ""
    else
        echo ""
        print_error "Some issues could not be resolved automatically"
        echo "Please review the output above and fix manually if needed"
        exit 1
    fi
}

# Run main function
main
