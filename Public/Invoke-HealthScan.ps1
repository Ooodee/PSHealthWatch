function Invoke-HealthScan {
    <#
    .SYNOPSIS
        Runs a full system health scan and optionally auto-creates a Jira Service
        Management incident when any metric exceeds its threshold.
    .PARAMETER ComputerName
        Target computer(s) to scan. Defaults to local machine. Accepts pipeline input.
    .PARAMETER AutoTicket
        When set, automatically creates a Jira ticket for Warning or Critical results.
        Requires -Site, -Email, -ApiKey, and -ProjectKey.
    .PARAMETER Site
        Jira site URL (e.g. 'ojdandan.atlassian.net').
    .PARAMETER Email
        Atlassian account email for authentication.
    .PARAMETER ApiKey
        Jira API token.
    .PARAMETER ProjectKey
        Jira project key (e.g. 'SUP').
    .PARAMETER CpuThreshold
        CPU warning threshold in percent. Default: 85.
    .PARAMETER MemoryThreshold
        Memory warning threshold in percent. Default: 80.
    .PARAMETER DiskThreshold
        Disk warning threshold in percent. Default: 85.
    .EXAMPLE
        Invoke-HealthScan
    .EXAMPLE
        Invoke-HealthScan -AutoTicket -Site 'ojdandan.atlassian.net' -Email 'you@gmail.com' -ApiKey $key -ProjectKey 'SUP'
    .EXAMPLE
        'SRV01','SRV02' | Invoke-HealthScan -AutoTicket -Site ojdandan.atlassian.net -Email you@gmail.com -ApiKey $key -ProjectKey SUP
    .EXAMPLE
        Invoke-HealthScan -AutoTicket -Site ojdandan.atlassian.net -Email you@gmail.com -ApiKey $key -ProjectKey SUP -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [switch]$AutoTicket,

        [Parameter()]
        [string]$Site,

        [Parameter()]
        [string]$Email,

        [Parameter()]
        [string]$ApiKey,

        [Parameter()]
        [string]$ProjectKey,

        [int]$CpuThreshold    = 85,
        [int]$MemoryThreshold = 80,
        [int]$DiskThreshold   = 85
    )

    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Scanning $computer..."

            $health = Get-SystemHealth -ComputerName $computer `
                                       -CpuThreshold    $CpuThreshold `
                                       -MemoryThreshold $MemoryThreshold `
                                       -DiskThreshold   $DiskThreshold

            Write-Output $health

            if ($AutoTicket -and $health.OverallStatus -ne 'OK') {
                if (-not $Site -or -not $Email -or -not $ApiKey -or -not $ProjectKey) {
                    Write-Warning '-AutoTicket requires -Site, -Email, -ApiKey, and -ProjectKey.'
                    continue
                }

                $health | New-HealthTicket -Site       $Site `
                                           -Email      $Email `
                                           -ApiKey     $ApiKey `
                                           -ProjectKey $ProjectKey `
                                           -WhatIf:($WhatIfPreference)
            }
        }
    }
}
