#! /usr/bin/env pwsh -NoProfile
<#
	@file: build-deploy.ps1
	@brief: Deploy built artifacts from tmp-ws/artifacts/ to artifacts/ (for gh-pages branch)
	@details: Syncs the exported HTMLs and post-index.txt, and removes deleted posts from artifacts/.
	@note: This script should be executed on the deployment branch---which contains the artifacts directory.
#>

$workspace = "tmp-ws"
$exportArtifactsDir = Join-Path $workspace "artifacts"
$artifactsDir = "artifacts"
$deleteFileList = Join-Path $workspace "delete-posts.txt"

# If the temporary artifacts directory does not exist, abort
if (-not (Test-Path $workspace)) {
	Write-Error "ERROR: Temporary workspace directory '$workspace' does not exist."
	exit 1
}

# Ensure artifacts directory exists
if (-not (Test-Path $artifactsDir)) {
	New-Item -Path $artifactsDir -ItemType Directory | Out-Null
}

# Copy new/updated HTML files from tmp-ws/artifacts/ to artifacts/
if (Test-Path $exportArtifactsDir) {
	Move-Item -Path "$exportArtifactsDir\*" -Destination $artifactsDir -Force
}

# Remove deleted posts from artifacts/
if (Test-Path $deleteFileList) {
	$deleteList = Get-Content $deleteFileList -Encoding utf8
	foreach ($item in $deleteList) {
		$artifactPath = Join-Path $artifactsDir $item
		if (Test-Path $artifactPath) {
			Remove-Item -Path $artifactPath -Recurse -Force
		}
	}
}

# Remove the temporary workspace directory
Remove-Item -Path $workspace -Recurse -Force

Write-Host "=> Deployment to artifacts/ complete."
