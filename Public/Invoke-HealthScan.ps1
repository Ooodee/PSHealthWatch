function Invoke-HealthScan {
    <#
    .SYNOPSIS
        Runs a full system health scan and optionally auto-creates a Freshservice
        incident ticket when any metric exceeds its threshold.
    .PARAMETER ComputerName
        Target computer(s) to scan. Defaults to local machine. Accepts pipeline input.
    .PARAMETER AutoTicket
        When set, automatically creates a Freshservice ticket for Warning or Critical results.
        Requires -Domain, -ApiKey, and -RequesterEmail.
    .PARAMETER Domain
        Freshservice subdomain (e.g. 'mycompany').
    .PARAMETER ApiKey
        Freshservice API key.
    .PARAMETER RequesterEmail
        Requester email for ticket creation.
    .PARAMETER CpuThreshold
        CPU warning threshold in percent. Default: 85.
    .PARAMETER MemoryThreshold
        Memory warning threshold in percent. Default: 80.
    .PARAMETER DiskThreshold
        Disk warning threshold in percent. Default: 85.
    .EXAMPLE
        Invoke-HealthScan
    .EXAMPLE
        Invoke-HealthScan -AutoTicket -Domain 'mycompany' -ApiKey $key -RequesterEmail 'ops@mycompany.com'
    .EXAMPLE
        'SRV01','SRV02' | Invoke-HealthScan -AutoTicket -Domain mycompany -ApiKey $key -RequesterEmail ops@co.com
    .EXAMPLE
        Invoke-HealthScan -AutoTicket -Domain mycompany -ApiKey $key -RequesterEmail ops@co.com -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [switch]$AutoTicket,

        [Parameter()]
        [string]$Domain,

        [Parameter()]
        [string]$ApiKey,

        [Parameter()]
        [string]$RequesterEmail,

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
                if (-not $Domain -or -not $ApiKey -or -not $RequesterEmail) {
                    Write-Warning '-AutoTicket requires -Domain, -ApiKey, and -RequesterEmail.'
                    continue
                }

                $health | New-HealthTicket -Domain $Domain `
                                           -ApiKey $ApiKey `
                                           -RequesterEmail $RequesterEmail `
                                           -WhatIf:($WhatIfPreference)
            }
        }
    }
}
