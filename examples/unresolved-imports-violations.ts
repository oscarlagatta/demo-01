// ❌ VIOLATIONS - These will trigger ESLint errors

// Typo in file name
import { Button } from "./componets/Button" // Should be 'components'

// Wrong relative path depth
import { utils } from "../utils" // Should be '../../utils'

// Missing file extension where required
import config from "./config" // Should be './config.json' or './config.ts'

// Package not in dependencies
import { someFunction } from "non-existent-package"

// Case sensitivity issue (on case-sensitive systems)
import { MyComponent } from "./MyComponent" // File is actually 'mycomponent.tsx'

// Incorrect barrel export reference
import { SpecificUtil } from "./utils" // utils/index.ts doesn't export SpecificUtil
