// ✅ Re-exports with types
export type { User } from "./types"
export { validateUser, type UserSchema } from "./validation"

// ✅ Dynamic imports (not affected by this rule)
const dynamicModule = await import("./dynamic-module")
type DynamicType = typeof dynamicModule.SomeType

// ❌ Common mistake - importing React for JSX
import type React from "react" // Should be: import type React from 'react'

interface Props {
  children: React.ReactNode // Using React only for typing
}
