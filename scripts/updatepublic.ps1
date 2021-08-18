$BasePath = $PSScriptRoot
$RootFolder = Split-Path $BasePath -Parent
$RepoFolder = Split-Path $RootFolder -Parent
$SourcePath = Join-Path -Path $RootFolder -ChildPath "modules\TeamsReporting\release\Scripts"
$DestinationPath = Join-Path -Path $RepoFolder -ChildPath "TeamsAdminSamples\PowerShell\TeamsReporting"

$Scripts = Get-ChildItem -Path $SourcePath -Filter *.ps1
foreach ($Script in $Scripts) {
    $Content = Get-Content -Path $Script.FullName | Select-Object -Skip 5
    Set-Content -Path "$DestinationPath\$($Script.Name)" -Value $Content -Force
}