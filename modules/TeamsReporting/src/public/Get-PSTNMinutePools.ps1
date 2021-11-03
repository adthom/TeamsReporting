function Get-PSTNMinutePools {
    [CmdletBinding()]
    param()

    $SkuHash = @{
        MCOPSTN1    = "Domestic Calling Plan (1200 minutes)"
        MCOPSTN1_NA = "Domestic Calling Plan (3000 minutes)"
        MCOPSTN2    = "International Calling Plan (1200 minutes)"
        MCOPSTN2_NA = "International Calling Plan (3000 minutes)"
        MCOPSTN5    = "Domestic Calling Plan (120 min)"
        MCOPSTN6    = "Domestic Calling Plan (240 min)"
        MCOMEETADD  = "Audio Conferencing - Outbound calls"
    }
    $MinsPerUserHash = @{
        MCOPSTN1    = 1200
        MCOPSTN1_NA = 3000
        MCOPSTN2    = 1200
        MCOPSTN2_NA = 3000
        MCOPSTN5    = 120
        MCOPSTN6    = 240
        MCOMEETADD  = 60
    }
    $Uri = "https://api.interfaces.records.teams.microsoft.com/Skype.Analytics/MinutePools"
    $Result = ConfigAPICall -Uri $Uri -Method GET
    $Pools = foreach ($r in $Result.value) {
        $r.pools | Where-Object { $_.totalSizeSeconds -gt 0 } | Add-Member -Name Capability -MemberType NoteProperty -Value $r.capability -PassThru
    }
    foreach ($Pool in $Pools) {
        $PoolIdParts = $Pool.id -split '\.'
        $SKUId = $PoolIdParts[0]
        $Region = $PoolIdParts[1].ToUpperInvariant()
        if ($Region -in @("US-PR", "CA")) {
            $SKUId += "_NA"
        }
        $CallingType = (Get-Culture).TextInfo.ToTitleCase($PoolIdParts[2])
        if ($Region -eq "__GLOBAL_CPC__") {
            $Region = "N/A"
            $CallingType = "Zone A"
        }
        $TotalPoolMinutes = [decimal]$Pool.totalSizeSeconds / 60.0d
        [int]$UserCount = $TotalPoolMinutes / $MinsPerUserHash[$SKUId]
        [PSCustomObject]@{
            LicenseId        = $Pool.Capability
            LicenseDetail    = $SkuHash[$SKUId]
            CountryRegion    = $Region
            UsersInPool      = $UserCount
            TotalPoolMinutes = $TotalPoolMinutes
            MinutesUsed      = [decimal]$Pool.usedSeconds / 60.0d
            MinutesAvailable = [decimal]$Pool.availableSeconds / 60.0d
            CallType         = $CallingType
        }
    }
}
