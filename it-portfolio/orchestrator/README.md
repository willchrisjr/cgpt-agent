# Orchestrator (PowerShell)

A PowerShell module that orchestrates common IT workflows. Intended to integrate with Microsoft Graph.

## Contents

- src/Orchestrator.psm1: Module functions
- src/Orchestrator.psd1: Module manifest
- scripts/orchestrator.ps1: Entry script for invoking orchestration
- samples/new_hire.json: Sample payload
- tests/Orchestrator.Tests.ps1: Pester tests

## Usage

```powershell
pwsh -File scripts/orchestrator.ps1 -Name "Example"
```

## Tests

```powershell
pwsh -c "Invoke-Pester -CI" -WorkingDirectory tests
```