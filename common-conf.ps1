# What: powershell configuration, prologue, common for all devices (for all platforms)
# Where: local
# How:
# - loaded by main pwsh_config.ps1 file
# - the content of this file is common for all, thus should execution order should precede other platform/device-specific configurations 
# Who: Tianhan Tang @ Lily MedTech Inc.
# When: initial creation 2021/08/05; last modified 2021/09/06
# ================================================================

# Locale
# ----------------------------------------------------------------
[cultureinfo]::CurrentCulture = 'ja-JP'

# Resolve module auto-loading issue
# NOTE: 
# - see 2021/08/16 notes on Slack
# ----------------------------------------------------------------
If ($null -ne (Get-Module PSReadLine)) {
	Remove-Module PSReadLine
}

# Namespace clean-up
# ----------------------------------------------------------------	
# Remove some alias preset to leave way for custom functions or to avoid confusion when working cross-platform
@(
	'which',
	'pwd', 'ls', 'cd',
	'mkdir', 'touch',
	'rmdir', 'rm',
	'cp',
	'mv',
	'ln', 
	'cat',
	'pbcopy', 'pbpaste',
	'type', 'file',
	'brew', 'conda',
	'mount', 'umount',
	'sl'
) | ?{
	'Alias' -eq (Get-Command $_ 2> $null).CommandType
} | %{
	Remove-Alias -Name $_ -Force
}

# Global auxiliary variable setup
# ----------------------------------------------------------------
# Custom error status
New-Variable `
	-Name 'custom_error_status' `
	-Value $true `
	-Scope Global `
	-Visibility Private `
	-Force

# Path info. on prompt
New-Variable `
	-Name 'custom_path_prompt' `
	-Value 'N/A' `
	-Scope Global `
	-Visibility Private `
	-Force

# Conda info. on prompt
New-Variable `
	-Name 'custom_conda_prompt' `
	-Value 'N/A' `
	-Scope Global `
	-Visibility Private `
	-Force

# Git info. on prompt
New-Variable `
	-Name 'custom_git_info' `
	-Value @{
		git_dir = 'N/A';
		git_prompt = 'N/A'
	} `
	-Scope Global `
	-Visibility Private `
	-Force

# Color scheme
New-Variable `
	-Name 'custom_color_scheme' `
	-Value (
		@{
			S0 = "`e[0m";
			F00 = "`e[30m"; F08 = "`e[90m";
			F01 = "`e[31m"; F09 = "`e[91m";
			F02 = "`e[32m"; F10 = "`e[92m";
			F03 = "`e[33m"; F11 = "`e[93m";
			F04 = "`e[34m"; F12 = "`e[94m";
			F05 = "`e[35m"; F13 = "`e[95m";
			F06 = "`e[36m"; F14 = "`e[96m";
			F07 = "`e[37m"; F15 = "`e[97m";
			S1 = "`e[47;30m"; # semi emphasis color
			S2 = "`e[44;30m" # emphasis color
		}
	) `
	-Scope Global `
	-Visibility Public `
	-Force

New-Variable `
	-Name 'custom_machine_id' `
	-Value ([Environment]::MachineName.ToUpper()) `
	-Scope Global `
	-Visibility Private `
	-Force

New-Variable `
	-Name 'custom_usr_id' `
	-Value ([Environment]::UserName.ToLower()) `
	-Scope Global `
	-Visibility Private `
	-Force	

# Modify pre-defined variable—mark "special" (central) workspace
$Global:custom_workspace_info['W4'].Color = "`e[1;49;36m";

# Function definition
# ----------------------------------------------------------------
# Helper function, extend the reolve-path function (e.g. add the ability to resolve workspace name)
# NOTE:
# - This function is actually device-dependent, but defined here using the auxiliary variable 'custom_info_workspace'
# - This function does NOT guarantee the output could resolve into a valid path
Function Decode-CustomPathToken {
	[OutputType([String])]
	param(
		[Parameter(Mandatory = $True, Position = 0)][AllowEmptyString()][string]$Path,
		[Parameter()][string]$host_name = [Environment]::MachineName,
		[parameter()][switch]$v
	)
	# Process
	$dir_part = $Path -split ([regex]::escape([IO.Path]::DirectorySeparatorChar)) | %{
		switch -Regex ($_) {
			# Workspace
			'^(?:Wo?r?k?s?p?a?c?e?)(?<idx>(i|\d+))(?:\:$)' {
				$wksp =  $Global:custom_workspace_info["W$($Matches.('idx'))"]
				if ($null -eq $wksp) {
					# Fallback
					$path_resolved = $_
					if ($v) {
						$err = "NO record for the requested workspace on $($host_name)!"
						Report-Status $err $null
					}
				} else {
					$path_resolved = [IO.Path]::Combine($HOME, $wksp.AccPt)
				}
				break
			}
			# Short-hand for relative path
			'^\.{2}(?<lv>\d+)$' {
				$path_resolved = (@(, '..') * [int]($Matches['lv'])) -join ([IO.Path]::DirectorySeparatorChar)
				break
			}
			# Default, no parsing
			default {
				$path_resolved = $_
				break
			}
		}
		return $path_resolved
	}
	$Global:custom_error_status = $true
	return ($dir_part -join ([regex]::escape([IO.Path]::DirectorySeparatorChar)))
}

# Helper function, decode Unix-style input argument
Function Decode-CustomArgument {
	# Argument parsing
	[string[]]$_args = $Args | %{$_} | ?{![string]::IsNullorEmpty($_)}
	switch ($_args.length) {
		{$_ -eq 0} {
			$opts = ''
			$params = ''
			break
		}
		{$_ -eq 1} {
			$opts = ''
			$params = $_args
			break
		}
		{$_ -gt 1} {
			if ($_args[0] -match '^-(\w+)$') {
				$opts = $Matches[1]
				$params = $_args[1..($_ - 1)]
			} elseif ($_args[-1] -match '^-(\w+)$') {
				$opts = $Matches[1]
				$params = $_args[0..($_ - 2)]
			} else {
				$opts = ''
				$params = $_args
			}
			break
		}
	}
	return @{
		Parameter = $params
		Option = $opts
	}
}

# Helper funciton, report function execution status
# NOTE:
# - The automatically generated information object from Cmdlet is often [ArrayList]
Function Report-Status {
	param(
		[Parameter(Mandatory = $True, Position = 0)][AllowNull()]$err,
		[parameter(Mandatory = $True, Position = 1)][AllowNull()]$msg
	)
	if (![string]::IsNullorEmpty($err)) {
		Write-Host ($Global:custom_color_scheme.F09 + $err) -Separator "`n"
	} elseif (![string]::IsNullorEmpty($msg)) {
		Write-Host ($Global:custom_color_scheme.S0 + $msg) -Separator "`n"
	}	
}

# Fundamental function, print working directory
Function Print-WorkDirectory {
	return $PWD.ToString()
}

# Fundamental function, list directory contents => ls
# NOTE:
# - Currently defined in platform dependent config
# - The major reason for a separate definition is the different permission scheme on different file-system

# Fundamental function, change directory
# NOTE:
# - cd w/o argument will go home dir (both pwsh and zsh default behavior)
Function Customize-SetLocation {
	# Argument checking (only single argument allowed)
	if ($Args.length -eq 0) {
		Set-Location $HOME
		$Global:custom_error_status = $true
	} elseif ($Args.length -eq 1) {
		$wk_dir_resolved = Decode-CustomPathToken $Args[0]
		Set-Location $wk_dir_resolved -ErrorVariable err 2> $null
		$Global:custom_error_status = $?
		# report status
		Report-Status $err $null
	} else {
		$Global:custom_error_status = $false
		$err = 'SYNTAX ERROR: refer to man of Unix command cd'
		# report status
		Report-Status $err $null		
	}

	# Generate auxiliary info @ the prompt
	Create-PathPrompt
	Create-GitPrompt
}

# Fundamental function, make directory
Function Make-Directory {
	# Argument parsing
	$_arg = Decode-CustomArgument @Args
	$_path = $_arg.Parameter
	$_opts = $_arg.Option
	# Process
	if ('' -ne $_path) {
		$option = @{}
		# parse option
		switch ($_opts) {
			{$_.Contains('v')} {
				$option.Add('OutVariable', 'msg')
			}
			{$_.Contains('f')} {
				$option.Add('Force', $true)
			}
			{$_.Contains('c')} {
				$option.Add('Confirm', $true)
			}
			{$_.Contains('n')} {
				$option.Add('WhatIf', $true)
			}
		}
		$_path | %{
			Decode-CustomPathToken $_
		} | %{
			New-Item $_ -ItemType Directory @option -ErrorVariable err 2>$null 1>$null
			$Global:custom_error_status = $?
			# report status
			Report-Status $err $msg			
		}		
	} else {
		$Global:custom_error_status = $false
		$err = 'SYNTAX ERROR!'
		# report status
		Report-Status $err $null
	}
}

# Fundamental function, touch file
Function Touch-File {
	# Argument parsing
	$_arg = Decode-CustomArgument @Args
	$_path = $_arg.Parameter
	$_opts = $_arg.Option
	# Process
	if ('' -ne $_path) {
		$option = @{}
		# parse option
		switch ($_opts) {
			{$_.Contains('v')} {
				$option.Add('OutVariable', 'msg')
			}
			{$_.Contains('f')} {
				$option.Add('Force', $true)
			}
			{$_.Contains('c')} {
				$option.Add('Confirm', $true)
			}
			{$_.Contains('n')} {
				$option.Add('WhatIf', $true)
			}
		}
		$_path | %{
			Decode-CustomPathToken $_
		} | %{
			If (Test-Path $_ -PathType Leaf) {
				# change the access time
				Set-ItemProperty $_ LastWriteTime (Get-Date)
			} else {
				# create new file
				New-Item $_ -ItemType File @option -ErrorVariable err 2>$null 1>$null
			}
			$Global:custom_error_status = $?
			# report status
			Report-Status $err $msg			
		}		
	} else {
		$Global:custom_error_status = $false
		$err = 'SYNTAX ERROR!'
		# report status
		Report-Status $err $null
	}
}

# Fundamental function, copy => cp
Function Customize-CopyItem {
	# Argument parsing
	$_arg = Decode-CustomArgument @Args
	$_path = $_arg.Parameter
	$_opts = $_arg.Option
	$len = $_path.length
	# Process
	if ($len -ge 2) {		
		$_src = $_path[0..($len-2)]
		$dst = Decode-CustomPathToken $_path[-1]
		$option = @{}
		# parse option
		switch ($_opts) {
			{$_.Contains('v')} {
				$option.Add('Verbose', $true)
			}
			{$_.Contains('r')} {
				$option.Add('Recurse', $true)
			}
			{$_.Contains('f')} {
				$option.Add('Force', $true)
			}
			{$_.Contains('c')} {
				$option.Add('Confirm', $true)
			}
			{$_.Contains('n')} {
				$option.Add('WhatIf', $true)
			}
		}
		$_src | %{
			Decode-CustomPathToken $_
		} | %{
			Copy-Item $_ $dst @option -OutVariable msg -ErrorVariable err 4>&1 2>$null 1>$null
			$Global:custom_error_status = $?
			# report status
			Report-Status $err $msg
		}
	} else {
		$Global:custom_error_status = $false
		$err = 'SYNTAX ERROR: refer to man of Unix command cp'
		# report status
		Report-Status $err $null			
	}
}

# Fundamental function, move => mv
Function Customize-MoveItem {
	# Argument parsing
	$_arg = Decode-CustomArgument @Args
	$_path = $_arg.Parameter
	$_opts = $_arg.Option
	$len = $_path.length
	# Process
	if ($len -ge 2) {		
		$_src = $_path[0..($len-2)]
		$dst = Decode-CustomPathToken $_path[-1]
		$option = @{}
		# parse option
		switch ($_opts) {
			{$_.Contains('v')} {
				$option.Add('Verbose', $true)
			}
			{$_.Contains('f')} {
				$option.Add('Force', $true)
			}
			{$_.Contains('c')} {
				$option.Add('Confirm', $true)
			}
			{$_.Contains('n')} {
				$option.Add('WhatIf', $true)
			}
		}
		$_src | %{
			Decode-CustomPathToken $_
		} | %{
			# Handle the special case of rename a folder to case-different name
			if ($_ -ieq $dst) {
				Rename-Item -Path $_ -NewName ($dst + '__') -PassThru -ErrorVariable err 2>$null | Rename-Item -NewName $dst
			} else {
				Move-Item $_ $dst @option -OutVariable msg -ErrorVariable err 4>&1 2>$null 1>$null
			}
			$Global:custom_error_status = $?
			# report status
			Report-Status $err $msg
		}
	} else {
		$Global:custom_error_status = $false
		$err = 'SYNTAX ERROR: refer to man of Unix command mv'
		# report status
		Report-Status $err $null			
	}
}

# Fundamental function, concatenate and print files => cat
Function Customize-GetContent {
	# Argument parsing
	$_arg = Decode-CustomArgument @Args
	$_path = $_arg.Parameter
	$_opts = $_arg.Option
	# Process
	if ('' -ne $_path) {
		$_path | %{
			Decode-CustomPathToken $_
		} | %{
			Get-Content $_  -ErrorVariable err 2>$null
			$Global:custom_error_status = $?
			# report status
			Report-Status $err $null
		}		
	} else {
		$Global:custom_error_status = $false
		$err = 'SYNTAX ERROR!'
		# report status
		Report-Status $err $null
	}
}

# Auxiliary function, construct text string about the path info. to be displayed @ prompt
# NOTE:
# - Should not be called directly
Function Create-PathPrompt {
	$path = (pwd) -replace "^$([regex]::escape($HOME))(.*)", '~$1'
	$path_part = $path -split [regex]::escape([IO.Path]::DirectorySeparatorChar)
	$len = $path_part.length

	$idx = @(0..($len - 1)) | ?{$path_part[$_] -match "Workspace(\d+)"} | Select-Object -First 1
	if ($null -ne $idx) {
		$path_part[$idx] = @(
			"`e[1;49;39m",
			$Global:custom_workspace_info["W$($Matches[1])"].Color, # if not exist, will be omiited
			$Matches[0],
			"`e[0m"
		) -join ''
	}
	if ($len -gt 4) {
		$path_part = @(
			$path_part[0],
			$path_part[1],
			([char]::ConvertFromUtf32(0x00002504) + "$($len - 4)" + [char]::ConvertFromUtf32(0x00002504)),
			$path_part[-2],
			$path_part[-1]
		)
	}
	$Global:custom_path_prompt = $path_part -join ([IO.Path]::DirectorySeparatorChar)
}

# Auxiliary function, construct text string about the conda env. info. to be displayed @ prompt
# NOTE:
# - Generally should not be called directly
# - Thus it has no error status report
Function Create-CondaPrompt {
	$Global:custom_conda_prompt = ($null -eq $Env:CONDA_PROMPT_MODIFIER) ?
		'N/A' : 
		($Env:CONDA_PROMPT_MODIFIER -replace '^\((.+)\).*$', '$1')
}

# Wrapper for miniforge
Function conda {
	Invoke-Conda @Args
	$Global:custom_error_status = ($LASTEXITCODE -eq 0) ? $true : $false
	Create-CondaPrompt
}

# Identity function
# - This function is changed every time a new version is issued
Function ver {
	$config_ver = '4.6.2'
	echo $config_ver
} 

# Alias setup
# ----------------------------------------------------------------	
# - Use PowerShell built-in cmdlet over some usaully used Unix command
Set-Alias -Name 'which' -Value 'Get-Command'
Set-Alias -Name 'pwd' -Value 'Print-WorkDirectory'
Set-Alias -Name 'cd' -Value 'Customize-SetLocation'
Set-Alias -Name 'mkdir' -Value 'Make-Directory'
Set-Alias -Name 'touch' -VAlue 'Touch-File'
Set-Alias -Name 'cp' -Value 'Customize-CopyItem'
Set-Alias -Name 'mv' -Value 'Customize-MoveItem'
Set-Alias -Name 'cat' -Value 'Customize-GetContent'
Set-Alias -Name 'pbcopy' -Value 'Set-Clipboard'
Set-Alias -Name 'pbpaste' -Value 'Get-Clipboard'

# Add custom tab complete behavior
# NOTE:
# - Decode-CustomPathToken is defined in pwsh_config_common_prologue.ps1
# - For "simple" function, the register of completer not follows the link, i.e., if defined on the underlying function, not effect on the alias, vice versa
# - For advanced function, the alias inherite the underlying function's completer
# ----------------------------------------------------------------
Register-ArgumentCompleter `
	-Native `
	-CommandName @('mkdir', 'touch', 'rm', 'cp', 'mv', 'cat') `
	-ScriptBlock {
		param (
			$WordToComplete,
			$CommandAst,
			$cursorPosition
		)
		if ($WordToComplete -match '^W(i|\d+):.*') {
			$path_resolved = (Decode-CustomPathToken $WordToComplete)
			return (
				$path_resolved.Contains(' ') ? ('''' + $path_resolved + '''') : $path_resolved
			)
		}
		# NOTE, else, the tab completion will fallback to PSReadLine built-in
	}

Register-ArgumentCompleter `
	-Native `
	-CommandName @('cd', 'rmdir') `
	-ScriptBlock {
		param (
			$WordToComplete,
			$CommandAst,
			$cursorPosition
		)
		$_path = ('' -eq $WordToComplete) ? ".$([IO.Path]::DirectorySeparatorChar)" : $WordToComplete
		$wk_dir_resolved = Decode-CustomPathToken $_path
		$folder_list = Get-ChildItem ($wk_dir_resolved.replace("'", '') + '*') -Directory
		if ($null -ne $folder_list) {
			$folder_list.fullname | Resolve-Path -Relative | %{
				$folder = Split-Path $_ -Leaf
				if ($_.Contains(' ')) {
					$dir_to_look = "'" + $_ + [IO.Path]::DirectorySeparatorChar + "'"
				} else {
					$dir_to_look = $_ + [IO.Path]::DirectorySeparatorChar
				}
				return [System.Management.Automation.CompletionResult]::new(
					$dir_to_look,
					$folder,
					'ParameterValue',
					$folder
				)				
			}
		} else {
			# to block the fall-back to PSReadLine default tab completion function, return value can not be null or empty
			return [System.Management.Automation.CompletionResult]::new(
				$wk_dir_resolved,
				'EOT',
				'ParameterValue',
				'EOT'
			)		
		}
	}

# Module configuration
# ----------------------------------------------------------------
# - Reload PSReadLine
Import-Module -Name PSReadLine
# - PSReadLine setup for line editing
$PSReadLineOptions = @{
	EditMode = "Emacs";
	HistoryNoDuplicates = $true;
	HistorySearchCursorMovesToEnd = $true
	Colors = @{	
		Command = $Global:custom_color_scheme.F04;
		Operator = $Global:custom_color_scheme.F04;
		Selection = $Global:custom_color_scheme.S1;
		Emphasis = $Global:custom_color_scheme.S2;
		Error = $Global:custom_color_scheme.F09;
		Variable = $Global:custom_color_scheme.S0;
		Keyword = $Global:custom_color_scheme.S0;
		Comment = $Global:custom_color_scheme.S0;
		String = $Global:custom_color_scheme.S0;
		ContinuationPrompt = $Global:custom_color_scheme.S0;
		Default = $Global:custom_color_scheme.S0;
		Member = $Global:custom_color_scheme.S0;
		Number = $Global:custom_color_scheme.S0;
		Type = $Global:custom_color_scheme.S0;
		Parameter = $Global:custom_color_scheme.S0
	}
}
Set-PSReadLineOption @PSReadLineOptions

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# Prompt function
Function prompt {
	$stat = $Global:custom_error_status -and $?
	# Line 2
	$line_2 = @(
		[char]::ConvertFromUtf32(0x00002570),
		'log:',
		(Get-Date -Format "yyyy-MM-dd HH:mm:ss K"),
		'|',
		'stat:',
		($stat ? [char]::ConvertFromUtf32(0x00002713) : [char]::ConvertFromUtf32(0x00002717))
	) -join ' '
	$line_3 = ''
	$line_0 = @(
		[char]::ConvertFromUtf32(0x0000256D),
		'env:',
		$Global:custom_conda_prompt,
		'|',
		(
			$Global:custom_usr_id +
			'@' + $Global:custom_machine_id + ':' + 
			$Global:custom_path_prompt
		),
		'|',
		'git:',
		$Global:custom_git_info.git_prompt
	) -join ' '
	$line_1 = @(
		[char]::ConvertFromUtf32(0x000003BB),
		('>' * ($nestedPromptLevel + 1)),
		''
	) -join ' '

	$Global:custom_error_status = $true

	return @(
		$line_2,
		$line_3,
		$line_0,
		$line_1
	) -join [System.Environment]::newline

}

# POST-LOG
# - Custom fundamental functions allow both prefix and postfix option convention (assuming file/dir path do not start w/ hyphen)
# - Custom error status is used
