function New-HealthTicket {
    <#
    .SYNOPSIS
        Creates a Freshservice incident ticket from a PSHealthWatch health summary.
    .DESCRIPTION
        Accepts a SystemHealth object (from Get-SystemHealth), builds a structured HTML
        ticket body with alert details, and submits it to Freshservice via REST API.
        Priority is inferred from OverallStatus unless explicitly overridden.
    .PARAMETER Domain
        Your Freshservice subdomain (e.g. 'mycompany' for mycompany.freshservice.com).
    .PARAMETER ApiKey
        Your Freshservice API key.
    .PARAMETER HealthData
        A PSHealthWatch.SystemHealth object. Accepts pipeline input from Get-SystemHealth.
    .PARAMETER RequesterEmail
        Email used by Freshservice to associate the ticket with a requester.
    .PARAMETER Priority
        Ticket priority: Low, Medium, High, or Urgent.
        Auto-resolved from OverallStatus if not specified.
    .EXAMPLE
        Get-SystemHealth | New-HealthTicket -Domain 'mycompany' -ApiKey $key -RequesterEmail 'ops@mycompany.com'
    .EXAMPLE
        $h = Get-SystemHealth -ComputerName SRV01
        New-HealthTicket -HealthData $h -Domain 'mycompany' -ApiKey $key -RequesterEmail 'ops@co.com' -Priority High
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$Domain,

        [Parameter(Mandatory)]
        [string]$ApiKey,

        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$HealthData,

        [Parameter(Mandatory)]
        [string]$RequesterEmail,

        [Parameter()]
        [ValidateSet('Low', 'Medium', 'High', 'Urgent')]
        [string]$Priority
    )

    process {
        $priorityMap = @{ Low = 1; Medium = 2; High = 3; Urgent = 4 }

        $resolvedPriority = if ($Priority) {
            $priorityMap[$Priority]
        } else {
            switch ($HealthData.OverallStatus) {
                'Critical' { 4 }
                'Warning'  { 3 }
                default    { 2 }
            }
        }

        $subject = "[PSHealthWatch] $($HealthData.OverallStatus): $($HealthData.ComputerName) — $($HealthData.AlertCount) alert(s)"
        $body    = ConvertTo-TicketBody -HealthData $HealthData

        $ticket = @{
            subject     = $subject
            description = $body
            email       = $RequesterEmail
            priority    = $resolvedPriority
            status      = 2
            type        = 'Incident'
            tags        = @('PSHealthWatch', 'Automated', $HealthData.ComputerName)
        }

        if ($PSCmdlet.ShouldProcess($HealthData.ComputerName, "Create Freshservice ticket: $subject")) {
            $response = Invoke-FreshserviceApi -Domain $Domain -ApiKey $ApiKey `
                            -Endpoint 'tickets' -Body $ticket
            Write-Output $response
        }
    }
}
