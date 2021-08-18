function Get-PstnCalls {
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )
    $Endpoint = "PstnCalls"
    Get-ConfigAPICalls -Endpoint $Endpoint @PSBoundParameters
}
