<#
.SYNOPSIS
    Queries Microsoft Graph API endpoints and returns all data.

.DESCRIPTION
    Takes a list of endpoints (from Get-GraphApiEndpoint) and queries each one,
    returning all data from the Graph API. Handles pagination automatically.
    Supports parallel execution with app-only authentication (PS 7+).

.PARAMETER Endpoints
    Array of endpoint objects from Get-GraphApiEndpoint, or an array of URI strings.

.PARAMETER Schema
    Optional. The schema object from Get-GraphApiMetaData.
    If not provided and -Endpoints is not specified, will fetch automatically.

.PARAMETER Root
    Optional. Filter to a specific root singleton (e.g., 'deviceManagement').
    Only used when -Endpoints is not provided.

.PARAMETER ClientId
    Application (client) ID for app-only authentication. Enables parallel execution.
    Must be used with -TenantId and -ClientSecret.

.PARAMETER TenantId
    Tenant ID for app-only authentication.
    Must be used with -ClientId and -ClientSecret.

.PARAMETER ClientSecret
    Client secret for app-only authentication.
    Must be used with -ClientId and -TenantId.

.PARAMETER ThrottleLimit
    Maximum number of parallel requests. Defaults to 5. Only valid with app-only auth.

.PARAMETER ContinueOnError
    If specified, continues processing remaining endpoints when an error occurs.

.EXAMPLE
    Invoke-GraphApiQuery -Root 'deviceManagement'
    Queries all deviceManagement endpoints sequentially using delegated auth.

.EXAMPLE
    Invoke-GraphApiQuery -Root 'deviceManagement' -ClientId $id -TenantId $tid -ClientSecret $sec -ThrottleLimit 10
    Queries endpoints in parallel using app-only authentication.

.OUTPUTS
    Hashtable with endpoint names as keys. Each value contains Uri, Data, Count, and Error properties.
#>
function Invoke-GraphApiQuery {
    [CmdletBinding(DefaultParameterSetName = 'Delegated')]
    param(
        [Parameter(ValueFromPipeline)]
        [object[]]$Endpoints,

        [Parameter()]
        [object]$Schema,

        [Parameter()]
        [string]$Root,

        [Parameter(Mandatory, ParameterSetName = 'AppOnly')]
        [string]$ClientId,

        [Parameter(Mandatory, ParameterSetName = 'AppOnly')]
        [string]$TenantId,

        [Parameter(Mandatory, ParameterSetName = 'AppOnly')]
        [string]$ClientSecret,

        [Parameter(ParameterSetName = 'AppOnly')]
        [int]$ThrottleLimit = 5,

        [Parameter()]
        [switch]$ContinueOnError
    )

    begin {
        $useParallel = $PSCmdlet.ParameterSetName -eq 'AppOnly' -and $PSVersionTable.PSVersion.Major -ge 7
        $authMode = if ($PSCmdlet.ParameterSetName -eq 'AppOnly') {
            if ($useParallel) { "App-only (parallel, ThrottleLimit: $ThrottleLimit)" }
            else { "App-only (sequential - PS 7+ required for parallel)" }
        } else { "Delegated (sequential)" }
        
        Write-Log "Authentication: $authMode" -Context 'Query'
        
        if ($PSCmdlet.ParameterSetName -eq 'AppOnly') {
            $secSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
            $credential = [PSCredential]::new($ClientId, $secSecret)
            Connect-MgGraph -ClientSecretCredential $credential -TenantId $TenantId -NoWelcome
        } else {
            $context = Get-MgContext
            if (-not $context) {
                Write-Log "Connecting to Microsoft Graph..." -Context 'Query'
                Connect-MgGraph -NoWelcome
            }
        }

        $collectedEndpoints = @()
    }

    process {
        if ($Endpoints) { $collectedEndpoints += $Endpoints }
    }

    end {
        # Auto-discover endpoints if none provided
        if (-not $collectedEndpoints) {
            $params = @{}
            if ($Schema) { $params.Schema = $Schema }
            if ($Root) { $params.Root = $Root }
            
            Write-Log "Auto-discovering endpoints..." -Context 'Query'
            $collectedEndpoints = Get-GraphApiEndpoint @params
        }

        # Normalize to objects with Uri/Name
        $normalizedEndpoints = @($collectedEndpoints | ForEach-Object {
            if ($_ -is [string]) { [PSCustomObject]@{ Uri = $_; Name = ($_ -split '/')[-1] } }
            else { $_ }
        })

        $totalCount = $normalizedEndpoints.Count
        $startTime = Get-Date
        Write-Log "Querying $totalCount endpoints..." -Context 'Query'

        # Query function for reuse
        $queryEndpoint = {
            param($Endpoint)
            
            $uri = $Endpoint.Uri
            $name = $Endpoint.Name
            $allData = @()
            $nextLink = $uri
            $err = $null

            try {
                do {
                    $response = Invoke-MgGraphRequest -Uri $nextLink -Method GET
                    
                    if ($response.value) { $allData += $response.value }
                    elseif ($response -is [array]) { $allData += $response }
                    else { $allData += $response }

                    $nextLink = if ($response -is [hashtable] -and $response.ContainsKey('@odata.nextLink')) {
                        $response['@odata.nextLink']
                    } else { $null }
                } while ($nextLink)
            }
            catch {
                $err = $_.Exception.Message
            }

            [PSCustomObject]@{
                Name  = $name
                Uri   = $uri
                Data  = $allData
                Count = $allData.Count
                Error = $err
            }
        }

        $resultsList = @()

        if ($useParallel) {
            # Thread-safe progress counter
            $progressCounter = [System.Collections.Concurrent.ConcurrentDictionary[string,int]]::new()
            $progressCounter['completed'] = 0

            # Parallel execution (PS 7+ with app-only auth)
            $resultsList = $normalizedEndpoints | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
                Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
                $secSecret = ConvertTo-SecureString $using:ClientSecret -AsPlainText -Force
                $cred = [PSCredential]::new($using:ClientId, $secSecret)
                Connect-MgGraph -ClientSecretCredential $cred -TenantId $using:TenantId -NoWelcome
                
                $ep = $_
                $uri = $ep.Uri
                $allData = @()
                $nextLink = $uri
                $err = $null

                try {
                    do {
                        $response = Invoke-MgGraphRequest -Uri $nextLink -Method GET
                        if ($response.value) { $allData += $response.value }
                        elseif ($response -is [array]) { $allData += $response }
                        else { $allData += $response }
                        $nextLink = if ($response -is [hashtable] -and $response.ContainsKey('@odata.nextLink')) {
                            $response['@odata.nextLink']
                        } else { $null }
                    } while ($nextLink)
                }
                catch { $err = $_.Exception.Message }

                # Update progress counter
                $counter = $using:progressCounter
                $null = $counter.AddOrUpdate('completed', 1, { param($k, $v) $v + 1 })
                $completed = $counter['completed']
                $total = $using:totalCount
                $pct = [math]::Round(($completed / $total) * 100)
                Write-Host "`r[Parallel] $completed/$total ($pct%) - $($ep.Name)".PadRight(80) -NoNewline

                [PSCustomObject]@{
                    Name  = $ep.Name
                    Uri   = $uri
                    Data  = $allData
                    Count = $allData.Count
                    Error = $err
                }
            }
            Write-Host ""  # New line after progress

            # Log errors after parallel completion
            $resultsList | Where-Object { $_.Error } | ForEach-Object {
                Write-Log "$($_.Name): $($_.Error)" -Level Warning -Context 'Query'
            }
        }
        else {
            # Sequential execution
            $current = 0

            foreach ($endpoint in $normalizedEndpoints) {
                $current++
                Write-Progress -Activity "Querying Graph API" -Status "$current/$totalCount - $($endpoint.Name)" -PercentComplete (($current / $totalCount) * 100)
                
                $result = & $queryEndpoint -Endpoint $endpoint
                $resultsList += $result

                if ($result.Error) {
                    Write-Log "$($endpoint.Name): $($result.Error)" -Level Warning -Context 'Query'
                    if (-not $ContinueOnError) { 
                        Write-Progress -Activity "Querying Graph API" -Completed
                        throw $result.Error 
                    }
                }
            }
            Write-Progress -Activity "Querying Graph API" -Completed
        }

        # Convert to hashtable
        $results = @{}
        foreach ($item in $resultsList) {
            $results[$item.Name] = [PSCustomObject]@{
                Uri   = $item.Uri
                Data  = $item.Data
                Count = $item.Count
                Error = $item.Error
            }
        }

        $successCount = @($resultsList | Where-Object { -not $_.Error }).Count
        $errorCount = @($resultsList | Where-Object { $_.Error }).Count
        $totalItems = ($resultsList | Measure-Object -Property Count -Sum).Sum
        $duration = (Get-Date) - $startTime

        Write-LogSummary -Success $successCount -Failed $errorCount -TotalItems $totalItems -Duration $duration -Context 'Query'

        return $results
    }
}
