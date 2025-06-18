#!/bin/bash

echo "🏥 Weekly ESLint Plugin Health Check"
echo "===================================="

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

# Create weekly report directory
WEEK_DIR="reports/weekly-health/$(date +%Y-W%U)"
mkdir -p "$WEEK_DIR"

print_info "Starting weekly health check for week $(date +%Y-W%U)..."

# 1. Plugin verification
print_info "1. Running comprehensive plugin verification..."
if node tools/plugin-verification-framework.js; then
    cp reports/eslint-verification/comprehensive-verification.json "$WEEK_DIR/"
    print_status "Plugin verification completed"
else
    print_error "Plugin verification failed"
fi

# 2. Performance monitoring
print_info "2. Running performance monitoring..."
if node tools/eslint-performance-monitor.js; then
    cp reports/eslint-performance/performance-report.md "$WEEK_DIR/"
    print_status "Performance monitoring completed"
else
    print_warning "Performance monitoring had issues"
fi

# 3. Check for outdated plugins
print_info "3. Checking for outdated plugins..."
npm outdated | grep eslint > "$WEEK_DIR/outdated-plugins.txt" 2>/dev/null || echo "No outdated ESLint plugins" > "$WEEK_DIR/outdated-plugins.txt"

# 4. Analyze recent commits for ESLint-related changes
print_info "4. Analyzing recent ESLint-related changes..."
git log --since="1 week ago" --grep="eslint\|lint" --oneline > "$WEEK_DIR/recent-eslint-commits.txt" 2>/dev/null || echo "No ESLint-related commits" > "$WEEK_DIR/recent-eslint-commits.txt"

# 5. Check configuration drift
print_info "5. Checking for configuration drift..."
if [ -f ".eslintrc.json" ]; then
    cp .eslintrc.json "$WEEK_DIR/current-eslint-config.json"
fi

# 6. Generate weekly summary
print_info "6. Generating weekly summary..."

cat > "$WEEK_DIR/weekly-summary.md" << EOF
# Weekly ESLint Plugin Health Check

**Week**: $(date +%Y-W%U)
**Date**: $(date)

## Summary

$(if [ -f "$WEEK_DIR/comprehensive-verification.json" ]; then
    node -e "
    const report = require('./$WEEK_DIR/comprehensive-verification.json');
    console.log(\`- Plugins tested: \${report.totalPlugins}\`);
    console.log(\`- Plugins working: \${report.summary.pluginsWorking}\`);
    console.log(\`- Plugins with issues: \${report.summary.pluginsFailing}\`);
    console.log(\`- Total tests: \${report.summary.totalTests}\`);
    console.log(\`- Tests passed: \${report.summary.totalPassed}\`);
    "
else
    echo "- Plugin verification data not available"
fi)

## Performance

$(if [ -f "reports/eslint-performance/performance-metrics.json" ]; then
    node -e "
    const metrics = require('./reports/eslint-performance/performance-metrics.json');
    const latest = metrics[metrics.length - 1];
    if (latest) {
        const avg = latest.measurements.reduce((sum, m) => sum + m.duration, 0) / latest.measurements.length;
        console.log(\`- Average execution time: \${avg.toFixed(0)}ms\`);
        console.log(\`- Performance status: \${avg > 1000 ? '⚠️ Slow' : avg > 500 ? '⚡ Moderate' : '✅ Good'}\`);
    }
    "
else
    echo "- Performance data not available"
fi)

## Outdated Plugins

\`\`\`
$(cat "$WEEK_DIR/outdated-plugins.txt")
\`\`\`

## Recent Changes

\`\`\`
$(cat "$WEEK_DIR/recent-eslint-commits.txt")
\`\`\`

## Recommendations

$(if [ -f "$WEEK_DIR/comprehensive-verification.json" ]; then
    failing=$(node -e "console.log(require('./$WEEK_DIR/comprehensive-verification.json').summary.pluginsFailing)")
    if [ "$failing" -gt 0 ]; then
        echo "⚠️ **Action Required**: $failing plugin(s) need attention"
        echo "- Review plugin verification report"
        echo "- Check plugin configurations"
        echo "- Update or reinstall problematic plugins"
    else
        echo "✅ **All Good**: All plugins are working correctly"
    fi
else
    echo "- Review plugin verification results when available"
fi)

$(if [ -s "$WEEK_DIR/outdated-plugins.txt" ] && ! grep -q "No outdated" "$WEEK_DIR/outdated-plugins.txt"; then
    echo ""
    echo "📦 **Plugin Updates Available**:"
    echo "- Consider updating outdated ESLint plugins"
    echo "- Test updates in a separate branch first"
    echo "- Review changelog for breaking changes"
fi)

## Next Steps

- [ ] Review any failing plugin tests
- [ ] Update outdated plugins if needed
- [ ] Monitor performance trends
- [ ] Update team on any configuration changes
EOF

print_status "Weekly summary generated: $WEEK_DIR/weekly-summary.md"

# 7. Send notifications if there are issues
if [ -f "$WEEK_DIR/comprehensive-verification.json" ]; then
    failing=$(node -e "console.log(require('./$WEEK_DIR/comprehensive-verification.json').summary.pluginsFailing)" 2>/dev/null || echo "0")
    
    if [ "$failing" -gt 0 ]; then
        print_warning "Found $failing failing plugin(s) - consider sending team notification"
        
        # Create notification file
        cat > "$WEEK_DIR/notification.md" << EOF
🚨 **ESLint Plugin Health Alert**

Week $(date +%Y-W%U) health check found $failing plugin(s) with issues.

**Action Required:**
- Review the weekly health report: $WEEK_DIR/weekly-summary.md
- Check plugin verification details
- Update or fix problematic plugins

**Report Location:** \`$WEEK_DIR/\`
EOF
        
        print_info "Notification prepared: $WEEK_DIR/notification.md"
    fi
fi

print_status "Weekly health check completed!"
print_info "Reports saved to: $WEEK_DIR/"

# Return appropriate exit code
if [ -f "$WEEK_DIR/comprehensive-verification.json" ]; then
    failing=$(node -e "console.log(require('./$WEEK_DIR/comprehensive-verification.json').summary.pluginsFailing)" 2>/dev/null || echo "0")
    if [ "$failing" -gt 0 ]; then
        exit 1
    fi
fi

exit 0
