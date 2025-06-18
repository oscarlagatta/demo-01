#!/bin/bash

echo "🔧 Jira Validation Troubleshooting"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're in a git repository
check_git_repo() {
    echo -e "${BLUE}🔍 Checking Git repository...${NC}"
    
    if [ ! -d ".git" ]; then
        echo -e "${RED}❌ Not in a Git repository${NC}"
        echo "Please run this from the root of your Git project"
        return 1
    fi
    
    echo -e "${GREEN}✅ Git repository found${NC}"
    return 0
}

# Check Husky installation
check_husky() {
    echo -e "${BLUE}🔍 Checking Husky installation...${NC}"
    
    if ! npm list husky >/dev/null 2>&1; then
        echo -e "${RED}❌ Husky not installed${NC}"
        echo "Run: npm install --save-dev husky"
        return 1
    fi
    
    husky_version=$(npm list husky --depth=0 | grep -o 'husky@[0-9.]*' | cut -d'@' -f2)
    echo -e "${GREEN}✅ Husky installed (version: $husky_version)${NC}"
    
    # Check .husky directory
    if [ ! -d ".husky" ]; then
        echo -e "${YELLOW}⚠️  .husky directory not found${NC}"
        echo "Run: npx husky init"
        return 1
    fi
    
    echo -e "${GREEN}✅ .husky directory exists${NC}"
    return 0
}

# Check commit-msg hook
check_commit_msg_hook() {
    echo -e "${BLUE}🔍 Checking commit-msg hook...${NC}"
    
    if [ ! -f ".husky/commit-msg" ]; then
        echo -e "${RED}❌ commit-msg hook not found${NC}"
        echo "Create .husky/commit-msg with the validation script"
        return 1
    fi
    
    if [ ! -x ".husky/commit-msg" ]; then
        echo -e "${YELLOW}⚠️  commit-msg hook not executable${NC}"
        echo "Run: chmod +x .husky/commit-msg"
        chmod +x .husky/commit-msg
        echo -e "${GREEN}✅ Fixed executable permission${NC}"
    else
        echo -e "${GREEN}✅ commit-msg hook is executable${NC}"
    fi
    
    return 0
}

# Check validation script
check_validation_script() {
    echo -e "${BLUE}🔍 Checking validation script...${NC}"
    
    if [ ! -f "tools/validate-jira-ticket.js" ]; then
        echo -e "${RED}❌ Validation script not found${NC}"
        echo "Please ensure tools/validate-jira-ticket.js exists"
        return 1
    fi
    
    echo -e "${GREEN}✅ Validation script found${NC}"
    
    # Test script syntax
    if node -c tools/validate-jira-ticket.js >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Validation script syntax is valid${NC}"
    else
        echo -e "${RED}❌ Validation script has syntax errors${NC}"
        node -c tools/validate-jira-ticket.js
        return 1
    fi
    
    return 0
}

# Check configuration file
check_configuration() {
    echo -e "${BLUE}🔍 Checking configuration...${NC}"
    
    if [ ! -f "tools/jira-config.js" ]; then
        echo -e "${RED}❌ Configuration file not found${NC}"
        echo "Please ensure tools/jira-config.js exists"
        return 1
    fi
    
    echo -e "${GREEN}✅ Configuration file found${NC}"
    
    # Test configuration syntax
    if node -c tools/jira-config.js >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Configuration syntax is valid${NC}"
    else
        echo -e "${RED}❌ Configuration has syntax errors${NC}"
        node -c tools/jira-config.js
        return 1
    fi
    
    return 0
}

# Check Git configuration
check_git_config() {
    echo -e "${BLUE}🔍 Checking Git configuration...${NC}"
    
    hooks_path=$(git config core.hooksPath)
    
    if [ "$hooks_path" != ".husky" ]; then
        echo -e "${YELLOW}⚠️  Git hooks path not set to .husky${NC}"
        echo "Current path: $hooks_path"
        echo "Run: git config core.hooksPath .husky"
        git config core.hooksPath .husky
        echo -e "${GREEN}✅ Fixed Git hooks path${NC}"
    else
        echo -e "${GREEN}✅ Git hooks path correctly set${NC}"
    fi
    
    return 0
}

# Test validation with sample messages
test_validation() {
    echo -e "${BLUE}🧪 Testing validation with sample messages...${NC}"
    
    # Create temporary test messages
    test_messages=(
        "EARS-1234: valid test message"
        "invalid message without ticket"
        "INVALID-123: wrong project prefix"
    )
    
    for i in "${!test_messages[@]}"; do
        message="${test_messages[$i]}"
        echo "$message" > /tmp/test-commit-msg-$i
        
        echo -e "${BLUE}Testing: \"$message\"${NC}"
        
        if node tools/validate-jira-ticket.js /tmp/test-commit-msg-$i >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Validation passed${NC}"
        else
            echo -e "${YELLOW}⚠️  Validation failed (expected for invalid messages)${NC}"
        fi
        
        rm -f /tmp/test-commit-msg-$i
        echo ""
    done
}

# Run comprehensive test
run_comprehensive_test() {
    echo -e "${BLUE}🧪 Running comprehensive test...${NC}"
    
    if [ -f "tools/test-jira-validation.js" ]; then
        node tools/test-jira-validation.js
    else
        echo -e "${YELLOW}⚠️  Comprehensive test script not found${NC}"
        echo "Basic validation test will be performed instead"
        test_validation
    fi
}

# Display common issues and solutions
show_common_issues() {
    echo -e "${BLUE}📋 Common Issues and Solutions${NC}"
    echo "=============================="
    echo ""
    
    echo -e "${YELLOW}Issue: Hook not running${NC}"
    echo "Solutions:"
    echo "  • Check git config core.hooksPath"
    echo "  • Ensure .husky/commit-msg is executable"
    echo "  • Verify Husky is properly installed"
    echo ""
    
    echo -e "${YELLOW}Issue: 'node: command not found'${NC}"
    echo "Solutions:"
    echo "  • Install Node.js"
    echo "  • Check PATH environment variable"
    echo "  • Use absolute path to node in hook"
    echo ""
    
    echo -e "${YELLOW}Issue: Module not found errors${NC}"
    echo "Solutions:"
    echo "  • Run 'npm install' to install dependencies"
    echo "  • Check file paths in validation script"
    echo "  • Ensure tools directory structure is correct"
    echo ""
    
    echo -e "${YELLOW}Issue: Validation always passes/fails${NC}"
    echo "Solutions:"
    echo "  • Check jira-config.js settings"
    echo "  • Verify project prefixes are correct"
    echo "  • Test with known good/bad commit messages"
    echo ""
}

# Main troubleshooting function
main_troubleshoot() {
    echo "Starting comprehensive troubleshooting..."
    echo ""
    
    local issues=0
    
    check_git_repo || ((issues++))
    echo ""
    
    check_husky || ((issues++))
    echo ""
    
    check_commit_msg_hook || ((issues++))
    echo ""
    
    check_validation_script || ((issues++))
    echo ""
    
    check_configuration || ((issues++))
    echo ""
    
    check_git_config || ((issues++))
    echo ""
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}🎉 No issues found! Running validation test...${NC}"
        echo ""
        run_comprehensive_test
    else
        echo -e "${RED}❌ Found $issues issue(s). Please fix them and run again.${NC}"
        echo ""
        show_common_issues
    fi
}

# Menu system
show_menu() {
    echo ""
    echo -e "${BLUE}🔧 Troubleshooting Menu${NC}"
    echo "======================"
    echo "1. Run full diagnostic"
    echo "2. Check individual components"
    echo "3. Test validation"
    echo "4. Show common issues"
    echo "5. Exit"
    echo ""
}

# Individual component checks
individual_checks() {
    echo ""
    echo "Individual Component Checks:"
    echo "1. Git repository"
    echo "2. Husky installation"
    echo "3. commit-msg hook"
    echo "4. Validation script"
    echo "5. Configuration file"
    echo "6. Git configuration"
    echo "7. Back to main menu"
    echo ""
    
    read -p "Choose component to check (1-7): " choice
    
    case $choice in
        1) check_git_repo ;;
        2) check_husky ;;
        3) check_commit_msg_hook ;;
        4) check_validation_script ;;
        5) check_configuration ;;
        6) check_git_config ;;
        7) return ;;
        *) echo -e "${RED}❌ Invalid option${NC}" ;;
    esac
}

# Main menu loop
while true; do
    show_menu
    read -p "Choose option (1-5): " choice
    
    case $choice in
        1) main_troubleshoot ;;
        2) individual_checks ;;
        3) run_comprehensive_test ;;
        4) show_common_issues ;;
        5) 
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please choose 1-5.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
