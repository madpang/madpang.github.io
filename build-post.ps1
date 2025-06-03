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
	- updated on 2025-05-18
#>

param(
	[Parameter(Mandatory = $True, Position = 1)][string]$path2html,
	[Parameter(Mandatory = $True, Position = 2)][string]$path2txt,
	[Parameter(Mandatory = $True, Position = 3)][string]$path2html_template
)

$converter_ = "./tools/mmd2html/mmd2html"

# === Convert the source text to HTML
$formatted_lines = (& $converter_ $path2txt)

# --- Extract h1 heading (for display in the tab title)
$tab_title_ = $null
foreach ($line in $formatted_lines) {
	if ($line -match '<h1>(.*)</h1>') {
		$tab_title_ = $Matches[1]
		break
	}
}
if (-not $tab_title_) {
	Write-Error "ERROR: article must have a title."
	exit 2
}

$author_info_ = "MadPang"

# === Read the template HTML file
$t_lines_ = Get-Content -Path $path2html_template

# === Initialize the output HTML
$out_lines_ = @()

# === Processing
$inBlockComment = $false
for ($ii = 0; $ii -lt $t_lines_.Count; $ii++) {
	$line = $t_lines_[$ii]
	# Check if the line is a block comment start, assuming only world character, `@`, and `:` are allowed
	if ($line -match '^<!--\s*(?<id>[@:\w]+)\s*$') {
		$inBlockComment = $true
		$id = $Matches['id']
		if ($id -eq '@ANCHOR:NULL') {
			$out_lines_ += '<!-- @note: This file is auto-generated. MANUAL EDITS WILL BE LOST -->'
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
		$out_lines_ += "$tab_title_ | $author_info_"
		continue
	}
	if ($line -match "^<!--\s*@ANCHOR:ARTICLE\s*-->$") {
		# Insert the formatted lines into the anchor point
		$out_lines_ += $formatted_lines
		continue
	}

	# Add normal line to the output
	$out_lines_ += $line
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

Set-Content -Path $path2html -Value $out_lines_ -Encoding utf8
