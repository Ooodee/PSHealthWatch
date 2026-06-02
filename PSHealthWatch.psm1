$private = Get-ChildItem -Path "$PSScriptRoot\Private" -Filter '*.ps1'
$public  = Get-ChildItem -Path "$PSScriptRoot\Public"  -Filter '*.ps1'

foreach ($file in $private) { . $file.FullName }
foreach ($file in $public)  {
    . $file.FullName
    Export-ModuleMember -Function $file.BaseName
}
