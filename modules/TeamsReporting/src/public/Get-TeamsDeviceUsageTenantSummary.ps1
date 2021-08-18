function Get-TeamsDeviceUsageTenantSummary {
    [CmdletBinding()]
    param (
        [ValidateSet(7, 30, 90)]
        [int]
        $TimePeriod = 7,

        [switch]
        $IncludeDaily
    )
    $Key = "DUR_C"
    $Route = "/devices/aggregated-summary-timeseries"
    $PSBoundParameters['TimePeriod'] = $TimePeriod
    $Results = Get-TASReport -Key $Key -Route $Route @PSBoundParameters
    if ($IncludeDaily) {
        $Results | Sort-Object -Property Date
    } else {
        $Results
    }
}
