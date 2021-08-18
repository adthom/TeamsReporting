function Get-TeamsLiveEventResources {
    param (
        $BroadcastResources,
        [ValidateSet("QnaReport", "AttendeeReport", "Recording", "AltRecording", "Transcript", "DeleteAll", "RestoreAll")]
        $Resource = "AttendeeReport",
        $Path = $PWD
    )
    if ($BroadcastResources -is [string]) {
        $BroadcastResources = $BroadcastResources | ConvertFrom-Json
    }
    $Download = $false
    $Url = switch ($Resource) {
        "AttendeeReport" {
            $BroadcastResources.AttendeeReport.url
            $Download = $true
            break
        }
        "Recording" {
            $BroadcastResources.Recording.url
            $Download = $true
            break
        }
        "AltRecording" {
            $BroadcastResources.AltRecording.url
            $Download = $true
            break
        }
        "DeleteAll" {
            $BroadcastResources.Links.DeleteAll
            break
        }
        "RestoreAll" {
            $BroadcastResources.Links.RestoreAll
            break
        }
        "QnAReport" {
            $BroadcastResources.QnaReport.url
            $Download = $true
            break
        }
        "Transcript" {
            $BroadcastResources.Transcript.urls
            $Download = $true
        }
        default {
            throw [System.NotImplementedException]::new($Resource)
        }
    }
    $Urls = if ($Url -isnot [string]) {
        $Languages = $Url | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        foreach ($Language in $Languages) {
            $Url.$Language
        }
    }
    else {
        @($Url)
    }
    foreach ($u in $Urls) {
        $OneTimeUrl = Get-TeamsLiveEventReport -LiveEventType attendee -LiveEventServiceUrl $u
        if ($Download -and ![string]::IsNullOrEmpty($OneTimeUrl.resourceUrl)) {

            UsingPS ($httpClient = [Net.Http.HttpClient]::new()) {
                $getTask = $httpClient.GetAsync($OneTimeUrl.resourceUrl)
                $getTask.Wait()
                $response = $getTask.Result.EnsureSuccessStatusCode()
                $FileName = $response.Content.Headers.ContentDisposition.FileName.Trim('"')
                $DPath = [IO.Path]::Combine($Path, $FileName)
                UsingPS ($fs = [IO.File]::OpenWrite($DPath)) {
                    $ct = $response.Content.CopyToAsync($fs)
                    $ct.Wait()
                }
            }
        }
        else {
            $OneTimeUrl
        }
    }
}
