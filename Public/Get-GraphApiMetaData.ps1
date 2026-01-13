<#
.SYNOPSIS
    Fetches Graph API metadata from Microsoft Graph.

.DESCRIPTION
    Connects to Microsoft Graph and retrieves the API metadata from the configured endpoint.
    Returns the parsed XML metadata object.

.PARAMETER ExportPath
    Optional. Directory path to save the metadata as XML and JSON files.

.EXAMPLE
    Get-GraphApiMetaData
    Fetches and returns the metadata object.

.EXAMPLE
    Get-GraphApiMetaData -ExportPath "C:\Output"
    Fetches metadata, saves to files, and returns the object.

.OUTPUTS
    System.Xml.XmlDocument
    Returns the parsed XML metadata as an object.
#>
function Get-GraphApiMetaData {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ExportPath
    )

    # Ensure connection to Microsoft Graph
    Connect-MgGraph -NoWelcome

    # Fetch Graph API metadata
    Write-Log "Fetching metadata from $($script:Config.GraphApiMetaUri)" -Context 'Metadata'
    $metaResponse = Invoke-MgGraphRequest -Uri $script:Config.GraphApiMetaUri -OutputType HttpResponseMessage
    $metaContent = $metaResponse.Content.ReadAsStringAsync().Result

    # Parse to XML object
    $apiMeta = [xml]$metaContent

    # Export to files if path specified
    if ($ExportPath) {
        if (-not (Test-Path $ExportPath)) {
            New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
        }

        $xmlPath = Join-Path $ExportPath "GraphApiMeta.xml"
        $metaContent | Set-Content -Path $xmlPath -Encoding UTF8
        Write-Log "Saved XML: $xmlPath" -Level Success -Context 'Metadata'

        $jsonPath = Join-Path $ExportPath "GraphApiMeta.json"
        $apiMeta | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
        Write-Log "Saved JSON: $jsonPath" -Level Success -Context 'Metadata'
    }

    return $apiMeta.edmx.DataServices.Schema
}
