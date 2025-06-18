#!/bin/bash

echo "🔧 Jira Project Configuration Helper"
echo "===================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Current configuration file
CONFIG_FILE="tools/jira-config.js"

# Function to display current configuration
show_current_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${BLUE}📋 Current Configuration:${NC}"
        echo "========================"
        
        # Extract project prefixes
        prefixes=$(grep -A 10 "projectPrefixes:" "$CONFIG_FILE" | grep -o "'[A-Z]*'" | tr -d "'" | tr '\n' ', ' | sed 's/,$//')
        echo -e "Project Prefixes: ${GREEN}$prefixes${NC}"
        
        # Extract other settings
        required=$(grep "required:" "$CONFIG_FILE" | grep -o "true\|false")
        echo -e "Validation Required: ${GREEN}$required${NC}"
        
        min_length=$(grep "minMessageLength:" "$CONFIG_FILE" | grep -o "[0-9]*")
        echo -e "Minimum Message Length: ${GREEN}$min_length${NC}"
        
        echo ""
    else
        echo -e "${YELLOW}⚠️  No configuration file found${NC}"
        echo "Run setup-jira-validation.sh first"
        exit 1
    fi
}

# Function to add new project prefix
add_project_prefix() {
    echo -e "${BLUE}➕ Add New Project Prefix${NC}"
    echo "========================="
    
    read -p "Enter new project prefix (e.g., NEWPROJ): " new_prefix
    
    if [ -z "$new_prefix" ]; then
        echo -e "${RED}❌ Project prefix cannot be empty${NC}"
        return
    fi
    
    # Convert to uppercase
    new_prefix=$(echo "$new_prefix" | tr '[:lower:]' '[:upper:]')
    
    # Check if already exists
    if grep -q "'$new_prefix'" "$CONFIG_FILE"; then
        echo -e "${YELLOW}⚠️  Project prefix '$new_prefix' already exists${NC}"
        return
    fi
    
    # Add to configuration
    sed -i "/projectPrefixes: \[/a\\    '$new_prefix'," "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ Added project prefix: $new_prefix${NC}"
}

# Function to remove project prefix
remove_project_prefix() {
    echo -e "${BLUE}➖ Remove Project Prefix${NC}"
    echo "========================"
    
    # Show current prefixes
    echo "Current prefixes:"
    grep -o "'[A-Z]*'" "$CONFIG_FILE" | tr -d "'" | nl
    
    read -p "Enter project prefix to remove: " remove_prefix
    
    if [ -z "$remove_prefix" ]; then
        echo -e "${RED}❌ Project prefix cannot be empty${NC}"
        return
    fi
    
    # Convert to uppercase
    remove_prefix=$(echo "$remove_prefix" | tr '[:lower:]' '[:upper:]')
    
    # Remove from configuration
    sed -i "/'$remove_prefix',/d" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ Removed project prefix: $remove_prefix${NC}"
}

# Function to update validation settings
update_validation_settings() {
    echo -e "${BLUE}⚙️  Update Validation Settings${NC}"
    echo "============================="
    
    echo "1. Toggle validation requirement"
    echo "2. Update minimum message length"
    echo "3. Toggle colon requirement"
    echo "4. Back to main menu"
    
    read -p "Choose option (1-4): " choice
    
    case $choice in
        1)
            current=$(grep "required:" "$CONFIG_FILE" | grep -o "true\|false")
            if [ "$current" = "true" ]; then
                sed -i 's/required: true/required: false/' "$CONFIG_FILE"
                echo -e "${GREEN}✅ Validation requirement disabled${NC}"
            else
                sed -i 's/required: false/required: true/' "$CONFIG_FILE"
                echo -e "${GREEN}✅ Validation requirement enabled${NC}"
            fi
            ;;
        2)
            read -p "Enter minimum message length (current: $(grep "minMessageLength:" "$CONFIG_FILE" | grep -o "[0-9]*")): " length
            if [[ "$length" =~ ^[0-9]+$ ]]; then
                sed -i "s/minMessageLength: [0-9]*/minMessageLength: $length/" "$CONFIG_FILE"
                echo -e "${GREEN}✅ Minimum message length updated to: $length${NC}"
            else
                echo -e "${RED}❌ Invalid number${NC}"
            fi
            ;;
        3)
            current=$(grep "requireColonAfterTicket:" "$CONFIG_FILE" | grep -o "true\|false")
            if [ "$current" = "true" ]; then
                sed -i 's/requireColonAfterTicket: true/requireColonAfterTicket: false/' "$CONFIG_FILE"
                echo -e "${GREEN}✅ Colon requirement disabled${NC}"
            else
                sed -i 's/requireColonAfterTicket: false/requireColonAfterTicket: true/' "$CONFIG_FILE"
                echo -e "${GREEN}✅ Colon requirement enabled${NC}"
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            ;;
    esac
}

# Function to test configuration
test_configuration() {
    echo -e "${BLUE}🧪 Test Configuration${NC}"
    echo "===================="
    
    if [ -f "tools/test-jira-validation.js" ]; then
        node tools/test-jira-validation.js
    else
        echo -e "${RED}❌ Test file not found${NC}"
        echo "Please ensure test-jira-validation.js exists"
    fi
}

# Main menu
main_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}🎫 Jira Configuration Menu${NC}"
        echo "=========================="
        echo "1. Show current configuration"
        echo "2. Add project prefix"
        echo "3. Remove project prefix"
        echo "4. Update validation settings"
        echo "5. Test configuration"
        echo "6. Exit"
        echo ""
        
        read -p "Choose option (1-6): " choice
        
        case $choice in
            1) show_current_config ;;
            2) add_project_prefix ;;
            3) remove_project_prefix ;;
            4) update_validation_settings ;;
            5) test_configuration ;;
            6) 
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option. Please choose 1-6.${NC}"
                ;;
        esac
    done
}

# Check if configuration exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
    echo "Please run setup-jira-validation.sh first"
    exit 1
fi

# Start main menu
main_menu
