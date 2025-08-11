#! /usr/bin/env pwsh -NoProfile
<#
	@file: build-post.ps1
	
	@brief: Build a full HTML page of a post from a custom plain text markup.

	@details:
	1. Read the template HTML file.
	2. Use the mmd2html tool to convert the source text to HTML, and insert it into the anchor point in the template.
	3. Write the output to the target HTML file.

	@author: madpang

	@date: [created: 2025-05-18, updated: 2025-08-11]
#>

param(
	[Parameter(Mandatory = $True, Position = 1)][string]$path2html,
	[Parameter(Mandatory = $True, Position = 2)][string]$path2txt,
	[Parameter(Mandatory = $True, Position = 3)][string]$path2template
)

$kTempOutput = "tmp-output.html" # @note: this is an intermediate file, it is an temporary usage, and will be optimized in the future.

$mConverter = 'java -jar ./mmd2html/app/build/libs/mmd2html.jar'

$mCmd = @($mConverter, $path2txt, $kTempOutput) -join ' '

Write-Host "[DEBUG  ] Converting source text to HTML: $mCmd"

# --- Convert the source text to HTML
Invoke-Expression $mCmd

if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERROR  ] mmd2html conversion failed with exit code $LASTEXITCODE."
	exit $LASTEXITCODE
}

if (-not (Test-Path $kTempOutput)) {
	Write-Host "[ERROR  ] mmd2html did not generate output file."
	exit 1
}

$formattedLines = Get-Content -Path $kTempOutput -Encoding utf8

# --- Extract h1 heading (for display in the web browser tab)
$browserTabTitle = $null
foreach ($line in $formattedLines) {
	if ($line -match '<h1>(.*)</h1>') {
		$browserTabTitle = $Matches[1]
		break
	}
}
if (-not $browserTabTitle) {
	Write-Host "[ERROR  ] article must have a title."
	exit 1
}

# --- Read the template HTML file
if (-not (Test-Path $path2template)) {
	Write-Host "[ERROR  ] Template file not found: $path2template"
	exit 1
}

$templateLines = Get-Content -Path $path2template

# --- Assemble the output HTML file
$authorInfo = "MadPang"
$inBlockComment = $false
$outputLines = @()
for ($ii = 0; $ii -lt $templateLines.Count; $ii++) {
	$line = $templateLines[$ii]
	# Check if the line is a block comment start, assuming only world character, `@`, and `:` are allowed
	if ($line -match '^<!--\s*(?<id>[@:\w]+)\s*$') {
		$inBlockComment = $true
		$id = $Matches['id']
		if ($id -eq '@ANCHOR:NULL') {
			$outputLines += '<!-- @note: This file is auto-generated. MANUAL EDITS WILL BE LOST -->'
		}
		continue
	}
	if ($line -match '^-->$') {
		$inBlockComment = $false
		continue
	}
	if ($inBlockComment) {
		# Skip the block comment
		continue
	}
	if ($line -match '^<!--\s*@ANCHOR:TITLE\s*-->$') {
		# Insert the title text into the anchor point
		$outputLines += "$browserTabTitle | $authorInfo"
		continue
	}
	if ($line -match "^<!--\s*@ANCHOR:ARTICLE\s*-->$") {
		# Insert the formatted lines into the anchor point
		$outputLines += $formattedLines
		continue
	}

	# Add normal line to the output
	$outputLines += $line
}

# === Write the output to HTML file

# Create the containing folder of the HTML post if it does not exist
$outputDir = Split-Path -Path $path2html -Parent
if (-not (Test-Path $outputDir)) {
	try {
		New-Item -ItemType Directory -Path $outputDir | Out-Null
	} catch {
		Write-Host "[ERROR  ] Failed to create output directory: $outputDir"
		exit 1
	}
}

try {
	Set-Content -Path $path2html -Value $outputLines -Encoding utf8
	Write-Host "[DEBUG  ] Successfully created: $path2html"
	exit 0
} catch {
	Write-Host "[ERROR  ] Failed to write output file: $path2html"
	exit 1
}
