param(
    [Parameter(Mandatory)]
    [string]$Endpoint,
    
    [ValidateSet('v1.0', 'beta')]
    [string]$ApiVersion = 'beta',
    
    [string]$AppId,
    [string]$TenantId,
    [string]$Secret
)

$useParallel = $AppId -and $TenantId -and $Secret

if ($useParallel)
{
    $secureSecret = ConvertTo-SecureString $Secret -AsPlainText -Force
    $credential = [PSCredential]::new($AppId, $secureSecret)
    Connect-MgGraph -ClientSecretCredential $credential -TenantId $TenantId -NoWelcome
}
else
{
    Connect-MgGraph -NoWelcome
}

$metaDataUri = "https://graph.microsoft.com/$ApiVersion/`$metadata" 

# Fetch schema and discover endpoints
$meta = [xml](Invoke-MgGraphRequest -Uri $metaDataUri -OutputType HttpResponseMessage).Content.ReadAsStringAsync().Result
$schema = $meta.edmx.DataServices.Schema | Where-Object Namespace -eq 'microsoft.graph'
$singleton = $schema.EntityContainer.Singleton | Where-Object Name -eq $Endpoint

if (-not $singleton) { throw "Endpoint '$Endpoint' not found" }

$typeName = $singleton.Type -replace '^microsoft\.graph\.', ''
$navProps = ($schema.EntityType | Where-Object Name -eq $typeName).NavigationProperty

$uris = $navProps | 
    Where-Object { $_.Attributes['Type'].Value -match '^Collection' } |
    ForEach-Object { @{ Name = $_.Name; Uri = "/$ApiVersion/$Endpoint/$($_.Name)" } }

# Fetch data scriptblock
$fetch = {
    param($Uri, $AppId, $TenantId, $Secret)
    
    if ($AppId)
    {
        Import-Module Microsoft.Graph.Authentication -Force
        $cred = [PSCredential]::new($AppId, (ConvertTo-SecureString $Secret -AsPlainText -Force))
        Connect-MgGraph -ClientSecretCredential $cred -TenantId $TenantId -NoWelcome
    }
    
    $data = @()
    try
    {
        do
        {
            $r = Invoke-MgGraphRequest -Uri $Uri -OutputType PSObject -ErrorAction Stop
            if ($r.value) { $data += $r.value }
            $Uri = $r.PSObject.Properties['@odata.nextLink']?.Value
        } while ($Uri)
    }
    catch
    {
        # Return nothing on error - job will have no data
    }
    $data
}

$result = [PSCustomObject]@{}

if ($useParallel)
{
    $total = $uris.Count
    $i = 0
    $jobs = $uris | ForEach-Object {
        Write-Progress -Activity "Starting jobs" -Status "$i of $total" -PercentComplete (($i++ / $total) * 100)
        Start-Job -Name $_.Name -ScriptBlock $fetch -ArgumentList $_.Uri, $AppId, $TenantId, $Secret
    }
    
    while ($jobs.State -match 'Running')
    {
        $running = @($jobs | Where-Object State -eq 'Running').Count
        $completed = @($jobs | Where-Object State -eq 'Completed').Count
        $failed = @($jobs | Where-Object State -eq 'Failed').Count
        Write-Progress -Activity "Fetching $Endpoint" -Status "Running: $running | Completed: $completed | Failed: $failed"
        Start-Sleep -Milliseconds 500
    }
    Write-Progress -Activity "Fetching $Endpoint" -Completed
    
    $jobs | ForEach-Object {
        if ($_.HasMoreData) 
        { 
            $result | Add-Member -NotePropertyName $_.Name -NotePropertyValue @(Receive-Job $_) 
        }
        Remove-Job $_
    }
}
else
{
    foreach ($u in $uris)
    {
        try
        {
            $data = @(& $fetch $u.Uri)

            if ($data) 
            { 
                $result | Add-Member -NotePropertyName $u.Name -NotePropertyValue $data 
            }
        }
        catch 
        { 
            Write-Warning "$($u.Name): $($_.Exception.Message)" 
        }
    }
}

Write-Output $result

Get-Job | Stop-Job -PassThru | Remove-Job