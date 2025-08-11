#! /usr/bin/env pwsh -NoProfile
<#
	@file: build.ps1

	@brief: Build html artifacts from the content directory for website deployment.

	@details:
	This script is split into three parts in order to fit into the my GitHub Actions workflow---preparation, export on the working branch, and deployment on the gh-pages branch.

	@note:
	- This script only processes directories that meet naming convention `XX_YYYY_MM_DD_x`, where `XX` is a two-letter tag, and `YYYY_MM_DD_x` is a date with an optional suffix.
	- In local environment, just execute `pwsh -nop build.ps1`.

	@date: [created: 2025-05-17, updated: 2025-08-11]

	@version: 0.3.0
#>

& ./prepare-build.ps1
if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERROR  ] Preparation failed, exit."
	exit $LASTEXITCODE
}

& ./export-build.ps1
if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERROR  ] Export failed, exit."
	exit $LASTEXITCODE
}

& ./deploy-build.ps1
if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERROR  ] Deployment failed, exit."
	exit $LASTEXITCODE
}

Write-Host "[INFO   ] Cleaning up post build workspace..."
# Clean up the temporary workspace
$kWorkspace = "tmp-ws"
if (Test-Path $kWorkspace) {
	Remove-Item -Path $kWorkspace -Recurse -Force
}

Write-Host "[INFO   ] Build process completed successfully."
exit 0
