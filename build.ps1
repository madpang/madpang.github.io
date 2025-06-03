#! /usr/bin/env pwsh -NoProfile
<#
	@file: build.ps1

	@brief: Build html artifacts from the content directory for website deployment.

	@details:
	This script is split into three parts in order to fit into the my GitHub Actions workflow---preparation, export on the working branch, and deployment on the gh-pages branch.

	@note:
	- This script only processes directories that meet naming convention `XX_YYYY_MM_DD_x`, where `XX` is a two-letter tag, and `YYYY_MM_DD_x` is a date with an optional suffix.
	- In local environment, just execute `pwsh -nop build.ps1`.

	@date:
	- created on 2025-05-17
	- updated on 2025-06-03

	@version: 0.2.1
#>

& ./build-prepare.ps1

& ./build-export.ps1

& ./build-deploy.ps1

Write-Host "==> FINISHED building post artifacts."
