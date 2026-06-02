function Get-GPUHealth {
    <#
    .SYNOPSIS
        Returns GPU information and utilization as a structured health object.
    .DESCRIPTION
        Retrieves GPU metadata via WMI and attempts to read engine utilization via
        PDH performance counters (Windows 10 1809+). Degrades gracefully if counters
        are unavailable (e.g. integrated graphics without drivers).
    .PARAMETER ComputerName
        Target computer(s). Accepts pipeline input.
    .EXAMPLE
        Get-GPUHealth
    .EXAMPLE
        'SRV01' | Get-GPUHealth
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($computer in $ComputerName) {
            try {
                $gpus = Get-CimInstance -ClassName Win32_VideoController -ComputerName $computer -ErrorAction Stop

                foreach ($gpu in $gpus) {
                    $usagePct = $null
                    try {
                        $counterPath = '\GPU Engine(*engtype_3D*)\Utilization Percentage'
                        $samples     = Get-Counter -Counter $counterPath -ComputerName $computer -ErrorAction Stop
                        $usagePct    = [math]::Round(
                            ($samples.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum, 1
                        )
                    }
                    catch { $usagePct = $null }

                    $vramGB = if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0) {
                        [math]::Round($gpu.AdapterRAM / 1GB, 2)
                    } else { 'N/A' }

                    [PSCustomObject]@{
                        PSTypeName   = 'PSHealthWatch.HealthResult'
                        ComputerName = $computer
                        Metric       = 'GPU'
                        Value        = if ($null -ne $usagePct) { $usagePct } else { 'N/A' }
                        Unit         = '%'
                        Threshold    = 95
                        Status       = if ($null -ne $usagePct -and $usagePct -ge 95) { 'Warning' } else { 'OK' }
                        Detail       = "$($gpu.Name) | VRAM: ${vramGB} GB | Driver: $($gpu.DriverVersion)"
                        Timestamp    = [datetime]::Now
                    }
                }
            }
            catch {
                Write-Warning "[$computer] GPU query failed: $_"
            }
        }
    }
}
