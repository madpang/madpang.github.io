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

	@date:
	- created on 2025-05-18
	- updated on 2025-07-01
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
	Write-Host "[ERROR] mmd2html conversion failed with exit code $LASTEXITCODE."
	exit
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
	Write-Error "ERROR: article must have a title."
	exit 2
}

$author_info = "MadPang"

# === Read the template HTML file
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
		$out_lines += "$tab_title | $v_author_info"
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
		Write-Error "ERROR: Failed to create output directory."
		exit -1
	}
}

Set-Content -Path $path2html -Value $m_out_lines -Encoding utf8
