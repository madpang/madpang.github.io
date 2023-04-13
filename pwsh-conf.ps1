# What: PowerShell configuration
# Where:
# - "$HOME\Documents\PowerShell" on Windows platofrm
# - "~/.config/powershell" on macOS platform
# How:
# - use separate script blocks for setup on each platform, on each device
# - some functionality requires .NET be installed
# - create a symbolic link to THIS file, utilizing $PROFILE to allow auto-load upon login
# - or manually source this file
# Who: Tianhan Tang @ Lily MedTech Inc.
# When: initial creation 2021/06/08; last modified 2021/08/27
# ================================================================

# Global variables
# ----------------------------------------------------------------
# Get the utility directory
$_entry_point = Get-ItemProperty $MyInvocation.MyCommand.Path
if ($null -ne $_entry_point.Target) {
	# It is a (symbolic) link
	New-Variable `
		-Name 'config_root' `
		-Value (Split-Path $_entry_point.Target -Parent) `
		-Option ReadOnly `
		-Scope Global `
		-Visibility Public `
		-Force
} else {
	# It is a solid file
	New-Variable `
		-Name 'config_root' `
		-Value $_entry_point.Directory.FullName `
		-Option ReadOnly `
		-Scope Global `
		-Visibility Public `
		-Force
}

# Workspace info. table
# ----------------------------------------------------------------
New-Variable `
	-Name 'custom_workspace_info' `
	-Value (
		(
			Get-Content (
				[IO.Path]::Combine($Global:config_root, 'pwsh', 'wksp-conf.json')
			) | ConvertFrom-Json -AsHashtable
		)
	) `
	-Option ReadOnly `
	-Scope Global `
	-Visibility Public `
	-Force

# Source the actual config files
# ----------------------------------------------------------------

# Common setup for all
. ([IO.Path]::Combine($Global:config_root,'pwsh','common-conf.ps1'))

# Platform-dependent setup
. ([IO.Path]::Combine($Global:config_root, 'pwsh', ($IsMacOS ? 'macOS' : ($IsWindows ? 'Windows' : 'Linux')) + '-conf.ps1'))

# Device dependent setup
. ([IO.Path]::Combine($Global:config_root, 'pwsh', [Environment]::MachineName + '-conf.ps1'))

# Function definition
# ----------------------------------------------------------------
# Helper function, preprocess the PowerShell script for script block creation
Function PreProcess-ScriptText {
	[OutputType([String])]
	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $true, Position = 0)][string]$Path,
		[Parameter()][string]$Symbol = '#'
	)
	process {
		$proc_txt = (
			Get-Content -Path $Path | %{
				($_ -replace "^(\s*)$($Symbol)+.*", '$1').TrimEnd()
			} | ?{'' -ne $_}
		) -join [System.Environment]::NewLine
		return $proc_txt
	}
}

# Helper function, export the configuration for a specific device to a single file
Function Export-Config {
	param(
		[Parameter(Mandatory = $True, Position = 0)]
		[ValidateSet("Lily-Acrux", "Lily-Titan", "lily-share03", 'SUPERMICRO-02', 'PD-Pisces')]
		[string]$device,
		[Parameter(Mandatory = $True, Position = 1)][string]$path,
		[Parameter()][switch]$f
	)
	# platform specification 
	$platform = switch ($Device) {
		{$_ -in @('Lily-Acrux', 'PD-Pisces')} {'macOS'}
		{$_ -in @('Lily-Titan')} {'Linux'}
		default {'Windows'}
	}

	# Workspace definition
	$def_wksp = @(
		'$Global:custom_workspace_info',
		'=',
		'ConvertFrom-Json -AsHashtable',
		(
			"'" + 
			($Global:custom_workspace_info | ConvertTo-Json) + 
			"'"
		)
	) -join ' '

	$config_common = [IO.Path]::Combine(
		$Global:config_root,
		'pwsh',
		'common-conf.ps1'
	)
	$config_platform = [IO.Path]::Combine(
		$Global:config_root,
		'pwsh',
		$platform + '-conf.ps1'
	)

	$config_device = [IO.Path]::Combine(
		$Global:config_root,
		'pwsh',
		$device + '-conf.ps1'
	)

	$def_config = (@($config_common, $config_platform, $config_device) | ?{Test-Path -Path $_ -PathType Leaf} | PreProcess-ScriptText) -join [System.Environment]::newline

	$param = @{
		Path = $path;
		Value = @($def_wksp, $def_config) -join [System.Environment]::newline
		Encoding = 'UTF8'
	}

	# Out-put content
	if (-not (Test-Path -Path $path -PathType Any)) {
		Set-Content @param
	} else {
		if ($f) {
			Set-Content @param
		} else {
			$_err = "$($path) already exist!"
			Write-Host $_err -ForegroundColor Red
		}
	}
}

# Clean-up temp variable
# ----------------------------------------------------------------
Remove-Variable -Name '_entry_point'
