function Get-AllTASReports {
    [CmdletBinding()]
    param (
        $Path = $PWD,

        $TimePeriod = 90
    )

    $Reports = @(
        "TeamsUserActivityTenantSummary"
        "TeamsUserActivity"
        "TeamsUsageTenantSummary"
        "TeamsUsage"
        "TeamsDeviceUsageTenantSummary"
        "TeamsDeviceUsage"
        "AppsUsageTenantSummary"
        "AppsUsage"
    )
    foreach ($Report in $Reports) {
        $ReportCommand = "Get-${Report}"
        $DailyPath = [IO.Path]::Combine($Path, "${Report}-Daily.csv")
        $SummaryPath = [IO.Path]::Combine($Path, "${Report}.csv")
        Write-Information -MessageData "Getting $Report"
        & $ReportCommand -TimePeriod $TimePeriod -IncludeDaily | Export-Csv -Path $DailyPath -NoTypeInformation
        Write-Information -MessageData "${Report} daily report saved to ${DailyPath}"
        & $ReportCommand -TimePeriod $TimePeriod | Export-Csv -Path $SummaryPath -NoTypeInformation
        Write-Information -MessageData "${Report} overall report saved to ${SummaryPath}"
    }
}

