#!/bin/bash

echo "🔄 CI/CD ESLint Plugin Verification"
echo "==================================="

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

# Set up environment
export NODE_ENV=test
export CI=true

# Create reports directory
mkdir -p reports/eslint-verification

print_info "Starting CI plugin verification..."

# Step 1: Verify ESLint installation and configuration
print_info "Step 1: Verifying ESLint setup..."

if ! command -v npx >/dev/null 2>&1; then
    print_error "npx not found"
    exit 1
fi

if ! npx eslint --version >/dev/null 2>&1; then
    print_error "ESLint not installed or not working"
    exit 1
fi

print_status "ESLint is available"

# Step 2: Check ESLint configuration
print_info "Step 2: Validating ESLint configuration..."

if npx eslint --print-config . >/dev/null 2>&1; then
    print_status "ESLint configuration is valid"
    npx eslint --print-config . > reports/eslint-verification/ci-config.json
else
    print_error "ESLint configuration is invalid"
    npx eslint --print-config . 2>&1 | tee reports/eslint-verification/ci-config-errors.txt
    exit 1
fi

# Step 3: Run plugin discovery
print_info "Step 3: Discovering installed plugins..."

./tools/discover-eslint-plugins.sh

# Step 4: Run comprehensive verification
print_info "Step 4: Running comprehensive plugin verification..."

if node tools/plugin-verification-framework.js; then
    print_status "Plugin verification completed successfully"
else
    print_error "Plugin verification failed"
    exit 1
fi

# Step 5: Check for critical plugins
print_info "Step 5: Checking critical plugins..."

critical_plugins=(
    "simple-import-sort"
    "@typescript-eslint/eslint-plugin"
)

for plugin in "${critical_plugins[@]}"; do
    if npm list "$plugin" >/dev/null 2>&1; then
        print_status "$plugin is installed"
    else
        print_error "Critical plugin missing: $plugin"
        exit 1
    fi
done

# Step 6: Performance check
print_info "Step 6: Running performance check..."

# Create a test file for performance testing
cat > /tmp/perf-test.ts << 'EOF'
import React from 'react';
import { useState } from 'react';
import axios from 'axios';
import { z } from 'zod';

function TestComponent() {
  const [data, setData] = useState('');
  return <div>{data}</div>;
}
EOF

# Measure ESLint performance
start_time=$(date +%s%N)
npx eslint /tmp/perf-test.ts >/dev/null 2>&1
end_time=$(date +%s%N)

duration=$((($end_time - $start_time) / 1000000)) # Convert to milliseconds

echo "ESLint performance: ${duration}ms" > reports/eslint-verification/ci-performance.txt

if [ $duration -gt 5000 ]; then # 5 seconds
    print_warning "ESLint is running slowly (${duration}ms)"
else
    print_status "ESLint performance is acceptable (${duration}ms)"
fi

# Clean up
rm -f /tmp/perf-test.ts

# Step 7: Generate CI summary
print_info "Step 7: Generating CI summary..."

cat > reports/eslint-verification/ci-summary.md << EOF
# CI ESLint Plugin Verification Summary

**Date**: $(date)
**Environment**: CI/CD Pipeline
**Node Version**: $(node --version)
**NPM Version**: $(npm --version)

## Results

$(if [ -f "reports/eslint-verification/comprehensive-verification.json" ]; then
    node -e "
    const report = require('./reports/eslint-verification/comprehensive-verification.json');
    console.log(\`- Total Plugins: \${report.totalPlugins}\`);
    console.log(\`- Working Plugins: \${report.summary.pluginsWorking}\`);
    console.log(\`- Failing Plugins: \${report.summary.pluginsFailing}\`);
    console.log(\`- Total Tests: \${report.summary.totalTests}\`);
    console.log(\`- Passed Tests: \${report.summary.totalPassed}\`);
    console.log(\`- Failed Tests: \${report.summary.totalFailed}\`);
    "
else
    echo "- Verification report not available"
fi)

## Performance

- ESLint execution time: $(cat reports/eslint-verification/ci-performance.txt)

## Status

$(if [ -f "reports/eslint-verification/comprehensive-verification.json" ]; then
    failing=$(node -e "console.log(require('./reports/eslint-verification/comprehensive-verification.json').summary.pluginsFailing)")
    if [ "$failing" -eq 0 ]; then
        echo "✅ All plugins are working correctly"
    else
        echo "❌ $failing plugin(s) have issues"
    fi
else
    echo "❌ Verification incomplete"
fi)
EOF

print_status "CI verification completed"

# Return appropriate exit code
if [ -f "reports/eslint-verification/comprehensive-verification.json" ]; then
    failing=$(node -e "console.log(require('./reports/eslint-verification/comprehensive-verification.json').summary.pluginsFailing)")
    if [ "$failing" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
