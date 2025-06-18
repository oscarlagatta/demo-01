#!/bin/bash

# Nx Lint-Staged Script - Targets only uncommitted files
# Usage: Called by lint-staged with staged file paths as arguments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Get staged files passed by lint-staged
STAGED_FILES=("$@")

if [ ${#STAGED_FILES[@]} -eq 0 ]; then
    print_warning "No files provided to lint"
    exit 0
fi

print_info "Linting ${#STAGED_FILES[@]} staged files..."

# Create temporary file list for processing
TEMP_FILE_LIST=$(mktemp)
printf '%s\n' "${STAGED_FILES[@]}" > "$TEMP_FILE_LIST"

# Function to get project for a file
get_project_for_file() {
    local file="$1"
    # Try to determine project from file path
    if [[ "$file" == apps/* ]]; then
        echo "$file" | cut -d'/' -f2
    elif [[ "$file" == libs/* ]]; then
        echo "$file" | cut -d'/' -f2
    else
        # For root files, return empty (will use workspace lint)
        echo ""
    fi
}

# Group files by project
declare -A PROJECT_FILES
WORKSPACE_FILES=()

for file in "${STAGED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        project=$(get_project_for_file "$file")
        if [[ -n "$project" ]]; then
            if [[ -z "${PROJECT_FILES[$project]}" ]]; then
                PROJECT_FILES[$project]="$file"
            else
                PROJECT_FILES[$project]="${PROJECT_FILES[$project]} $file"
            fi
        else
            WORKSPACE_FILES+=("$file")
        fi
    fi
done

# Function to lint files with ESLint directly (most efficient)
lint_files_directly() {
    local files=("$@")
    print_info "Running ESLint directly on ${#files[@]} files..."
    
    # Create a temporary file with the list of files to lint
    local temp_file_list=$(mktemp)
    printf '%s\n' "${files[@]}" > "$temp_file_list"
    
    # Run ESLint with the file list
    if npx eslint --fix --file-list "$temp_file_list" 2>/dev/null; then
        print_success "ESLint completed successfully"
        rm "$temp_file_list"
        return 0
    else
        # Fallback: lint files individually to get better error reporting
        print_warning "Batch linting failed, trying individual files..."
        rm "$temp_file_list"
        
        local failed_files=()
        for file in "${files[@]}"; do
            if ! npx eslint --fix "$file" 2>/dev/null; then
                failed_files+=("$file")
            fi
        done
        
        if [ ${#failed_files[@]} -gt 0 ]; then
            print_error "Linting failed for files: ${failed_files[*]}"
            return 1
        else
            print_success "All files linted successfully"
            return 0
        fi
    fi
}

# Function to lint using Nx project-specific commands
lint_project_files() {
    local project="$1"
    shift
    local files=("$@")
    
    print_info "Linting project '$project' with ${#files[@]} files..."
    
    # Check if project has a lint target
    if nx show project "$project" --json 2>/dev/null | jq -e '.targets.lint' >/dev/null 2>&1; then
        # Create temporary ESLint config that only processes our specific files
        local temp_eslint_args=""
        for file in "${files[@]}"; do
            temp_eslint_args="$temp_eslint_args \"$file\""
        done
        
        # Run nx lint for the specific project
        if eval "nx lint $project --fix --files=$temp_eslint_args" 2>/dev/null; then
            print_success "Project '$project' linted successfully"
            return 0
        else
            print_warning "Nx lint failed for project '$project', falling back to direct ESLint..."
            lint_files_directly "${files[@]}"
            return $?
        fi
    else
        print_warning "Project '$project' has no lint target, using direct ESLint..."
        lint_files_directly "${files[@]}"
        return $?
    fi
}

# Main linting logic
OVERALL_SUCCESS=true

# Lint project-specific files
for project in "${!PROJECT_FILES[@]}"; do
    # Convert space-separated string back to array
    IFS=' ' read -ra files <<< "${PROJECT_FILES[$project]}"
    
    if ! lint_project_files "$project" "${files[@]}"; then
        OVERALL_SUCCESS=false
    fi
done

# Lint workspace-level files
if [ ${#WORKSPACE_FILES[@]} -gt 0 ]; then
    print_info "Linting ${#WORKSPACE_FILES[@]} workspace-level files..."
    if ! lint_files_directly "${WORKSPACE_FILES[@]}"; then
        OVERALL_SUCCESS=false
    fi
fi

# Clean up
rm -f "$TEMP_FILE_LIST"

# Final result
if [ "$OVERALL_SUCCESS" = true ]; then
    print_success "All staged files linted successfully!"
    exit 0
else
    print_error "Some files failed linting. Please fix the issues and try again."
    exit 1
fi
