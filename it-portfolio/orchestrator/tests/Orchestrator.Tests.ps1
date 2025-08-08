$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../src/Orchestrator.psd1'
Import-Module -Name $modulePath -Force

Describe 'Invoke-ItOrchestration' {
    It 'returns OK with the provided name' {
        $result = Invoke-ItOrchestration -Name 'Test'
        $result | Should -Be 'OK: Test'
    }
}

Describe 'Get-OrchestratorConfig' {
    It 'prefers environment variables over file values' {
        $env:ORCH_TENANT_ID = 'env-tenant'
        try {
            $cfg = Get-OrchestratorConfig
            $cfg.TenantId | Should -Be 'env-tenant'
        }
        finally { Remove-Item Env:\ORCH_TENANT_ID -ErrorAction SilentlyContinue }
    }
}

Describe 'Invoke-GraphRequest' {
    BeforeAll {
        Mock -ModuleName Orchestrator Get-GraphToken { @{ AccessToken = 'dummy'; ExpiresOn = (Get-Date).AddHours(1) } }
    }

    It 'adds Authorization header and returns value on success' {
        $capturedHeaders = $null
        Mock -ModuleName Orchestrator Invoke-RestMethod { param($Method,$Uri,$Headers,$Body,$ContentType) $script:__headers = $Headers; return @{ ok = $true } }
        $res = Invoke-GraphRequest -Method GET -Uri 'https://example' -Headers @{ 'X-Test' = '1' }
        $res.ok | Should -BeTrue
        $script:__headers['Authorization'] | Should -Match '^Bearer dummy$'
        $script:__headers['X-Test'] | Should -Be '1'
    }

    It 'retries on 429 with Retry-After and eventually succeeds' {
        $callCount = 0
        Mock -ModuleName Orchestrator Invoke-RestMethod {
            $script:__headers = $Headers
            $script:__calls = $script:__calls + 1
            if ($script:__calls -lt 2) {
                $ex = [System.Exception]::new('Too Many Requests')
                $ex.Data['StatusCode'] = 429
                $ex.Data['Retry-After'] = '0'
                throw $ex
            }
            return @{ ok = $true }
        }
        $script:__calls = 0
        $res = Invoke-GraphRequest -Method GET -Uri 'https://example'
        $res.ok | Should -BeTrue
        $script:__calls | Should -Be 2
    }
}

Describe 'Actions' {
    BeforeAll {
        Mock -ModuleName Orchestrator Get-GraphToken { @{ AccessToken = 'dummy'; ExpiresOn = (Get-Date).AddHours(1) } }
        Mock -ModuleName Orchestrator Invoke-RestMethod { return @{ ok = $true } }
    }

    It 'Disable-GraphUser issues PATCH to users endpoint' {
        $null = Disable-GraphUser -UserId 'user-1'
        Assert-MockCalled -ModuleName Orchestrator Invoke-RestMethod -Times 1 -ParameterFilter { $Method -eq 'PATCH' -and $Uri -match '/users/user-1$' }
    }

    It 'Add-GraphUserToGroup posts to members ref' {
        $null = Add-GraphUserToGroup -UserId 'user-1' -GroupId 'group-9'
        Assert-MockCalled -ModuleName Orchestrator Invoke-RestMethod -Times 1 -ParameterFilter { $Method -eq 'POST' -and $Uri -match '/groups/group-9/members/\$ref$' }
    }
}