function Get-TASToken {
    [CmdletBinding()]
    $Scopes = [string[]] @("https://tas.teams.microsoft.com/.default")
    Get-TokenFromMicrosoftTeams -Scopes $Scopes
}
