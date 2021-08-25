function Get-ConfigAPICalls {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("PstnCalls", "DirectRouting", "PstnCallGraph", "DirectRoutingGraph")]
        [string]
        $Endpoint,
        
        [DateTime]
        $StartDate,
        
        [DateTime]
        $EndDate,
        
        [int]
        $PageSize = 100,
        
        [int]
        $Skip = 0
    )
    do {
        $Uri = "https://api.interfaces.records.teams.microsoft.com/Skype.Analytics/${Endpoint}"
        $Uri += "?`$top=${PageSize}"
        if ($Skip -gt 0) {
            $Uri += "&`$skip=${Skip}"
        }
        if ($StartDate -or $EndDate) {
            $Uri += "&`$filter="
            if ($StartDate) {
                $StartString = $StartDate.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffK')
                $Uri += "callStart+ge+" + [Uri]::EscapeDataString($StartString)
            }
            if ($StartDate -and $EndDate) {
                $Uri += "+and+"
            }
            if ($EndDate) {
                $EndString = $EndDate.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffK')
                $Uri += "callStart+le+" + [Uri]::EscapeDataString($EndString)
            }
        }
        $Result = ConfigAPICall -Uri $Uri -Method GET
        $Skip += $PageSize
        foreach ($r in $Result.value) {
            $r
        }

        if ($Result.'@odata.count' -gt $Skip -and $Result.value.Count -eq $PageSize) {
            $Remaining = ($Skip / $Result.'@odata.count') * 100
            Write-Progress -Activity "Getting Results from $Endpoint" -PercentComplete $Remaining -CurrentOperation "$Skip of $($Result.'@odata.count') completed"
        }
    } while ($Result.'@odata.count' -gt $Skip -and $Result.value.Count -eq $PageSize)
    
    Write-Progress -Activity "Getting Results from $Endpoint" -PercentComplete 100 -Completed
}
