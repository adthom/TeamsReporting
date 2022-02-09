function Get-PstnCalls {
    [CmdletBinding()]
    param(
        [DateTime]
        $StartDate,

        [DateTime]
        $EndDate
    )

    $Endpoint = "PstnCalls"
    if ($null -eq $EndDate) {
        $EndDate = [datetime]::Now
        $PSBoundParameters['EndDate'] = $EndDate
    }
    Get-ConfigAPICalls -Endpoint $Endpoint @PSBoundParameters
}

