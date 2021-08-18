function Get-AppsUsageTenantSummary {
    [CmdletBinding()]
    param (
        [ValidateSet(7, 30, 90)]
        [int]
        $TimePeriod = 7,

        [switch]
        $IncludeDaily
    )
    $Key = "AUR_C"
    $Route = "/appTypes/summary-timeseries"
    $PSBoundParameters['TimePeriod'] = $TimePeriod
    $Results = Get-TASReport -Key $Key -Route $Route @PSBoundParameters
    if ($IncludeDaily) {
        $Results | Sort-Object -Property DisplayName, Date
    } else {
        $Results
    }
}
