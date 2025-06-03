#! /usr/bin/env pwsh -NoProfile
<#$
	@file: build-export.ps1
	@brief: Build HTML artifacts for new and updated posts, outputting to tmp-ws/artifacts/.
	@note: This script should be executed on the working branch which has contents folder.
#>

$workspace = "tmp-ws"
$contentsDir = "contents"
$exportArtifactsDir = Join-Path $workspace "artifacts"
$newFileList = Join-Path $workspace "new-posts.txt"
$updateFileList = Join-Path $workspace "update-posts.txt"
$path2template_ = Join-Path "commons" "templates" "post-template.html"
$builder_ = "./build-post.ps1"

# Read new and update lists
$newList = @()
$updateList = @()
if (Test-Path $newFileList) {
	$newList = Get-Content $newFileList -Encoding utf8
}
if (Test-Path $updateFileList) {
	$updateList = Get-Content $updateFileList -Encoding utf8
}

$buildList = $newList + $updateList
foreach ($item in $buildList) {
	$path2content = Join-Path $contentsDir $item ($item + ".txt")
	$path2artifact = Join-Path $exportArtifactsDir $item ($item + ".html")
	# Call external script to build the post
	& $builder_ $path2artifact $path2content $path2template_
}

Write-Host "=> FINISHED exporting post artifacts to $exportArtifactsDir."
