#! /usr/bin/env pwsh -NoProfile
<#
	@file: build-deploy.ps1

	@brief: Deploy built artifacts from `tmp-ws/artifacts/` to `artifacts/` (for gh-pages branch).

	@details: Syncs the exported HTMLs and post-index.txt, and removes deleted posts.

	@note: This script should be executed on the deployment branch---which contains the artifacts directory.

	@author: madpang

	@date: [created: 2025-06-03, updated: 2025-08-11]
#>

$kWorkspace = "tmp-ws"
$kArtifacts = "artifacts"

$artifactsExportDir = Join-Path $kWorkspace $kArtifacts
$deletedListFile = Join-Path $kWorkspace "posts-to-delete.txt"

# If the temporary artifacts directory does not exist, abort
if (-not (Test-Path $kWorkspace)) {
	Write-Error "[ERROR  ] Temporary workspace directory '$kWorkspace' does not exist."
	exit 1
}

# Ensure artifacts directory exists
if (-not (Test-Path $kArtifacts)) {
	New-Item -Path $kArtifacts -ItemType Directory | Out-Null
}

# Copy new/updated HTML files from tmp-ws/artifacts/ to artifacts/
Get-ChildItem -Path $artifactsExportDir -Directory | ForEach-Object {
	$destinationPath = Join-Path $kArtifacts $_.Name
	Copy-Item -Path $_.FullName -Destination $kArtifacts -Force -Recurse
}
# Overwrite `artifacts/post-index.txt`.
Copy-Item -Path (Join-Path $artifactsExportDir "post-index.txt") -Destination (Join-Path $kArtifacts "post-index.txt") -Force

# Remove deleted posts from artifacts/
if (Test-Path $deletedListFile) {
	$deletedList = Get-Content $deletedListFile -Encoding utf8
	foreach ($item in $deletedList) {
		$artifactPath = Join-Path $kArtifacts $item
		if (Test-Path $artifactPath) {
			Remove-Item -Path $artifactPath -Recurse -Force
		}
	}
}

Write-Host "[INFO   ] Finished deployment of artifacts."
