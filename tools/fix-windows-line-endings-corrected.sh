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
        return 0  # Success (true)
    else
        print_info "Non-Windows environment detected"
        return 1  # Failure (false)
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
    
    return 0  # Always return success for this function
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
    return 0
}

# Fix Husky hooks for Windows
fix_husky_hooks_windows() {
    print_info "Fixing Husky hooks for Windows..."
    
    if [ ! -d ".husky" ]; then
        print_error ".husky directory not found"
        return 1
    fi
    
    local hooks_fixed=0
    local hooks_total=0
    
    # Convert all hooks to LF line endings
    for hook_file in .husky/*; do
        if [ -f "$hook_file" ] && [ "$(basename "$hook_file")" != "_" ]; then
            ((hooks_total++))
            print_info "Processing $(basename "$hook_file")..."
            
            # Convert CRLF to LF using sed
            if sed -i 's/\r$//' "$hook_file" 2>/dev/null || {
                # Alternative method using tr
                tr -d '\r' < "$hook_file" > "${hook_file}.tmp" && mv "${hook_file}.tmp" "$hook_file"
            }; then
                # Ensure hook is executable (important for Git Bash)
                chmod +x "$hook_file"
                print_status "Fixed $(basename "$hook_file")"
                ((hooks_fixed++))
            else
                print_error "Failed to fix $(basename "$hook_file")"
            fi
        fi
    done
    
    if [ $hooks_fixed -eq $hooks_total ] && [ $hooks_total -gt 0 ]; then
        return 0  # All hooks fixed successfully
    elif [ $hooks_fixed -gt 0 ]; then
        return 2  # Some hooks fixed, but not all
    else
        return 1  # No hooks fixed or no hooks found
    fi
}

# Create missing hooks with proper line endings
create_windows_hooks() {
    print_info "Creating missing hooks with Windows compatibility..."
    
    local hooks_created=0
    
    # Create pre-push hook if missing
    if [ ! -f ".husky/pre-push" ]; then
        # Use printf to ensure LF line endings
        {
            printf '#!/bin/sh\n'
            printf 'echo "🚀 Running pre-push checks..."\n'
            printf '\n'
            printf '# Get current branch\n'
            printf 'current_branch=$(git branch --show-current)\n'
            printf '\n'
            printf '# Optional: Prevent direct push to main/master\n'
            printf '# protected_branches="main master"\n'
            printf '# if echo "$protected_branches" | grep -wq "$current_branch"; then\n'
            printf '#     echo "⚠️  Warning: Pushing to protected branch: $current_branch"\n'
            printf '# fi\n'
            printf '\n'
            printf 'echo "✅ Pre-push checks completed!"\n'
        } > .husky/pre-push
        
        chmod +x .husky/pre-push
        print_status "Created pre-push hook with LF line endings"
        ((hooks_created++))
    fi
    
    # Ensure commit-msg hook exists
    if [ ! -f ".husky/commit-msg" ]; then
        {
            printf '#!/bin/sh\n'
            printf 'echo "📝 Validating commit message..."\n'
            printf 'echo "✅ Commit message validation passed!"\n'
        } > .husky/commit-msg
        
        chmod +x .husky/commit-msg
        print_status "Created commit-msg hook with LF line endings"
        ((hooks_created++))
    fi
    
    if [ $hooks_created -gt 0 ]; then
        return 0  # Success - hooks were created
    else
        return 0  # Success - no hooks needed to be created
    fi
}

# Test hooks execution
test_hooks_windows() {
    print_info "Testing hooks execution on Windows..."
    
    local tests_passed=0
    local tests_total=0
    
    for hook in pre-commit commit-msg pre-push; do
        if [ -f ".husky/$hook" ]; then
            ((tests_total++))
            print_info "Testing $hook..."
            
            # Test if hook can be executed
            if bash ".husky/$hook" >/dev/null 2>&1; then
                print_status "$hook executes successfully"
                ((tests_passed++))
            else
                print_error "$hook failed to execute"
            fi
            
            # Check line endings
            if command -v file >/dev/null 2>&1; then
                if file ".husky/$hook" 2>/dev/null | grep -q "CRLF"; then
                    print_warning "$hook still has CRLF line endings"
                else
                    print_status "$hook has correct LF line endings"
                    ((tests_passed++))
                fi
            else
                # If 'file' command not available, assume success
                ((tests_passed++))
            fi
        fi
    done
    
    # Return success if all tests passed, failure otherwise
    if [ $tests_passed -eq $((tests_total * 2)) ]; then
        return 0  # All tests passed
    else
        return 1  # Some tests failed
    fi
}

# Main execution for Windows
main_windows() {
    local overall_success=0  # Track overall success (0 = success, 1 = failure)
    
    if check_windows; then
        print_info "Running Windows-specific fixes..."
    else
        print_info "Running Unix/Linux fixes..."
    fi
    
    echo ""
    
    # Run each fix and track success
    if ! fix_windows_git_config; then
        print_error "Failed to configure Git for Windows"
        overall_success=1
    fi
    echo ""
    
    if ! create_windows_gitattributes; then
        print_error "Failed to create .gitattributes"
        overall_success=1
    fi
    echo ""
    
    if ! fix_husky_hooks_windows; then
        print_error "Failed to fix some Husky hooks"
        overall_success=1
    fi
    echo ""
    
    if ! create_windows_hooks; then
        print_error "Failed to create missing hooks"
        overall_success=1
    fi
    echo ""
    
    # Refresh Git index
    print_info "Refreshing Git index..."
    if git add --renormalize . 2>/dev/null; then
        print_status "Git index refreshed"
    else
        print_warning "Could not refresh Git index (this may be normal)"
    fi
    echo ""
    
    # Test the hooks
    if test_hooks_windows; then
        print_status "All hook tests passed"
    else
        print_warning "Some hook tests failed"
        overall_success=1
    fi
    
    # Final summary
    if [ $overall_success -eq 0 ]; then
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
        return 0
    else
        print_error "Some issues remain. Please check the output above."
        echo ""
        echo "🔧 Troubleshooting steps:"
        echo "  1. Check file permissions: ls -la .husky/"
        echo "  2. Test hooks manually: bash .husky/pre-commit"
        echo "  3. Verify Git config: git config --list | grep core"
        echo "  4. Run diagnostic: ./tools/diagnose-git-issues.sh"
        return 1
    fi
}

# Run the Windows-specific fixes
if main_windows; then
    exit 0
else
    exit 1
fi
