@{
    RootModule        = 'Orchestrator.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '4a0b2a0d-2d8f-4df3-b9a5-1a6cb8437e10'
    Author            = 'IT Team'
    CompanyName       = 'IT'
    Copyright         = '(c) IT. All rights reserved.'
    Description       = 'IT Orchestrator module.'

    PowerShellVersion = '7.0'

    FunctionsToExport = @('Invoke-ItOrchestration')
    CmdletsToExport   = @()
    AliasesToExport   = @()

    PrivateData = @{ }
}