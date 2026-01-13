<#
.SYNOPSIS
    Internal logging functions with colored, timestamped output.
#>

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info',

        [Parameter()]
        [string]$Context
    )

    $config = @{
        Info    = @{ Prefix = 'INF'; Color = 'Cyan' }
        Warning = @{ Prefix = 'WRN'; Color = 'Yellow' }
        Error   = @{ Prefix = 'ERR'; Color = 'Red' }
    }[$Level]

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $ctx = if ($Context) { "[$Context] " } else { '' }
    
    Write-Host "[$timestamp] [$($config.Prefix)] $ctx$Message" -ForegroundColor $config.Color
}

function Write-LogSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Success,
        [Parameter()][int]$Failed = 0,
        [Parameter()][int]$TotalItems = 0,
        [Parameter()][TimeSpan]$Duration,
        [Parameter()][string]$Context
    )

    $dur = if ($Duration) { " in $($Duration.ToString('mm\:ss'))" } else { '' }
    
    Write-Host ""
    Write-Log "=== Summary$dur ===" -Context $Context
    Write-Host "    Successful: $Success" -ForegroundColor Green
    if ($Failed -gt 0) { Write-Host "    Failed: $Failed" -ForegroundColor Yellow }
    if ($TotalItems -gt 0) { Write-Host "    Total items: $TotalItems" -ForegroundColor Cyan }
    Write-Host ""
}
