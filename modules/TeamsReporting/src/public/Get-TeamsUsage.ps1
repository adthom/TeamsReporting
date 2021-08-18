function Get-TeamsUsage {
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
    $Key = "TUR_T"
    $Route = "/teams/summary-timeseries"
    $PSBoundParameters['TimePeriod'] = $TimePeriod
    $Results = Get-TASReport -Key $Key -Route $Route -Paginated -Command $MyInvocation.MyCommand.Name @PSBoundParameters
    if ($IncludeDaily) {
        $Results | Sort-Object -Property DisplayName, Date
    } else {
        $Results
    }
}
