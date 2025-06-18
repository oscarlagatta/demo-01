// ✅ CORRECT - These follow the rule

// Type-only imports
import type { User, ApiResponse } from "./types"
import type React from "react"

// Using imported types
function processUser(user: User): ApiResponse<User> {
  return { data: user, success: true }
}

// React type-only import
const MyComponent: React.FC = () => {
  return <div>Hello</div>
}

// Mixed usage - separate type and runtime imports
import { validateUser } from "./validation"
import type { UserSchema, ErrorType } from "./validation"

function handleUser(user: UserSchema): ErrorType | null {
  return validateUser(user)
}

// Alternative inline type imports (also valid)
// import { validateUser, type UserSchema, type ErrorType } from './validation'
