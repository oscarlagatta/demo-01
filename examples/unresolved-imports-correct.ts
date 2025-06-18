// ✅ CORRECT - These resolve properly

// Correct relative paths
import { Button } from "./components/Button"
import { utils } from "../../utils"

// Proper package imports (packages exist in package.json)
import React from "react"
import { clsx } from "clsx"

// Correct file extensions
import config from "./config.json"
import type { Config } from "./types"

// Proper barrel exports
import { formatDate, validateEmail } from "./utils"

// Absolute imports with proper path mapping
import { Button as UIBUtton } from "@/components/ui/Button"
import type { User } from "@/types/user"
