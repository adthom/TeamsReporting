function Get-PstnCallGraph {
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )
    $Endpoint = "PstnCallGraph"
    Get-ConfigAPICalls -Endpoint $Endpoint @PSBoundParameters
}
