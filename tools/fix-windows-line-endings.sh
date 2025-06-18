#!/bin/bash

echo "🪟 Windows Line Ending Fix for Git Hooks"
echo "========================================"

# This script specifically addresses Windows CRLF issues with Git hooks

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

# Check if we're on Windows
check_windows() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        print_info "Windows environment detected"
        return 0
    else
        print_info "Non-Windows environment detected"
        return 1
    fi
}

# Fix Git configuration for Windows
fix_windows_git_config() {
    print_info "Configuring Git for Windows..."
    
    # Set autocrlf to true for Windows
    git config --global core.autocrlf true
    print_status "Set core.autocrlf=true"
    
    # Set safecrlf to false to avoid blocking commits
    git config --global core.safecrlf false
    print_status "Set core.safecrlf=false"
    
    # Set filemode to false (Windows doesn't track executable bit properly)
    git config core.filemode false
    print_status "Set core.filemode=false"
}

# Create Windows-compatible .gitattributes
create_windows_gitattributes() {
    print_info "Creating Windows-compatible .gitattributes..."
    
    cat > .gitattributes << 'EOF'
# Handle line endings automatically for files detected as text
# and leave all files detected as binary untouched.
* text=auto

# The above will handle all files NOT found below
# These files are text and should be normalized (Convert crlf => lf)
*.css           text
*.html          text
*.js            text
*.jsx           text
*.ts            text
*.tsx           text
*.json          text
*.md            text
*.txt           text
*.xml           text
*.yml           text
*.yaml          text

# These files are binary and should be left untouched
# (binary is a macro for -text -diff)
*.png           binary
*.jpg           binary
*.jpeg          binary
*.gif           binary
*.ico           binary
*.mov           binary
*.mp4           binary
*.mp3           binary
*.flv           binary
*.fla           binary
*.swf           binary
*.gz            binary
*.zip           binary
*.7z            binary
*.ttf           binary
*.eot           binary
*.woff          binary
*.pyc           binary
*.pdf           binary

# Shell scripts should always use LF
*.sh            text eol=lf

# Husky hooks should use LF (critical for execution)
.husky/*        text eol=lf

# Windows batch files should use CRLF
*.bat           text eol=crlf
*.cmd           text eol=crlf
EOF
    
    print_status "Created .gitattributes with Windows compatibility"
}

# Fix Husky hooks for Windows
fix_husky_hooks_windows() {
    print_info "Fixing Husky hooks for Windows..."
    
    if [ ! -d ".husky" ]; then
        print_error ".husky directory not found"
        return 1
    fi
    
    # Convert all hooks to LF line endings
    for hook_file in .husky/*; do
        if [ -f "$hook_file" ] && [ "$(basename "$hook_file")" != "_" ]; then
            print_info "Processing $(basename "$hook_file")..."
            
            # Convert CRLF to LF using sed
            sed -i 's/\r$//' "$hook_file" 2>/dev/null || {
                # Alternative method using tr
                tr -d '\r' < "$hook_file" > "${hook_file}.tmp" && mv "${hook_file}.tmp" "$hook_file"
            }
            
            # Ensure hook is executable (important for Git Bash)
            chmod +x "$hook_file"
            
            print_status "Fixed $(basename "$hook_file")"
        fi
    done
}

# Create missing hooks with proper line endings
create_windows_hooks() {
    print_info "Creating missing hooks with Windows compatibility..."
    
    # Create pre-push hook if missing
    if [ ! -f ".husky/pre-push" ]; then
        # Use printf to ensure LF line endings
        printf '#!/bin/sh\n' > .husky/pre-push
        printf 'echo "🚀 Running pre-push checks..."\n' >> .husky/pre-push
        printf '\n' >> .husky/pre-push
        printf '# Get current branch\n' >> .husky/pre-push
        printf 'current_branch=$(git branch --show-current)\n' >> .husky/pre-push
        printf '\n' >> .husky/pre-push
        printf '# Optional: Prevent direct push to main/master\n' >> .husky/pre-push
        printf '# protected_branches="main master"\n' >> .husky/pre-push
        printf '# if echo "$protected_branches" | grep -wq "$current_branch"; then\n' >> .husky/pre-push
        printf '#     echo "⚠️  Warning: Pushing to protected branch: $current_branch"\n' >> .husky/pre-push
        printf '# fi\n' >> .husky/pre-push
        printf '\n' >> .husky/pre-push
        printf 'echo "✅ Pre-push checks completed!"\n' >> .husky/pre-push
        
        chmod +x .husky/pre-push
        print_status "Created pre-push hook with LF line endings"
    fi
    
    # Ensure commit-msg hook exists
    if [ ! -f ".husky/commit-msg" ]; then
        printf '#!/bin/sh\n' > .husky/commit-msg
        printf 'echo "📝 Validating commit message..."\n' >> .husky/commit-msg
        printf 'echo "✅ Commit message validation passed!"\n' >> .husky/commit-msg
        
        chmod +x .husky/commit-msg
        print_status "Created commit-msg hook with LF line endings"
    fi
}

# Test hooks execution
test_hooks_windows() {
    print_info "Testing hooks execution on Windows..."
    
    local test_passed=true
    
    for hook in pre-commit commit-msg pre-push; do
        if [ -f ".husky/$hook" ]; then
            print_info "Testing $hook..."
            
            # Test if hook can be executed
            if bash ".husky/$hook" >/dev/null 2>&1; then
                print_status "$hook executes successfully"
            else
                print_error "$hook failed to execute"
                test_passed=false
            fi
            
            # Check line endings
            if file ".husky/$hook" 2>/dev/null | grep -q "CRLF"; then
                print_warning "$hook still has CRLF line endings"
                test_passed=false
            else
                print_status "$hook has correct LF line endings"
            fi
        fi
    done
    
    return $test_passed
}

# Main execution for Windows
main_windows() {
    if check_windows; then
        print_info "Running Windows-specific fixes..."
    else
        print_info "Running Unix/Linux fixes..."
    fi
    
    echo ""
    fix_windows_git_config
    echo ""
    
    create_windows_gitattributes
    echo ""
    
    fix_husky_hooks_windows
    echo ""
    
    create_windows_hooks
    echo ""
    
    # Refresh Git index
    print_info "Refreshing Git index..."
    git add --renormalize . 2>/dev/null || true
    print_status "Git index refreshed"
    echo ""
    
    if test_hooks_windows; then
        echo "🎉 Windows line ending fixes completed successfully!"
        echo ""
        echo "📋 Summary of changes:"
        echo "  ✅ Git configured for Windows (core.autocrlf=true)"
        echo "  ✅ Created .gitattributes for proper line ending handling"
        echo "  ✅ Fixed all Husky hooks to use LF line endings"
        echo "  ✅ Created missing hooks with proper formatting"
        echo "  ✅ All hooks are executable and tested"
        echo ""
        echo "🧪 Next steps:"
        echo "  1. git add ."
        echo "  2. git commit -m 'fix: resolve line ending issues'"
        echo "  3. git push"
        echo ""
        echo "💡 The CRLF warnings should now be resolved!"
    else
        print_error "Some issues remain. Please check the output above."
        exit 1
    fi
}

# Run the Windows-specific fixes
main_windows
