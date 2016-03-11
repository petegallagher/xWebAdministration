function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[System.String]
		$Location,

		[parameter(Mandatory = $true)]
		[ValidateSet("Anonymous","Basic","Windows")]
		[System.String]
		$Type
	)

	try 
	{
		$xPath = GetXpath($Type)
		Write-Verbose "Getting configuration for $xPath, location $Location"
		$config = Get-WebConfigurationProperty -Filter $xPath -Name enabled -Location $Location 
	}
	catch [System.IO.FileNotFoundException]
	{
		Throw "Location $Location Not Found"
	}

	if ($config -eq $null)
	{
		$ensure = "Absent"
	}
	else
	{
		$ensure = if ($config.Value -eq $true) {"Present"} else {"Absent"}
	}

	$returnValue = @{
		Location = $Location
		Type = $Type
		Ensure = $ensure
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[System.String]
		$Location,

		[parameter(Mandatory = $true)]
		[ValidateSet("Anonymous","Basic","Windows")]
		[System.String]
		$Type,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$value = if ($Ensure -eq "Present") {$true} else {$false}

	Write-Verbose "Setting $Type Authentication to $value for $Location"

	try 
	{
		$xPath = GetXpath($Type)
		Write-Verbose "Setting configuration for $xPath, location $Location"
		Set-WebConfigurationProperty -Filter $xPath -Name enabled -Location $Location -Value $value
	}
	catch [System.IO.FileNotFoundException]
	{
		Throw "Location $Location Not Found"
	}
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[System.String]
		$Location,

		[parameter(Mandatory = $true)]
		[ValidateSet("Anonymous","Basic","Windows")]
		[System.String]
		$Type,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
	$config = Get-TargetResource -Location $Location -Type $Type
	$result = ($config.Ensure -eq $Ensure)
	Write-Verbose $Location.GetType()

	$result
}


function GetXpath($type)
{
	"/system.WebServer/security/authentication/" + $type.ToLower() + "Authentication"
}


Export-ModuleMember -Function *-TargetResource