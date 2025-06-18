#!/usr/bin/env node

const fs = require("fs")
const path = require("path")

console.log("🧪 Generating Plugin-Specific Tests")
console.log("===================================")

// Plugin test configurations
const pluginTests = {
  "simple-import-sort": {
    rules: ["simple-import-sort/imports", "simple-import-sort/exports"],
    testCases: [
      {
        name: "import-sorting",
        description: "Test import statement sorting",
        code: `
// This should trigger simple-import-sort/imports
import { z } from 'zod';
import React from 'react';
import { a } from './local-file';
import fs from 'fs';

export { z, a };
export { React };
        `,
        expectedViolations: ["simple-import-sort/imports", "simple-import-sort/exports"],
      },
    ],
  },
  "@typescript-eslint/eslint-plugin": {
    rules: ["@typescript-eslint/no-unused-vars", "@typescript-eslint/explicit-function-return-type"],
    testCases: [
      {
        name: "typescript-rules",
        description: "Test TypeScript-specific rules",
        code: `
// This should trigger @typescript-eslint rules
function testFunction(param: string) {
  const unusedVar = 'test';
  return param;
}

const implicitReturn = (x: number) => x * 2;
        `,
        expectedViolations: ["@typescript-eslint/no-unused-vars"],
      },
    ],
  },
  "eslint-plugin-react": {
    rules: ["react/jsx-uses-react", "react/jsx-uses-vars"],
    testCases: [
      {
        name: "react-jsx",
        description: "Test React JSX rules",
        code: `
// This should test React rules
import React from 'react';

function Component() {
  const unusedVar = 'test';
  return <div>Hello</div>;
}
        `,
        expectedViolations: ["react/jsx-uses-vars"],
      },
    ],
  },
  "eslint-plugin-import": {
    rules: ["import/no-unresolved", "import/order"],
    testCases: [
      {
        name: "import-rules",
        description: "Test import rules",
        code: `
// This should test import rules
import './non-existent-file';
import { z } from 'zod';
import React from 'react';
        `,
        expectedViolations: ["import/no-unresolved", "import/order"],
      },
    ],
  },
}

// Create test files directory
const testDir = "test-files/eslint-plugin-tests"
if (!fs.existsSync(testDir)) {
  fs.mkdirSync(testDir, { recursive: true })
}

// Generate test files for each plugin
Object.entries(pluginTests).forEach(([pluginName, config]) => {
  const pluginDir = path.join(testDir, pluginName.replace(/[@/]/g, "-"))
  if (!fs.existsSync(pluginDir)) {
    fs.mkdirSync(pluginDir, { recursive: true })
  }

  config.testCases.forEach((testCase, index) => {
    const fileName = `${testCase.name}.ts`
    const filePath = path.join(pluginDir, fileName)

    const fileContent = `// Test case: ${testCase.description}
// Expected violations: ${testCase.expectedViolations.join(", ")}
// Plugin: ${pluginName}

${testCase.code}
`

    fs.writeFileSync(filePath, fileContent)
    console.log(`✅ Generated test file: ${filePath}`)
  })

  // Generate plugin-specific test script
  const testScript = `#!/bin/bash
echo "🧪 Testing ${pluginName} plugin functionality"
echo "============================================="

# Run ESLint on test files
echo "Running ESLint on ${pluginName} test files..."
npx eslint "${pluginDir}/**/*.ts" --format=json > "reports/eslint-verification/${pluginName.replace(/[@/]/g, "-")}-results.json" 2>/dev/null

# Check if expected violations were found
echo "Analyzing results..."
node -e "
const results = require('./reports/eslint-verification/${pluginName.replace(/[@/]/g, "-")}-results.json');
const expectedRules = ${JSON.stringify(config.rules)};
const foundRules = new Set();

results.forEach(file => {
  file.messages.forEach(msg => {
    if (msg.ruleId) foundRules.add(msg.ruleId);
  });
});

console.log('Expected rules:', expectedRules);
console.log('Found violations:', Array.from(foundRules));

const missingRules = expectedRules.filter(rule => !foundRules.has(rule));
if (missingRules.length > 0) {
  console.log('❌ Missing rule violations:', missingRules);
  process.exit(1);
} else {
  console.log('✅ All expected rules are working');
}
"

echo "✅ ${pluginName} plugin test completed"
`

  const scriptPath = path.join("tools", `test-${pluginName.replace(/[@/]/g, "-")}.sh`)
  fs.writeFileSync(scriptPath, testScript)
  fs.chmodSync(scriptPath, "755")
  console.log(`✅ Generated test script: ${scriptPath}`)
})

// Generate master test runner
const masterTestScript = `#!/bin/bash
echo "🚀 Running All ESLint Plugin Tests"
echo "=================================="

mkdir -p reports/eslint-verification

# Run individual plugin tests
${Object.keys(pluginTests)
  .map((plugin) => `./tools/test-${plugin.replace(/[@/]/g, "-")}.sh`)
  .join("\n")}

echo ""
echo "📊 Generating summary report..."
node tools/generate-test-summary.js

echo "✅ All plugin tests completed!"
echo "📋 Check reports/eslint-verification/ for detailed results"
`

fs.writeFileSync("tools/test-all-eslint-plugins.sh", masterTestScript)
fs.chmodSync("tools/test-all-eslint-plugins.sh", "755")

console.log("✅ Generated master test script: tools/test-all-eslint-plugins.sh")
console.log("🎯 Test generation complete!")
