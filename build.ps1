#! /usr/bin/env pwsh -NoProfile
<#
    @file: build.ps1

    @brief: Build html artifacts from the content directory for website deployment.

    @details: It copies `./content/*` to `./artifact/`

	@note:
	- This script only processes directories that meet naming convention `XX_YYYY_MM_DD_x`, where `XX` is a two-letter tag, and `YYYY_MM_DD_x` is a date with an optional suffix.

    @date:
    - created on 2025-05-17
    - updated on 2025-06-01

    @version: 0.2.0
#>

$contentsDir = "contents"
$artifactsDir = "artifacts"
$indexFile = Join-Path $artifactsDir "post-index.txt"
$hotIndexFile = Join-Path $artifactsDir "hot-post-index.txt"

Write-Host "==> Scanning current post information..."

$currentPostLists = Get-ChildItem $contentsDir -Directory | Where-Object { $_.Name -match '^(?<tag>[A-Z]{2})_(?<key>\d{4}_\d{2}_\d{2}_[a-z])$' } | ForEach-Object {
	$contentFile = Join-Path $_.FullName ($_.Name + ".txt")
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
	$newRecords | ForEach-Object { "$( $_["Name"] )`t$( $_["Version"] )" } | Set-Content -Path $hotIndexFile -Encoding utf8
	Write-Host "==> Found $($currentPostLists.Count) post(s)."
} else {
	Write-Host "==> No valid posts found."
	return
}

Write-Host "==> Checking the previous post records..."

$oldPostLists = (Test-Path $indexFile) ? (
	Get-Content -Path $indexFile -Encoding utf8 | Where-Object {
		$_ -match '^(?<tag>[A-Z]{2})_(?<key>[0-9]{4}_[0-9]{2}_[0-9]{2}_[a-z])\t(?<ver>\d+\.\d+\.\d+)$'
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
} else {
	Write-Host "==> No previous post records found."
}
	
# === Main Processing ===

$i = 0
$j = 0
while (($i -lt $oldRecords.Count) -and ($j -lt $newRecords.Count)) {
	$oldRecord = $oldRecords[$i]
	$newRecord = $newRecords[$j]
	# @note: Key is sorted, and it is comparable.
	if ($oldRecord['Key'] -eq $newRecord['Key']) {
		if ($oldRecord['Version'] -eq $newRecord["Version"]) {
			Write-Host "=> No change for post $($oldRecord['Name']), skipping."
		} else {
			Write-Host "=> Updating post $($newRecord['Name'])."
			# @todo
		}
		$i++
		$j++
	} elseif ($oldRecord['Key'] -lt $newRecord["Key"]) {
		Write-Host "=> Deleting post $($oldRecord['Name'])."
		# @todo
		$i++
	} else { # $oldRecord['Key'] > $newRecord["Key"]
		Write-Host "=> Adding new post $($newRecord['Name'])."
		# @todo
		$j++
	}
}

# Remaining old items are deletions
while ($i -lt $oldRecords.Count) {
	Write-Host "=> Deleting post $($oldRecords[$i]['Name'])."
	# @todo
	$i++
}

# Remaining new items are additions
while ($j -lt $newRecords.Count) {
	Write-Host "=> Adding new post $($newRecords[$j]['Name'])."
	# @todo
	$j++
}
