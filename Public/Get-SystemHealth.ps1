function Get-SystemHealth {
    <#
    .SYNOPSIS
        Aggregates CPU, Memory, Disk, GPU, and Service health into a single summary object.
    .PARAMETER ComputerName
        Target computer(s). Defaults to local machine. Accepts pipeline input.
    .PARAMETER CpuThreshold
        CPU warning threshold in percent. Default: 85.
    .PARAMETER MemoryThreshold
        Memory warning threshold in percent. Default: 80.
    .PARAMETER DiskThreshold
        Disk warning threshold in percent. Default: 85.
    .PARAMETER ServiceName
        Services to monitor. Defaults to a standard set of critical Windows services.
    .EXAMPLE
        Get-SystemHealth
    .EXAMPLE
        Get-SystemHealth -CpuThreshold 75 -MemoryThreshold 70
    .EXAMPLE
        'SRV01','SRV02' | Get-SystemHealth
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [int]$CpuThreshold    = 85,
        [int]$MemoryThreshold = 80,
        [int]$DiskThreshold   = 85,

        [string[]]$ServiceName = @('wuauserv', 'Spooler', 'WinDefend', 'EventLog', 'LanmanServer')
    )

    process {
        foreach ($computer in $ComputerName) {
            $allMetrics = @(
                Get-CPUHealth     -ComputerName $computer -ThresholdPercent $CpuThreshold
                Get-MemoryHealth  -ComputerName $computer -ThresholdPercent $MemoryThreshold
                Get-DiskHealth    -ComputerName $computer -ThresholdPercent $DiskThreshold
                Get-GPUHealth     -ComputerName $computer
                Get-ServiceHealth -ComputerName $computer -ServiceName $ServiceName
            )

            $alerts = $allMetrics | Where-Object { $_.Status -in 'Warning', 'Critical' }

            [PSCustomObject]@{
                PSTypeName    = 'PSHealthWatch.SystemHealth'
                ComputerName  = $computer
                OverallStatus = if   ($alerts | Where-Object Status -eq 'Critical') { 'Critical' }
                                elseif ($alerts | Where-Object Status -eq 'Warning')  { 'Warning' }
                                else { 'OK' }
                AlertCount    = $alerts.Count
                Alerts        = $alerts
                AllMetrics    = $allMetrics
                Timestamp     = [datetime]::Now
            }
        }
    }
}
