function Get-CsOnlineSessionDetail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $CommunicationId,

        [Parameter(Mandatory = $true)]
        $SessionId
    )

    $SUri = "https://api.interfaces.records.teams.microsoft.com/Skype.Analytics/Communications('$CommunicationId')/Sessions('$SessionId')"
    $Session = ConfigAPICall -Uri $SUri -Method GET
    $QUri = $SUri + "/QualityReports"
    $Quality = ConfigAPICall -Uri $QUri -Method GET
    $DUri = $SUri + "/DiagnosticReports"
    $Diagnostics = ConfigAPICall -Uri $DUri -Method GET
    $FUri = $SUri + "/FeedbackReports"
    $Feedback = ConfigAPICall -Uri $FUri -Method GET
    [PSCustomObject]@{
        SessionDetails     = $Session | Select-Object -Property * -ExcludeProperty '@odata.context'
        QualityReports     = $Quality.value
        DiagnosticsReports = $Diagnostics.value
        FeedbackReports    = $Feedback.value
    }
}

