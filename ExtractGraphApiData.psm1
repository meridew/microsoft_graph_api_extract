# ExtractGraphApiData Module

# Module-scoped strict settings (does not affect user's session)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Get the module's directory path
$script:ModuleRoot = $PSScriptRoot

# Load configuration
$script:Config = Import-PowerShellDataFile -Path (Join-Path $script:ModuleRoot "config.psd1")

# Dot source private functions
$privateFunctions = Get-ChildItem -Path (Join-Path $script:ModuleRoot "Private") -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($function in $privateFunctions) {
    try {
        . $function.FullName
        Write-Verbose "Imported private function: $($function.BaseName)"
    }
    catch {
        Write-Error "Failed to import private function $($function.FullName): $_"
    }
}

# Dot source public functions
$publicFunctions = Get-ChildItem -Path (Join-Path $script:ModuleRoot "Public") -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($function in $publicFunctions) {
    try {
        . $function.FullName
        Write-Verbose "Imported public function: $($function.BaseName)"
    }
    catch {
        Write-Error "Failed to import public function $($function.FullName): $_"
    }
}

# Export only public functions
Export-ModuleMember -Function $publicFunctions.BaseName
