param (
    [int]
    [ValidateRange(0, [int]::MaxValue)]
    $MajorVersion,

    [int]
    [ValidateRange(0, [int]::MaxValue)]
    $MinorVersion,

    [string]
    $Company,

    [string]
    $Author
)

# Get Project Root Folder
$ProjectRoot = Split-Path -Path $PSScriptRoot -Parent

# Get Module Name from Project Folder Name
$ModuleName = Split-Path -Path $ProjectRoot -Leaf

# Setup Path/File Variables for use in build
$srcPath = [IO.Path]::Combine($ProjectRoot, "src")
$releasePath = [IO.Path]::Combine($ProjectRoot, "release", $ModuleName)
$zipPath = [IO.Path]::Combine($ProjectRoot, "release")
$moduleFile = "${releasePath}\${ModuleName}.psm1"
$moduleManifestFile = "${releasePath}\${ModuleName}.psd1"
$srcModuleManifest = "${srcPath}\${ModuleName}.psd1"

$ModuleManifest = Import-PowerShellDataFile -Path $srcModuleManifest

if (($MajorVersion + $MinorVersion) -eq 0 -and $null -ne $ModuleManifest['ModuleVersion']) {
    $MajorVersion = [int]($ModuleManifest['ModuleVersion'] -split '\.')[0]
    if ( ($ModuleManifest['ModuleVersion'] -split '\.').Count -gt 1 ) {
        $MinorVersion = [int]($ModuleManifest['ModuleVersion'] -split '\.')[1]
    }
    $BuildNumber = [int]([datetime]::Now.ToString("yy") + [datetime]::Now.DayOfYear)
    if ( ($ModuleManifest['ModuleVersion'] -split '\.').Count -gt 2 ) {
        $CurrentBuildNumber = [int]($ModuleManifest['ModuleVersion'] -split '\.')[2]
        if ( ($ModuleManifest['ModuleVersion'] -split '\.').Count -gt 3 ) {
            $Revision = [int]($ModuleManifest['ModuleVersion'] -split '\.')[3]
        }
    }
    if ( $CurrentBuildNumber -ne $BuildNumber ) {
        $Revision = 1
    }
    else {
        $Revision++
    }
}
$Version = "{0}.{1}.{2}.{3}" -f @(
    $MajorVersion,
    $MinorVersion,
    $BuildNumber,
    $Revision
)
Update-ModuleManifest -Path $srcModuleManifest -ModuleVersion $Version

#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $srcPath\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $srcPath\Private\*.ps1 -ErrorAction SilentlyContinue )

$FunctionsToExport = @($Public | Select-Object -ExpandProperty BaseName)
Write-Host "Public Functions:" $FunctionsToExport -Separator "`r`n"

$NewModuleManifestParams = @{
    Path              = $moduleManifestFile
    FunctionsToExport = $FunctionsToExport
    ModuleVersion     = $Version
    CompanyName       = $Company
    Author            = $Author
}

if ( [string]::IsNullOrEmpty($Company) -and $ModuleManifest['CompanyName'].ToLower() -ne "unknown" ) {
    $NewModuleManifestParams['CompanyName'] = $ModuleManifest['CompanyName']
}
if ( [string]::IsNullOrEmpty($Author) ) {
    $NewModuleManifestParams['Author'] = $ModuleManifest['Author']
}

# Update properties from src Manifest
$Parameters = (Get-Command -Name Update-ModuleManifest).Parameters.Keys
foreach ( $p in $Parameters ) {
    if ( $null -ne $ModuleManifest[$p] ) {
        if ( $p -eq "PrivateData" ) {
            foreach ( $d in $ModuleManifest['PrivateData']['PSData'].Keys ) {
                $PSData = $ModuleManifest['PrivateData']['PSData']
                if ( $null -ne $PSData[$d] ) {
                    if ( $d -in $Parameters ) {
                        $PSData.Remove($d)
                    }
                    if ( $d -notin $NewModuleManifestParams.Keys) {
                        [void] $NewModuleManifestParams.Add($d, $PSData[$d])
                    }
                }
                if ( $PSData.Keys -gt 0 ) {
                    [void] $NewModuleManifestParams.Add("PrivateData", $PSData)
                }
            }
        }
        elseif ( $p -notin $NewModuleManifestParams.Keys -and $p -notin @("Copyright") ) {
            if ( $p -ne "FunctionsToExport" -and $p.EndsWith("ToExport") -and $ModuleManifest[$p] -eq '*' ) {
                [void] $NewModuleManifestParams.Add($p, @())
            }
            else {
                [void] $NewModuleManifestParams.Add($p, $ModuleManifest[$p])
            }
        }
    }
}

# Remove old release, copy all data from src to releasePath
if ( -not ( Test-Path -Path $releasePath -PathType Container) ) {
    New-Item -Path $releasePath -ItemType Directory
}
Remove-Item -Path "${releasePath}\*" -Recurse
Copy-Item -Path "${srcPath}\*" -Recurse -Destination $releasePath

# Cleanup Empty Files
Get-ChildItem -Path $releasePath -Recurse -File | ForEach-Object {
    if ( [string]::IsNullOrWhiteSpace( ( Get-Content -Path $_.FullName ) ) ) {
        Remove-Item -Path $_.FullName
    }    
}

# Cleanup Empty Folders
Get-ChildItem -Path $releasePath -Recurse -Directory | ForEach-Object {
    if ($null -eq (Get-ChildItem -Path $_.FullName -File -Recurse)) {
        Remove-Item -Path $_.FullName -Recurse
    }
}

# Create psm1 for module
Set-Content -Path $moduleFile -Value "# $ModuleName"
Add-Content -Path $moduleFile -Value "# Version: $Version"
Add-Content -Path $moduleFile -Value "# $($NewModuleManifestParams['Copyright'])`n"
Add-Content -Path $moduleFile -Value "# Importing Module Members`n"

#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $releasePath\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $releasePath\Private\*.ps1 -ErrorAction SilentlyContinue )

$replacePattern = $releasePath -replace '\\', '\\'
foreach ($import in @($Public)) {
    # add the dot source for all discovered PS1 files to our psm1
    $PS1Path = $import.FullName -replace $replacePattern, ''
    Add-Content -Path $moduleFile -Value ". `"`$PSScriptRoot${PS1Path}`""
}

# Create new module manifest with our inputs

New-ModuleManifest @NewModuleManifestParams

$Files = Get-ChildItem -Path $releasePath | Select-Object -ExpandProperty FullName
Compress-Archive -Path $Files -DestinationPath ([IO.Path]::Combine($zipPath, "Module.zip")) -CompressionLevel Optimal -Force
