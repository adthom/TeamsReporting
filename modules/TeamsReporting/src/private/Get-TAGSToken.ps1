function Get-TAGSToken {
    $Scopes = [string[]] @("https://tags.teams.microsoft.com/.default")
    Get-TokenFromMicrosoftTeams -Scopes $Scopes
}
