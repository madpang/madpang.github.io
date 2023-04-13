# What: powershell configuration, device specific
# Where: local
# How:
# - loaded by main pwsh_config.ps1 file, after common setup
# Who: Tianhan Tang @ Lily MedTech Inc.
# When: initial creation 2022/01/06
# ================================================================

# CLI env. initialization
# ----------------------------------------------------------------

# Default workspace
$Global:custom_workspace_info['Wi'] = $Global:custom_workspace_info['W4']

# Tri-color customization for box visual differentiation
# - assume machine name has the form 'PREFIX-POSTFIX'
$_name_part = ([Environment]::MachineName.ToUpper()) -split '(-)', 2
$Global:custom_machine_id = @(
	"`e[48;2;0;0;0;38;2;255;255;255m",
	$_name_part[0],
	"`e[101;38;2;255;255;255m", # $Global:custom_color_scheme.F09 as background	
	$_name_part[1],
	"`e[48;2;255;215;5;38;2;0;0;0m",	
	$_name_part[2],
	"`e[0m"
) -join ''

Remove-Variable _name_part

Create-GitPrompt
Create-PathPrompt
