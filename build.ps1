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

& ./build-prepare.ps1
if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERROR  ] Preparation failed, exiting."
	exit $LASTEXITCODE
}

& ./build-export.ps1
if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERROR  ] Export failed, exiting."
	exit $LASTEXITCODE
}

& ./build-deploy.ps1
if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERROR  ] Deployment failed, exiting."
	exit $LASTEXITCODE
}

Write-Host "[INFO   ] building post artifacts."
