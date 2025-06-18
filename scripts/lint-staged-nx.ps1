# Nx Lint-Staged PowerShell Script - Windows Compatible
# Usage: Called by lint-staged with staged file paths as arguments

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$StagedFiles
)

# Enable strict error handling
$ErrorActionPreference = "Stop"

# Colors for output (Windows PowerShell compatible)
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check if files were provided
if (-not $StagedFiles -or $StagedFiles.Count -eq 0) {
    Write-Warning "No files provided to lint"
    exit 0
}

Write-Info "Linting $($StagedFiles.Count) staged files..."

# Function to get project for a file (Windows path handling)
function Get-ProjectForFile {
    param([string]$FilePath)
    
    # Normalize path separators for Windows
    $normalizedPath = $FilePath -replace '\\', '/'
    
    if ($normalizedPath -match '^apps/([^/]+)') {
        return $matches[1]
    }
    elseif ($normalizedPath -match '^libs/([^/]+)') {
        return $matches[1]
    }
    else {
        return $null
    }
}

# Group files by project
$projectFiles = @{}
$workspaceFiles = @()

foreach ($file in $StagedFiles) {
    if (Test-Path $file) {
        $project = Get-ProjectForFile $file
        if ($project) {
            if (-not $projectFiles.ContainsKey($project)) {
                $projectFiles[$project] = @()
            }
            $projectFiles[$project] += $file
        }
        else {
            $workspaceFiles += $file
        }
    }
}

# Function to lint files with ESLint directly
function Invoke-ESLintDirect {
    param([string[]]$Files)
    
    Write-Info "Running ESLint directly on $($Files.Count) files..."
    
    try {
        # Create temporary file list for ESLint
        $tempFile = [System.IO.Path]::GetTempFileName()
        $Files | Out-File -FilePath $tempFile -Encoding UTF8
        
        # Run ESLint with file list
        $eslintResult = & npx eslint --fix --file-list $tempFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "ESLint completed successfully"
            Remove-Item $tempFile -Force
            return $true
        }
        else {
            Write-Warning "Batch linting failed, trying individual files..."
            Remove-Item $tempFile -Force
            
            # Fallback: lint files individually
            $failedFiles = @()
            foreach ($file in $Files) {
                $result = & npx eslint --fix $file 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $failedFiles += $file
                }
            }
            
            if ($failedFiles.Count -gt 0) {
                Write-Error "Linting failed for files: $($failedFiles -join ', ')"
                return $false
            }
            else {
                Write-Success "All files linted successfully"
                return $true
            }
        }
    }
    catch {
        Write-Error "ESLint execution failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to lint using Nx project-specific commands
function Invoke-NxProjectLint {
    param(
        [string]$Project,
        [string[]]$Files
    )
    
    Write-Info "Linting project '$Project' with $($Files.Count) files..."
    
    try {
        # Check if project has lint target
        $projectInfo = & nx show project $Project --json 2>$null | ConvertFrom-Json
        
        if ($projectInfo.targets.lint) {
            # Prepare file arguments for Nx
            $fileArgs = ($Files | ForEach-Object { "`"$_`"" }) -join ' '
            
            # Run nx lint for specific project
            $nxResult = & nx lint $Project --fix --files=$fileArgs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Project '$Project' linted successfully"
                return $true
            }
            else {
                Write-Warning "Nx lint failed for project '$Project', falling back to direct ESLint..."
                return Invoke-ESLintDirect $Files
            }
        }
        else {
            Write-Warning "Project '$Project' has no lint target, using direct ESLint..."
            return Invoke-ESLintDirect $Files
        }
    }
    catch {
        Write-Warning "Nx command failed for project '$Project', using direct ESLint..."
        return Invoke-ESLintDirect $Files
    }
}

# Main linting logic
$overallSuccess = $true

# Lint project-specific files
foreach ($project in $projectFiles.Keys) {
    $files = $projectFiles[$project]
    
    if (-not (Invoke-NxProjectLint $project $files)) {
        $overallSuccess = $false
    }
}

# Lint workspace-level files
if ($workspaceFiles.Count -gt 0) {
    Write-Info "Linting $($workspaceFiles.Count) workspace-level files..."
    if (-not (Invoke-ESLintDirect $workspaceFiles)) {
        $overallSuccess = $false
    }
}

# Final result
if ($overallSuccess) {
    Write-Success "All staged files linted successfully!"
    exit 0
}
else {
    Write-Error "Some files failed linting. Please fix the issues and try again."
    exit 1
}
