function FixSpacing ($inputString) {
    $Lines = $inputString -split [Environment]::NewLine
    $lastLine = $Lines[-1]
    $extraSpace = $lastLine -replace "^(\s*).*$", "`$1"
    $trimmedLines = foreach ($line in $Lines) {
        $line -replace "^$extraSpace", ""
    }
    $trimmedLines -join [Environment]::NewLine
}

function FindMatchingStrings {
    param (
        $Content,
        $OpenString,
        $CloseString
    )
    $lContent = $Content
    if (($openIndex = $lContent.IndexOf($OpenString)) -ge 0) {
        $cursor = 1
        $nextopen = $openIndex
        $stringBuilder = [Text.StringBuilder]::new()
        $stringBuilder.Append($lContent.Substring($openIndex, $OpenString.Length)) | Out-Null
        $sub = $lContent.Substring($nextopen)
        $offset = 0
        do {
            if ($nextopen -ge 0) {
                $start = $nextopen + $OpenString.Length
            } else {
                $start = 0
            }
            $sub = $sub.Substring($start)
            $nextclose = $sub.IndexOf($CloseString)
            $nextopen = $sub.IndexOf($OpenString)
            $offset = $start + $offset
            if ($nextclose -lt $nextopen -or $nextopen -lt 0) {
                $cursor--
                $nextopen = $nextclose
            } else {
                $cursor++
            }
        } while ($cursor -gt 0)
        $toRemove = $sub.Substring($nextclose + $CloseString.Length)
        $Content.Replace($toRemove, "").Trim()
    }
}

$Disclaimer = @(Get-Content -Path "${PSScriptRoot}\disclaimer.txt" | ForEach-Object { "# {0}" -f $_ }) -join "$([Environment]::NewLine)"

# Get Project Root Folder
$ProjectRoot = Split-Path -Path $PSScriptRoot -Parent

# Setup Path/File Variables for use in build
$srcPath = [IO.Path]::Combine($ProjectRoot, "src")
$releasePath = [IO.Path]::Combine($ProjectRoot, "release", "Scripts")

# Get Module Name from Project Folder Name
$ModuleName = Split-Path -Path $ProjectRoot -Leaf

$srcModuleManifest = "${srcPath}\${ModuleName}.psd1"
$ModuleManifestString = (Get-Content -Path $srcModuleManifest | 
    Where-Object { $_ -notmatch '^\s*#' } | 
    ForEach-Object { $_ -replace '#.+$', '' } | 
    Where-Object { $_ -ne [string]::Empty }
) -join [Environment]::NewLine
if ( -not [string]::IsNullOrWhiteSpace($ModuleManifestString) ) {
    $ModuleManifest = Invoke-Expression -Command $ModuleManifestString
}

$RequiredModules = [Text.StringBuilder]::new()
if ($null -ne $ModuleManifest['RequiredModules']) {
    $RequiredModules.Append("#Requires -Modules ") | Out-Null
    $i = 1
    foreach ($moduleHash in $ModuleManifest['RequiredModules']) {
        if ($moduleHash -is [System.Collections.Hashtable]) {
            $hashString = "@{ " + (($moduleHash.GetEnumerator() | ForEach-Object { "$($_.Key) = '$($_.Value)'" }) -join "; ") + " }"
            $RequiredModules.Append($hashString) | Out-Null
        }
        else {
            $RequiredModules.Append($moduleHash) | Out-Null
        }
        if ($i -lt $ModuleManifest['RequiredModules'].Length) {
            $RequiredModules.Append(",") | Out-Null
        }
        $i++
    }
}

# Import all functions into current session
$Privates = Get-ChildItem -Path ([IO.Path]::Combine($srcPath, "private")) -Filter *.ps1 -File
$Publics = Get-ChildItem -Path ([IO.Path]::Combine($srcPath, "public")) -Filter *.ps1 -File
foreach ($import in @($Publics + $Privates)) {
    try {
        . $import.FullName
    } catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# import getUsedLocalFunctions function
$GetUsedLocalFunc = Get-ChildItem -Path Function:GetUsedLocalFunctions -ErrorAction SilentlyContinue
if ($null -eq $GetUsedLocalFunc) {
    . "${PSScriptRoot}\GetUsedLocalFunctions.ps1"
}

foreach ($file in $Publics) {
    $FunctionName = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    $Function = Get-ChildItem -Path "Function:$FunctionName" -ErrorAction SilentlyContinue
    $ScriptBlock = $Function.ScriptBlock
    if ($null -eq $ScriptBlock) {
        Write-Warning "$FunctionName has no scriptblock!"
        continue
    } else {
        Write-Host "Building Script for $FunctionName"
    }
    $UsedFunctionStrings = GetUsedLocalFunctions -Script $ScriptBlock -Functions $null -GetStrings $true

    $content = $Function.Definition
    
    $helpText = FindMatchingStrings -OpenString "<#" -CloseString "#>" -Content $content
    if (![string]::IsNullOrEmpty($helpText)) {
        $modifiedContent = $content.Replace($helpText, "").Trim()
        $helpText = $helpText.Trim()
    } else {
        $helpText = ""
        $modifiedContent = $content.Trim()
    }

    if (($first = $modifiedContent.ToLower().IndexOf('[cmdletbinding')) -ge 0) {
        $sub = $modifiedContent.Substring($first)
        $CmdletBindingText = FindMatchingStrings -Content $sub -OpenString "[" -CloseString "]"
        $modifiedContent = $modifiedContent.Replace($CmdletBindingText, "").Trim()
        $CmdletBindingText = $CmdletBindingText.Trim()
    } else {
        $CmdletBindingText = ""
    }
    
    if (($first = $modifiedContent.ToLower().IndexOf('param')) -ge 0) {
        $first = $first + 5
        $sub = $modifiedContent.Substring($first)
        $params = FindMatchingStrings -Content $sub -OpenString "(" -CloseString ")"
        $paramPattern = "param\s*" + [Regex]::Escape($params)
        if ($modifiedContent -match $paramPattern) {
            $params = $Matches[0]
            $modifiedContent = $modifiedContent.Replace($params, "").Trim()
        } else {
            Write-Warning "$params does not match $modifiedContent"
        }
    } else {
        $params = ""
    }

    $functionText = $modifiedContent.Trim()

    if (![string]::IsNullOrEmpty($helpText)) {
        $helpText = FixSpacing $helpText
    }
    if (![string]::IsNullOrEmpty($params)) {
        $params = FixSpacing $params
    }
    $functionText = FixSpacing $functionText

    # merge strings to $compiledScript
    $scriptArray = @()
    if (![string]::IsNullOrEmpty($Disclaimer)) {
        $scriptArray += $Disclaimer
    }
    if (![string]::IsNullOrEmpty($RequiredModules.ToString())) {
        $scriptArray += $RequiredModules.ToString()
    }
    if (![string]::IsNullOrEmpty($helpText)) {
        $scriptArray += $helpText
    }
    if (![string]::IsNullOrEmpty($CmdletBindingText)) {
        $scriptArray += $CmdletBindingText
    }
    if (![string]::IsNullOrEmpty($params)) {
        $scriptArray += $params
    }
    if (![string]::IsNullOrEmpty($UsedFunctionStrings)) {
        $scriptArray += $UsedFunctionStrings
    }
    if (![string]::IsNullOrEmpty($functionText)) {
        $scriptArray += $functionText
    }
    $compiledScript = $scriptArray -join "$([Environment]::NewLine)$([Environment]::NewLine)"
    $nlr = [Regex]::Escape([Environment]::NewLine)
    $compiledScript = $compiledScript -replace "$nlr{3,}", "$([Environment]::NewLine)$([Environment]::NewLine)"

    if (!(Test-Path -Path $releasePath)) {
        New-Item -Path $releasePath -ItemType Directory | Out-Null
    }
    Set-Content -Path ([IO.Path]::Combine($releasePath, $file.Name)) -Value $compiledScript
}

# create Zip Package
$Scripts = Get-ChildItem -Path $releasePath -Filter *.ps1 | Select-Object -ExpandProperty FullName
Compress-Archive -Path $Scripts -DestinationPath ([IO.Path]::Combine($releasePath, "Scripts.zip")) -CompressionLevel Optimal -Force
