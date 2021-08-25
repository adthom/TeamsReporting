function Get-TASReport {
    [CmdletBinding(DefaultParameterSetName = 'TimePeriod')]
    param (
        [Parameter(ParameterSetName = 'TimePeriod', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Date', Mandatory = $true)]
        [Parameter(ParameterSetName = 'TimePeriodPaginated', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatePaginated', Mandatory = $true)]
        [string]
        $Key,

        [Parameter(ParameterSetName = 'TimePeriod', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Date', Mandatory = $true)]
        [Parameter(ParameterSetName = 'TimePeriodPaginated', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatePaginated', Mandatory = $true)]
        [string]
        $Route,

        [Parameter(ParameterSetName = 'TimePeriod', Mandatory = $true)]
        [Parameter(ParameterSetName = 'TimePeriodPaginated', Mandatory = $true)]
        [ValidateSet(7, 30, 90)]
        [int]
        $TimePeriod,

        [Parameter(ParameterSetName = 'Date', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatePaginated', Mandatory = $true)]
        [datetime]
        $StartDate,

        [Parameter(ParameterSetName = 'Date', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatePaginated', Mandatory = $true)]
        [datetime]
        $EndDate,

        [Parameter(ParameterSetName = 'TimePeriod')]
        [Parameter(ParameterSetName = 'Date')]
        [Parameter(ParameterSetName = 'TimePeriodPaginated')]
        [Parameter(ParameterSetName = 'DatePaginated')]
        [switch]
        $IncludeDaily,

        [Parameter(ParameterSetName = 'TimePeriodPaginated', Mandatory = $true)]
        [Parameter(ParameterSetName = 'DatePaginated', Mandatory = $true)]
        [switch]
        $Paginated
    )
    $ReportParams = Get-TASReportParameters -Key $Key
    $LastAvailable = [datetime]$ReportParams.LatestDate
    $Route = $Route.Trim().TrimEnd('?')
    $QueryHash = @{}
    switch ($TimePeriod) {
        7 {
            $QueryHash['TimePeriod'] = "last-seven-days"
            break
        }
        30 {
            $QueryHash['TimePeriod'] = "last-thirty-days"
            break
        }
        90 {
            $QueryHash['TimePeriod'] = "last-ninety-days"
            break
        }
        default {
            break
        }
    }
    if ($StartDate) {
        if ($StartDate -lt $LastAvailable.AddDays(-90)) {
            Write-Error -Message "StartDate is invalid!" -ErrorAction Stop
        }
        $QueryHash['StartDate'] = $StartDate.ToString('yyyy-MM-dd')
    }
    if ($EndDate) {
        if ($EndDate -lt $StartDate -or $EndDate -gt $LastAvailable) {
            Write-Error -Message "EndDate is invalid!" -ErrorAction Stop
        }
        $QueryHash['EndDate'] = $EndDate.ToString('yyyy-MM-dd')
    }
    $QueryHash['Metrics'] = $ReportParams.MetricNames
    if ($IncludeDaily) {
        $QueryHash['IncludeTimeSeries'] = $ReportParams.MetricNames
    }
    if ($Paginated) {
        $QueryHash['pageSize'] = 100
    }
    do {
        if ($null -ne $QueryHash['nextCursor']) {
            Write-Host "Getting next $($QueryHash['pageSize']) results..." -ForegroundColor DarkGray
        }
        $Response = Invoke-TASMethod -Route $Route -QueryHash $QueryHash -Method Get
        if ($Response) {
            $ErrorCode = $Response.errorCode
            if ($ErrorCode) {
                Write-Warning "Response contained errors! ErrorCode: $ErrorCode"
            }
            else {
                $TenantId = $Response.id
                $StartDate = [datetime]$Response.startDate
                $EndDate = [datetime]$Response.endDate
                $TotalCount = $Response.TotalCount
                if ($null -eq $QueryHash['nextCursor']) {
                    if ($null -eq $TotalCount) {
                        $TotalCount = 1
                    }
                    $Summary = "Found {0} result{1} between {2:yyyy-MM-dd} and {3:yyyy-MM-dd}" -f $TotalCount, "$(if ($TotalCount -gt 1) {'s'})", $StartDate, $EndDate
                    Write-Host $Summary -ForegroundColor Green
                }
                $Result = [System.Collections.Specialized.OrderedDictionary]::new()
                foreach ($User in $Response.users) {
                    $Result['StartDate'] = $StartDate
                    $Result['EndDate'] = $EndDate
                    $Result['DisplayName'] = $User.displayName
                    $Result['Email'] = $User.email
                    $Result['ObjectId'] = $User.id
                    if ($TenantId) {
                        $Result['TenantId'] = $TenantId
                    }
                    ParseResults -Item $User -Result $Result
                }
                foreach ($Tenant in $Response.tenants) {
                    $Result['StartDate'] = $StartDate
                    $Result['EndDate'] = $EndDate
                    if ($TenantId) {
                        $Result['TenantId'] = $TenantId
                    }
                    ParseResults -Item $Tenant -Result $Result
                }
                foreach ($Team in $Response.teams) {
                    $Result['StartDate'] = $StartDate
                    $Result['EndDate'] = $EndDate
                    $Result['DisplayName'] = $Team.displayName
                    $Result['ObjectId'] = $Team.id
                    if ($TenantId) {
                        $Result['TenantId'] = $TenantId
                    }
                    ParseResults -Item $Team -Result $Result
                }
                foreach ($Device in $Response.devices) {
                    $Result['StartDate'] = $StartDate
                    $Result['EndDate'] = $EndDate
                    if ($TenantId) {
                        $Result['TenantId'] = $TenantId
                    }
                    ParseResults -Item $Device -Result $Result
                }
                foreach ($App in $Response.apps) {
                    $Result['StartDate'] = $StartDate
                    $Result['EndDate'] = $EndDate
                    $Result['Name'] = $App.name
                    $Result['Id'] = $App.id
                    $Result['AppType'] = $App.type
                    $Result['Developer'] = $App.developerName
                    $Result['Version'] = $App.version
                    $Result['Categories'] = $App.categories
                    $Result['LargeImageUrl'] = $App.largeImageUrl
                    $Result['LongDescription'] = $App.longDescription
                    $Result['SmallImageUrl'] = $App.smallImageUrl
                    $Result['ShortDescription'] = $App.shortDescription
                    $Result['SecurityComplianceInfo'] = $App.securityComplianceInfo
                    if ($TenantId) {
                        $Result['TenantId'] = $TenantId
                    }
                    if ($App.permissions) {
                        $Result['Permissions'] = $App.permissions
                    }
                    if ($App.publisherType) {
                        $Result['PublisherType'] = $App.publisherType
                    }
                    ParseResults -Item $App -Result $Result
                }
                foreach ($AppType in $Response.appTypes) {
                    $Result['StartDate'] = $StartDate
                    $Result['EndDate'] = $EndDate
                    $Result['DisplayName'] = $AppType.displayName
                    if ($TenantId) {
                        $Result['TenantId'] = $TenantId
                    }
                    ParseResults -Item $AppType -Result $Result
                }
            }
            if ($null -ne $Response.paging) {
                $QueryHash['nextCursor'] = $Response.paging.nextCursor
            } else {
                $QueryHash['nextCursor'] = $null
            }
        }
    } while ($null -ne $QueryHash['nextCursor'])
}