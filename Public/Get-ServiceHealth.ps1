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
            $isLocal = $computer -in @($env:COMPUTERNAME, 'localhost', '127.0.0.1', '.')
            foreach ($svc in $ServiceName) {
                try {
                    $service = if ($isLocal) {
                        Get-Service -Name $svc -ErrorAction Stop
                    } else {
                        Invoke-Command -ComputerName $computer -ScriptBlock {
                            Get-Service -Name $using:svc -ErrorAction Stop
                        }
                    }

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
