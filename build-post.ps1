#! /usr/bin/env pwsh -NoProfile
<#
	@file: build-post.ps1
	
	@brief: Build a full HTML page of a post from a custom plain text markup.

	@details:
	1. Read the template HTML file.
	2. Use the mmd2html tool to convert the source text to HTML, and insert it into the anchor point in the template.
	3. Write the output to the target HTML file.

	@author
	- madpang

	@date: [created: 2025-05-18, updated: 2025-08-11]
#>

param(
	[Parameter(Mandatory = $True, Position = 1)][string]$path2html,
	[Parameter(Mandatory = $True, Position = 2)][string]$path2txt,
	[Parameter(Mandatory = $True, Position = 3)][string]$path2template
)

$kTempOutput = "tmp-output.html" # @note: this is an intermediate file, it is an temporary usage, and will be optimized in the future.

$m_converter = 'java -jar ./mmd2html/app/build/libs/mmd2html.jar'

$m_cmd = @($m_converter, $path2txt, $kTempOutput) -join ' '

Write-Host "[DEBUG] Converting source text to HTML: $m_cmd"

# === Convert the source text to HTML
Invoke-Expression $m_cmd
if ($LASTEXITCODE -ne 0) {
	Write-Host "[ERROR  ] mmd2html conversion failed with exit code $LASTEXITCODE."
	exit $LASTEXITCODE
}

if (-not (Test-Path $kTempOutput)) {
	Write-Host "[ERROR  ] mmd2html did not generate output file."
	exit 1
}

$formatted_lines = Get-Content -Path $kTempOutput -Encoding utf8

# --- Extract h1 heading (for display in the tab title)
$tab_title = $null
foreach ($line in $formatted_lines) {
	if ($line -match '<h1>(.*)</h1>') {
		$tab_title = $Matches[1]
		break
	}
}
if (-not $tab_title) {
	Write-Host "[ERROR  ] article must have a title."
	exit 1
}

$author_info = "MadPang"

# === Read the template HTML file
if (-not (Test-Path $path2template)) {
	Write-Host "[ERROR  ] Template file not found: $path2template"
	exit 1
}

$template_lines = Get-Content -Path $path2template

# === Initialize the output HTML
$m_out_lines = @()

# === Processing
$inBlockComment = $false
for ($ii = 0; $ii -lt $template_lines.Count; $ii++) {
	$line = $template_lines[$ii]
	# Check if the line is a block comment start, assuming only world character, `@`, and `:` are allowed
	if ($line -match '^<!--\s*(?<id>[@:\w]+)\s*$') {
		$inBlockComment = $true
		$id = $Matches['id']
		if ($id -eq '@ANCHOR:NULL') {
			$m_out_lines += '<!-- @note: This file is auto-generated. MANUAL EDITS WILL BE LOST -->'
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
		$m_out_lines += "$tab_title | $author_info"
		continue
	}
	if ($line -match "^<!--\s*@ANCHOR:ARTICLE\s*-->$") {
		# Insert the formatted lines into the anchor point
		$m_out_lines += $formatted_lines
		continue
	}

	# Add normal line to the output
	$m_out_lines += $line
}

# === Write the output to HTML file

# Create the containing folder of the HTML post if it does not exist
$out_dir = Split-Path -Path $path2html -Parent
if (-not (Test-Path $out_dir)) {
	try {
		New-Item -ItemType Directory -Path $out_dir | Out-Null
	} catch {
		Write-Host "[ERROR  ] Failed to create output directory: $out_dir"
		exit 1
	}
}

try {
	Set-Content -Path $path2html -Value $m_out_lines -Encoding utf8
	Write-Host "[INFO   ] Successfully created: $path2html"
	exit 0
} catch {
	Write-Host "[ERROR  ] Failed to write output file: $path2html"
	exit 1
}
