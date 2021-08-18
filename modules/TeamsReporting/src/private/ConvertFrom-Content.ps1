function ConvertFrom-Content {
    param (
        $Content,
        $MediaType
    )
    if ($Content -is [System.Net.Http.StreamContent]) {
        $Content = $Content.ReadAsStringAsync().Result
    }
    if ($MediaType -eq 'application/json') {
        $Content | ConvertFrom-Json
    }
    else {
        $Content
    }
}
