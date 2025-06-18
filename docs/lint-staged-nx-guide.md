# Nx Lint-Staged Configuration Guide

This guide explains how to efficiently lint only uncommitted files in an Nx monorepo using a custom lint-staged configuration.

## Problem Solved

The default `nx affected:lint --fix --files` command processes all libraries regardless of changes, which is inefficient in large monorepos. Our solution targets only the specific uncommitted files.

## Solution Overview

Our custom `lint-staged-nx.sh` script:

1. **Receives staged files** from lint-staged
2. **Groups files by project** (apps/libs vs workspace-level)
3. **Uses direct ESLint** for maximum efficiency
4. **Falls back to Nx commands** when needed
5. **Provides clear feedback** on what was linted

## Key Features

### 🎯 **Targeted Linting**
- Only lints the exact files you've changed
- Groups files by project for efficient processing
- Handles both project-specific and workspace-level files

### ⚡ **Performance Optimized**
- Uses ESLint directly when possible (fastest)
- Falls back to Nx project commands when needed
- Processes files in batches for efficiency

### 🛡️ **Robust Error Handling**
- Graceful fallbacks if Nx commands fail
- Individual file processing for better error reporting
- Clear success/failure indicators

### 📊 **Clear Output**
- Color-coded status messages
- File count and project information
- Detailed error reporting when issues occur

## Configuration Files

### 1. Main Script: `scripts/lint-staged-nx.sh`
The core script that handles the intelligent linting logic.

### 2. Package.json Configuration
\`\`\`json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "./scripts/lint-staged-nx.sh",
      "nx format:write --uncommitted"
    ],
    "*.{json,md,css,scss,html}": [
      "nx format:write --uncommitted"
    ]
  }
}
\`\`\`

### 3. Test Script: `scripts/test-lint-staged.sh`
Validates that the configuration works correctly.

## Usage

### Automatic (Recommended)
The script runs automatically when you commit files:

\`\`\`bash
git add src/app/component.tsx
git commit -m "feat: add new component"
# lint-staged runs automatically via Husky pre-commit hook
\`\`\`

### Manual Testing
\`\`\`bash
# Test the configuration
npm run lint:staged:test

# Run on specific files
./scripts/lint-staged-nx.sh apps/my-app/src/component.tsx libs/shared/src/utils.ts

# Test with staged files
git add .
npx lint-staged
\`\`\`

## How It Works

### File Processing Logic

1. **File Grouping**: Files are grouped by project based on their path:
   - `apps/my-app/src/file.ts` → Project: `my-app`
   - `libs/shared/src/file.ts` → Project: `shared`
   - `tools/script.ts` → Workspace-level file

2. **Linting Strategy**:
   - **Direct ESLint**: Used when possible for maximum speed
   - **Nx Project Lint**: Used for projects with specific lint configurations
   - **Individual Files**: Fallback for better error reporting

3. **Error Handling**:
   - If batch linting fails, tries individual files
   - If Nx commands fail, falls back to direct ESLint
   - Clear error messages for debugging

### Performance Comparison

| Method | Speed | Accuracy | Use Case |
|--------|-------|----------|----------|
| `nx affected:lint` | Slow | High | All affected projects |
| `eslint --fix <files>` | Fast | High | Specific files only |
| **Our Solution** | **Fast** | **High** | **Staged files only** |

## Troubleshooting

### Common Issues

#### Script Not Executable
\`\`\`bash
chmod +x scripts/lint-staged-nx.sh
\`\`\`

#### ESLint Not Found
\`\`\`bash
npm install --save-dev eslint
\`\`\`

#### Nx Commands Failing
The script automatically falls back to direct ESLint, but you can debug with:
\`\`\`bash
nx show projects --json
nx show project <project-name> --json
\`\`\`

#### Performance Issues
- Check if you have too many staged files
- Consider running `nx reset` to clear cache
- Verify ESLint configuration is optimized

### Debug Mode
Add debug output by modifying the script:
\`\`\`bash
# Add this near the top of lint-staged-nx.sh
set -x  # Enable debug mode
\`\`\`

## Best Practices

### 1. **Stage Files Strategically**
\`\`\`bash
# Good: Stage related files together
git add src/components/button/

# Avoid: Staging entire workspace
git add .  # Only if necessary
\`\`\`

### 2. **Use with Pre-commit Hooks**
Ensure Husky is configured to run lint-staged:
\`\`\`bash
# .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
\`\`\`

### 3. **Monitor Performance**
\`\`\`bash
# Time the linting process
time npx lint-staged
\`\`\`

### 4. **Keep ESLint Config Optimized**
- Use `extends` instead of individual rules when possible
- Avoid expensive rules for large files
- Use `.eslintignore` to exclude unnecessary files

## Integration with CI/CD

The script works seamlessly with existing CI/CD pipelines:

\`\`\`yaml
# GitHub Actions example
- name: Run lint-staged
  run: |
    git diff --name-only HEAD~1 HEAD | xargs ./scripts/lint-staged-nx.sh
\`\`\`

## Migration from Old Configuration

### Before (Inefficient)
\`\`\`json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "nx affected:lint --fix --files --parallel=1"
    ]
  }
}
\`\`\`

### After (Optimized)
\`\`\`json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "./scripts/lint-staged-nx.sh"
    ]
  }
}
\`\`\`

## Maintenance

### Regular Updates
- Keep ESLint and plugins updated
- Test the configuration after Nx updates
- Monitor performance and adjust as needed

### Monitoring
\`\`\`bash
# Check script performance
./scripts/test-lint-staged.sh

# Validate configuration
npm run lint:staged:test
\`\`\`

## Support

If you encounter issues:

1. Run the test script: `./scripts/test-lint-staged.sh`
2. Check the troubleshooting section above
3. Verify your Nx and ESLint configurations
4. Test with a minimal set of files first

## Contributing

When modifying the script:

1. Test with various file combinations
2. Ensure error handling works correctly
3. Update documentation as needed
4. Run the test suite before committing
