#!/bin/bash

echo "🔍 Git Hooks and Line Endings Diagnostic"
echo "========================================"

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

# System Information
diagnose_system() {
    print_header "System Information"
    
    echo "Operating System: $OSTYPE"
    echo "Shell: $SHELL"
    echo "Git Version: $(git --version)"
    
    if command -v node >/dev/null 2>&1; then
        echo "Node.js Version: $(node --version)"
    else
        print_warning "Node.js not found"
    fi
    
    if command -v npm >/dev/null 2>&1; then
        echo "npm Version: $(npm --version)"
    else
        print_warning "npm not found"
    fi
    
    echo ""
}

# Git Configuration
diagnose_git_config() {
    print_header "Git Configuration"
    
    echo "core.autocrlf: $(git config --get core.autocrlf || echo 'not set')"
    echo "core.safecrlf: $(git config --get core.safecrlf || echo 'not set')"
    echo "core.filemode: $(git config --get core.filemode || echo 'not set')"
    echo "core.hooksPath: $(git config --get core.hooksPath || echo 'not set')"
    
    # Check if we're in a Git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
        print_status "In a Git repository"
        echo "Repository root: $(git rev-parse --show-toplevel)"
    else
        print_error "Not in a Git repository"
    fi
    
    echo ""
}

# Husky Installation
diagnose_husky() {
    print_header "Husky Installation"
    
    if [ -f "package.json" ]; then
        print_status "package.json found"
        
        if npm list husky >/dev/null 2>&1; then
            husky_version=$(npm list husky --depth=0 2>/dev/null | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
            print_status "Husky installed (version: $husky_version)"
            
            major_version=$(echo "$husky_version" | cut -d'.' -f1)
            if [[ "$major_version" -ge 9 ]]; then
                print_info "Using Husky v9+ (modern format)"
            else
                print_info "Using Husky v8.x (legacy format)"
            fi
        else
            print_error "Husky not installed"
        fi
        
        if npm list lint-staged >/dev/null 2>&1; then
            print_status "lint-staged installed"
        else
            print_warning "lint-staged not installed"
        fi
    else
        print_error "package.json not found"
    fi
    
    echo ""
}

# Hook Files
diagnose_hooks() {
    print_header "Git Hook Files"
    
    if [ -d ".husky" ]; then
        print_status ".husky directory exists"
        
        for hook in pre-commit commit-msg pre-push; do
            hook_file=".husky/$hook"
            if [ -f "$hook_file" ]; then
                print_status "$hook hook exists"
                
                # Check if executable
                if [ -x "$hook_file" ]; then
                    print_status "$hook is executable"
                else
                    print_error "$hook is not executable"
                fi
                
                # Check line endings
                if command -v file >/dev/null 2>&1; then
                    line_ending=$(file "$hook_file" | grep -o "CRLF\|LF" | head -1)
                    if [ "$line_ending" = "CRLF" ]; then
                        print_warning "$hook has CRLF line endings"
                    else
                        print_status "$hook has LF line endings"
                    fi
                fi
                
                # Show first few lines
                echo "  Content preview:"
                head -3 "$hook_file" | sed 's/^/    /'
                
            else
                print_warning "$hook hook not found"
            fi
            echo ""
        done
    else
        print_error ".husky directory not found"
    fi
}

# Line Ending Configuration
diagnose_line_endings() {
    print_header "Line Ending Configuration"
    
    if [ -f ".gitattributes" ]; then
        print_status ".gitattributes file exists"
        echo "Content:"
        cat .gitattributes | head -10 | sed 's/^/  /'
        if [ $(wc -l < .gitattributes) -gt 10 ]; then
            echo "  ... (truncated)"
        fi
    else
        print_warning ".gitattributes file not found"
    fi
    
    echo ""
    
    # Check for files with mixed line endings
    print_info "Checking for files with line ending issues..."
    
    mixed_files=0
    for ext in sh js ts jsx tsx json md; do
        if find . -name "*.$ext" -type f -exec grep -l $'\r' {} \; 2>/dev/null | head -5; then
            ((mixed_files++))
        fi
    done
    
    if [ $mixed_files -eq 0 ]; then
        print_status "No obvious line ending issues found"
    else
        print_warning "Found files with potential CRLF line endings"
    fi
    
    echo ""
}

# Recent Git Operations
diagnose_recent_operations() {
    print_header "Recent Git Operations"
    
    echo "Last 5 commits:"
    git log --oneline -5 2>/dev/null || print_warning "Could not retrieve commit history"
    
    echo ""
    echo "Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo "Staged files:"
    git diff --cached --name-only 2>/dev/null || print_warning "Could not retrieve staged files"
    
    echo ""
}

# Test Hook Execution
test_hook_execution() {
    print_header "Hook Execution Test"
    
    for hook in pre-commit commit-msg pre-push; do
        hook_file=".husky/$hook"
        if [ -f "$hook_file" ]; then
            print_info "Testing $hook execution..."
            
            # Create a test environment
            if [ "$hook" = "commit-msg" ]; then
                # commit-msg needs a file argument
                echo "test commit message" > /tmp/test-commit-msg
                if bash "$hook_file" /tmp/test-commit-msg >/dev/null 2>&1; then
                    print_status "$hook executes successfully"
                else
                    print_error "$hook failed to execute"
                fi
                rm -f /tmp/test-commit-msg
            else
                if bash "$hook_file" >/dev/null 2>&1; then
                    print_status "$hook executes successfully"
                else
                    print_error "$hook failed to execute"
                fi
            fi
        fi
    done
    
    echo ""
}

# Recommendations
provide_recommendations() {
    print_header "Recommendations"
    
    echo "Based on the diagnostic results:"
    echo ""
    
    # Check if we're on Windows
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        echo "🪟 Windows Environment Detected:"
        echo "  • Run: ./tools/fix-windows-line-endings.sh"
        echo "  • Ensure Git is configured with core.autocrlf=true"
        echo ""
    fi
    
    # Check for missing hooks
    if [ ! -f ".husky/pre-push" ]; then
        echo "🔧 Missing pre-push hook:"
        echo "  • Run: ./tools/fix-git-line-endings.sh"
        echo ""
    fi
    
    # Check for line ending issues
    if git config --get core.autocrlf >/dev/null 2>&1; then
        autocrlf=$(git config --get core.autocrlf)
        if [ "$autocrlf" != "true" ] && [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
            echo "⚙️  Git Configuration:"
            echo "  • Set core.autocrlf=true for Windows"
            echo "  • Run: git config --global core.autocrlf true"
            echo ""
        fi
    fi
    
    echo "🚀 Quick Fix Commands:"
    echo "  chmod +x tools/fix-git-line-endings.sh"
    echo "  ./tools/fix-git-line-endings.sh"
    echo ""
}

# Main diagnostic function
main_diagnostic() {
    echo "Running comprehensive Git hooks diagnostic..."
    echo ""
    
    diagnose_system
    diagnose_git_config
    diagnose_husky
    diagnose_hooks
    diagnose_line_endings
    diagnose_recent_operations
    test_hook_execution
    provide_recommendations
    
    echo "🎯 Diagnostic complete!"
    echo ""
    echo "💡 If you found issues, run the appropriate fix script:"
    echo "   • ./tools/fix-git-line-endings.sh (general fixes)"
    echo "   • ./tools/fix-windows-line-endings.sh (Windows-specific)"
}

# Run the diagnostic
main_diagnostic
