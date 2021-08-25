function Export-TeamsLiveEvents {
    param (
        [datetime]
        $StartTime,
        
        [datetime]
        $EndTime,

        $OrganizerId,
        
        $Path = $PWD,

        [switch]
        $DownloadResources
    )
    $LiveEvents = Get-TeamsLiveEventReport -StartTime $StartTime -EndTime $EndTime -OrganizerId $OrganizerId
    $Resources = @("QnaReport", "AttendeeReport", "Recording", "Transcript")
    $InvalidPattern = "[^\s\w]+"
    $Reports = foreach ($Event in $LiveEvents) {
        $EventReport = [PSCustomObject]@{
            Subject                    = $Event.subject
            Organizer                  = $Event.participants.organizer.upn
            ScheduledStart             = if ($null -ne $Event.startTime) { [datetime]$Event.startTime } else { $null }
            ScheduledEnd               = if ($null -ne $Event.endTime) { [datetime]$Event.endTime } else { $null }
            EventStart                 = if ($null -ne $Event.extensionData.streamStartTime) { [datetime]$Event.extensionData.streamStartTime } else { $null }
            EventEnd                   = if ($null -ne $Event.extensionData.streamEndTime) { [datetime]$Event.extensionData.streamEndTime } else { $null }
            InternalMeetingFirstJoined = if ($null -ne $Event.extensionData.firstJoinTime) { [datetime]$Event.extensionData.firstJoinTime } else { $null }
            Views                      = $Event.extensionData.broadcastResources.SessionCount
            Producers                  = $Event.participants.producers.Count
            Presenters                 = $Event.participants.contributors.Count + $Event.participants.presenters.Count
            ExportedResourcePath       = ""
        }
        if ($DownloadResources) {
            Write-Host "Getting Resources for event " -NoNewline
            $EventFolder = if (![string]::IsNullOrEmpty($EventReport.Subject)) {
                Write-Host $EventReport.Subject
                $EventReport.Subject
            }
            else {
                $Start = $EventReport.ScheduledStart.ToString('u')
                Write-Host "organized by" $EventReport.Organizer "on" $Start
                @($EventReport.Organizer, $Start) -join "_"
            }
            $EventFolder = $EventFolder -replace $InvalidPattern, '_'
            if ($EventFolder.Length -gt 50) {
                $EventFolder = $EventFolder.Substring(0, 50)
            }
            $EventPath = [IO.Path]::Combine($Path, $EventFolder)
            if ((Test-Path -Path $EventPath)) {
                $CurrentContents = Get-ChildItem -Path $EventPath
                if ($CurrentContents.Count -gt 0) {
                    # need to find unique folder as this is in use
                    $iterator = 0
                    $EventPath += ("_{0:D2}" -f $iterator)
                    do {
                        $iterator++
                        $EventPath = $EventPath.Substring(0, $EventPath.Length - 2) + ("{0:D2}" -f $iterator)
                        $PathInUse = Test-Path -Path $EventPath
                    } while ($PathInUse)
                }
            }
            $EventReport.ExportedResourcePath = $EventPath
    
            if (!$Event.extensionData.broadcastResources.IsDeleted -and [datetime]::Now -lt [datetime]$Event.extensionData.broadcastResources.Expiry) {
                if (!(Test-Path -Path $EventReport.ExportedResourcePath)) {
                    New-Item -Path $EventReport.ExportedResourcePath -ItemType Directory | Out-Null
                }
                foreach ($Resource in $Resources) {
                    if ($null -ne $Event.extensionData.broadcastResources.$Resource) {
                        Get-TeamsLiveEventResources -BroadcastResources $Event.extensionData.broadcastResources -Resource $Resource -Path $EventReport.ExportedResourcePath
                    }
                }
            }
            else {
                Write-Warning "$EventFolder has expired, resources are no longer available for export!"
                Remove-Item -Path $EventReport.ExportedResourcePath -ErrorAction SilentlyContinue
                $EventReport.ExportedResourcePath = $null
            }
        }
        $EventReport
    }
    $ReportAppend = ""
    $ReportAppend += $StartTime.ToString('yyyy_MM_dd') -replace $InvalidPattern, '_'
    $ReportAppend += "_" + ($EndTime.ToString('yyyy_MM_dd') -replace $InvalidPattern, '_')
    if (![string]::IsNullOrEmpty($OrganizerId)) {
        $ReportAppend += "_" + ($OrganizerId -replace $InvalidPattern, '_')
    }
    $SummaryPath = [IO.Path]::Combine($Path, "TeamsLiveEventReport_${ReportAppend}.csv")
    
    if ((Test-Path -Path $SummaryPath)) {
        $iterator = 0
        $ReportAppend += ("_{0:D2}" -f $iterator)
        do {
            $iterator++
            $ReportAppend = $ReportAppend.Substring(0, $ReportAppend.Length - 2) + ("{0:D2}" -f $iterator)
            $SummaryPath = [IO.Path]::Combine($Path, "TeamsLiveEventReport_${ReportAppend}.csv") 
            $PathInUse = Test-Path -Path $SummaryPath
        } while ($PathInUse)
    }
    $Reports = $Reports | Where-Object { $null -ne $_ }
    if ($Reports.Count -gt 0) {
        $Reports | Export-Csv -Path $SummaryPath -NoTypeInformation
        Write-Host "Report Summary saved to $SummaryPath"
    }    
}
