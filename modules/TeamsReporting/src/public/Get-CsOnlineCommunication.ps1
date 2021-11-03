function Get-CsOnlineCommunication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $CommunicationId
    )

    $Select = @(
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
        "qualityScore"
        "issueCount"
        "callDuration"
        "participantsDropped"
        "totalActiveVoipParticipants"
        "totalActivePstnParticipants"
        # "participants"
        # "sessions"
    ) -join ','
    $Uri = "https://api.interfaces.records.teams.microsoft.com/Skype.Analytics/Communications('${CommunicationId}')?`$select=${Select}"
    $Result = ConfigAPICall -Uri $Uri -Method GET
    $Result = $Result | Select-Object -Property * -ExcludeProperty '@odata.context'
    $PUri = "https://api.interfaces.records.teams.microsoft.com/Skype.Analytics/Communications('${CommunicationId}')/Participants"
    $PResult = ConfigAPICall -Uri $PUri -Method GET
    $Result | Add-Member -MemberType NoteProperty -Name Participants -Value $PResult.value
    $Result
}

