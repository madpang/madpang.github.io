#! /usr/bin/env pwsh -NoProfile
<#$
	@file: build-export.ps1
	@brief: Build HTML artifacts for new and updated posts, outputting to tmp-ws/artifacts/.
	@note: This script should be executed on the working branch which has contents folder.
#>

$kWorkspace = "tmp-ws"
$kContents = "contents"

$m_template_file = Join-Path "commons" "templates" "post-template.html"
$m_build_exe = "./build-post.ps1"

$exportArtifactsDir = Join-Path $kWorkspace "artifacts"
$newFileList = Join-Path $kWorkspace "new-posts.txt"
$updateFileList = Join-Path $kWorkspace "update-posts.txt"

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
	$path2content = Join-Path $kContents $item ($item + ".txt")
	$path2artifact = Join-Path $exportArtifactsDir $item ($item + ".html")
	# Call external script to build the post
	& $m_build_exe $path2artifact $path2content $m_template_file
}

Write-Host "=> FINISHED exporting post artifacts to $exportArtifactsDir."
