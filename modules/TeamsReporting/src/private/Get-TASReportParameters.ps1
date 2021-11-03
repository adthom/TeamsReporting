function Get-TASReportParameters {
    [CmdletBinding()]
    param (
        $Key
    )

    $Report = @{
        Key = $Key
    }
    $Routes = @(
        "MetricNames"
        "LatestDate"
    )
    foreach ($U in $Routes) {
        $Route = "/${U}"
        $QueryHash = @{
            ReportKey = $Key
        }
        $Response = Invoke-TASMethod -Route $Route -QueryHash $QueryHash -Method Get
        $Report[$U] = $Response
    }
    [PSCustomObject]$Report
}

