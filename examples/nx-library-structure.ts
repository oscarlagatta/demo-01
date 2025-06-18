"use client"

import type React from "react"

// Non-buildable library structure in Nx
// libs/shared/ui/src/lib/button/button.tsx

export interface ButtonProps {
  children: React.ReactNode
  variant?: "primary" | "secondary"
  onClick?: () => void
}

// This code is NOT compiled separately
// It's included in the application's build process
export function Button({ children, variant = "primary", onClick }: ButtonProps) {
  return (
    <button className={`btn btn-${variant}`} onClick={onClick}>
      {children}
    </button>
  )
}
