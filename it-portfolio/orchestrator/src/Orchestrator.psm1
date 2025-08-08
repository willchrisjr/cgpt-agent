# Region: Configuration
function Get-OrchestratorConfig {
    [CmdletBinding()]
    param()

    $configPath = Join-Path -Path $PSScriptRoot -ChildPath 'Orchestrator.Config.psd1'
    $cfg = if (Test-Path -LiteralPath $configPath) { Import-PowerShellDataFile -Path $configPath } else { @{} }

    $envMap = @{ 
        TenantId       = 'ORCH_TENANT_ID'
        ClientId       = 'ORCH_CLIENT_ID'
        ClientSecret   = 'ORCH_CLIENT_SECRET'
        CertThumbprint = 'ORCH_CERT_THUMBPRINT'
        Scopes         = 'ORCH_SCOPES'
        GraphBaseUrl   = 'ORCH_GRAPH_BASE_URL'
    }

    foreach ($k in $envMap.Keys) {
        $envName = $envMap[$k]
        $val = [System.Environment]::GetEnvironmentVariable($envName)
        if ($null -ne $val -and $val -ne '') {
            if ($k -eq 'Scopes') { $cfg[$k] = $val -split ',' } else { $cfg[$k] = $val }
        }
    }

    # Defaults
    if (-not $cfg.ContainsKey('Scopes') -or -not $cfg.Scopes) { $cfg['Scopes'] = @('https://graph.microsoft.com/.default') }
    if (-not $cfg.ContainsKey('GraphBaseUrl') -or -not $cfg.GraphBaseUrl) { $cfg['GraphBaseUrl'] = 'https://graph.microsoft.com' }

    return [pscustomobject]$cfg
}

# Region: Auth
$script:GraphToken = $null
function Get-GraphToken {
    [CmdletBinding()]
    param(
        [switch]$ForceRefresh
    )

    if (-not $ForceRefresh -and $script:GraphToken) {
        try {
            $expires = Get-Date ($script:GraphToken.ExpiresOn)
            if ($expires -gt (Get-Date).AddMinutes(2)) { return $script:GraphToken }
        } catch { }
    }

    $cfg = Get-OrchestratorConfig

    if (-not $cfg.TenantId -or -not $cfg.ClientId -or (-not $cfg.ClientSecret -and -not $cfg.CertThumbprint)) {
        throw 'Graph auth configuration incomplete. Provide TenantId, ClientId, and ClientSecret or CertThumbprint.'
    }

    if (-not (Get-Module -ListAvailable -Name 'MSAL.PS')) {
        Write-Verbose 'MSAL.PS module not found. Install-Module MSAL.PS may be required in CI or on first run.'
    }

    if ($cfg.ClientSecret) {
        $tok = Get-MsalToken -TenantId $cfg.TenantId -ClientId $cfg.ClientId -ClientSecret ($cfg.ClientSecret) -Scopes $cfg.Scopes
    } elseif ($cfg.CertThumbprint) {
        $tok = Get-MsalToken -TenantId $cfg.TenantId -ClientId $cfg.ClientId -ClientCertificateThumbprint $cfg.CertThumbprint -Scopes $cfg.Scopes
    }

    if (-not $tok -or -not $tok.AccessToken) { throw 'Failed to acquire Graph token.' }
    $script:GraphToken = $tok
    return $tok
}

# Region: HTTP Wrapper
function Invoke-GraphRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateSet('GET','POST','PATCH','PUT','DELETE')] [string]$Method,
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter()][object]$Body,
        [Parameter()][hashtable]$Headers,
        [int]$MaxRetries = 3
    )

    $token = (Get-GraphToken).AccessToken

    $hdrs = @{
        'Authorization' = "Bearer $token"
        'Accept'        = 'application/json'
    }
    if ($Headers) { $Headers.GetEnumerator() | ForEach-Object { $hdrs[$_.Key] = $_.Value } }

    $jsonBody = $null
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
        if ($Body -is [string]) { $jsonBody = $Body } else { $jsonBody = ($Body | ConvertTo-Json -Depth 10) }
    }

    $attempt = 0
    $lastError = $null
    do {
        try {
            $params = @{ Method = $Method; Uri = $Uri; Headers = $hdrs }
            if ($null -ne $jsonBody) { $params['Body'] = $jsonBody; $params['ContentType'] = 'application/json' }
            return Invoke-RestMethod @params
        }
        catch {
            $lastError = $_
            $statusCode = $null
            $retryAfter = $null
            if ($_.Exception -and $_.Exception.Data.Contains('StatusCode')) { $statusCode = [int]$_.Exception.Data['StatusCode'] }
            if ($_.Exception -and $_.Exception.Data.Contains('Retry-After')) { $retryAfter = [string]$_.Exception.Data['Retry-After'] }
            if (-not $statusCode -and $_.Exception.Response) {
                try { $statusCode = [int]$_.Exception.Response.StatusCode } catch { }
                try { $retryAfter = $_.Exception.Response.Headers['Retry-After'] } catch { }
            }

            if (($statusCode -eq 429) -or ($statusCode -ge 500 -and $statusCode -lt 600)) {
                $attempt++
                if ($attempt -gt $MaxRetries) { break }
                $delay = if ($retryAfter) { [int]$retryAfter } else { [math]::Pow(2, $attempt - 1) }
                Start-Sleep -Seconds $delay
                # Refresh token on 401, otherwise keep
                if ($statusCode -eq 401) { [void](Get-GraphToken -ForceRefresh) }
                continue
            }
            throw
        }
    } while ($attempt -le $MaxRetries)

    throw $lastError
}

# Region: Actions
function Disable-GraphUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$UserId
    )
    $cfg = Get-OrchestratorConfig
    $uri = "${($cfg.GraphBaseUrl)}/v1.0/users/$UserId"
    $body = @{ accountEnabled = $false }
    return Invoke-GraphRequest -Method PATCH -Uri $uri -Body $body
}

function Add-GraphUserToGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$UserId,
        [Parameter(Mandatory=$true)][string]$GroupId
    )
    $cfg = Get-OrchestratorConfig
    $uri = "${($cfg.GraphBaseUrl)}/v1.0/groups/$GroupId/members/$ref"
    $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$UserId" }
    return Invoke-GraphRequest -Method POST -Uri $uri -Body $body
}

# Region: Orchestrator entry
function Invoke-ItOrchestration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter()][string]$InputJsonPath
    )

    $actions = @()
    if ($PSBoundParameters.ContainsKey('InputJsonPath') -and (Test-Path -LiteralPath $InputJsonPath)) {
        try {
            $json = Get-Content -LiteralPath $InputJsonPath -Raw | ConvertFrom-Json
            if ($null -ne $json.actions) { $actions = $json.actions }
        }
        catch { throw "Failed to parse JSON from path: $InputJsonPath" }
    }

    $results = @()
    foreach ($a in $actions) {
        switch ($a.name) {
            'disable_user' { $results += Disable-GraphUser -UserId $a.with.user_id }
            'add_to_group' { $results += Add-GraphUserToGroup -UserId $a.with.user_id -GroupId $a.with.group_id }
            default { throw "Unknown action: $($a.name)" }
        }
    }

    if (-not $results -or $results.Count -eq 0) { return "OK: $Name" }
    return $results
}

Export-ModuleMember -Function Get-OrchestratorConfig, Get-GraphToken, Invoke-GraphRequest, Disable-GraphUser, Add-GraphUserToGroup, Invoke-ItOrchestration