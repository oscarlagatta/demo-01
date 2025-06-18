"use client"

import { useState } from "react"

// Application Component (more lenient)
export default function UserProfileApp({ userId }: { userId: string }) {
  console.log("Rendering user:", userId) // OK in apps

  const [user, setUser] = useState() // Implicit any OK

  // Internal function, no explicit return type needed
  const handleClick = () => {
    // Some logic
  }

  return <div onClick={handleClick}>User Profile</div>
}

// Library Component (stricter)
export interface UserProfileProps {
  userId: string
  onUserClick?: (userId: string) => void
}

export function UserProfile({ userId, onUserClick }: UserProfileProps): JSX.Element {
  // No console.log allowed

  const [user, setUser] = useState<User | null>(null) // Explicit typing

  // Explicit return type required
  const handleClick = (): void => {
    onUserClick?.(userId)
  }

  return <div onClick={handleClick}>User Profile</div>
}

// Named export for better tree-shaking
UserProfile.displayName = "UserProfile" // Required for debugging

interface User {
  id: string
  name: string
}
