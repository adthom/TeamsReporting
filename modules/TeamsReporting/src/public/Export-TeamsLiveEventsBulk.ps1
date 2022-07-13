function Export-TeamsLiveEventsBulk {
    [CmdletBinding()]
    param (
        [DateTime]
        $StartDate = [DateTime]::Now.Date.AddYears(-1),

        [DateTime]
        $EndDate = [DateTime]::Now.Date.AddMonths(6),

        [string]
        $OrganizerId,

        [string]
        $Path = $PWD,

        [switch]
        $DownloadResources,

        [int]
        $HoursPerReport = 24 * 7
    )
    end {
        $Reports = for ($CurrentDate = $StartDate; $CurrentDate -lt $EndDate; $CurrentDate = $CurrentDate.AddHours($HoursPerReport)) {
            $Params = @{
                StartTime         = $CurrentDate
                EndTime           = $CurrentDate.AddHours($HoursPerReport).AddSeconds(-1)
                Path              = $Path
                DownloadResources = $DownloadResources
                OrganizerId       = $OrganizerId
            }
            Write-Verbose "Running for $($Params['StartTime'].ToString('yyyy-MM-dd HH:mm:ss')) to $($Params['EndTime'].ToString('yyyy-MM-dd HH:mm:ss')) "
            Export-TeamsLiveEvents @Params
        }
        # Summarize all reports
        if ($Reports.Count -gt 0) {
            $Reports | Import-Csv | Export-Csv -Path (Join-Path $Path "TeamsLiveEventReport_$($StartDate.ToString('yyyy_MM_dd'))_$($EndDate.ToString('yyyy_MM_dd'))_summary.csv") -NoTypeInformation
            $Reports | Remove-Item
        }
    }
}

