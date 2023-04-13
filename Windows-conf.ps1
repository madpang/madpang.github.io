# What: PowerShell configuration, common for Windows platform
# Where: local
# How:
# - loaded by main pwsh_config.ps1 file
# - the content of this file is common for Windows platform, thus execution order should precede other device-specific config, but after common config
# Who: Tianhan Tang @ Lily MedTech Inc.
# When: initial creation 2021/08/30; last modified 2021/09/08
# ================================================================

# Function definiiton
# ----------------------------------------------------------------
# Fundamental function, list drive names
Function List-Drive {
	wmic logicaldisk get name
}

# List directory content, alias: ls (a wrapper over Get-ChildItem)
# NOTE:
# - NO options are passed through
Function List-Content {
	# Argument parsing
	$_arg = Decode-CustomArgument @Args
	$_path = ('' -ne $_arg.Parameter) ? $_arg.Parameter : '.'
	$_opts = $_arg.Option
	# Processing
	$path = $_path | %{
		Decode-CustomPathToken $_
	}
	Get-ChildItem $path -ErrorVariable err 2>$null
	$Global:custom_error_status = $?
	# report status
	Report-Status $err $null	
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
		if ($Global:custom_workspace_info.Contains($wk_name)) {
			if (
				([Environment]::MachineName -in $Global:custom_workspace_info.$wk_name.Allow) -or
				('All' -eq $Global:custom_workspace_info.$wk_name.Allow)
			) {
				if (
					($Global:custom_workspace_info.Wi.AccPt -eq $Global:custom_workspace_info.$wk_name.AccPt) -or 
					($Global:custom_workspace_info.$wk_name.Host -eq 'iCloud')
				) {
					$Global:custom_error_status = $true
					$msg = "No need to mount the specified workpace $($wk_name)!"
					# report status
					Report-Status $null $msg
				} else {
					# get the next available drive to mount to
					$mount_point = (
						'A' .. 'Z' | ?{
							$_ -notin (Get-PSDrive -PSProvider filesystem).Name
						} | Select-Object -First 1
					) + ':'
					if (Test-Path $mount_point) {	
						$Global:custom_error_status = $false
						$err = "Mount point already exist! please take care!"
						# report status
						Report-Status $err $null
						return
					}		
					$mount_target = '\\' + 
						(('' -eq $IP) ? $Global:custom_workspace_info.$wk_name.IP : $IP) + '\' + 
						(('' -eq $Vol) ? $Global:custom_workspace_info.$wk_name.Volume : $Vol)
					$mount_id = '/user:' + $Global:custom_workspace_info.$wk_name.User
					$mount_pwd = $Global:custom_workspace_info.$wk_name.Pswd
					net use $mount_point $mount_target $mount_id $mount_pwd /persistent:no
					$Global:custom_error_status = $?
					# create symbolic-link to the access point
					if ($Global:custom_error_status) {
						$Global:custom_workspace_info.$wk_name.Add('drive', $mount_point)
						$link_to_mount_point = [IO.Path]::Combine(
							$HOME,
							(('' -eq $MPt) ? $Global:custom_workspace_info.$wk_name.AccPt : $MPt)
						)
						if (-not (Test-Path $link_to_mount_point)) {
							New-Item `
								-ItemType SymbolicLink `
								-Path $link_to_mount_point `
								-Value $Global:custom_workspace_info.$wk_name.drive `
								1>$null
						} else {
							$Global:custom_error_status = $false
							$err = "Link already exist! please take care!"
							# report status
							Report-Status $err $null
							return
						}
					}
				}
			}
		} else {
			$Global:custom_error_status = $false
			$err = "The specified workpace $($wk_name) is NOT available!"
			# report status
			Report-Status $err $null
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
			if ($Global:custom_workspace_info.$wk_name.Contains('drive')) {
				net use $Global:custom_workspace_info.$wk_name.drive /delete
				$Global:custom_error_status = $?
				$Global:custom_workspace_info.$wk_name.Remove('drive')
			}
			$link_pt = [IO.Path]::Combine(
				$HOME,
				(('' -eq $MPt) ? $Global:custom_workspace_info.$wk_name.AccPt : $MPt)
			)
			if (-not (Test-Path ([IO.Path]::Combine($link_pt, '*')))) {
				Remove-Item $link_pt
			}			
		}
	}
}

# Auxiliary function, construct text string about the Git repo. info. to be displayed @ prompt
Function Create-GitPrompt {
	$path = pwd
	if (Test-Path (Join-Path $path '.git') -PathType Container) {
		$Global:custom_git_info.git_prompt = 'inside'
		$Global:custom_git_info.git_dir = $path
	} elseif (
		$path -like ($Global:custom_git_info.git_dir + [IO.Path]::DirectorySeparatorChar + '*')
	) {
		$Global:custom_git_info.git_prompt = 'inside'
	} else {
		$Global:custom_git_info.git_prompt = 'N/A'
	}
}

# Alias setup
# ----------------------------------------------------------------	
Set-Alias -Name 'ls' -Value 'List-Content'

# Add custom tab complete behavior
# ----------------------------------------------------------------
Register-ArgumentCompleter `
	-Native `
	-CommandName 'ls' `
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
	-CommandName @('Mount-WKSP', 'Remove-WKSP') `
	-ParameterName 'Name' `
	-ScriptBlock {
		param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)	
		$Global:custom_workspace_info | Select-Object -ExpandProperty Keys | where {
			$_ -like ($WordToComplete + '*')
		}
	}
