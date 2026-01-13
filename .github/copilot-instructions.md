# Copilot Instructions for ExtractGraphApiData

## Project Overview
PowerShell module for extracting Microsoft Graph API metadata and querying Intune/Microsoft 365 configuration data. Uses the `Microsoft.Graph.Authentication` module for API access.

## Architecture

### Module Structure
- **ExtractGraphApiData.psm1** - Entry point that dot-sources functions from `Public/` and `Private/` folders
- **Public/** - Exported functions (cmdlets users call directly)
- **Private/** - Internal helper functions (not exported)
- **config.psd1** - Configuration including API URIs and predefined endpoint definitions

### Data Flow
1. `Get-GraphApiMetaData` → Fetches OData metadata XML from Graph API beta endpoint
2. `Get-GraphApiEndpoint` → Parses metadata schema to discover queryable collection endpoints
3. `Invoke-GraphApiQuery` → Queries discovered endpoints with automatic pagination handling

### Key Design Patterns
- Functions access module config via `$script:Config` (loaded from `config.psd1`)
- Schema parsing targets `microsoft.graph` namespace for `EntityContainer` and `NavigationProperty`
- Only collection endpoints (`IsCollection = $true`) are returned as queryable
- All functions use `Connect-MgGraph` for authentication (requires user to be authenticated)

## Development Workflow

### Loading the Module
```powershell
Import-Module .\ -Force  # Reload during development
```

### Testing Pattern (see testing.ps1)
```powershell
Import-Module .\ -Force
Get-GraphApiEndpoint  # Test individual functions
```

## Function Conventions

### Comment-Based Help
All public functions must include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, and `.OUTPUTS` sections. See `Public/Get-GraphApiMetaData.ps1` for the template.

### Parameter Patterns
- Use `[CmdletBinding()]` on all functions
- Optional parameters should allow functions to auto-fetch dependencies (e.g., `$Schema` parameter in `Get-GraphApiEndpoint` calls `Get-GraphApiMetaData` if not provided)
- Support pipeline input where appropriate (`[Parameter(ValueFromPipeline)]`)

### Error Handling
- Module sets `$ErrorActionPreference = 'Stop'` and `Set-StrictMode -Version Latest`
- Throw on unrecoverable errors; use `-ContinueOnError` switch pattern for batch operations

### Logging (Private/Write-Log.ps1)
Use the internal logging functions for consistent, colored, timestamped output:
```powershell
Write-Log "Message" -Context 'FunctionName'                    # Info (default)
Write-Log "Message" -Level Warning -Context 'FunctionName'     # Warning
Write-LogSummary -Success 8 -Failed 2 -TotalItems 100 -Duration $timespan -Context 'Query'
```
Progress uses native `Write-Progress` - no per-item success logging needed.

### Output Objects
Return `[PSCustomObject]` with consistent property names:
```powershell
[PSCustomObject]@{
    Uri        = "/$ApiVersion/$singletonName/$($navProp.Name)"
    Name       = $navProp.Name
    EntityType = $entityTypeName
    Root       = $singletonName
}
```

## Threading Support
`Invoke-GraphApiQuery` supports parallel execution with app-only authentication (PS 7+):
```powershell
Invoke-GraphApiQuery -Root 'deviceManagement' -ClientId $appId -TenantId $tid -ClientSecret $secret -ThrottleLimit 10
```

## Configuration (config.psd1)
- `GraphApiMetaUri` - Metadata endpoint (default: beta)
- `OutputPath` - Default export location
- `Endpoints` - Predefined endpoint definitions with parent/child relationships using `{id}` placeholders

## Dependencies
- **Microsoft.Graph.Authentication** - Required for `Connect-MgGraph` and `Invoke-MgGraphRequest`
- PowerShell 5.1+ (cross-platform compatible with PS 7+)
