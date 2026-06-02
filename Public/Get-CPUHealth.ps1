function Get-CPUHealth {
    <#
    .SYNOPSIS
        Returns CPU utilization as a structured health object.
    .DESCRIPTION
        Queries WMI for processor load and returns a PSCustomObject with current
        utilization, configured threshold, and a status indicator (OK/Warning/Critical).
    .PARAMETER ComputerName
        Target computer(s). Defaults to local machine. Accepts pipeline input.
    .PARAMETER ThresholdPercent
        Usage % above which status becomes Warning. Critical triggers at ThresholdPercent + 10.
    .EXAMPLE
        Get-CPUHealth
    .EXAMPLE
        Get-CPUHealth -ThresholdPercent 75
    .EXAMPLE
        'SRV01','SRV02' | Get-CPUHealth
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateRange(1, 99)]
        [int]$ThresholdPercent = 85
    )

    process {
        foreach ($computer in $ComputerName) {
            try {
                $procs = Get-CimInstance -ClassName Win32_Processor -ComputerName $computer -ErrorAction Stop
                $load  = [math]::Round(($procs | Measure-Object -Property LoadPercentage -Average).Average, 1)

                [PSCustomObject]@{
                    PSTypeName   = 'PSHealthWatch.HealthResult'
                    ComputerName = $computer
                    Metric       = 'CPU'
                    Value        = $load
                    Unit         = '%'
                    Threshold    = $ThresholdPercent
                    Status       = switch ($load) {
                        { $_ -ge ($ThresholdPercent + 10) } { 'Critical'; break }
                        { $_ -ge $ThresholdPercent }        { 'Warning';  break }
                        default                             { 'OK' }
                    }
                    Detail       = ($procs | Select-Object -First 1 -ExpandProperty Name)
                    Timestamp    = [datetime]::Now
                }
            }
            catch {
                Write-Warning "[$computer] CPU query failed: $_"
            }
        }
    }
}
