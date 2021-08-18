function Get-TeamsUserActivityTenantSummary {
    [CmdletBinding(DefaultParameterSetName = 'TimePeriod')]
    param (
        [Parameter(ParameterSetName = 'TimePeriod', Mandatory = $true)]
        [ValidateSet(7, 30, 90)]
        [int]
        $TimePeriod,
        
        [Parameter(ParameterSetName = 'Date', Mandatory = $true)]
        [datetime]
        $StartDate,

        [Parameter(ParameterSetName = 'Date', Mandatory = $true)]
        [datetime]
        $EndDate,

        [switch]
        $IncludeDaily
    )
    $Key = "UAR_C"
    $Route = "/users/aggregated-summary-timeseries"
    $Results = Get-TASReport -Key $Key -Route $Route @PSBoundParameters
    if ($IncludeDaily) {
        $Results | Sort-Object -Property Date
    } else {
        $Results
    }
}
