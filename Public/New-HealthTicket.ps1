function New-HealthTicket {
    <#
    .SYNOPSIS
        Creates a Jira Service Management incident from a PSHealthWatch health summary.
    .DESCRIPTION
        Accepts a SystemHealth object from Get-SystemHealth, builds a structured
        Atlassian Document Format (ADF) ticket body, and submits it to Jira via REST API v3.
        Priority is inferred from OverallStatus unless explicitly overridden.
    .PARAMETER Site
        Your Jira site URL (e.g. 'ojdandan.atlassian.net').
    .PARAMETER Email
        The Atlassian account email used to authenticate.
    .PARAMETER ApiKey
        Your Jira API token.
    .PARAMETER ProjectKey
        The Jira project key to create the issue in (e.g. 'SUP').
    .PARAMETER HealthData
        A PSHealthWatch.SystemHealth object. Accepts pipeline input from Get-SystemHealth.
    .PARAMETER Priority
        Ticket priority: Highest, High, Medium, Low, or Lowest.
        Auto-resolved from OverallStatus if not specified.
    .EXAMPLE
        Get-SystemHealth | New-HealthTicket -Site 'ojdandan.atlassian.net' -Email 'you@gmail.com' -ApiKey $key -ProjectKey 'SUP'
    .EXAMPLE
        $h = Get-SystemHealth
        New-HealthTicket -HealthData $h -Site 'ojdandan.atlassian.net' -Email 'you@gmail.com' -ApiKey $key -ProjectKey 'SUP' -Priority High
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$Site,

        [Parameter(Mandatory)]
        [string]$Email,

        [Parameter(Mandatory)]
        [string]$ApiKey,

        [Parameter(Mandatory)]
        [string]$ProjectKey,

        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject]$HealthData,

        [Parameter()]
        [ValidateSet('Highest', 'High', 'Medium', 'Low', 'Lowest')]
        [string]$Priority
    )

    process {
        $resolvedPriority = if ($Priority) {
            $Priority
        } else {
            switch ($HealthData.OverallStatus) {
                'Critical' { 'High' }
                'Warning'  { 'Medium' }
                default    { 'Low' }
            }
        }

        $summary = "[PSHealthWatch] $($HealthData.OverallStatus): $($HealthData.ComputerName), $($HealthData.AlertCount) alert(s)"
        $body    = ConvertTo-TicketBody -HealthData $HealthData

        $issue = @{
            fields = @{
                project     = @{ key = $ProjectKey }
                summary     = $summary
                description = $body
                issuetype   = @{ name = '[System] Incident' }
                priority    = @{ name = $resolvedPriority }
            }
        }

        if ($PSCmdlet.ShouldProcess($HealthData.ComputerName, "Create Jira ticket: $summary")) {
            $response = Invoke-JiraApi -Site $Site -Email $Email -ApiKey $ApiKey `
                            -Endpoint 'issue' -Body $issue
            Write-Output $response
        }
    }
}
