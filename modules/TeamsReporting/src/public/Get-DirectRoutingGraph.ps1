function Get-DirectRoutingGraph {
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )
    $Endpoint = "DirectRoutingGraph"
    Get-ConfigAPICalls -Endpoint $Endpoint @PSBoundParameters
}
