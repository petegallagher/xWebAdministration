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

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$PSPath,

		[Parameter(Mandatory = $true)]
		[String]
		$Location,

		[String]
		$Verbs
	)

	$Filter = GetFilterXpath -ResourceType $ResourceType -Value $Value -Verbs $Verbs

	Write-Verbose "Getting configuration for `"$Filter`" at PSPath `"$PSPath`" and Location `"$Location`""
	return Get-WebConfiguration -Filter $Filter -PSPath $PSPath -Location $Location
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
		$Verbs,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$PSPath,

		[Parameter(Mandatory = $true)]
		[String]
		$Location
		)

	$Filter = GetFilterXpath -ResourceType $ResourceType -Value $Value -Verbs $Verbs
	
	if ($Ensure -eq "Present") {
		Switch ($ResourceType) {
			"Users" { $users = $Value }
			"Roles" { $roles = $Value }
		}

		$CurrentRule = Get-TargetResource -ResourceType $ResourceType -Value $Value -Verbs $Verbs -PSPath $PSPath -Location $Location

		if ($CurrentRule) {
			# Update the authorization rule
			Write-Verbose "Setting configuration for `"$Filter`" at PSPath `"$PSPath`""
			Set-WebConfiguration -Filter $Filter -PSPath $PSPath -Location $Location -Value @{accessType=$Action;users="$users";roles="$roles";verbs="$Verbs"}
		} else {
			# We set the filter to the root path for authorization when creating new rules
			$Filter = "/system.webServer/security/authorization"

			# Create the authorization rule
			Write-Verbose "Adding configuration for `"$Filter`" at PSPath `"$PSPath`""
			Add-WebConfiguration -Filter $Filter -PSPath $PSPath -Location $Location -Value @{accessType=$Action;users="$users";roles="$roles";verbs="$Verbs"}
		}
	} else {
		# Delete the authorization rule
		Write-Verbose "Clearing configuration for `"$Filter`" at PSPath `"$PSPath`""
		Clear-WebConfiguration -Filter $Filter -PSPath $PSPath -Location $Location
		# TODO: This is a workaround required for inherited rules. If a rule has been inherited
		# then running Clear-WebConfiguration once will only create a local copy of the rule,
		# instead of removing it. We need to either:
		#     1. Check if the rule has been inherited first and then action accordingly, or
		#     2. Run Clear-WebConfiguration twice to ensure removal
		# In this example we have opted for 2. until we can figure out a way to determine if the 
		# rule is inherited. If the rule was not inherited then a warning is thrown, so we also use
		# the "SilentlyContinue" directive for the WarningAction to prevent this from being 
		# displayed.
		Clear-WebConfiguration -Filter $Filter -PSPath $PSPath -Location $Location -WarningAction SilentlyContinue
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
		$PSPath,

		[Parameter(Mandatory = $true)]
		[String]
		$Location
		)

    Write-Verbose "Testing configuration for `"$ResourceType`", value `"$Value`", site `"$PSPath`", location `"$Location`""
	$InDesiredState = $true

	$CurrentRule = Get-TargetResource -ResourceType $ResourceType -Value $Value -Verbs $Verbs -PSPath $PSPath -Location $Location

	if ($Ensure -eq "Present") {
		if($CurrentRule) {
            if ($Action -ne $CurrentRule.Action) { $InDesiredState = $false }
			if ($ResourceType -ne $CurrentRule.ResourceType) { $InDesiredState = $false }
			if ($Value -ne $CurrentRule.Value) { $InDesiredState = $false }
			if ($Verbs -ne $CurrentRule.Verbs) { $InDesiredState = $false }
			if ($PSPath -ne $CurrentRule.PSPath) { $InDesiredState = $false }
			if ($Location -ne $CurrentRule.Location) { $InDesiredState = $false }
        } else {
            $InDesiredState = $false
        }	
	} elseif ($Ensure -eq "Absent") {
		if($CurrentRule) {
            $InDesiredState = $false
        }
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

Export-ModuleMember -Function *-TargetResource
