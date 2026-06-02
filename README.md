# PSHealthWatch

A PowerShell module for Windows system health monitoring with automated Freshservice incident ticketing.

Monitors CPU, memory, disk, GPU, and critical Windows services. When a threshold is breached, it automatically opens a structured incident ticket in Freshservice. No manual intervention needed.

## Features

* **Modular architecture**: each metric is an independent, reusable function
* **Pipeline-native**: all functions accept pipeline input and emit typed `PSCustomObject` output
* **Argument completers**: tab-completion for drive letters and service names
* **Freshservice integration**: auto-creates HTML-formatted incident tickets via REST API
* **WhatIf support**: test ticket creation without submitting
* **Remote-ready**: pass `-ComputerName` to any function to query remote machines

## Requirements

* PowerShell 7.0+
* Windows 10 / Windows Server 2016+
* Freshservice account + API key (for ticketing)

## Installation

```powershell
# Clone the repo
git clone https://github.com/Ooodee/PSHealthWatch.git

# Import the module
Import-Module .\PSHealthWatch\PSHealthWatch.psd1
```

## Usage

### Quick scan (local machine)

```powershell
Get-SystemHealth
```

### Scan with custom thresholds

```powershell
Get-SystemHealth -CpuThreshold 75 -MemoryThreshold 70 -DiskThreshold 80
```

### Scan multiple remote machines

```powershell
'SRV01','SRV02','SRV03' | Get-SystemHealth
```

### Individual metric checks

```powershell
Get-CPUHealth
Get-MemoryHealth
Get-DiskHealth -DriveLetter C,D    # tab-completion supported
Get-GPUHealth
Get-ServiceHealth                  # tab-completion on service names
'wuauserv','Spooler' | Get-ServiceHealth
```

### Full scan with auto-ticketing

```powershell
$apiKey = 'your-freshservice-api-key'

Invoke-HealthScan -AutoTicket `
                  -Domain        'mycompany' `
                  -ApiKey        $apiKey `
                  -RequesterEmail 'ops@mycompany.com'
```

### WhatIf: preview ticket without submitting

```powershell
Invoke-HealthScan -AutoTicket -Domain mycompany -ApiKey $key -RequesterEmail ops@co.com -WhatIf
```

### Manual ticket from health data

```powershell
$health = Get-SystemHealth -ComputerName SRV01
New-HealthTicket -HealthData $health `
                 -Domain        'mycompany' `
                 -ApiKey        $apiKey `
                 -RequesterEmail 'ops@mycompany.com' `
                 -Priority       High
```

### Export results to CSV

```powershell
Get-SystemHealth | Select-Object -ExpandProperty AllMetrics | Export-Csv health-report.csv -NoTypeInformation
```

## Freshservice Setup

1. Log in to your Freshservice account
2. Go to **Profile Settings > API Key**
3. Copy the key and pass it as `-ApiKey`
4. Your subdomain is the part before `.freshservice.com` in your URL

## Configuration

Copy `config/thresholds.example.psd1` to `config/thresholds.psd1` and adjust values:

```powershell
@{
    CPU    = @{ Warning = 85; Critical = 95 }
    Memory = @{ Warning = 80; Critical = 90 }
    Disk   = @{ Warning = 85; Critical = 92 }
    Services = @('wuauserv', 'Spooler', 'WinDefend', 'EventLog')
}
```

## Module Structure

```
PSHealthWatch/
├── PSHealthWatch.psd1          # Module manifest
├── PSHealthWatch.psm1          # Module root
├── Public/
│   ├── Get-CPUHealth.ps1
│   ├── Get-MemoryHealth.ps1
│   ├── Get-DiskHealth.ps1
│   ├── Get-GPUHealth.ps1
│   ├── Get-ServiceHealth.ps1
│   ├── Get-SystemHealth.ps1    # Aggregates all metrics
│   ├── New-HealthTicket.ps1    # Creates Freshservice incident
│   └── Invoke-HealthScan.ps1  # Main entry point
├── Private/
│   ├── Invoke-FreshserviceApi.ps1
│   └── ConvertTo-TicketBody.ps1
└── config/
    └── thresholds.example.psd1
```

## License

MIT
