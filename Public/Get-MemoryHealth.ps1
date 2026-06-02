function Get-MemoryHealth {
    <#
    .SYNOPSIS
        Returns physical memory utilization as a structured health object.
    .PARAMETER ComputerName
        Target computer(s). Accepts pipeline input.
    .PARAMETER ThresholdPercent
        Usage % above which status becomes Warning. Critical at ThresholdPercent + 10.
    .EXAMPLE
        Get-MemoryHealth
    .EXAMPLE
        Get-MemoryHealth -ThresholdPercent 75
    .EXAMPLE
        'SRV01','SRV02' | Get-MemoryHealth
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateRange(1, 99)]
        [int]$ThresholdPercent = 80
    )

    process {
        foreach ($computer in $ComputerName) {
            try {
                $os      = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop
                $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                $freeGB  = [math]::Round($os.FreePhysicalMemory     / 1MB, 2)
                $usedGB  = [math]::Round($totalGB - $freeGB, 2)
                $usedPct = [math]::Round(($usedGB / $totalGB) * 100, 1)

                [PSCustomObject]@{
                    PSTypeName   = 'PSHealthWatch.HealthResult'
                    ComputerName = $computer
                    Metric       = 'Memory'
                    Value        = $usedPct
                    Unit         = '%'
                    Threshold    = $ThresholdPercent
                    Status       = switch ($usedPct) {
                        { $_ -ge ($ThresholdPercent + 10) } { 'Critical'; break }
                        { $_ -ge $ThresholdPercent }        { 'Warning';  break }
                        default                             { 'OK' }
                    }
                    Detail       = "${usedGB} GB used of ${totalGB} GB"
                    Timestamp    = [datetime]::Now
                }
            }
            catch {
                Write-Warning "[$computer] Memory query failed: $_"
            }
        }
    }
}
