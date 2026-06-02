function Get-ServiceHealth {
    <#
    .SYNOPSIS
        Checks the running state of Windows services and returns structured health objects.
    .PARAMETER ServiceName
        One or more service names to check. Accepts pipeline input. Tab-completion supported.
        Defaults to a set of common critical Windows services.
    .PARAMETER ComputerName
        Target computer(s).
    .EXAMPLE
        Get-ServiceHealth
    .EXAMPLE
        'wuauserv','Spooler' | Get-ServiceHealth
    .EXAMPLE
        Get-ServiceHealth -ServiceName WinDefend -ComputerName SRV01
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete)
            Get-Service -Name "$wordToComplete*" -ErrorAction SilentlyContinue |
                ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new(
                        $_.Name, $_.Name, 'ParameterValue', $_.DisplayName
                    )
                }
        })]
        [string[]]$ServiceName = @('wuauserv', 'Spooler', 'WinDefend', 'EventLog', 'LanmanServer', 'W32Time'),

        [Parameter()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($computer in $ComputerName) {
            foreach ($svc in $ServiceName) {
                try {
                    $service = Get-Service -Name $svc -ComputerName $computer -ErrorAction Stop

                    [PSCustomObject]@{
                        PSTypeName   = 'PSHealthWatch.HealthResult'
                        ComputerName = $computer
                        Metric       = "Service ($($service.Name))"
                        Value        = $service.Status.ToString()
                        Unit         = 'state'
                        Threshold    = 'Running'
                        Status       = if ($service.Status -eq 'Running') { 'OK' } else { 'Critical' }
                        Detail       = $service.DisplayName
                        Timestamp    = [datetime]::Now
                    }
                }
                catch {
                    Write-Warning "[$computer] Service '$svc' not found: $_"
                }
            }
        }
    }
}
