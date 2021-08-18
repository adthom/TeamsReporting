function Get-AppsUsage {
    [CmdletBinding()]
    param (
        [ValidateSet(7, 30, 90)]
        [int]
        $TimePeriod = 7,
        
        [Parameter(DontShow = $true)]
        [string]
        $NextCursor,

        [switch]
        $IncludeDaily
    )
    $Key = "AUR_T"
    $Route = "/apps/summary-timeseries"
    $PSBoundParameters['TimePeriod'] = $TimePeriod
    $Results = Get-TASReport -Key $Key -Route $Route -Paginated -Command $MyInvocation.MyCommand.Name @PSBoundParameters
    if ($IncludeDaily) {
        $Results | Sort-Object -Property Name, Date
    } else {
        $Results
    }
}
