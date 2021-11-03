function Get-CsOnlineUserObjectId {
    [CmdletBinding()]
    param (
        $Identity
    )

    $IdGuid = [Guid]::Empty
    if ($null -ne $Identity.MemberId) {
        $Identity = $Identity.MemberId
    }
    if ([Guid]::TryParse($Identity, [ref]$IdGuid)) {
        $Identity = $IdGuid.Guid
    }
    else {
        Write-Verbose -Message "Looking up ObjectId for $Identity"
        $User = Get-CsOnlineUser -Identity $Identity -ErrorAction Stop
        $Identity = $User.ObjectId.Guid
        if ($null -eq $Identity) {
            $Identity = $User.Identity -replace '^.*([\da-f]{8}-?[\da-f]{4}-?[\da-f]{4}-?[\da-f]{4}-?[\da-f]{12}).*$', '$1'
        }
    }
    $Identity
}

