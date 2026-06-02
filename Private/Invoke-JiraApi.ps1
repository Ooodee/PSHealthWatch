function Invoke-JiraApi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string]$Site,
        [Parameter(Mandatory)] [string]$Email,
        [Parameter(Mandatory)] [string]$ApiKey,
        [Parameter(Mandatory)] [string]$Endpoint,
        [Parameter(Mandatory)] [hashtable]$Body,
        [string]$Method = 'POST'
    )

    $uri  = "https://${Site}/rest/api/3/${Endpoint}"
    $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Email}:${ApiKey}"))

    $params = @{
        Uri         = $uri
        Method      = $Method
        Headers     = @{
            Authorization  = "Basic $cred"
            'Content-Type' = 'application/json'
            Accept         = 'application/json'
        }
        Body        = $Body | ConvertTo-Json -Depth 20
        ErrorAction = 'Stop'
    }

    try {
        Invoke-RestMethod @params
    }
    catch {
        $statusCode = $_.Exception.Response?.StatusCode.value__
        Write-Error "Jira API error (HTTP $statusCode): $_"
    }
}
