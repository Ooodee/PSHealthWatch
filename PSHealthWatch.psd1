@{
    ModuleVersion     = '1.0.0'
    GUID              = '1cbfea53-1e3f-465c-a33b-5a5352b13b63'
    Author            = 'Omar Dandan'
    CompanyName       = 'github.com/Ooodee'
    Copyright         = '(c) 2026 Omar Dandan. MIT License.'
    Description       = 'PowerShell module for Windows system health monitoring with automated Freshservice incident ticketing.'
    PowerShellVersion = '7.0'
    RootModule        = 'PSHealthWatch.psm1'
    FunctionsToExport = @(
        'Get-CPUHealth'
        'Get-MemoryHealth'
        'Get-DiskHealth'
        'Get-GPUHealth'
        'Get-ServiceHealth'
        'Get-SystemHealth'
        'New-HealthTicket'
        'Invoke-HealthScan'
    )
    PrivateData = @{
        PSData = @{
            Tags       = @('Monitoring', 'ITSM', 'Freshservice', 'SystemHealth', 'Automation', 'Windows')
            ProjectUri = 'https://github.com/Ooodee/PSHealthWatch'
            LicenseUri = 'https://github.com/Ooodee/PSHealthWatch/blob/main/LICENSE'
        }
    }
}
