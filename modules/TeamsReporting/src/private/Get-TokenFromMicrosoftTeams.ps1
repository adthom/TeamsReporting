function Get-TokenFromMicrosoftTeams {
    [CmdletBinding()]
    param ( 
        [string[]]$Scopes
    )
    try {
        $Application = [Microsoft.TeamsCmdlets.Powershell.Connect.TeamsPowerShellSession]::PublicClientApplication
    } 
    catch {
        $Application = $null
    }
    if ($null -eq $Application) {
        Write-Error "Run Connect-MicrosoftTeams before running cmdlets." -ErrorAction Stop
    }
    $LoginHint = [Microsoft.TeamsCmdlets.Powershell.Connect.Models.AzureRmProfileProvider]::Instance.Profile.Context.Account.Id
    try {
        $Token = $Application.AcquireTokenSilent($Scopes, $LoginHint).ExecuteAsync().Result
    }
    catch {
        Write-Verbose "Could not acquire token silently, acquiring without prompt"
        $MSALPrompt = [Microsoft.Identity.Client.Prompt, Microsoft.Identity.Client, Version = 4.29.0.0, Culture = neutral, PublicKeyToken = 0a613f4dd989e8ae]::NoPrompt
        $Token = $Application.AcquireTokenInteractive($Scopes).WithLoginHint($LoginHint).WithPrompt($MSALPrompt).ExecuteAsync().Result
    }
    $Token
}
