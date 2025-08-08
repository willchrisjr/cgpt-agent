$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../src/Orchestrator.psd1'
Import-Module -Name $modulePath -Force

Describe 'Invoke-ItOrchestration' {
    It 'returns OK with the provided name' {
        $result = Invoke-ItOrchestration -Name 'Test'
        $result | Should -Be 'OK: Test'
    }
}