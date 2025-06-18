// Without strictNullChecks, TypeScript can't properly analyze these patterns:

// ❌ This rule can't work properly without strictNullChecks
function example1(value: string | null) {
  return value || "default" // Should be value ?? 'default'
}

// ❌ Rule can't detect the difference between these cases
function example2(value: string | undefined) {
  return value || "default" // Should be value ?? 'default'
}

// ❌ Without strict null checks, these are treated the same
function example3(value: string) {
  return value || "default" // This might be fine with ||
}

// ✅ With strictNullChecks, the rule can properly suggest:
function exampleCorrect(value: string | null | undefined) {
  return value ?? "default" // Nullish coalescing only for null/undefined
}
