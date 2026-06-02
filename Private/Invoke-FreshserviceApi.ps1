function Invoke-FreshserviceApi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string]$Domain,
        [Parameter(Mandatory)] [string]$ApiKey,
        [Parameter(Mandatory)] [string]$Endpoint,
        [Parameter(Mandatory)] [hashtable]$Body,
        [string]$Method = 'POST'
    )

    $uri  = "https://${Domain}.freshservice.com/api/v2/${Endpoint}"
    $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ApiKey}:X"))

    $params = @{
        Uri         = $uri
        Method      = $Method
        Headers     = @{
            Authorization  = "Basic $cred"
            'Content-Type' = 'application/json'
        }
        Body        = $Body | ConvertTo-Json -Depth 5
        ErrorAction = 'Stop'
    }

    try {
        $response = Invoke-RestMethod @params
        $response.ticket
    }
    catch {
        $statusCode = $_.Exception.Response?.StatusCode.value__
        Write-Error "Freshservice API error (HTTP $statusCode): $_"
    }
}
