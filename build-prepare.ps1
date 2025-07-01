#! /usr/bin/env pwsh -NoProfile
<#$
	@file: build-prepare.ps1
	@brief: Prepare for building HTML artifacts from the text manuscripts
	@note: This script should be executed on the working branch which has contents folder.
#>

$kWorkspace = "tmp-ws"
$kContents = "contents"
$kArtifacts = "artifacts"

$oldIndexFile = Join-Path $kArtifacts "post-index.txt"
$hotIndexFile = Join-Path $kWorkspace $kArtifacts "post-index.txt"

# if contents directory does not exist, abort
if (-not (Test-Path $kContents)) {
	Write-Error "ERROR: contents directory does not exist."
	exit 1
}

# If tmp kWorkspace already exists, remove it
if (Test-Path $kWorkspace) {
	Remove-Item -Path $kWorkspace -Recurse -Force
}
New-Item -Path $kWorkspace -ItemType Directory | Out-Null
New-Item -Path (Join-Path $kWorkspace $kArtifacts) -ItemType Directory | Out-Null

Write-Host "==> Scanning current post information..."

$currentPostLists = Get-ChildItem $kContents -Directory | Where-Object { $_.Name -match '^(?<tag>[A-Z]{2})_(?<key>\d{4}_\d{2}_\d{2}_[a-z])$' } | ForEach-Object {
	$contentFile = Join-Path $kContents $_.Name ($_.Name + ".txt")
	if (Test-Path $contentFile) {
		$key = $Matches['key']
		$name = $_.Name
		$version = $null
		# Extract the version info. of the post
		foreach($line in [System.IO.File]::ReadLines($contentFile)) {
			if ($line -match '^\+{3}$') {
				# only read as far as the header ends
				break
			} elseif ($line -match '^@version:\s*(\d+\.\d+\.\d+)\s*$') {
				$version = $Matches[1]
			} else {
				continue
			}
		}
		if ($version) {
			# collect the entry
			@{
				"Key" = $key
				"Name" = $name
				"Version" = $version
			}
		} # else do nothing
	}
}

# If the list is not empty, sort it by key and write to the index file
$newRecords = @()
if ($currentPostLists) {
	# Keep as objects for processing
	$newRecords += $currentPostLists | Sort-Object -Property "Key"
	# Write to file in string format
	$newRecords | ForEach-Object { "$( $_['Name'] )`t$( $_['Version'] )" } | Set-Content -Path $hotIndexFile -Encoding utf8
	Write-Host "=> Found $($currentPostLists.Count) post(s)."
} else {
	Write-Host "=> No valid posts found."
	return
}

Write-Host "==> Checking the previous post records..."

$oldPostLists = (Test-Path $oldIndexFile) ? (
	Get-Content -Path $oldIndexFile -Encoding utf8 | Where-Object {
		$_ -match '^(?<tag>[A-Z]{2})_(?<key>[0-9]{4}_[0-9]{2}_[0-9]{2}_[a-z])[\t\s]+(?<ver>\d+\.\d+\.\d+)$'
	} | ForEach-Object {
		@{
			"Key" = $Matches['key']
			"Name" = $Matches['tag'] + "_" + $Matches['key']
			"Version" = $Matches['ver']
		}
	}
) : @()

$oldRecords = @()
if ($oldPostLists) {
	# Sort the previous posts by key
	$oldRecords += $oldPostLists | Sort-Object -Property "Key"
	Write-Host "=> Previous records found."
} else {
	Write-Host "=> No previous post records found."
}
	
# === Main Processing ===
Write-Host "==> Building post artifacts..."

# --- Determine new/update/delete actions

$newList = @()
$updateList = @()
$deleteList = @()

$i = 0
$j = 0
while (($i -lt $oldRecords.Count) -and ($j -lt $newRecords.Count)) {
	$oldRecord = $oldRecords[$i]
	$newRecord = $newRecords[$j]
	# @note: Key is sorted, and it is comparable.
	if ($oldRecord['Key'] -eq $newRecord['Key']) {
		if ($oldRecord['Version'] -eq $newRecord['Version']) {
			Write-Host "=> Skipping unchanged post $($oldRecord['Name'])"
		} else {
			Write-Host "=> Updating modified post $($newRecord['Name'])"
			$updateList += $newRecord['Name']
		}
		$i++
		$j++
	} elseif ($oldRecord['Key'] -lt $newRecord['Key']) {
		Write-Host "=> Deleting post $($oldRecord['Name'])"
		$deleteList += $oldRecord['Name']
		$i++
	} else { # $oldRecord['Key'] > $newRecord['Key']
		Write-Host "=> Adding new post $($newRecord['Name'])"
		$newList += $newRecord['Name']
		$j++
	}
}

# Remaining old items are deletions
while ($i -lt $oldRecords.Count) {
	Write-Host "=> Removing deleted post $($oldRecords[$i]['Name'])"
	$deleteList += $oldRecords[$i]['Name']
	$i++
}

# Remaining new items are additions
while ($j -lt $newRecords.Count) {
	Write-Host "=> Adding new post $($newRecords[$j]['Name'])"
	$newList += $newRecords[$j]['Name']
	$j++
}

# --- Export the new/update/delete lists

$newList | Set-Content -Path (Join-Path $kWorkspace "new-posts.txt") -Encoding utf8

$updateList | Set-Content -Path (Join-Path $kWorkspace "update-posts.txt") -Encoding utf8

$deleteList | Set-Content -Path (Join-Path $kWorkspace "delete-posts.txt") -Encoding utf8
