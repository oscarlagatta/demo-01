// Library-specific ESLint concerns

// ❌ Bad for libraries - console logs in production
export function processData(data: any) {
  console.log("Processing:", data) // ESLint error in library config
  return data.map((item) => item.value)
}

// ❌ Bad for libraries - default exports make tree-shaking harder
export default function MyComponent() {
  return <div>Hello</div>
}

// ❌ Bad for libraries - implicit return types
export function calculateTotal(items) {
  // Missing return type
  return items.reduce((sum, item) => sum + item.price, 0)
}

// ✅ Good for libraries - explicit API
export function calculateTotalGood(items: Array<{ price: number }>): number {
  return items.reduce((sum, item) => sum + item.price, 0)
}

// ✅ Good for libraries - named exports
export function MyComponentGood(): JSX.Element {
  return <div>Hello</div>
}

// ✅ Good for libraries - no side effects
export const CONSTANTS = {
  MAX_ITEMS: 100,
  DEFAULT_TIMEOUT: 5000,
} as const
