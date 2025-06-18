// Your project's import resolver configuration affects this rule

// These imports work because of your resolver settings:
// "import/resolver": {
//   "typescript": {
//     "alwaysTryTypes": true
//   },
//   "node": {
//     "extensions": [".js", ".jsx", ".ts", ".tsx"]
//   }
// }

// TypeScript path mapping resolution
import { Button } from "@/components/ui/Button" // Resolves via tsconfig paths

// Automatic extension resolution
import { helper } from "./helper" // Finds helper.ts automatically

// Type-only imports (still need to resolve)
import type { ApiResponse } from "@/types/api" // Must resolve to actual file
