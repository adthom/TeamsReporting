function ConvertTo-QueryString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $QueryHash
    )
    $TempList = [System.Collections.Generic.List[string]]::new()
    foreach ( $Query in $QueryHash.Keys ) {
        $ValueString = $QueryHash[$Query] -join ','
        $TempList.Add(('{0}={1}' -f $Query, [Web.HttpUtility]::UrlEncode($ValueString))) | Out-Null
    }
    $queryString = $TempList -join '&'
    $queryString
}
