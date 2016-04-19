function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebsitePath,

        [parameter(Mandatory = $true)]
        [String]
        $Key
    )

    Write-Verbose "Getting configuration for `"$Key`" at PSPath `"$WebsitePath`""
    return Get-WebConfiguration -PSPath $WebsitePath -Filter $Key
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebsitePath,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [String]
        $Key,

        [String]
        $Value
    )

    if($Ensure -eq 'Present')
    {
        $existingResource = Get-TargetResource -WebsitePath $WebsitePath -Key $Key

        if($existingResource) {
            Write-Verbose "Setting configuration `"$Key`"=`"$Value`" at PSPath `"$WebsitePath`""
            Set-WebConfiguration -Filter $Key -PSPath $WebsitePath -Value $Value
        } else {
            Write-Verbose "Adding configuration for `"$Key`"=`"$Value`" at PSPath `"$WebsitePath`""
            Add-WebConfiguration -Filter $Key -PSPath $WebsitePath -Value $Value
        }
    }
    else
    {
        Write-Verbose "Clearing configuration for `"$Key`" at PSPath `"$WebsitePath`""
        Clear-WebConfiguration -Filter $Key -PSPath $WebsitePath
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebsitePath,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [String]
        $Key,

        [String]
        $Value
    )

    $existingResource = Get-TargetResource -WebsitePath $WebsitePath -Key $Key
    
    if($Ensure -eq 'Present') {
        if($Value -eq $existingResource.Value) {
            return $true
        } else {
            return $false
        }
    } elseif ($Ensure -eq "Absent") {
        if(!$existingResource) {
            return $true
        } else {
            return $false
        }
    }
}

Export-ModuleMember -Function *-TargetResource