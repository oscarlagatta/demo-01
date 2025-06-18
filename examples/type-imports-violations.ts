// ❌ VIOLATIONS - These will trigger ESLint errors

// Regular import when only used for typing
import type { User, ApiResponse } from "./types"
import type React from "react"

// Using imported types
function processUser(user: User): ApiResponse<User> {
  return { data: user, success: true }
}

// Using React only for JSX typing
const MyComponent: React.FC = () => {
  return <div>Hello</div>
}

// Mixed usage - some runtime, some type-only
import { validateUser, type UserSchema, type ErrorType } from "./validation"

function handleUser(user: UserSchema): ErrorType | null {
  return validateUser(user) // Only validateUser is used at runtime
}
