function GetUsedLocalFunctions {
    param (
        [ScriptBlock]
        $Script,
        [Collections.Generic.List[object]]
        $Functions = $null,
        [bool]
        $GetStrings = $true
    )
    if ($null -eq $Functions) {
        $allFunctions = Get-ChildItem -Path Function: | Where-Object { [string]::IsNullOrEmpty($_.ModuleName) `
            -and [string]::IsNullOrEmpty($_.Version) `
            -and [string]::IsNullOrEmpty($_.Source) `
            -and [string]::IsNullOrEmpty($_.HelpUri) `
            -and [string]::IsNullOrEmpty($_.HelpFile) `
        }
        $Functions = [Collections.Generic.List[object]]::new()
        foreach ($func in $allFunctions) {
            $Functions.Add($func) | Out-Null
        }
    }
    $newFunctions = [Collections.Generic.List[object]]::new()
    foreach ($func in $Functions) {
        if ($func.ScriptBlock -ne $Script) {
            $newFunctions.Add($func) | Out-Null
        }
    }
    $usedFunctions = foreach ($func in $newFunctions) {
        $funcName = $func.Name.ToLower()
        $scriptString = $Script.ToString().ToLower()
        if ($scriptString.IndexOf($funcName) -ge 0 -and $scriptString -match "(?<=[\=\s\(\)\{\}\:])${funcName}(?=[\=\s\(\)\{\}\:])") {
            $func
            GetUsedLocalFunctions -Script $func.ScriptBlock -Functions $newFunctions -GetStrings $false
        }
    }
    $usedFunctions = $usedFunctions | Sort-Object -Property Name -Unique
    if ($GetStrings) {
        $usedFunctions | ForEach-Object { "function $($_.Name) {$([Environment]::NewLine)$($_.Definition.Trim([Environment]::NewLine))$([Environment]::NewLine)}" }
    } else {
        $usedFunctions
    }
}