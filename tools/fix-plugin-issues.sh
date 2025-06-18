#!/bin/bash

echo "🔧 ESLint Plugin Issue Resolver"
echo "==============================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Function to fix installation issues
fix_installation_issues() {
    local plugin="$1"
    print_info "Fixing installation issues for $plugin..."
    
    # Try to install the plugin
    if npm install --save-dev "$plugin"; then
        print_status "Successfully installed $plugin"
        return 0
    else
        print_error "Failed to install $plugin"
        return 1
    fi
}

# Function to fix configuration issues
fix_configuration_issues() {
    local plugin="$1"
    print_info "Fixing configuration issues for $plugin..."
    
    # Get the plugin short name
    local plugin_short_name
    case "$plugin" in
        "eslint-plugin-"*)
            plugin_short_name="${plugin#eslint-plugin-}"
            ;;
        "@typescript-eslint/eslint-plugin")
            plugin_short_name="@typescript-eslint"
            ;;
        *)
            plugin_short_name="$plugin"
            ;;
    esac
    
    # Check if ESLint config exists
    local config_file=""
    if [ -f ".eslintrc.json" ]; then
        config_file=".eslintrc.json"
    elif [ -f ".eslintrc.js" ]; then
        config_file=".eslintrc.js"
    elif [ -f "eslint.config.js" ]; then
        config_file="eslint.config.js"
    else
        print_warning "No ESLint configuration file found, creating .eslintrc.json"
        echo '{"extends": ["eslint:recommended"], "plugins": [], "rules": {}}' > .eslintrc.json
        config_file=".eslintrc.json"
    fi
    
    # Add plugin to configuration
    if [ "$config_file" = ".eslintrc.json" ]; then
        # Use jq to add plugin
        if command -v jq >/dev/null 2>&1; then
            jq --arg plugin "$plugin_short_name" '.plugins += [$plugin] | .plugins |= unique' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
            print_status "Added $plugin_short_name to $config_file"
        else
            print_warning "jq not available, manual configuration needed"
        fi
    else
        print_warning "Manual configuration needed for $config_file"
        echo "Add '$plugin_short_name' to the plugins array in $config_file"
    fi
}

# Function to fix dependency issues
fix_dependency_issues() {
    local plugin="$1"
    print_info "Fixing dependency issues for $plugin..."
    
    # Common peer dependencies for ESLint plugins
    local common_deps=()
    
    case "$plugin" in
        "@typescript-eslint/eslint-plugin")
            common_deps=("typescript" "@typescript-eslint/parser")
            ;;
        "eslint-plugin-react")
            common_deps=("react")
            ;;
        "eslint-plugin-react-hooks")
            common_deps=("react" "eslint-plugin-react")
            ;;
        "eslint-plugin-jsx-a11y")
            common_deps=("eslint-plugin-react")
            ;;
    esac
    
    # Install common dependencies
    for dep in "${common_deps[@]}"; do
        if ! npm list "$dep" >/dev/null 2>&1; then
            print_info "Installing missing dependency: $dep"
            if npm install --save-dev "$dep"; then
                print_status "Installed $dep"
            else
                print_warning "Failed to install $dep - may need manual installation"
            fi
        fi
    done
}

# Function to add common rules for a plugin
add_common_rules() {
    local plugin="$1"
    print_info "Adding common rules for $plugin..."
    
    local config_file=".eslintrc.json"
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Define common rules for each plugin
    case "$plugin" in
        "simple-import-sort")
            if command -v jq >/dev/null 2>&1; then
                jq '.rules["simple-import-sort/imports"] = "error" | .rules["simple-import-sort/exports"] = "error"' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
                print_status "Added simple-import-sort rules"
            fi
            ;;
        "@typescript-eslint/eslint-plugin")
            if command -v jq >/dev/null 2>&1; then
                jq '.rules["@typescript-eslint/no-unused-vars"] = "error" | .rules["@typescript-eslint/no-explicit-any"] = "warn"' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
                print_status "Added TypeScript ESLint rules"
            fi
            ;;
        "eslint-plugin-react")
            if command -v jq >/dev/null 2>&1; then
                jq '.rules["react/jsx-uses-react"] = "error" | .rules["react/jsx-uses-vars"] = "error"' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
                print_status "Added React rules"
            fi
            ;;
    esac
}

# Main fix function
fix_plugin() {
    local plugin="$1"
    print_info "Attempting to fix issues with $plugin..."
    
    # Run debug to identify issues
    local debug_report="reports/eslint-debugging/${plugin//[@\/]/-}-debug.json"
    
    if [ ! -f "$debug_report" ]; then
        print_info "Running debug first..."
        node tools/debug-plugin-issues.js "$plugin"
    fi
    
    if [ ! -f "$debug_report" ]; then
        print_error "Could not generate debug report for $plugin"
        return 1
    fi
    
    # Parse issues from debug report
    local has_installation_issue=$(node -e "
        try {
            const report = require('./$debug_report');
            console.log(report.issues.some(i => i.type === 'installation') ? 'true' : 'false');
        } catch(e) { console.log('false'); }
    ")
    
    local has_config_issue=$(node -e "
        try {
            const report = require('./$debug_report');
            console.log(report.issues.some(i => i.type === 'configuration') ? 'true' : 'false');
        } catch(e) { console.log('false'); }
    ")
    
    local has_dependency_issue=$(node -e "
        try {
            const report = require('./$debug_report');
            console.log(report.issues.some(i => i.type === 'dependencies') ? 'true' : 'false');
        } catch(e) { console.log('false'); }
    ")
    
    # Fix issues in order of priority
    local fixed=false
    
    if [ "$has_installation_issue" = "true" ]; then
        if fix_installation_issues "$plugin"; then
            fixed=true
        fi
    fi
    
    if [ "$has_dependency_issue" = "true" ]; then
        fix_dependency_issues "$plugin"
        fixed=true
    fi
    
    if [ "$has_config_issue" = "true" ]; then
        fix_configuration_issues "$plugin"
        add_common_rules "$plugin"
        fixed=true
    fi
    
    if [ "$fixed" = "true" ]; then
        print_status "Applied fixes for $plugin"
        
        # Re-run verification
        print_info "Re-running verification..."
        if node tools/plugin-verification-framework.js; then
            print_status "$plugin is now working correctly"
            return 0
        else
            print_warning "$plugin may still have issues"
            return 1
        fi
    else
        print_info "No automatic fixes available for $plugin"
        return 1
    fi
}

# Fix all plugins with issues
fix_all_plugins() {
    print_info "Fixing all plugins with issues..."
    
    # Run debug on all plugins first
    node tools/debug-plugin-issues.js
    
    # Get list of plugins with issues
    local master_report="reports/eslint-debugging/master-debug-report.json"
    
    if [ ! -f "$master_report" ]; then
        print_error "Master debug report not found"
        return 1
    fi
    
    # Get plugins with issues
    local broken_plugins=$(node -e "
        try {
            const report = require('./$master_report');
            const broken = report.results.filter(r => r.issues.length > 0).map(r => r.plugin);
            console.log(broken.join(' '));
        } catch(e) { console.log(''); }
    ")
    
    if [ -z "$broken_plugins" ]; then
        print_status "No plugins need fixing"
        return 0
    fi
    
    print_info "Found plugins needing fixes: $broken_plugins"
    
    local fixed_count=0
    local total_count=0
    
    for plugin in $broken_plugins; do
        ((total_count++))
        print_info "Fixing plugin $total_count: $plugin"
        
        if fix_plugin "$plugin"; then
            ((fixed_count++))
        fi
    done
    
    print_info "Fixed $fixed_count out of $total_count plugins"
    
    if [ $fixed_count -eq $total_count ]; then
        print_status "All plugins fixed successfully"
        return 0
    else
        print_warning "Some plugins still have issues"
        return 1
    fi
}

# Main execution
if [ $# -eq 0 ]; then
    print_info "Fixing all plugins with issues..."
    fix_all_plugins
else
    plugin="$1"
    print_info "Fixing specific plugin: $plugin"
    fix_plugin "$plugin"
fi
