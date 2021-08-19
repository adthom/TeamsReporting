function Get-AllTASReports {
    param (
        $Path = $PWD,
        $TimePeriod = 90
    )
    
    # Keep this comment block to allow the script builder to add references
    # Get-TeamsUserActivityTenantSummary
    # Get-TeamsUserActivity
    # Get-TeamsUsageTenantSummary
    # Get-TeamsUsage
    # Get-TeamsDeviceUsageTenantSummary
    # Get-TeamsDeviceUsage
    # Get-AppsUsageTenantSummary
    # Get-AppsUsage

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

        Write-Host "Getting $Report"
        & $ReportCommand -TimePeriod $TimePeriod -IncludeDaily | Export-Csv -Path $DailyPath -NoTypeInformation
        Write-Host "${Report} daily report saved to ${DailyPath}"
        & $ReportCommand -TimePeriod $TimePeriod | Export-Csv -Path $SummaryPath -NoTypeInformation
        Write-Host "${Report} overall report saved to ${SummaryPath}"
    }
}
