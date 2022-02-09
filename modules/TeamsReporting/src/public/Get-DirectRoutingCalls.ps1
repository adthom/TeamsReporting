function Get-DirectRoutingCalls {
    [CmdletBinding()]
    param(
        [DateTime]
        $StartDate,

        [DateTime]
        $EndDate
    )

    $Endpoint = "DirectRouting"
    Get-ConfigAPICalls -Endpoint $Endpoint @PSBoundParameters
}

