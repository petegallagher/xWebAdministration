function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
		[ValidateSet("Users","Roles")]
		[String]
		$ResourceType,

		[parameter(Mandatory = $true)]
		[String]
		$Value,

		[String]
		$Verbs,

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
		$Filter = GetFilterXpath -ResourceType $ResourceType -Value $Value -Verbs $Verbs
		$PSPath = GetLocationXpath -Site $Site -Application $Application -Path $Path

		Write-Verbose "Getting configuration for `"$Filter`" at PSPath `"$PSPath`""
		$AuthorizationRule = Get-WebConfiguration -Filter $Filter -PSPath $PSPath
	}
	catch [System.Management.Automation.ItemNotFoundException] {
		Write-Verbose "PSPath `"$PSPath`" Not Found"
	}

	if ($AuthorizationRule -eq $null) {
		$EnsureResult = "Absent"
	}
	else {
		$EnsureResult = "Present"
	}

	return @{
		Ensure = $EnsureResult
		Action = $AuthorizationRule.accessType
		ResourceType = $ResourceType
		Value = $Value
		Verbs = $Verbs
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

		[ValidateSet("Allow", "Deny")]
		[String]
		$Action = "Allow",

		[parameter(Mandatory = $true)]
		[ValidateSet("Users","Roles")]
		[String]
		$ResourceType,

		[parameter(Mandatory = $true)]
		[String]
		$Value,

		[String]
		$Verbs = "",

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$Site,

		[String]
		$Application,

		[String]
		$Path
		)

	$Filter = GetFilterXpath -ResourceType $ResourceType -Value $Value -Verbs $Verbs
	$PSPath = GetLocationXpath -Site $Site -Application $Application -Path $Path

	if ($Ensure -eq "Present") {
		Switch ($ResourceType) {
			"Users" { $users = $Value }
			"Roles" { $roles = $Value }
		}

		$CurrentRule = Get-TargetResource -ResourceType $ResourceType -Value $Value -Verbs $Verbs -Site $Site -Application $Application -Path $Path

		if ($CurrentRule.Ensure -eq "Present") {
			# Update the authorization rule
			Write-Verbose "Setting configuration for `"$Filter`" at PSPath `"$PSPath`""
			Set-WebConfiguration -Filter $Filter -PSPath $PSPath -Value @{accessType=$Action;users="$users";roles="$roles";verbs="$Verbs"}
		} else {
			# We set the filter to the root path for authorization when creating new rules
			$Filter = "/system.webServer/security/authorization"	

			# Create the authorization rule
			Write-Verbose "Adding configuration for `"$Filter`" at PSPath `"$PSPath`""
			Add-WebConfiguration -Filter $Filter -PSPath $PSPath -Value @{accessType=$Action;users="$users";roles="$roles";verbs="$Verbs"}
		}
	} else {
		# Delete the authorization rule
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
		$Ensure = 'Present',

		[ValidateSet("Allow", "Deny")]
		[String]
		$Action = 'Allow',

		[parameter(Mandatory = $true)]
		[ValidateSet("Users","Roles")]
		[String]
		$ResourceType,

		[parameter(Mandatory = $true)]
		[String]
		$Value,

		[String]
		$Verbs,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$Site,

		[String]
		$Application,

		[String]
		$Path
		)

    Write-Verbose "Testing configuration for `"$ResourceType`", value `"$Value`", site `"$Site`""
	$InDesiredState = $true

	$CurrentRule = Get-TargetResource -ResourceType $ResourceType -Value $Value -Verbs $Verbs -Site $Site -Application $Application -Path $Path

	if ($Ensure -eq "Present") { 
		if ($Ensure -ne $CurrentRule.Ensure) { $InDesiredState = $false }
		if ($Action -ne $CurrentRule.Action) { $InDesiredState = $false }
		if ($ResourceType -ne $CurrentRule.ResourceType) { $InDesiredState = $false }
		if ($Value -ne $CurrentRule.Value) { $InDesiredState = $false }
		if ($Verbs -ne $CurrentRule.Verbs) { $InDesiredState = $false }
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
		[ValidateSet("Users","Roles")]
		[String]
		$ResourceType,

		[parameter(Mandatory = $true)]
		[String]
		$Value,

		[String]
		$Verbs
		)

	Switch ($ResourceType)
	{
		"Users" { $users = $Value }
		"Roles" { $roles = $Value }
	}

	"/system.webServer/security/authorization/add[@users='$($users)' and @roles='$($roles)' and @verbs='$($verbs)']"
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