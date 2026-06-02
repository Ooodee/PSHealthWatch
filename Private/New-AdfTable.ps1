function New-AdfTable {
    param (
        [Parameter(Mandatory)]
        [array]$Rows
    )

    $headers = @('Metric', 'Value', 'Threshold', 'Status', 'Detail')

    $headerRow = @{
        type    = 'tableRow'
        content = @(
            $headers | ForEach-Object {
                @{
                    type    = 'tableHeader'
                    attrs   = @{}
                    content = @(@{
                        type    = 'paragraph'
                        content = @(@{ type = 'text'; text = $_; marks = @(@{ type = 'strong' }) })
                    })
                }
            }
        )
    }

    $dataRows = $Rows | ForEach-Object {
        $row = $_
        @{
            type    = 'tableRow'
            content = @(
                "$($row.Metric)",
                "$($row.Value) $($row.Unit)",
                "$($row.Threshold)",
                "$($row.Status)",
                "$($row.Detail)"
            ) | ForEach-Object {
                @{
                    type    = 'tableCell'
                    attrs   = @{}
                    content = @(@{
                        type    = 'paragraph'
                        content = @(@{ type = 'text'; text = $_ })
                    })
                }
            }
        }
    }

    return @{
        type    = 'table'
        attrs   = @{ isNumberColumnEnabled = $false; layout = 'default' }
        content = @($headerRow) + @($dataRows)
    }
}
