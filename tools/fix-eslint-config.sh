#!/bin/bash

echo "🔧 Fixing ESLint Configuration Issues"
echo "===================================="

# Colors for output
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

# Create backup directory
backup_dir="config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"

print_header "Step 1: Backing Up Current Configuration"

# Backup existing config files
for config in .eslintrc.js .eslintrc.json .eslintrc.yml .eslintrc.yaml eslint.config.js eslint.config.mjs; do
    if [ -f "$config" ]; then
        cp "$config" "$backup_dir/"
        print_status "Backed up $config"
    fi
done

print_header "Step 2: Detecting Current Configuration Format"

# Determine the primary config file
primary_config=""
if [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
    primary_config="eslint.config.js"
    config_format="flat"
    print_info "Detected flat config format"
elif [ -f ".eslintrc.js" ]; then
    primary_config=".eslintrc.js"
    config_format="legacy"
    print_info "Detected legacy JavaScript config"
elif [ -f ".eslintrc.json" ]; then
    primary_config=".eslintrc.json"
    config_format="legacy"
    print_info "Detected legacy JSON config"
else
    print_warning "No primary config file found, creating new one"
    primary_config=".eslintrc.js"
    config_format="legacy"
fi

print_header "Step 3: Creating Optimized Configuration"

if [ "$config_format" = "flat" ]; then
    # Create flat config (ESLint 9+)
    cat > eslint.config.js << 'EOF'
import js from '@eslint/js';
import typescript from 'typescript-eslint';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import simpleImportSort from 'eslint-plugin-simple-import-sort';
import unusedImports from 'eslint-plugin-unused-imports';
import tailwindcss from 'eslint-plugin-tailwindcss';

export default [
  js.configs.recommended,
  ...typescript.configs.recommended,
  {
    files: ['**/*.{js,jsx,ts,tsx}'],
    plugins: {
      'react': react,
      'react-hooks': reactHooks,
      'simple-import-sort': simpleImportSort,
      'unused-imports': unusedImports,
      'tailwindcss': tailwindcss,
    },
    rules: {
      // Simple Import Sort Rules
      'simple-import-sort/imports': 'error',
      'simple-import-sort/exports': 'error',
      
      // TypeScript Rules
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/prefer-const': 'error',
      '@typescript-eslint/no-var-requires': 'error',
      
      // React Rules
      'react/react-in-jsx-scope': 'off',
      'react/prop-types': 'off',
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
      
      // Unused Imports
      'unused-imports/no-unused-imports': 'error',
      'unused-imports/no-unused-vars': [
        'warn',
        {
          vars: 'all',
          varsIgnorePattern: '^_',
          args: 'after-used',
          argsIgnorePattern: '^_',
        },
      ],
      
      // Tailwind CSS
      'tailwindcss/classnames-order': 'warn',
      'tailwindcss/no-custom-classname': 'off',
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: typescript.parser,
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
  },
];
EOF
    print_status "Created flat config (eslint.config.js)"
else
    # Create legacy config
    cat > .eslintrc.js << 'EOF'
module.exports = {
  root: true,
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:react/jsx-runtime',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  plugins: [
    '@typescript-eslint',
    'react',
    'react-hooks',
    'simple-import-sort',
    'unused-imports',
    'tailwindcss',
  ],
  rules: {
    // Simple Import Sort Rules
    'simple-import-sort/imports': 'error',
    'simple-import-sort/exports': 'error',
    
    // TypeScript Rules
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/prefer-const': 'error',
    '@typescript-eslint/no-var-requires': 'error',
    
    // React Rules
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',
    
    // Unused Imports
    'unused-imports/no-unused-imports': 'error',
    'unused-imports/no-unused-vars': [
      'warn',
      {
        vars: 'all',
        varsIgnorePattern: '^_',
        args: 'after-used',
        argsIgnorePattern: '^_',
      },
    ],
    
    // Tailwind CSS
    'tailwindcss/classnames-order': 'warn',
    'tailwindcss/no-custom-classname': 'off',
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
  overrides: [
    {
      files: ['**/*.ts', '**/*.tsx'],
      parser: '@typescript-eslint/parser',
      parserOptions: {
        project: './tsconfig.json',
      },
    },
  ],
};
EOF
    print_status "Created legacy config (.eslintrc.js)"
fi

print_header "Step 4: Validating New Configuration"

# Test the new configuration
test_file="config-validation-test.ts"
cat > "$test_file" << 'EOF'
// Test file for configuration validation
import { z } from 'zod';
import React, { useState } from 'react';
import { readFileSync } from 'fs';
import path from 'path';
import { Component } from './local-component';

interface TestInterface {
    prop: any;
}

function testFunction(param: string): any {
    const unusedVariable = 'test';
    return param;
}

const TestComponent: React.FC = () => {
    const [count, setCount] = useState(0);
    return <div className="flex p-4 bg-white">{count}</div>;
};

export default TestComponent;
EOF

if npx eslint "$test_file" --format=json > config-test-results.json 2>&1; then
    print_status "New configuration is valid"
    
    if command -v jq >/dev/null 2>&1; then
        import_violations=$(jq '[.[].messages[] | select(.ruleId == "simple-import-sort/imports")] | length' config-test-results.json 2>/dev/null)
        ts_violations=$(jq '[.[].messages[] | select(.ruleId | contains("@typescript-eslint"))] | length' config-test-results.json 2>/dev/null)
        
        echo "  Import sort violations: $import_violations"
        echo "  TypeScript violations: $ts_violations"
        
        if [ "$import_violations" -gt 0 ] && [ "$ts_violations" -gt 0 ]; then
            print_status "Both plugins are working correctly!"
        else
            print_warning "Some plugins may need additional configuration"
        fi
    fi
else
    print_error "Configuration validation failed"
    cat config-test-results.json
fi

# Clean up
rm -f "$test_file" config-test-results.json

print_header "Step 5: Creating Documentation"

cat > docs/eslint-configuration-guide.md << 'EOF'
# ESLint Configuration Guide

## Overview

This project uses ESLint with the following plugins:
- `typescript-eslint` - TypeScript-specific linting rules
- `simple-import-sort` - Automatic import sorting
- `eslint-plugin-react` - React-specific rules
- `eslint-plugin-unused-imports` - Remove unused imports
- `eslint-plugin-tailwindcss` - Tailwind CSS class validation

## Configuration Files

### Primary Configuration
- **Legacy format**: `.eslintrc.js`
- **Flat config format**: `eslint.config.js` (ESLint 9+)

### Key Rules

#### Simple Import Sort
\`\`\`javascript
'simple-import-sort/imports': 'error',
'simple-import-sort/exports': 'error',
