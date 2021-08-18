function ConfigAPICall {
    [CmdletBinding()]
    param (
        $Uri,
        $Method = "GET",
        $Body
    )
    Write-Verbose "Calling ConfigApi"
    Write-Verbose " Target Url: $Uri"
    Write-Verbose "HTTP Method: $Method"
    $Request = [System.Net.Http.HttpRequestMessage]::new($Method, $Uri)
    if (![string]::IsNullOrEmpty($Body)) {
        Write-Verbose "    Payload: $Body"
        $Request.Content = [System.Net.Http.StringContent]::new($Body, [Text.Encoding]::UTF8)
        $Request.Content.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/json")
    }
    $InvocationInfo = $MyInvocation
    $Pipeline = [Microsoft.Teams.ConfigAPI.Cmdlets.Generated.Module]::Instance.CreatePipeline($InvocationInfo)
    $Task = $Pipeline.Pipeline.SendAsync( $Request, [Microsoft.Teams.ConfigAPI.Cmdlets.Generated.Runtime.EventListener]::new() )
    $Task.Wait()
    if ($Task.IsFaulted) {
        Write-Error -Exception $Task.Exception
    }
    else {
        $Result = $Task.Result
        $Content = ConvertFrom-Content -Content $Result.Content -MediaType $Result.Content.Headers.ContentType.MediaType
        if ($Result.IsSuccessStatusCode) {
            $Content
        }
        else {
            $WriteError = @{}
            if ($Content.error) {
                $Content = $Content.error
            }
            if ($Content -is [string]) {
                $WriteError['Message'] = $Content
            }
            if ($Content.message) {
                $WriteError['Message'] = $Content.message
            }
            if ($Content.code) {
                $WriteError['ErrorId'] = $Content.code
            }
            if ($Content.target) {
                $WriteError['TargetObject'] = $Content.target
            }
            else {
                $WriteError['TargetObject'] = $Task
            }
            if ($Content.action) {
                $WriteError['RecommendedAction'] = $Content.action
            }
            if ($null -eq $WriteError['Message']) {
                $WriteError['Message'] = "Unhandled ConfigApi Exception"
                $WriteError['RecommendedAction'] = "See TargetObject for more detail"
                $WriteError['TargetObject'] = $Content
            }
            Write-Error @WriteError
        }
    }
}
