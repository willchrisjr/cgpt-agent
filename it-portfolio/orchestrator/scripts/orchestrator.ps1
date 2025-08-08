param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter()][string]$InputJsonPath
)

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../src/Orchestrator.psd1'
Import-Module -Name $modulePath -Force

$result = Invoke-ItOrchestration -Name $Name -InputJsonPath $InputJsonPath
Write-Host $result