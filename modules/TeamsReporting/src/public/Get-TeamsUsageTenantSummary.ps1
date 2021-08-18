function Get-TeamsUsageTenantSummary {
    [CmdletBinding()]
    param (
        [ValidateSet(7, 30, 90)]
        [int]
        $TimePeriod = 7,

        [string]
        $NextCursor,

        [switch]
        $IncludeDaily
    )
    $Key = "TUR_C"
    $Route = "/teams/aggregated-summary-timeseries"
    $PSBoundParameters['TimePeriod'] = $TimePeriod
    $Results = Get-TASReport -Key $Key -Route $Route -Paginated -Command $MyInvocation.MyCommand.Name @PSBoundParameters
    if ($IncludeDaily) {
        $Results | Sort-Object -Property Date
    } else {
        $Results
    }
}
