const fs = require("fs")
const path = require("path")

class TailwindESLintFixer {
  constructor() {
    this.fixes = []
  }

  // Fix 1: Update ESLint configuration for better Tailwind v3 support
  updateESLintConfig() {
    const eslintConfigPath = ".eslintrc.json"

    try {
      const config = JSON.parse(fs.readFileSync(eslintConfigPath, "utf8"))

      // Enhanced Tailwind settings
      config.settings.tailwindcss = {
        ...config.settings.tailwindcss,
        callees: ["cn", "clsx", "cva", "classNames"],
        cssFilesRefreshRate: 5000,
        removeDuplicates: true,
        whitelist: [
          // Arbitrary values
          "^\\[.*\\]$",
          // Data attributes
          "^data-\\[.*\\]:",
          // Group/peer selectors
          "^(group|peer)-\\[.*\\]:",
          // CSS features
          "^supports-\\[.*\\]:",
          // Custom animations
          "^animate-.*",
          // Sizing utilities
          "^(min|max)-(w|h)-\\[.*\\]$",
          // Spacing utilities
          "^(m|p)(t|r|b|l|x|y)?-\\[.*\\]$",
          // Color utilities
          "^(bg|text|border|ring)-\\[.*\\]$",
        ],
      }

      // Update Tailwind rules
      config.rules["tailwindcss/no-custom-classname"] = [
        "warn",
        {
          callees: ["cn", "clsx", "cva", "classNames"],
          config: "tailwind.config.ts",
          whitelist: config.settings.tailwindcss.whitelist,
        },
      ]

      // Add new Tailwind v3 specific rules
      config.rules["tailwindcss/no-arbitrary-value"] = "off"
      config.rules["tailwindcss/enforces-negative-arbitrary-values"] = "error"
      config.rules["tailwindcss/no-unnecessary-arbitrary-value"] = "warn"

      fs.writeFileSync(eslintConfigPath, JSON.stringify(config, null, 2))

      this.fixes.push({
        type: "config-update",
        message: "Updated .eslintrc.json with enhanced Tailwind v3 support",
        file: eslintConfigPath,
      })
    } catch (error) {
      console.error("Failed to update ESLint config:", error.message)
    }
  }

  // Fix 2: Create Tailwind class validation utility
  createClassValidator() {
    const validatorContent = `
// Utility to validate Tailwind classes before linting
export function validateTailwindClass(className: string): boolean {
  const tailwindV3Patterns = [
    /^\\[.*\\]$/, // Arbitrary values
    /^data-\\[.*\\]:/, // Data attributes
    /^group-\\[.*\\]:/, // Group selectors
    /^peer-\\[.*\\]:/, // Peer selectors
    /^supports-\\[.*\\]:/, // CSS supports
    /^animate-/, // Custom animations
  ];

  // Check if class matches known Tailwind v3 patterns
  return tailwindV3Patterns.some(pattern => pattern.test(className));
}

// Helper for className props validation
export function cn(...classes: (string | undefined | null | boolean)[]): string {
  return classes.filter(Boolean).join(' ');
}
`

    const utilsDir = "lib"
    if (!fs.existsSync(utilsDir)) {
      fs.mkdirSync(utilsDir, { recursive: true })
    }

    fs.writeFileSync(path.join(utilsDir, "tailwind-validator.ts"), validatorContent)

    this.fixes.push({
      type: "utility-creation",
      message: "Created Tailwind class validation utility",
      file: "lib/tailwind-validator.ts",
    })
  }

  // Fix 3: Update package.json scripts for better linting
  updatePackageScripts() {
    const packageJsonPath = "package.json"

    try {
      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"))

      // Add Tailwind-specific linting scripts
      packageJson.scripts = {
        ...packageJson.scripts,
        "lint:tailwind": "eslint --ext .ts,.tsx --fix --config configs/eslint-tailwind-optimized.json",
        "lint:tailwind:check": "eslint --ext .ts,.tsx --config configs/eslint-tailwind-optimized.json",
        "validate:tailwind": "node tools/tailwind-class-validator.js",
      }

      fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2))

      this.fixes.push({
        type: "script-update",
        message: "Added Tailwind-specific linting scripts to package.json",
        file: packageJsonPath,
      })
    } catch (error) {
      console.error("Failed to update package.json:", error.message)
    }
  }

  // Fix 4: Create component-specific ESLint overrides
  createComponentOverrides() {
    const overridesConfig = {
      overrides: [
        {
          files: ["**/components/ui/**/*.{ts,tsx}"],
          rules: {
            "tailwindcss/no-custom-classname": [
              "warn",
              {
                whitelist: [
                  "^\\[.*\\]$", // Allow all arbitrary values in UI components
                  "^data-\\[.*\\]:", // Data attributes for Radix UI
                  "^group-\\[.*\\]:", // Group states
                  "^peer-\\[.*\\]:", // Peer states
                ],
              },
            ],
          },
        },
        {
          files: ["**/app/**/*.{ts,tsx}", "**/pages/**/*.{ts,tsx}"],
          rules: {
            "tailwindcss/no-custom-classname": [
              "error", // Stricter for pages
              {
                whitelist: [
                  "^animate-.*", // Custom animations only
                  "^data-\\[.*\\]:", // Data attributes only
                ],
              },
            ],
          },
        },
      ],
    }

    fs.writeFileSync("configs/eslint-component-overrides.json", JSON.stringify(overridesConfig, null, 2))

    this.fixes.push({
      type: "override-creation",
      message: "Created component-specific ESLint overrides",
      file: "configs/eslint-component-overrides.json",
    })
  }

  // Apply all fixes
  applyAllFixes() {
    console.log("🔧 Applying Tailwind ESLint fixes...\n")

    this.updateESLintConfig()
    this.createClassValidator()
    this.updatePackageScripts()
    this.createComponentOverrides()

    console.log("✅ Applied fixes:")
    this.fixes.forEach((fix) => {
      console.log(`   ${fix.type}: ${fix.message}`)
      console.log(`   📁 ${fix.file}\n`)
    })

    console.log("🚀 Next steps:")
    console.log("   1. Run: npm run lint:tailwind:check")
    console.log("   2. Run: npm run validate:tailwind")
    console.log("   3. Update your components to use the new validator")
    console.log("   4. Consider upgrading to ESLint v9 for better performance")
  }
}

// Execute fixes
const fixer = new TailwindESLintFixer()
fixer.applyAllFixes()

module.exports = TailwindESLintFixer
