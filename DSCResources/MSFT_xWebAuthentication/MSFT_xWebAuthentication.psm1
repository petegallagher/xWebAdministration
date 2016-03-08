function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
		[ValidateSet("Anonymous","Basic","Digest","Windows")]
		[String]
		$Type,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$Site,

		[String]
		$Application,

		[String]
		$Path
		)

	try {
		$Filter = GetFilterXpath -Type $Type
		$PSPath = GetLocationXpath -Site $Site -Application $Application -Path $Path

		Write-Verbose "Getting configuration for `"$Filter`" at PSPath `"$PSPath`""
		$AuthenticationRule = Get-WebConfiguration -Filter $Filter -PSPath $PSPath
	}
	catch [System.Management.Automation.ItemNotFoundException] {
		Write-Verbose "PSPath `"$PSPath`" Not Found"
	}

	if ($AuthenticationRule -eq $null) {
		$EnsureResult = "Absent"
	}
	else {
		$EnsureResult = "Present"
	}

	if ($AuthenticationRule.enabled -eq $True) {
		$StateResult = "Enabled"
	} else {
		$StateResult = "Disabled"
	}

	return @{
		Ensure = $EnsureResult
		State = $StateResult
		Type = $Type
		Site = $Site
		Application = $Application
		Path = $Path
	}
}


function Set-TargetResource
{
	[CmdletBinding()]
	param (
		[ValidateSet("Present", "Absent")]
		[String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[ValidateSet("Anonymous","Basic","Digest","Windows")]
		[String]
		$Type,

		[ValidateSet("Enabled", "Disabled")]
		[String]
		$State = "Enabled",

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$Site,

		[String]
		$Application,

		[String]
		$Path
		)

	$Filter = GetFilterXpath -Type $Type
	$PSPath = GetLocationXpath -Site $Site -Application $Application -Path $Path

	if ($Ensure -eq "Present") {
		if ($State -eq "Enabled") {
			$Value = $True
		} else {
			$Value = $False
		}

		# Create the authentication rule
		Write-Verbose "Setting configuration for `"$Filter`" at PSPath `"$PSPath`""
		Set-WebConfiguration -Filter $Filter -PSPath $PSPath -Value @{enabled=$Value}
	} else {
		# Delete the authentication rule
		Write-Verbose "Clearing configuration for `"$Filter`" at PSPath `"$PSPath`""
		Clear-WebConfiguration -Filter $Filter -PSPath $PSPath
	}
}


function Test-TargetResource
{
	[CmdletBinding()]
	param (
		[ValidateSet("Present", "Absent")]
		[String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[ValidateSet("Anonymous","Basic","Digest","Windows")]
		[String]
		$Type,

		[ValidateSet("Enabled", "Disabled")]
		[String]
		$State = "Enabled",

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$Site,

		[String]
		$Application,

		[String]
		$Path
		)

    Write-Verbose "Testing configuration for `"$Type`" authentication, state `"$State`", site `"$Site`""
	$InDesiredState = $true

	$CurrentRule = Get-TargetResource -Type $Type -Site $Site -Application $Application -Path $Path

	if ($Ensure -eq "Present") { 
		if ($Ensure -ne $CurrentRule.Ensure) { $InDesiredState = $false }
		if ($Type -ne $CurrentRule.Type) { $InDesiredState = $false }
		if ($State -ne $CurrentRule.State) { $InDesiredState = $false }
		if ($Site -ne $CurrentRule.Site) { $InDesiredState = $false }
		if ($Application -ne $CurrentRule.Application) { $InDesiredState = $false }
		if ($Path -ne $CurrentRule.Path) { $InDesiredState = $false }
	} elseif ($Ensure -eq "Absent") {
		if ($Ensure -ne $CurrentRule.Ensure) { $InDesiredState = $false }
	}
    
	return $InDesiredState
}


function GetFilterXpath
{
	param(
		[parameter(Mandatory = $true)]
		[ValidateSet("Anonymous","Basic","Digest","Windows")]
		[String]
		$Type
		)

	"/system.WebServer/security/authentication/$($Type.ToLower())Authentication"
}

function GetLocationXpath
{
	param
	(
		[String]
		$Site,

		[String]
		$Application,

		[String]
		$Path
		)

	@("IIS:\sites", $Site, $Application, $Path) -join "\"
}

Export-ModuleMember -Function *-TargetResource