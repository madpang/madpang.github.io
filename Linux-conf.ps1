# What: powershell configuration, common for Linux platform
# Where: local
# How:
# - loaded by main pwsh_config.ps1 file
# - the content of this file is common for Linux platform, thus should execution order should precede other device-specific configurations, but after common_all_prelude 
# Who: Tianhan Tang @ Lily MedTech Inc.
# When: initial creation 2021/12/20; last modified 2021/12/20
# ================================================================

# CLI env config
# ----------------------------------------------------------------
# Environment variable for the Linux command `ls`, w/ color outptut
$Env:LS_COLORS = "rs=0:di=0;36:ln=0;37:ex=0;39";
# Set terminal tab size
Invoke-Expression (@((Get-Command 'tabs' -CommandType Application -TotalCount 1).Source, '-4') -join ' ')

# Function definiiton
# ----------------------------------------------------------------
# List directory content, alias: ls (a wrapper over Linux ls)
Function List-Content {
	# Argument parsing
	$_arg = Decode-CustomArgument @Args
	$_path = ('' -ne $_arg.Parameter) ? $_arg.Parameter : '.'
	$_opts = $_arg.Option
	# Processing
	$opts = '-h' + $_opts
	$path = $_path | %{
		Decode-CustomPathToken $_
	}
	/bin/ls --color $opts $path
	$Global:custom_error_status = $?
}

# Make link, alias: ln (a wrapper over Linux ln)
Function Make-Link {
	# Argument parsing
	$_arg = Decode-CustomArgument @Args
	$_path = $_arg.Parameter
	$_opts = $_arg.Option
	if ('' -ne $_path) {
		$opts = (('' -ne $_opts) ? '-' : '') + $_opts
		$path = $_path | %{
			Decode-CustomPathToken $_
		}
		/bin/ln $opts $path
		$Global:custom_error_status = $?
	} else {
		$Global:custom_error_status = $false
		$err = 'SYNTAX ERROR: refer to man of Linux command ln'
		# report status
		Report-Status $err $null
	}
}

# Mount shared workspace
Function Mount-WKSP {
	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $true, Position = 0)][string]$Name,
		[Parameter()][string]$IP = '',
		[Parameter()][string]$Vol = '',
		[Parameter()][string]$MPt = ''		
	)
	process {
		$wk_name = $Name.Replace(':', '')
		if (
			($null -eq $Global:custom_workspace_info.$wk_name) -or
			($Global:custom_workspace_info.Wi.AccPt -eq $Global:custom_workspace_info.$wk_name.AccPt)
		) {
			$Global:custom_error_status = $false
			$err = "The specified workpace $($wk_name) is NOT valid!"
			# report status
			Report-Status $err $null
		} else {
			$mount_point =  [IO.Path]::Combine(
				$HOME,
				(('' -eq $MPt) ? $Global:custom_workspace_info.$wk_name.AccPt : $MPt)
			)
			if (-not (Test-Path $mount_point)) {
				New-Item $mount_point -ItemType Directory 1>$null
			} else {
				$Global:custom_error_status = $false
				$err = "Mount point already exist! please take care!"
				# report status
				Report-Status $err $null
				return
			}
			$mount_id = "user=$($Global:custom_workspace_info[$wk_name]['User'])" + ',' +
				"pass=$($Global:custom_workspace_info[$wk_name]['Pswd'])" + ',' +
				"uid=1000,gid=1000,file_mode=0664,dir_mode=0775"
			$mount_target = '//' + 
			(('' -eq $IP) ? $Global:custom_workspace_info.$wk_name.IP : $IP) + '/' +
			(('' -eq $Vol) ? $Global:custom_workspace_info.$wk_name.Volume : $Vol)
			sudo /usr/bin/mount -t cifs -o $mount_id $mount_target $mount_point
			$Global:custom_error_status = $?	
		}
	}
}

# Unmount shared workspace
Function Remove-WKSP {
	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $true, Position = 0)][string]$Name,
		[Parameter()][string]$MPt = ''
	)
	process {
		$wk_name = $Name.Replace(':', '')
		if (
			($null -eq $Global:custom_workspace_info.$wk_name) -or 
			($Global:custom_workspace_info.Wi.AccPt -eq $Global:custom_workspace_info.$wk_name.AccPt)
		) {
			$Global:custom_error_status = $false
			$err = "The specified workpace $($wk_name) is NOT valid!"
			# report status
			Report-Status $err $null
		} else {
			$mount_point = [IO.Path]::Combine(
				$HOME,
				(('' -eq $MPt) ? $Global:custom_workspace_info.$wk_name.AccPt : $MPt)
			)
			if (-not (Test-Path $mount_point)) {
				$Global:custom_error_status = $false
				$err = "The specified workpace $($wk_name) is NOT mounted!"
				# report status
				Report-Status $err $null			
			} else {
				sudo /usr/bin/umount $mount_point
				$Global:custom_error_status = $?
				if (-not (Test-Path ([IO.Path]::Combine($mount_point, '*')))) {
					Remove-Item $mount_point
				}
			}
		}
	}
}

# Auxiliary function, construct text string about the Git repo. info. to be displayed @ prompt
# NOTE:
# - Generally should not be called directly
# - Thus it has no error status report
Function Create-GitPrompt {
	param(
		[Parameter()][switch]$v
	)	
	$path = pwd
	if ($path -like ($Global:custom_git_info.git_dir + [IO.Path]::DirectorySeparatorChar + '*')) {
		$Global:custom_git_info.git_prompt = $Global:custom_git_info.git_prompt
	} elseif (Test-Path (Join-Path $path '.git') -PathType Container) {
		$Global:custom_git_info.git_prompt = 'inside'
		$Global:custom_git_info.git_dir = $path
	} else {
		$Global:custom_git_info.git_prompt = 'N/A'
		$Global:custom_git_info.git_dir = 'N/A'
	}
	# Verbose ver.
	if ($v) {
		$git_exe = (Get-Command 'git' -CommandType Application -TotalCount 1).Source
		$cmd_1 = @(
			$git_exe,
			'--no-optional-locks',
			'-c core.quotepath=false',
			'-c color.status=false',
			'status',
			'-uall',
			'--short'
			'--branch'
		) -join ' '
		$status = Invoke-Expression $cmd_1 2> $null
		# git --no-optional-locks -c core.quotepath=false -c color.status=false status -uall --short --branch 2> $null
		if ($null -ne $status) {
			$_git_status = @{}
			$_git_status.add('A0', [int]0) # Added
			$_git_status.add('A1', [int]0) # Added, but untracked
			$_git_status.add('M', [int]0)  # Modified
			$_git_status.add('D', [int]0)  # Deleted
			$_git_status.add('S', [int]0)  # Stash
			foreach ($ln in $status) {
				switch -regex ($ln) {
					'^## (?<br>\S+?)(?:\.{3}(?<rr>\S+))?(?: \[(?:ahead (?<ah>\d+))?(?:,\s)?(?:behind (?<bh>\d+))?(?<gn>gone)?\])?$' {
						$_git_status.add('br', $Matches['br'])
						$_git_status.add('rr', $Matches['rr'])
						$_git_status.add('ah', $Matches['ah'])
						$_git_status.add('bh', $Matches['bh'])
						$_git_status.add('gn', $Matches['gn'])
						break
					}
					'^## [\w\s]+ on (?<br>\S+)' {
						$_git_status.add('br', $Matches['br'])
						break
					}
					'^\s?(A)\s+' {
						$_git_status['A0'] += 1
						break
					}
					'^\s?(\?{2})\s+' {
						$_git_status['A1'] += 1
						break
					}
					'^\s?(M)\s+' {
						$_git_status['M'] += 1
						break
					}
					'^\s?(D)\s+' {
						$_git_status['D'] += 1
						break
					}
				}
			}
			$cmd_2 = @(
				$git_exe,
				'--no-optional-locks',
				'stash',
				'list'
			) -join ' '
			$stash = Invoke-Expression $cmd_2 2>$null
			# $stash = git --no-optional-locks stash list 2>$null
			if ($null -ne $stash) {								
				foreach ($ln in $stash) {
					switch -regex ($ln) {
						'^stash@{\d+}: On (?<br>\S+): .*$' {
							if($Matches['br'] -eq $_git_status['br']) {
								$_git_status['S'] += 1
							}
						}
					}				
				}
			}
			$git_part_0 = @(
				[char]::ConvertFromUtf32(0x0000251C),
				(
					$_git_status['br'] + 
					(
						($_git_status['S'] -gt 0) ? 
						(
							[char]::ConvertFromUtf32(0x0000207D) + 
							[char]::ConvertFromUtf32(0x0000207A) + 
							[char]::ConvertFromUtf32(0x0000207E)
						) : ''
					)
				),
				(
					($null -eq $_git_status['rr']) ?
					[char]::ConvertFromUtf32(0x000025CA) :
					(
						($null -ne $_git_status['gn']) ?
						[char]::ConvertFromUtf32(0x0000221E) :
						(
							(($null -ne $_git_status['ah']) -and ($null -ne $_git_status['bh'])) ?
							(
								$_git_status['ah'] +
								[char]::ConvertFromUtf32(0x00002191) +
								[char]::ConvertFromUtf32(0x00002193) +
								$_git_status['bh']
							) : 
							(
								($null -ne $_git_status['ah']) ?
								($_git_status['ah'] + [char]::ConvertFromUtf32(0x00002191)) :
								(
									($null -ne $_git_status['bh']) ?
									([char]::ConvertFromUtf32(0x00002193) + $_git_status['bh']) :
									'='
								)
							)
						)
					)
				)
			) -join ' '

			$git_part_1 = [char]::ConvertFromUtf32(0x00002502)

			$git_part_2 = @(
				"+$($_git_status['A0'])($($_git_status['A1']))", 
				"~$($_git_status['M'])",
				"-$($_git_status['D'])"
			) -join ' '

			$Global:custom_git_info.git_prompt = @(
				$git_part_0,
				$git_part_1,
				$git_part_2
			) -join ' '

		} else {
			$Global:custom_git_info.git_prompt = 'N/A'
			$Global:custom_git_info.git_dir = 'N/A'
		}
	}
}

# Wrapper for git
Function git {
	# Pass all argument to the underlying Unix binary
	$git_exe = (Get-Command 'git' -CommandType Application -TotalCount 1).Source
	&$git_exe @Args
	# Hook additional operation
	Create-GitPrompt -v
}

# Alias setup
# ----------------------------------------------------------------	
Set-Alias -Name 'ls' -Value 'List-Content'
Set-Alias -Name 'ln' -Value 'Make-Link'

# Add custom tab complete behavior
# ----------------------------------------------------------------
Register-ArgumentCompleter `
	-Native `
	-CommandName @('ls', 'ln') `
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
	-CommandName 'ssh' `
	-ScriptBlock {
		param (
			$WordToComplete,
			$CommandAst,
			$cursorPosition
		)
		# NOTE, the name should be defined in .ssh/config
		@(
			'Lily-Acrux', 
			'Lily-Titan', 
			'Lily-Share03', 'Supermicro-02',
			'PD-Pisces'
		) | where {
			$_ -like ($WordToComplete + '*')
		}
	}

Register-ArgumentCompleter `
	-CommandName @('Mount-WKSP', 'Remove-WKSP') `
	-ParameterName 'Name' `
	-ScriptBlock {
		param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)	
		$Global:custom_workspace_info | Select-Object -ExpandProperty Keys | where {
			$_ -like ($WordToComplete + '*')
		}
	}

# NOTE
# - Decode-CustomPathToken should be pre-defined, default in pwsh_config_common_prologue
# - Decode-CustomArgument should be pre-defined, default in pwsh_config_common_prologue
# - `tabs` is a CLI utility comes w/ macOS
