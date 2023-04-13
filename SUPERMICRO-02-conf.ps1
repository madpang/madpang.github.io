# What: powershell configuration, device specific
# Where: local
# How:
# - loaded by main pwsh_config.ps1 file, after common setup
# Who: Tianhan Tang @ Lily MedTech Inc.
# When: initial creation 2021-08-31; last modified 2022-01-06
# ================================================================
# NOTE:
# - use Conda.psm1 in dotfiles/src/utility to replace the default ones

# PATH
# ----------------------------------------------------------------
$Env:PATH = ''
$Env:PATH = @(
	'C:\ProgramData\chocolatey\bin',
	'C:\Program Files\PowerShell\7',
	'C:\Program Files\MATLAB\R2021b\bin',
	'C:\Program Files\NVIDIA Corporation\NVSMI',
	'C:\WINDOWS\system32',
	'C:\WINDOWS\System32\OpenSSH',
	'C:\WINDOWS\System32\Wbem',
	'C:\Users\tangt\AppData\Local\Programs\Microsoft VS Code\bin' # for VS Code
) -join ';'

# Configure Miniconda
# NOTE:
# - Installed via Chocolatey
# ----------------------------------------------------------------
$Env:CONDA_EXE = "C:\tools\miniconda3\Scripts\conda.exe"
$Env:_CE_M = ""
$Env:_CE_CONDA = ""
$Env:_CONDA_ROOT = "C:\tools\miniconda3"
$Env:_CONDA_EXE = "C:\tools\miniconda3\Scripts\conda.exe"

# CLI env. initialization
# ----------------------------------------------------------------

Import-Module "$Env:_CONDA_ROOT\shell\condabin\Conda.psm1"
conda activate base

$_env_name = "lily"
$_env_list = (conda env list)
foreach ($ln in $_env_list[2..($_env_list.length - 2)]) {
	if ($ln.StartsWith($_env_name)) {
		conda activate $_env_name
		break
	}
}

Remove-Variable _env_name
Remove-Variable _env_list

# Default workspace
$Global:custom_workspace_info['Wi'] = $Global:custom_workspace_info['W7']

# Tri-color customization for box visual differentiation
# - assume machine name has the form 'PREFIX-POSTFIX'
$_name_part = ([Environment]::MachineName.ToUpper()) -split '(-)', 2
$Global:custom_machine_id = @(
	"`e[42;38;2;255;255;255m", # $Global:custom_color_scheme.F02 as background
	$_name_part[0],
	"`e[48;2;255;255;255;38;2;0;0;0m", # RGB triplet
	$_name_part[1],
	"`e[48;2;255;147;0;38;2;255;255;255m", # RGB triplet
	$_name_part[2],
	"`e[0m"
) -join ''

# Create-GitPrompt # [TODO]
Create-PathPrompt
