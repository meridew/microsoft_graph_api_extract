<#
.SYNOPSIS
    Gets all queryable collection endpoints from Microsoft Graph API metadata.

.DESCRIPTION
    Parses the Graph API metadata to extract collection endpoints that can be queried.
    Optionally filters to a specific root singleton like deviceManagement.

.PARAMETER Schema
    The schema object returned from Get-GraphApiMetaData. Auto-fetched if not provided.

.PARAMETER Root
    Filter to a specific root singleton (e.g., 'deviceManagement', 'users').

.PARAMETER ApiVersion
    The API version to use in the URI. Defaults to 'beta'.

.EXAMPLE
    Get-GraphApiEndpoint -Root 'deviceManagement'

.OUTPUTS
    PSCustomObject[] with Uri, Name, EntityType, Root properties.
#>
function Get-GraphApiEndpoint {
    [CmdletBinding()]
    param(
        [Parameter()][object]$Schema,
        [Parameter()][string]$Root,
        [Parameter()][ValidateSet('beta', 'v1.0')][string]$ApiVersion = 'beta'
    )

    if (-not $Schema) {
        Write-Log "Fetching schema..." -Context 'Endpoints'
        $Schema = Get-GraphApiMetaData
    }

    $graphSchema = $Schema | Where-Object Namespace -eq 'microsoft.graph'
    if (-not $graphSchema -or -not $graphSchema.EntityContainer) { 
        throw "Invalid schema: missing microsoft.graph EntityContainer" 
    }

    # Build type lookup for O(1) access
    $typeMap = @{}
    $graphSchema.EntityType | ForEach-Object { $typeMap[$_.Name] = $_ }

    # Filter singletons
    $singletons = $graphSchema.EntityContainer.Singleton
    if ($Root) {
        $singletons = @($singletons | Where-Object Name -eq $Root)
        if (-not $singletons) { throw "Root '$Root' not found. Available: $($graphSchema.EntityContainer.Singleton.Name -join ', ')" }
    }

    # Transform singletons → endpoints via pipeline
    $singletons | ForEach-Object {
        $singletonName = $_.Name
        $typeName = $_.Type -replace '^microsoft\.graph\.', ''
        $entityType = $typeMap[$typeName]
        
        if ($entityType.NavigationProperty) {
            $entityType.NavigationProperty | Where-Object { $_.Type -like 'Collection(*' } | ForEach-Object {
                [PSCustomObject]@{
                    Uri        = "/$ApiVersion/$singletonName/$($_.Name)"
                    Name       = $_.Name
                    EntityType = $_.Type -replace 'Collection\(microsoft\.graph\.|Collection\(graph\.|\)', ''
                    Root       = $singletonName
                }
            }
        }
    }
}
