function Get-DiskHealth {
    <#
    .SYNOPSIS
        Returns disk utilization per logical drive as structured health objects.
    .PARAMETER ComputerName
        Target computer(s). Accepts pipeline input.
    .PARAMETER DriveLetter
        Filter to specific drive letter(s) (e.g. 'C','D'). Defaults to all fixed drives.
        Tab-completion is supported.
    .PARAMETER ThresholdPercent
        Usage % above which status becomes Warning. Critical at ThresholdPercent + 5.
    .EXAMPLE
        Get-DiskHealth
    .EXAMPLE
        Get-DiskHealth -DriveLetter C -ThresholdPercent 80
    .EXAMPLE
        Get-DiskHealth -DriveLetter C,D
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete)
            (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue).DeviceID -replace ':','' |
                Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "$_ Drive")
                }
        })]
        [string[]]$DriveLetter,

        [Parameter()]
        [ValidateRange(1, 99)]
        [int]$ThresholdPercent = 85
    )

    process {
        foreach ($computer in $ComputerName) {
            try {
                $filter = 'DriveType=3'
                if ($DriveLetter) {
                    $letters = ($DriveLetter | ForEach-Object { "DeviceID='$($_):'" }) -join ' OR '
                    $filter  = "DriveType=3 AND ($letters)"
                }

                $isLocal = $computer -in @($env:COMPUTERNAME, 'localhost', '127.0.0.1', '.')
                $cimArgs = @{ ClassName = 'Win32_LogicalDisk'; Filter = $filter; ErrorAction = 'Stop' }
                if (-not $isLocal) { $cimArgs.ComputerName = $computer }
                $disks = Get-CimInstance @cimArgs

                foreach ($disk in $disks) {
                    $totalGB = [math]::Round($disk.Size      / 1GB, 2)
                    $freeGB  = [math]::Round($disk.FreeSpace / 1GB, 2)
                    $usedGB  = [math]::Round($totalGB - $freeGB, 2)
                    $usedPct = [math]::Round(($usedGB / $totalGB) * 100, 1)

                    [PSCustomObject]@{
                        PSTypeName   = 'PSHealthWatch.HealthResult'
                        ComputerName = $computer
                        Metric       = "Disk ($($disk.DeviceID))"
                        Value        = $usedPct
                        Unit         = '%'
                        Threshold    = $ThresholdPercent
                        Status       = switch ($usedPct) {
                            { $_ -ge ($ThresholdPercent + 5) } { 'Critical'; break }
                            { $_ -ge $ThresholdPercent }       { 'Warning';  break }
                            default                            { 'OK' }
                        }
                        Detail       = "${usedGB} GB used of ${totalGB} GB"
                        Timestamp    = [datetime]::Now
                    }
                }
            }
            catch {
                Write-Warning "[$computer] Disk query failed: $_"
            }
        }
    }
}
