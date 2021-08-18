function Get-CsOnlineUserCommunications {
    param (
        [Parameter(Mandatory = $true)]
        $Identity,

        [int]
        $Top = 500,

        [ValidateSet("Call","Conference", IgnoreCase = $false)]
        [string]
        $CallType
    )
    $Identity = Get-CsOnlineUserObjectId -Identity $Identity
    $Select = @(
        "userId"
        "id"
        "communicationType"
        "endDateTime"
        "startDateTime"
        "isComplete"
        "status"
        "statusIsPartial"
        "providerType"
        "modalities"
        "organizerId"
        "organizerIdType"
    ) -join ','
    $Uri = "https://api.interfaces.records.teams.microsoft.com/Skype.Analytics/Users('${Identity}')/Communications?`$top=${Top}&`$select=${Select}"
    if (![string]::IsNullOrEmpty($CallType)) {
        $Uri += "&`$filter=communicationType eq '${CallType}'"
    }
    $Result = ConfigAPICall -Uri $Uri -Method GET
    foreach ($r in $Result.value) {
        $r
    }
}
