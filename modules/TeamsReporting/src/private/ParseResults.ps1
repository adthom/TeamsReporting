function ParseResults {
    [CmdletBinding()]
    param (
        $Item,
        [System.Collections.Specialized.OrderedDictionary]
        $Result
    )
    $RootProperties = $Item | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    $RootPropName = $null
    foreach ($Prop in $RootProperties) {
        if ($null -ne $Item.$Prop.value) {
            continue
        }
        else {
            $SubProps = $Item.$Prop | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            foreach ($SProp in $SubProps) {
                if ($null -ne $Item.$Prop.$SProp.value) {
                    $RootPropName = $Prop
                    break
                }
            }
            if ($RootPropName) {
                break
            }
        }
    }
    if ($null -eq $RootPropName) {
        $ItemMetrics = $Item
    }
    else {
        $ItemMetrics = $Item.$RootPropName
    }

    $DailyResult = $false
    if ($ItemMetrics) {
        $Daily = @{}
        $Metrics = $ItemMetrics | Get-Member -Type NoteProperty | Select-Object -ExpandProperty Name
        foreach ($Metric in $Metrics) {
            if ([string]::IsNullOrWhiteSpace($Metric)) {
                continue
            }
            $mArray = $Metric.ToCharArray()
            $mArray[0] = [char]::ToUpper($mArray[0])
            $Metric = [string]::new($mArray)

            if ($null -ne $ItemMetrics.$Metric.timeSeries) {
                foreach ($day in $ItemMetrics.$Metric.timeSeries) {
                    if ($null -eq $day) {
                        continue
                    }
                    $Date = [datetime]$day.date
                    $Value = $day.value
                    if ($null -eq $Daily[$Date]) {
                        $Daily[$Date] = [ordered]@{
                            Date = $Date
                        }
                    }
                    $Daily[$Date][$Metric] = $Value
                }
            }
            if ($Metric -eq "LastActivity") {
                $Value = ([datetime]'1970-01-01T00:00:00.000Z').AddMilliseconds($ItemMetrics.$Metric.value)
            }
            else {
                $Value = $ItemMetrics.$Metric.value
            }
            $Result[$Metric] = $Value
        }
        if ($Daily.Keys.Count -gt 0) {
            $DailyResult = $true
            $MissingKeys = $Result.Keys | Where-Object { $_ -notin $Daily[$Daily.Keys[0]].Keys -and $_ -notin @('StartDate', 'EndDate') }
            foreach ($Key in $Daily.Keys) {
                foreach ($mKey in $MissingKeys) {
                    $Daily[$Key][$mKey] = $Result[$mKey]
                }
                [PSCustomObject]$Daily[$Key]
            }
        }
    }
    else {
        $Result['Item'] = $Item
    }
    if (!$DailyResult) {
        [PSCustomObject]$Result
    }
}
