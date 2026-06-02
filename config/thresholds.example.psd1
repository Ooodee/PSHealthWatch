# PSHealthWatch — threshold configuration example
# Copy to thresholds.psd1 and adjust values to match your environment.

@{
    CPU = @{
        Warning  = 85   # % — status becomes Warning above this value
        Critical = 95   # % — status becomes Critical above this value
    }
    Memory = @{
        Warning  = 80
        Critical = 90
    }
    Disk = @{
        Warning  = 85
        Critical = 92
    }
    Services = @(
        'wuauserv'       # Windows Update
        'Spooler'        # Print Spooler
        'WinDefend'      # Windows Defender Antivirus
        'EventLog'       # Windows Event Log
        'LanmanServer'   # SMB File Server
        'W32Time'        # Windows Time (NTP sync)
    )
}
