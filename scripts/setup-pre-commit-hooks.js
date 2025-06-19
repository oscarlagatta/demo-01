#!/usr/bin/env node

const fs = require("fs")
const { execSync } = require("child_process")

class PreCommitSetup {
  constructor() {
    this.packageJsonPath = "package.json"
    this.huskyDir = ".husky"
  }

  async setup() {
    console.log("🔧 Setting up pre-commit hooks...")

    try {
      // Step 1: Install dependencies
      await this.installDependencies()

      // Step 2: Setup Husky
      await this.setupHusky()

      // Step 3: Configure lint-staged
      await this.configureLintStaged()

      // Step 4: Create pre-commit hook
      await this.createPreCommitHook()

      console.log("✅ Pre-commit hooks setup complete!")
      console.log("🚀 ESLint will now run automatically on staged files before each commit")
    } catch (error) {
      console.error("❌ Setup failed:", error.message)
      process.exit(1)
    }
  }

  async installDependencies() {
    console.log("📦 Installing dependencies...")

    const dependencies = ["husky", "lint-staged"]

    try {
      execSync(`npm install --save-dev ${dependencies.join(" ")}`, { stdio: "inherit" })
    } catch (error) {
      throw new Error("Failed to install dependencies")
    }
  }

  async setupHusky() {
    console.log("🐕 Setting up Husky...")

    try {
      execSync("npx husky install", { stdio: "inherit" })

      // Add husky install to package.json scripts
      const packageJson = JSON.parse(fs.readFileSync(this.packageJsonPath, "utf8"))

      if (!packageJson.scripts) {
        packageJson.scripts = {}
      }

      packageJson.scripts.prepare = "husky install"

      fs.writeFileSync(this.packageJsonPath, JSON.stringify(packageJson, null, 2))
    } catch (error) {
      throw new Error("Failed to setup Husky")
    }
  }

  async configureLintStaged() {
    console.log("🎭 Configuring lint-staged...")

    const packageJson = JSON.parse(fs.readFileSync(this.packageJsonPath, "utf8"))

    packageJson["lint-staged"] = {
      "*.{js,jsx,ts,tsx}": ["eslint --fix", "git add"],
    }

    fs.writeFileSync(this.packageJsonPath, JSON.stringify(packageJson, null, 2))
  }

  async createPreCommitHook() {
    console.log("🪝 Creating pre-commit hook...")

    const hookContent = `#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

echo "🔍 Running ESLint on staged files..."
npx lint-staged

if [ $? -ne 0 ]; then
  echo "❌ ESLint found issues. Please fix them before committing."
  echo "💡 Tip: Run 'npm run lint:fix' to auto-fix some issues"
  exit 1
fi

echo "✅ ESLint passed!"
`

    const hookPath = `${this.huskyDir}/pre-commit`

    // Ensure .husky directory exists
    if (!fs.existsSync(this.huskyDir)) {
      fs.mkdirSync(this.huskyDir, { recursive: true })
    }

    fs.writeFileSync(hookPath, hookContent)

    // Make hook executable
    try {
      execSync(`chmod +x ${hookPath}`)
    } catch (error) {
      console.warn("⚠️  Could not make hook executable (Windows?)")
    }
  }
}

// CLI execution
if (require.main === module) {
  const setup = new PreCommitSetup()
  setup.setup()
}

module.exports = PreCommitSetup
