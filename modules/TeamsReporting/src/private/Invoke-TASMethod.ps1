function Invoke-TASMethod {
    [CmdletBinding()]
    param (
        [string]
        $Route,

        [hashtable]
        $QueryHash,

        $Method = "Get"
    )

    $Token = Get-TASToken
    $Route = $Route.Trim().TrimStart('/')
    $Uri = "https://tas.teams.microsoft.com/v2/${Route}"
    if ($QueryHash) {
        $QueryString = ConvertTo-QueryString -QueryHash $QueryHash
        $Uri += "?" + $QueryString
    }
    try {
        Write-Verbose -Message "URI: $Uri"
        $Result = Invoke-RestMethod -Method $Method -Headers @{ 'Authorization' = "Bearer $($Token.AccessToken)" } -Uri $Uri -ErrorAction Stop
    }
    catch {
        $contentStream = $_.Exception.Response.GetResponseStream()
        $sr = [IO.StreamReader]::new($contentStream)
        $sr.BaseStream.Position = 0
        $rString = $sr.ReadToEnd()
        if ($_.Exception.Response.ContentType -in @("application/json", "text/json")) {
            $eBody = $rString | ConvertFrom-Json
            $m = if ($eBody.message) {
                $eBody.message
            }
            elseif ($eBody.error) {
                $eBody.error
            }
            else {
                $rString
            }
            Write-Error -Message $m -TargetObject $_.TargetObject
        }
        else {
            Write-Error -Message $rString -TargetObject $_.TargetObject
        }
        $sr.Dispose()
        $contentStream.Dispose()
    }
    $Result
}

