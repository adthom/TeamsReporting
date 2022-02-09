function Get-DirectRoutingGraph {
    [CmdletBinding()]
    param(
        [DateTime]
        $StartDate,

        [DateTime]
        $EndDate
    )

    $Endpoint = "DirectRoutingGraph"
    Get-ConfigAPICalls -Endpoint $Endpoint @PSBoundParameters
}

