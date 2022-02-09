function Get-TeamsLiveEventReport {
    [CmdletBinding()]
    param (
        $LiveEventType = "scheduling",

        $LiveEventServiceUrl = "https://scheduler.teams.microsoft.com/teams/v1/meetings/daterange/{0}",

        [datetime]
        $StartTime,

        [datetime]
        $EndTime,

        $OrganizerId
    )

    $Token = Get-TAGSToken
    $Uri = "https://tags.teams.microsoft.com/api/v1/liveeventservice"
    $BodyObject = @{
        liveEventTypeOfService = $LiveEventType
        liveEventServiceUrl    = $LiveEventServiceUrl -f $Token.TenantId
    }
    if ($StartTime) {
        $BodyObject['startTime'] = $StartTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffK')
    }
    if ($EndTime) {
        $BodyObject['endTime'] = $EndTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffK')
    }
    $BodyObject['organizerId'] = if ($OrganizerId) { $OrganizerId } else { [string]::Empty }
    $Body = $BodyObject | ConvertTo-Json -Compress
    try {
        $Headers = @{
            'Authorization' = "Bearer $($Token.AccessToken)"
        }
        $Response = Invoke-RestMethod -Method Post -Headers $Headers -Uri $Uri -Body $Body -ContentType "application/json"
    }
    catch {
        $contentStream = $_.Exception.Response.GetResponseStream()
        $sr = [IO.StreamReader]::new($contentStream)
        $sr.BaseStream.Position = 0
        $rString = $sr.ReadToEnd()
        $rString | ConvertFrom-Json
    }
    if ($null -ne $Response.liveEventServiceData) {
        $ResultObject = $Response.liveEventServiceData | ConvertFrom-Json
        if ($ResultObject -is [object[]]) {
            $FoundThreads = [Collections.Generic.List[object]]::new()
            foreach ($result in $ResultObject) {
                if ($null -eq $result.groupContext -or $null -eq $result.groupContext.threadId) {
                    continue
                }
                if ($FoundThreads -contains $result.groupContext.threadId) {
                    continue
                }
                $FoundThreads.Add($result.groupContext.threadId) | Out-Null
                if (![string]::IsNullOrEmpty($result.extensionData.broadcastResources)) {
                    $broadcastResources = $result.extensionData.broadcastResources | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($null -ne $broadcastResources) {
                        $result.extensionData.broadcastResources = $broadcastResources
                    }
                }
                $result
            }
        }
        else {
            $ResultObject
        }
    }
    else {
        $Response
    }
}

