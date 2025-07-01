#! /usr/bin/env pwsh -NoProfile
<#
	@file: build-deploy.ps1
	@brief: Deploy built artifacts from tmp-ws/artifacts/ to artifacts/ (for gh-pages branch)
	@details: Syncs the exported HTMLs and post-index.txt, and removes deleted posts from artifacts/.
	@note: This script should be executed on the deployment branch---which contains the artifacts directory.
#>

$kWorkspace = "tmp-ws"
$kArtifacts = "artifacts"

$exportArtifactsDir = Join-Path $kWorkspace $kArtifacts
$deleteFileList = Join-Path $kWorkspace "delete-posts.txt"

# If the temporary artifacts directory does not exist, abort
if (-not (Test-Path $kWorkspace)) {
	Write-Error "ERROR: Temporary workspace directory '$kWorkspace' does not exist."
	exit 1
}

# Ensure artifacts directory exists
if (-not (Test-Path $kArtifacts)) {
	New-Item -Path $kArtifacts -ItemType Directory | Out-Null
}

# Copy new/updated HTML files from tmp-ws/artifacts/ to artifacts/
if (Test-Path $exportArtifactsDir) {
	Move-Item -Path "$exportArtifactsDir\*" -Destination $kArtifacts -Force
}

# Remove deleted posts from artifacts/
if (Test-Path $deleteFileList) {
	$deleteList = Get-Content $deleteFileList -Encoding utf8
	foreach ($item in $deleteList) {
		$artifactPath = Join-Path $kArtifacts $item
		if (Test-Path $artifactPath) {
			Remove-Item -Path $artifactPath -Recurse -Force
		}
	}
}

# Remove the temporary kWorkspace directory
Remove-Item -Path $kWorkspace -Recurse -Force

Write-Host "=> Deployment to artifacts/ complete."
